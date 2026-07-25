import SwiftUI

/// API Key 管理設定頁面（每個供應商可設定多組帳號，達額度時自動切換）
struct APISettingsTab: View {
    private var settingsStore = SettingsStore.shared
    private var usageTracker = UsageTracker.shared
    private var accountStore = APIAccountStore.shared

    // 新增帳號輸入
    @State private var newSTTKey: String = ""
    @State private var newSTTKeyVisible: Bool = false
    @State private var newLLMKey: String = ""
    @State private var newLLMKeyVisible: Bool = false

    @State private var testingSTT: Bool = false
    @State private var testingLLM: Bool = false
    @State private var testResult: (success: Bool, message: String)?

    // 編輯既有帳號的 Key
    @State private var editingAccountID: UUID?
    @State private var editingKey: String = ""
    @State private var editingKeyVisible: Bool = true

    private var selectedLLM: LLMProvider {
        settingsStore.settings.llmProvider
    }

    private var sttScope: String {
        APIAccountStore.scope(stt: .groq)
    }

    private var llmScope: String {
        APIAccountStore.scope(llm: selectedLLM)
    }

    var body: some View {
        Form {
            // MARK: - STT Section
            Section("語音辨識（STT）— Groq") {
                accountRows(scope: sttScope, placeholder: "gsk_...")
                addAccountRow(placeholder: "gsk_...", key: $newSTTKey, visible: $newSTTKeyVisible, scope: sttScope)

                HStack {
                    Button("測試連線") {
                        testSTT()
                    }
                    .disabled(accountStore.accounts(sttScope).isEmpty || testingSTT)

                    if testingSTT {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

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
                    Text("可新增多組不同帳號的 Key，達免費額度時會自動切換。")
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

                // API Key 帳號列表（Ollama / Apple 不需要）
                if selectedLLM.requiresAPIKey {
                    accountRows(scope: llmScope, placeholder: selectedLLM.keyPlaceholder)
                    addAccountRow(placeholder: selectedLLM.keyPlaceholder, key: $newLLMKey, visible: $newLLMKeyVisible, scope: llmScope)
                }

                HStack {
                    Text("模型")
                    Spacer()
                    Text(settingsStore.llmModel())
                        .foregroundStyle(.secondary)
                }

                // Apple 本機模型可用性狀態
                if selectedLLM == .apple {
                    HStack {
                        Text("狀態")
                        Spacer()
                        if let reason = AppleFoundationModel.unavailableReason {
                            Text(reason)
                                .foregroundStyle(.orange)
                        } else {
                            Text("可用")
                                .foregroundStyle(.green)
                        }
                    }
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
                    .disabled(testingLLM || (selectedLLM.requiresAPIKey && accountStore.accounts(llmScope).isEmpty))

                    if testingLLM {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }

            // MARK: - 今日用量（僅顯示使用中帳號的統計）
            Section("今日用量（本地統計）") {
                let sttProvider = settingsStore.settings.activeProvider
                let sttUsageScope = APIAccountStore.scope(stt: sttProvider)
                let sttAccount = accountStore.activeAccount(sttUsageScope)
                let llmAccount = accountStore.activeAccount(llmScope)

                HStack {
                    Text("語音辨識（\(sttProvider.displayName)\(sttAccount.map { " — \($0.label)" } ?? "")）")
                    Spacer()
                    Text("\(usageTracker.todayRequests(accountStore.usageKey(sttUsageScope))) 次")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("語意修正（\(selectedLLM.displayName)\(llmAccount.map { " — \($0.label)" } ?? "")）")
                    Spacer()
                    let usageKey = accountStore.usageKey(llmScope)
                    Text("\(usageTracker.todayRequests(usageKey)) 次 / \(usageTracker.todayTokens(usageKey)) tokens")
                        .foregroundStyle(.secondary)
                }

                // Groq 回應 headers 提供的即時剩餘額度（使用中帳號）
                if sttProvider == .groq,
                   let limit = usageTracker.groqLimits[accountStore.usageKey(sttUsageScope)],
                   let remaining = limit.remainingRequests {
                    HStack {
                        Text("Groq 語音辨識剩餘額度\(sttAccount.map { "（\($0.label)）" } ?? "")")
                        Spacer()
                        Text("\(remaining)\(limit.limitRequests.map { " / \($0)" } ?? "") 次")
                            .foregroundStyle(remaining < 50 ? .orange : .secondary)
                    }
                }
                if selectedLLM == .groq,
                   let limit = usageTracker.groqLimits[accountStore.usageKey(llmScope)],
                   let remaining = limit.remainingRequests {
                    HStack {
                        Text("Groq 語意修正剩餘額度\(llmAccount.map { "（\($0.label)）" } ?? "")")
                        Spacer()
                        Text("\(remaining)\(limit.limitRequests.map { " / \($0)" } ?? "") 次")
                            .foregroundStyle(remaining < 50 ? .orange : .secondary)
                    }
                }

                Text("次數與 tokens 為本 app 的本地統計，僅計入目前使用中的帳號；Groq 剩餘額度來自官方回應。其他供應商的官方額度請至各家控制台查看（Gemini：aistudio.google.com/rate-limit）。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .onChange(of: settingsStore.settings.llmProvider) { _, _ in
            newLLMKey = ""
            newLLMKeyVisible = false
            endEditing()
            testResult = nil
        }
    }

    // MARK: - 帳號列表

    @ViewBuilder
    private func accountRows(scope: String, placeholder: String) -> some View {
        let accounts = accountStore.accounts(scope)
        let activeID = accountStore.activeAccount(scope)?.id

        ForEach(accounts) { account in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Button {
                        accountStore.setActive(accountID: account.id, scope: scope)
                    } label: {
                        Image(systemName: account.id == activeID ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(account.id == activeID ? Color.accentColor : Color.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("設為使用中")

                    Text(account.label)
                    Text(account.maskedKey)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if account.id == activeID {
                        Text("使用中")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                            .foregroundStyle(.green)
                    }

                    Spacer()

                    Button {
                        if editingAccountID == account.id {
                            endEditing()
                        } else {
                            editingAccountID = account.id
                            editingKey = account.key
                            editingKeyVisible = true
                        }
                    } label: {
                        Image(systemName: editingAccountID == account.id ? "chevron.up" : "pencil")
                    }
                    .buttonStyle(.borderless)
                    .help(editingAccountID == account.id ? "收合" : "檢視／編輯此 Key")

                    Button(role: .destructive) {
                        if editingAccountID == account.id { endEditing() }
                        accountStore.remove(accountID: account.id, scope: scope)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("刪除此帳號")
                }

                if editingAccountID == account.id {
                    HStack {
                        if editingKeyVisible {
                            TextField(placeholder, text: $editingKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField(placeholder, text: $editingKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button {
                            editingKeyVisible.toggle()
                        } label: {
                            Image(systemName: editingKeyVisible ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)

                        Button("儲存") {
                            let trimmed = editingKey.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            accountStore.update(accountID: account.id, key: trimmed, scope: scope)
                            endEditing()
                        }
                        .disabled(editingKeyTrimmed.isEmpty || editingKeyTrimmed == account.key)

                        Button("取消") {
                            endEditing()
                        }
                    }
                }
            }
        }

        if accounts.count > 1 {
            Text("達額度上限（HTTP 429）時會自動切換到下一組帳號。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var editingKeyTrimmed: String {
        editingKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func endEditing() {
        editingAccountID = nil
        editingKey = ""
        editingKeyVisible = true
    }

    // MARK: - 新增帳號

    @ViewBuilder
    private func addAccountRow(placeholder: String, key: Binding<String>, visible: Binding<Bool>, scope: String) -> some View {
        HStack {
            if visible.wrappedValue {
                TextField(placeholder, text: key)
                    .textFieldStyle(.roundedBorder)
            } else {
                SecureField(placeholder, text: key)
                    .textFieldStyle(.roundedBorder)
            }
            Button {
                visible.wrappedValue.toggle()
            } label: {
                Image(systemName: visible.wrappedValue ? "eye.slash" : "eye")
            }
            .buttonStyle(.borderless)

            Button("新增帳號") {
                let trimmed = key.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                accountStore.add(key: trimmed, scope: scope)
                key.wrappedValue = ""
                visible.wrappedValue = false
            }
            .disabled(key.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Test

    private func testSTT() {
        testingSTT = true
        testResult = nil

        Task {
            do {
                let service = STTServiceFactory.create(for: .groq)
                let testAudio = createSilentWAV(durationSeconds: 1)
                let result = try await service.transcribe(audioData: testAudio, language: "zh", prompt: nil)
                let accountLabel = accountStore.activeAccount(sttScope).map { "，\($0.label)" } ?? ""
                testResult = (true, "Groq STT 連線成功！（\(String(format: "%.1f", result.duration))秒\(accountLabel)）")
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

                // Apple 本機模型不走 HTTP，直接呼叫 FoundationModels
                if provider == .apple {
                    if #available(macOS 26.0, *), AppleFoundationModel.isAvailable {
                        let response = try await AppleFoundationModel.process(
                            "測試", systemPrompt: "回覆「OK」即可。", temperature: 0
                        )
                        testResult = (true, "Apple 本機模型可用！（回應：\(response)）")
                    } else {
                        testResult = (false, "Apple 本機模型：\(AppleFoundationModel.unavailableReason ?? "無法使用")")
                    }
                    testingLLM = false
                    return
                }

                let apiKey = settingsStore.llmApiKey(for: provider) ?? ""
                let url = settingsStore.llmURL(for: provider)
                let model = settingsStore.llmModel(for: provider)

                let llm = LLMPostProcessor(
                    url: url,
                    model: model,
                    apiKey: apiKey,
                    systemPrompt: "回覆「OK」即可。",
                    temperature: settingsStore.settings.llmTemperature
                )
                let response = try await llm.process("測試")
                let accountLabel = accountStore.activeAccount(llmScope).map { "，\($0.label)" } ?? ""
                testResult = (true, "\(provider.displayName) LLM 連線成功！（回應：\(response)\(accountLabel)）")
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
