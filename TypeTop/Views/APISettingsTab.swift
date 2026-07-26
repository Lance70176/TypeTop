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

    // 編輯既有帳號的名稱與 Key
    @State private var editingAccountID: UUID?
    @State private var editingLabel: String = ""
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
            Section(L("api.section.stt")) {
                accountRows(scope: sttScope, placeholder: "gsk_...")
                addAccountRow(placeholder: "gsk_...", key: $newSTTKey, visible: $newSTTKeyVisible, scope: sttScope)

                HStack {
                    Button(L("api.test-connection")) {
                        testSTT()
                    }
                    .disabled(accountStore.accounts(sttScope).isEmpty || testingSTT)

                    if testingSTT {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                HStack {
                    Text(L("api.model"))
                    Spacer()
                    Text(APIProvider.groq.modelName)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("api.howto.title"))
                        .font(.caption).bold()
                    Text(L("api.howto.step1"))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(L("api.howto.step2"))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(L("api.howto.step3"))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(L("api.howto.multi-account"))
                        .font(.caption).foregroundStyle(.secondary).italic()
                    Button(L("api.open-groq-console")) {
                        NSWorkspace.shared.open(URL(string: "https://console.groq.com/keys")!)
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                }
                .padding(.vertical, 2)
            }

            // MARK: - LLM Section
            Section(L("api.section.llm", selectedLLM.displayName)) {
                Picker(L("api.llm-provider"), selection: Bindable(settingsStore).settings.llmProvider) {
                    ForEach(LLMProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }

                // 自訂 endpoint 欄位
                if selectedLLM == .custom {
                    TextField("Base URL", text: Bindable(settingsStore).settings.customLLMBaseURL)
                        .textFieldStyle(.roundedBorder)
                    TextField(L("api.model-name"), text: Bindable(settingsStore).settings.customLLMModel)
                        .textFieldStyle(.roundedBorder)
                }

                // API Key 帳號列表（Ollama / Apple 不需要）
                if selectedLLM.requiresAPIKey {
                    accountRows(scope: llmScope, placeholder: selectedLLM.keyPlaceholder)
                    addAccountRow(placeholder: selectedLLM.keyPlaceholder, key: $newLLMKey, visible: $newLLMKeyVisible, scope: llmScope)
                }

                HStack {
                    Text(L("api.model"))
                    Spacer()
                    Text(settingsStore.llmModel())
                        .foregroundStyle(.secondary)
                }

                // Apple 本機模型可用性狀態
                if selectedLLM == .apple {
                    HStack {
                        Text(L("api.status"))
                        Spacer()
                        if let reason = AppleFoundationModel.unavailableReason {
                            Text(reason)
                                .foregroundStyle(.orange)
                        } else {
                            Text(L("api.available"))
                                .foregroundStyle(.green)
                        }
                    }
                }

                // 說明文字
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedLLM.helpText)
                        .font(.caption).foregroundStyle(.secondary)

                    if let helpURL = selectedLLM.helpURL {
                        Button(L("api.open-website", selectedLLM.displayName)) {
                            NSWorkspace.shared.open(URL(string: helpURL)!)
                        }
                        .font(.caption)
                        .buttonStyle(.link)
                    }
                }
                .padding(.vertical, 2)

                // 測試 LLM 連線
                HStack {
                    Button(L("api.test-llm-connection")) {
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
            Section(L("usage.section")) {
                let sttProvider = settingsStore.settings.activeProvider
                let sttUsageScope = APIAccountStore.scope(stt: sttProvider)
                let sttAccount = accountStore.activeAccount(sttUsageScope)
                let llmAccount = accountStore.activeAccount(llmScope)

                HStack {
                    Text(L("usage.stt", sttProvider.displayName + (sttAccount.map { " — \($0.label)" } ?? "")))
                    Spacer()
                    Text(L("usage.requests", String(usageTracker.todayRequests(accountStore.usageKey(sttUsageScope)))))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(L("usage.llm", selectedLLM.displayName + (llmAccount.map { " — \($0.label)" } ?? "")))
                    Spacer()
                    let usageKey = accountStore.usageKey(llmScope)
                    Text(L("usage.requests-tokens", String(usageTracker.todayRequests(usageKey)), String(usageTracker.todayTokens(usageKey))))
                        .foregroundStyle(.secondary)
                }

                // Groq 回應 headers 提供的即時剩餘額度（使用中帳號）
                if sttProvider == .groq,
                   let limit = usageTracker.groqLimits[accountStore.usageKey(sttUsageScope)],
                   let remaining = limit.remainingRequests {
                    HStack {
                        Text(L("usage.groq-stt-remaining", sttAccount.map { "（\($0.label)）" } ?? ""))
                        Spacer()
                        Text("\(remaining)\(limit.limitRequests.map { " / \($0)" } ?? "") 次")
                            .foregroundStyle(remaining < 50 ? .orange : .secondary)
                    }
                }
                if selectedLLM == .groq,
                   let limit = usageTracker.groqLimits[accountStore.usageKey(llmScope)],
                   let remaining = limit.remainingRequests {
                    HStack {
                        Text(L("usage.groq-llm-remaining", llmAccount.map { "（\($0.label)）" } ?? ""))
                        Spacer()
                        Text("\(remaining)\(limit.limitRequests.map { " / \($0)" } ?? "") 次")
                            .foregroundStyle(remaining < 50 ? .orange : .secondary)
                    }
                }

                Text(L("usage.note"))
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
                        .help(L("api.copy-message"))
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
                    .help(L("api.set-active"))

                    Text(account.label)
                    Text(account.maskedKey)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if account.id == activeID {
                        Text(L("api.in-use"))
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
                            editingLabel = account.label
                            editingKey = account.key
                            editingKeyVisible = true
                        }
                    } label: {
                        Image(systemName: editingAccountID == account.id ? "chevron.up" : "pencil")
                    }
                    .buttonStyle(.borderless)
                    .help(editingAccountID == account.id ? L("api.collapse") : L("api.edit-key"))

                    Button(role: .destructive) {
                        if editingAccountID == account.id { endEditing() }
                        accountStore.remove(accountID: account.id, scope: scope)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help(L("api.delete-account"))
                }

                if editingAccountID == account.id {
                    HStack {
                        Text(L("api.name"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField(L("api.account-name"), text: $editingLabel)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("Key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                    }

                    HStack {
                        Spacer()

                        Button(L("common.cancel")) {
                            endEditing()
                        }

                        Button(L("common.save")) {
                            accountStore.update(
                                accountID: account.id,
                                label: editingLabelTrimmed,
                                key: editingKeyTrimmed,
                                scope: scope
                            )
                            endEditing()
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(!hasEdits(for: account))
                    }
                }
            }
        }

        if accounts.count > 1 {
            Text(L("api.failover-note"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var editingKeyTrimmed: String {
        editingKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var editingLabelTrimmed: String {
        editingLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 名稱或 Key 有實際變動才允許儲存；兩者都不可留空
    private func hasEdits(for account: APIAccount) -> Bool {
        guard !editingLabelTrimmed.isEmpty, !editingKeyTrimmed.isEmpty else { return false }
        return editingLabelTrimmed != account.label || editingKeyTrimmed != account.key
    }

    private func endEditing() {
        editingAccountID = nil
        editingLabel = ""
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

            Button(L("api.add-account")) {
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
                testResult = (true, L("test.stt-ok", String(format: "%.1f", result.duration), accountLabel))
            } catch {
                testResult = (false, L("test.stt-fail", error.localizedDescription))
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
                        testResult = (true, L("test.apple-ok", response))
                    } else {
                        testResult = (false, L("test.apple-fail", AppleFoundationModel.unavailableReason ?? L("error.apple.unavailable")))
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
                testResult = (true, L("test.llm-ok", provider.displayName, response, accountLabel))
            } catch {
                testResult = (false, L("test.llm-fail", settingsStore.settings.llmProvider.displayName, error.localizedDescription))
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
