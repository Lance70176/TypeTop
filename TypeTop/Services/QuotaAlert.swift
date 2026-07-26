import AppKit

/// 額度用罄（HTTP 429）提示：通知使用者並詢問是否切換供應商
@MainActor
enum QuotaAlert {

    /// 同類提示最短間隔，避免連續輸入時重複跳窗
    private static let minInterval: TimeInterval = 600
    private static var lastPromptAt: [String: Date] = [:]

    private static func shouldPrompt(_ kind: String) -> Bool {
        if let last = lastPromptAt[kind], Date().timeIntervalSince(last) < minInterval {
            return false
        }
        lastPromptAt[kind] = Date()
        return true
    }

    /// LLM 供應商達到額度上限
    static func llmQuotaExceeded() {
        guard shouldPrompt("llm") else { return }
        let settingsStore = SettingsStore.shared
        let current = settingsStore.settings.llmProvider

        // 尋找已設定 API Key（或不需 Key）的替代供應商
        let candidate = LLMProvider.allCases.first { provider in
            provider != current && provider != .custom &&
            (provider != .apple || AppleFoundationModel.isAvailable) &&
            (!provider.requiresAPIKey || !(settingsStore.llmApiKey(for: provider) ?? "").isEmpty)
        }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "\(current.displayName) 已達用量上限"
        if let candidate {
            alert.informativeText = "語意修正（LLM）供應商 \(current.displayName) 的所有帳號均回報已達額度上限（HTTP 429）。要切換到 \(candidate.displayName) 嗎？"
            alert.addButton(withTitle: "切換到 \(candidate.displayName)")
            alert.addButton(withTitle: "稍後再說")
            NSApp.activate(ignoringOtherApps: true)
            if alert.runModal() == .alertFirstButtonReturn {
                settingsStore.settings.llmProvider = candidate
            }
        } else {
            alert.informativeText = "語意修正（LLM）供應商 \(current.displayName) 的所有帳號均回報已達額度上限（HTTP 429）。沒有其他已設定 API Key 的供應商可切換，請至「API 設定」新增其他供應商或帳號的 Key。"
            alert.addButton(withTitle: "知道了")
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    /// STT 供應商達到額度上限
    static func sttQuotaExceeded() {
        guard shouldPrompt("stt") else { return }
        let settingsStore = SettingsStore.shared
        let current = settingsStore.settings.activeProvider

        // STT 目前僅 Groq / OpenAI 兩家，找另一家有 Key 的
        let candidate = APIProvider.allCases.first { provider in
            provider != current && settingsStore.apiKey(for: provider) != nil
        }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "\(current.displayName) 已達用量上限"
        if let candidate {
            alert.informativeText = "語音辨識（STT）供應商 \(current.displayName) 的所有帳號均回報已達額度上限（HTTP 429）。要切換到 \(candidate.displayName) 嗎？"
            alert.addButton(withTitle: "切換到 \(candidate.displayName)")
            alert.addButton(withTitle: "稍後再說")
            NSApp.activate(ignoringOtherApps: true)
            if alert.runModal() == .alertFirstButtonReturn {
                settingsStore.settings.activeProvider = candidate
            }
        } else {
            alert.informativeText = "語音辨識（STT）供應商 \(current.displayName) 的所有帳號均回報已達額度上限（HTTP 429）。沒有其他已設定 API Key 的供應商可切換，請至「API 設定」新增其他供應商或帳號的 Key。"
            alert.addButton(withTitle: "知道了")
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }
}
