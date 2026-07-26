import SwiftUI

/// 語言設定頁面
struct LanguageSettingsTab: View {
    private var settingsStore = SettingsStore.shared

    var body: some View {
        Form {
            Section(L("lang.section.primary")) {
                Picker(L("lang.recognition-language"), selection: Bindable(settingsStore).settings.primaryLanguage) {
                    ForEach(SupportedLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .onChange(of: settingsStore.settings.primaryLanguage) { _, newValue in
                    // 使用者沒自訂過的提示詞才跟著換語言，避免蓋掉手動修改
                    if PromptTemplates.isDefaultWhisperPrompt(settingsStore.settings.whisperPrompt) {
                        settingsStore.settings.whisperPrompt = PromptTemplates.whisperPrompt(for: newValue)
                    }
                    if PromptTemplates.isDefaultCorrectionPrompt(settingsStore.settings.llmSystemPrompt) {
                        settingsStore.settings.llmSystemPrompt = settingsStore.settings.llmCorrectionLevel.defaultPrompt(for: newValue)
                    }
                }

                Toggle(L("lang.mixed-mode"), isOn: Bindable(settingsStore).settings.mixedLanguageMode)

                Text(L("lang.mixed-mode-note"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(L("lang.section.text")) {
                Toggle(L("lang.auto-space"), isOn: Bindable(settingsStore).settings.autoSpaceBetweenCJKAndLatin)

                Text(L("lang.auto-space-note"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker(L("lang.punctuation-style"), selection: Bindable(settingsStore).settings.punctuationStyle) {
                    ForEach(PunctuationStyle.allCases, id: \.rawValue) { style in
                        Text(style.displayName).tag(style)
                    }
                }

                Text(L("lang.punctuation-note"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(L("lang.section.whisper-prompt")) {
                TextEditor(text: Bindable(settingsStore).settings.whisperPrompt)
                    .frame(height: 80)
                    .font(.system(.body, design: .monospaced))

                Text(L("lang.whisper-prompt-note"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(L("common.reset-default")) {
                    settingsStore.settings.whisperPrompt = PromptTemplates.whisperPrompt(for: settingsStore.settings.primaryLanguage)
                }
            }

            Section(L("lang.section.llm")) {
                Toggle(L("lang.enable-llm"), isOn: Bindable(settingsStore).settings.enableLLMPostProcessing)

                Picker(L("api.llm-provider"), selection: Bindable(settingsStore).settings.llmProvider) {
                    ForEach(LLMProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }

                HStack {
                    Text(L("lang.model-in-use"))
                    Spacer()
                    Text(settingsStore.llmModel())
                        .foregroundStyle(.secondary)
                }

                if settingsStore.settings.llmProvider.requiresAPIKey,
                   settingsStore.llmApiKey(for: settingsStore.settings.llmProvider) == nil {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(L("lang.need-api-key", settingsStore.settings.llmProvider.displayName))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Text(L("lang.provider-note"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(L("lang.temperature"))
                    Slider(value: Bindable(settingsStore).settings.llmTemperature, in: 0...1, step: 0.1)
                    Text(String(format: "%.1f", settingsStore.settings.llmTemperature))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 28, alignment: .trailing)
                }

                Text(L("lang.temperature-note"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(L("lang.section.system-prompt")) {
                Picker(L("lang.correction-level"), selection: Binding(
                    get: { settingsStore.settings.llmCorrectionLevel },
                    set: { newLevel in
                        settingsStore.settings.llmCorrectionLevel = newLevel
                        settingsStore.settings.llmSystemPrompt = newLevel.defaultPrompt(for: settingsStore.settings.primaryLanguage)
                    }
                )) {
                    ForEach(LLMCorrectionLevel.allCases) { level in
                        Text("\(level.displayName) — \(level.description)").tag(level)
                    }
                }

                TextEditor(text: Bindable(settingsStore).settings.llmSystemPrompt)
                    .frame(height: 120)
                    .font(.system(.caption, design: .monospaced))

                Text(L("lang.level-note"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(L("lang.reset-level-default")) {
                    settingsStore.settings.llmSystemPrompt = settingsStore.settings.llmCorrectionLevel.defaultPrompt(for: settingsStore.settings.primaryLanguage)
                }
            }
            .disabled(!settingsStore.settings.enableLLMPostProcessing)
            .opacity(settingsStore.settings.enableLLMPostProcessing ? 1 : 0.5)
        }
        .formStyle(.grouped)
        .padding()
    }
}
