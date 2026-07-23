import Foundation
import AppKit

/// 轉錄流水線：串接 錄音 → API 辨識 → 後處理 → 文字注入
@Observable
final class TranscriptionPipeline {
    static let shared = TranscriptionPipeline()

    let audioRecorder = AudioRecorder()
    private let hotkeyManager = HotkeyManager.shared
    private let settingsStore = SettingsStore.shared

    var state: TranscriptionState = .idle
    var lastResult: TranscriptionResult?
    var errorMessage: String?

    private var activationTimer: Timer?

    private init() {
        setupHotkey()
    }

    // MARK: - 快捷鍵設定

    private func setupHotkey() {
        hotkeyManager.onKeyDown = { [weak self] in
            self?.startRecording()
        }

        hotkeyManager.onKeyUp = { [weak self] in
            self?.stopRecordingAndTranscribe()
        }

        hotkeyManager.onCancel = { [weak self] in
            self?.cancelRecording()
        }
    }

    /// 取消目前錄音
    func cancelRecording() {
        guard state == .recording else { return }
        AppDelegate.shared.updateStatusIcon(isRecording: false)

        // 恢復系統音訊
        if settingsStore.settings.muteSystemAudioWhileRecording {
            SystemAudioManager.restoreSystemAudio()
        }

        _ = audioRecorder.stopRecording() // 丟棄音訊
        state = .cancelled

        if settingsStore.settings.playSoundEffects {
            NSSound(named: .init("Funk"))?.play()
        }

        // 自動回到閒置狀態
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if case .cancelled = self.state {
                self.state = .idle
            }
        }
    }

    /// 啟動全域快捷鍵監聽（若權限尚未授權，會自動每 2 秒重試）
    func activate() {
        // 同步啟動鍵設定
        hotkeyManager.activationKey = settingsStore.settings.activationKey
        if hotkeyManager.start() {
            // 成功啟動，清除重試計時器
            activationTimer?.invalidate()
            activationTimer = nil
            if case .error = state {
                state = .idle
            }
        } else {
            state = .error("需要輔助使用權限，請在系統設定中允許")
            // 設定定時重試，等待使用者授權後自動啟動
            if activationTimer == nil {
                activationTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                    self?.activate()
                }
            }
        }
    }

    /// 停止全域快捷鍵監聽
    func deactivate() {
        activationTimer?.invalidate()
        activationTimer = nil
        hotkeyManager.stop()
    }

    // MARK: - 錄音流程

    func startRecording() {
        guard state != .recording && state != .processing else { return }

        // 檢查麥克風權限
        guard AudioRecorder.hasPermission else {
            Task {
                let granted = await AudioRecorder.requestPermission()
                if !granted {
                    state = .error("需要麥克風使用權限")
                }
            }
            return
        }

        // 檢查 API Key
        guard settingsStore.apiKey() != nil else {
            state = .error("請先設定 API Key")
            return
        }

        do {
            // 錄音時自動靜音系統音訊
            if settingsStore.settings.muteSystemAudioWhileRecording {
                SystemAudioManager.muteSystemAudio()
            }

            try audioRecorder.startRecording()
            state = .recording
            AppDelegate.shared.updateStatusIcon(isRecording: true)

            // 播放開始音效
            if settingsStore.settings.playSoundEffects {
                NSSound(named: .init("Tink"))?.play()
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func stopRecordingAndTranscribe() {
        guard state == .recording else { return }
        AppDelegate.shared.updateStatusIcon(isRecording: false)

        // 恢復系統音訊
        if settingsStore.settings.muteSystemAudioWhileRecording {
            SystemAudioManager.restoreSystemAudio()
        }

        guard let audioData = audioRecorder.stopRecording() else {
            state = .idle
            return
        }

        // 播放結束音效
        if settingsStore.settings.playSoundEffects {
            NSSound(named: .init("Pop"))?.play()
        }

        // 如果錄音太短（小於 0.3 秒），忽略
        if audioRecorder.recordingDuration < 0.3 {
            state = .idle
            return
        }

        state = .processing

        Task {
            await transcribeAndInject(audioData: audioData)
        }
    }

    // MARK: - 辨識與注入

    private func transcribeAndInject(audioData: Data) async {
        do {
            // 1. 呼叫 API 辨識（使用設定中的 STT 供應商）
            let settings = settingsStore.settings
            let service = STTServiceFactory.create(for: settings.activeProvider)

            var result = try await service.transcribe(
                audioData: audioData,
                language: settings.primaryLanguage.whisperCode,
                prompt: settings.whisperPrompt
            )

            // logger.notice("[TypeTop] Whisper 原始結果: \(result.rawText, privacy: .public)")

            // 2. LLM 語意後處理（使用獨立的 LLM 供應商）
            let llmProvider = settings.llmProvider
            let llmApiKey = settingsStore.llmApiKey(for: llmProvider) ?? ""
            if settings.enableLLMPostProcessing,
               (!llmProvider.requiresAPIKey || !llmApiKey.isEmpty) {
                // 附加常用詞提示，協助 LLM 在同音字之間選對詞
                var systemPrompt = settings.llmSystemPrompt
                let hintWords = VocabularyStore.shared.library.hintWords
                if !hintWords.isEmpty {
                    systemPrompt += "\n\n使用者常用詞彙（遇同音或發音相近的字詞時，優先採用以下寫法）：\n" + hintWords.joined(separator: "、")
                }

                if llmProvider == .apple {
                    // Apple Intelligence 本機模型（FoundationModels framework）
                    if #available(macOS 26.0, *) {
                        do {
                            result.processedText = try await AppleFoundationModel.process(
                                result.rawText,
                                systemPrompt: systemPrompt,
                                temperature: settings.llmTemperature
                            )
                            UsageTracker.shared.record("llm.apple")
                        } catch {
                            // 本機模型失敗（含安全護欄誤判）：使用原始辨識結果
                            // logger.notice("[TypeTop] Apple 本機模型失敗: \(error, privacy: .public)")
                        }
                    }
                } else {
                    let llmURL = settingsStore.llmURL(for: llmProvider)
                    let llmModel = settingsStore.llmModel(for: llmProvider)
                    // logger.notice("[TypeTop] LLM 後處理啟用，使用 \(llmProvider.displayName, privacy: .public) / \(llmModel, privacy: .public)")
                    let scope = APIAccountStore.scope(llm: llmProvider)
                    let accountStore = APIAccountStore.shared
                    var apiKey = llmApiKey
                    // 達額度（429）時自動輪替到下一組帳號重試，全部試過才跳出切換供應商詢問
                    var triedIDs: Set<UUID> = []
                    while true {
                        let llm = LLMPostProcessor(
                            url: llmURL,
                            model: llmModel,
                            apiKey: apiKey,
                            systemPrompt: systemPrompt,
                            temperature: settings.llmTemperature,
                            usageKey: accountStore.usageKey(scope)
                        )
                        do {
                            result.processedText = try await llm.process(result.rawText)
                            // logger.notice("[TypeTop] LLM 修正結果: \(result.processedText, privacy: .public)")
                            break
                        } catch LLMError.rateLimited {
                            if let currentID = accountStore.activeAccount(scope)?.id {
                                triedIDs.insert(currentID)
                            }
                            let next = await MainActor.run { accountStore.switchToNext(scope) }
                            if let next, !triedIDs.contains(next.id) {
                                apiKey = next.key
                            } else {
                                // 所有帳號額度用罄：跳出切換詢問，本次直接使用原始辨識結果
                                await MainActor.run { QuotaAlert.llmQuotaExceeded() }
                                break
                            }
                        } catch {
                            // logger.notice("[TypeTop] LLM 後處理失敗: \(error, privacy: .public)")
                            break
                        }
                    }
                }
            } else {
                // logger.notice("[TypeTop] LLM 後處理未啟用")
            }

            // 3. 規則式後處理（中英間距、標點轉換、詞彙替換）
            let processor = TextPostProcessor(settings: settings)
            result.processedText = processor.process(result.processedText)
            // logger.notice("[TypeTop] 最終輸出: \(result.processedText, privacy: .public)")

            // 4. 注入文字
            if !result.processedText.isEmpty {
                await TextInjector.inject(result.processedText)
            }

            lastResult = result
            state = .completed(result.processedText)

            // 4. 自動回到閒置狀態
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if case .completed = state {
                state = .idle
            }
        } catch {
            if case STTError.rateLimited = error {
                await MainActor.run { QuotaAlert.sttQuotaExceeded() }
            }
            state = .error(error.localizedDescription)
            errorMessage = error.localizedDescription

            // 自動清除錯誤狀態
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if case .error = state {
                state = .idle
                errorMessage = nil
            }
        }
    }
}
