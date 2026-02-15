import Foundation
import SwiftUI

/// 應用程式設定存儲（使用 UserDefaults）
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard
    private let settingsKey = "com.typetop.settings"

    var settings: AppSettings {
        didSet { save() }
    }

    private init() {
        if let data = defaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettings()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: settingsKey)
        }
    }

    func reset() {
        settings = AppSettings()
    }

    // MARK: - 便捷存取

    var activeProvider: APIProvider {
        get { settings.activeProvider }
        set { settings.activeProvider = newValue }
    }

    var primaryLanguage: SupportedLanguage {
        get { settings.primaryLanguage }
        set { settings.primaryLanguage = newValue }
    }

    var mixedLanguageMode: Bool {
        get { settings.mixedLanguageMode }
        set { settings.mixedLanguageMode = newValue }
    }

    var whisperPrompt: String {
        get { settings.whisperPrompt }
        set { settings.whisperPrompt = newValue }
    }

    // MARK: - STT API Key

    /// 取得 STT API Key
    func apiKey(for provider: APIProvider? = nil) -> String? {
        let p = provider ?? settings.activeProvider
        return KeychainHelper.load(key: p.keychainKey)
    }

    /// 設定 STT API Key
    func setAPIKey(_ key: String, for provider: APIProvider) {
        KeychainHelper.save(key: provider.keychainKey, value: key)
    }

    /// 清除 STT API Key
    func clearAPIKey(for provider: APIProvider) {
        KeychainHelper.delete(key: provider.keychainKey)
    }

    // MARK: - LLM API Key

    /// 取得 LLM API Key
    func llmApiKey(for provider: LLMProvider? = nil) -> String? {
        let p = provider ?? settings.llmProvider
        return KeychainHelper.load(key: p.keychainKey)
    }

    /// 設定 LLM API Key
    func setLLMApiKey(_ key: String, for provider: LLMProvider) {
        KeychainHelper.save(key: provider.keychainKey, value: key)
    }

    /// 清除 LLM API Key
    func clearLLMApiKey(for provider: LLMProvider) {
        KeychainHelper.delete(key: provider.keychainKey)
    }

    // MARK: - LLM 便捷方法

    /// 取得 LLM 供應商的 URL（考慮 custom 情況）
    func llmURL(for provider: LLMProvider? = nil) -> String {
        let p = provider ?? settings.llmProvider
        if p == .custom {
            return settings.customLLMBaseURL
        }
        return p.chatCompletionURL
    }

    /// 取得 LLM 供應商的模型名稱（考慮 custom 情況）
    func llmModel(for provider: LLMProvider? = nil) -> String {
        let p = provider ?? settings.llmProvider
        if p == .custom {
            return settings.customLLMModel
        }
        return p.defaultModel
    }
}
