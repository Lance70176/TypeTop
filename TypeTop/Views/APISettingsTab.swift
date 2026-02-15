import SwiftUI

/// API Key 管理設定頁面
struct APISettingsTab: View {
    private var settingsStore = SettingsStore.shared

    // STT
    @State private var groqKey: String = ""
    @State private var groqKeyVisible: Bool = false
    @State private var testingSTT: Bool = false

    // LLM
    @State private var llmKey: String = ""
    @State private var llmKeyVisible: Bool = false
    @State private var testingLLM: Bool = false

    @State private var testResult: (success: Bool, message: String)?

    private var selectedLLM: LLMProvider {
        settingsStore.settings.llmProvider
    }

    var body: some View {
        Form {
            // MARK: - STT Section
            Section("語音辨識（STT）— Groq") {
                sttKeyField
                HStack {
                    Text("模型")
                    Spacer()
                    Text(APIProvider.groq.modelName)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("如何取得 Groq API Key：")
                        .font(.caption).bold()
                    Text("1. 前往 console.groq.com 註冊／登入")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("2. 左側選單點「API Keys」→「Create API Key」")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("3. 複製 gsk_ 開頭的 Key 貼到上方欄位")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Groq 提供免費額度，日常使用綽綽有餘。")
                        .font(.caption).foregroundStyle(.secondary).italic()
                    Button("開啟 Groq Console") {
                        NSWorkspace.shared.open(URL(string: "https://console.groq.com/keys")!)
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                }
                .padding(.vertical, 2)
            }

            // MARK: - LLM Section
            Section("語意修正（LLM）— \(selectedLLM.displayName)") {
                Picker("LLM 供應商", selection: Bindable(settingsStore).settings.llmProvider) {
                    ForEach(LLMProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }

                // 自訂 endpoint 欄位
                if selectedLLM == .custom {
                    TextField("Base URL", text: Bindable(settingsStore).settings.customLLMBaseURL)
                        .textFieldStyle(.roundedBorder)
                    TextField("模型名稱", text: Bindable(settingsStore).settings.customLLMModel)
                        .textFieldStyle(.roundedBorder)
                }

                // API Key 欄位（Ollama 不需要）
                if selectedLLM.requiresAPIKey {
                    llmKeyField
                }

                HStack {
                    Text("模型")
                    Spacer()
                    Text(settingsStore.llmModel())
                        .foregroundStyle(.secondary)
                }

                // 說明文字
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedLLM.helpText)
                        .font(.caption).foregroundStyle(.secondary)

                    if let helpURL = selectedLLM.helpURL {
                        Button("開啟 \(selectedLLM.displayName) 官網") {
                            NSWorkspace.shared.open(URL(string: helpURL)!)
                        }
                        .font(.caption)
                        .buttonStyle(.link)
                    }
                }
                .padding(.vertical, 2)

                // 測試 LLM 連線
                HStack {
                    Button("測試 LLM 連線") {
                        testLLM()
                    }
                    .disabled(testingLLM || (selectedLLM.requiresAPIKey && llmKey.isEmpty))

                    if testingLLM {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }

            if let result = testResult {
                Section {
                    HStack {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.success ? .green : .red)
                        Text(result.message)
                            .font(.caption)
                            .textSelection(.enabled)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(result.message, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("複製訊息")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadKeys()
        }
        .onChange(of: settingsStore.settings.llmProvider) { _, _ in
            loadLLMKey()
            testResult = nil
        }
    }

    // MARK: - STT Key Field

    @ViewBuilder
    private var sttKeyField: some View {
        HStack {
            if groqKeyVisible {
                TextField("gsk_...", text: $groqKey)
                    .textFieldStyle(.roundedBorder)
            } else {
                SecureField("gsk_...", text: $groqKey)
                    .textFieldStyle(.roundedBorder)
            }
            Button {
                groqKeyVisible.toggle()
            } label: {
                Image(systemName: groqKeyVisible ? "eye.slash" : "eye")
            }
            .buttonStyle(.borderless)
        }
        .onChange(of: groqKey) { _, newValue in
            if !newValue.isEmpty {
                settingsStore.setAPIKey(newValue, for: .groq)
            }
        }

        HStack {
            Button("測試連線") {
                testSTT()
            }
            .disabled(groqKey.isEmpty || testingSTT)

            if testingSTT {
                ProgressView()
                    .controlSize(.small)
            }

            Spacer()

            if !groqKey.isEmpty {
                Button("清除", role: .destructive) {
                    groqKey = ""
                    settingsStore.clearAPIKey(for: .groq)
                }
            }
        }
    }

    // MARK: - LLM Key Field

    @ViewBuilder
    private var llmKeyField: some View {
        HStack {
            if llmKeyVisible {
                TextField(selectedLLM.keyPlaceholder, text: $llmKey)
                    .textFieldStyle(.roundedBorder)
            } else {
                SecureField(selectedLLM.keyPlaceholder, text: $llmKey)
                    .textFieldStyle(.roundedBorder)
            }
            Button {
                llmKeyVisible.toggle()
            } label: {
                Image(systemName: llmKeyVisible ? "eye.slash" : "eye")
            }
            .buttonStyle(.borderless)
        }
        .onChange(of: llmKey) { _, newValue in
            if !newValue.isEmpty {
                settingsStore.setLLMApiKey(newValue, for: selectedLLM)
            }
        }

        HStack {
            Spacer()

            if !llmKey.isEmpty {
                Button("清除", role: .destructive) {
                    llmKey = ""
                    settingsStore.clearLLMApiKey(for: selectedLLM)
                }
            }
        }
    }

    // MARK: - Load / Test

    private func loadKeys() {
        groqKey = settingsStore.apiKey(for: .groq) ?? ""
        loadLLMKey()
    }

    private func loadLLMKey() {
        llmKey = settingsStore.llmApiKey(for: settingsStore.settings.llmProvider) ?? ""
        llmKeyVisible = false
    }

    private func testSTT() {
        testingSTT = true
        testResult = nil

        Task {
            do {
                let service = STTServiceFactory.create(for: .groq)
                let testAudio = createSilentWAV(durationSeconds: 1)
                let result = try await service.transcribe(audioData: testAudio, language: "zh", prompt: nil)
                testResult = (true, "Groq STT 連線成功！（\(String(format: "%.1f", result.duration))秒）")
            } catch {
                testResult = (false, "Groq STT：\(error.localizedDescription)")
            }
            testingSTT = false
        }
    }

    private func testLLM() {
        testingLLM = true
        testResult = nil

        Task {
            do {
                let provider = settingsStore.settings.llmProvider
                let apiKey = settingsStore.llmApiKey(for: provider) ?? ""
                let url = settingsStore.llmURL(for: provider)
                let model = settingsStore.llmModel(for: provider)

                let llm = LLMPostProcessor(
                    url: url,
                    model: model,
                    apiKey: apiKey,
                    systemPrompt: "回覆「OK」即可。"
                )
                let response = try await llm.process("測試")
                testResult = (true, "\(provider.displayName) LLM 連線成功！（回應：\(response)）")
            } catch {
                testResult = (false, "\(settingsStore.settings.llmProvider.displayName) LLM：\(error.localizedDescription)")
            }
            testingLLM = false
        }
    }

    /// 建立靜音 WAV 檔用於測試
    private func createSilentWAV(durationSeconds: Double) -> Data {
        let sampleRate: Int = 16000
        let numSamples = Int(Double(sampleRate) * durationSeconds)
        let dataSize = numSamples * 2  // 16-bit = 2 bytes per sample

        var wav = Data()
        // RIFF header
        wav.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        let fileSize = UInt32(36 + dataSize)
        wav.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian, Array.init))
        wav.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        // fmt chunk
        wav.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))  // PCM
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))  // mono
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian, Array.init))  // block align
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian, Array.init)) // bits per sample
        // data chunk
        wav.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian, Array.init))
        wav.append(contentsOf: [UInt8](repeating: 0, count: dataSize))

        return wav
    }
}
