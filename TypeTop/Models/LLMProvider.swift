import Foundation

/// LLM 語意修正 API 供應商（獨立於 STT 供應商）
enum LLMProvider: String, Codable, CaseIterable, Identifiable {
    case openai = "openai"
    case groq = "groq"
    case deepseek = "deepseek"
    case moonshot = "moonshot"
    case gemini = "gemini"
    case apple = "apple"
    case ollama = "ollama"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .groq: return "Groq"
        case .deepseek: return "DeepSeek"
        case .moonshot: return "Moonshot (Kimi)"
        case .gemini: return "Google Gemini"
        case .apple: return L("provider.apple")
        case .ollama: return L("provider.ollama")
        case .custom: return L("provider.custom")
        }
    }

    var chatCompletionURL: String {
        switch self {
        case .openai: return "https://api.openai.com/v1/chat/completions"
        case .groq: return "https://api.groq.com/openai/v1/chat/completions"
        case .deepseek: return "https://api.deepseek.com/chat/completions"
        case .moonshot: return "https://api.moonshot.ai/v1/chat/completions"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
        case .apple: return "" // 使用 FoundationModels framework，不走 HTTP
        case .ollama: return "http://localhost:11434/v1/chat/completions"
        case .custom: return "" // 由 AppSettings.customLLMBaseURL 提供
        }
    }

    var defaultModel: String {
        switch self {
        case .openai: return "gpt-4o-mini"
        case .groq: return "llama-3.3-70b-versatile"
        case .deepseek: return "deepseek-chat"
        case .moonshot: return "kimi-k2.5"
        case .gemini: return "gemini-3.1-flash-lite"
        case .apple: return L("provider.apple-model")
        case .ollama: return "llama3"
        case .custom: return "" // 由 AppSettings.customLLMModel 提供
        }
    }

    var keyPlaceholder: String {
        switch self {
        case .openai: return "sk-..."
        case .groq: return "gsk_..."
        case .deepseek: return "sk-..."
        case .moonshot: return "sk-..."
        case .gemini: return "AIza..."
        case .apple: return ""
        case .ollama: return ""
        case .custom: return L("provider.custom-key-placeholder")
        }
    }

    /// 是否需要 API Key
    var requiresAPIKey: Bool {
        self != .ollama && self != .apple
    }

    var helpURL: String? {
        switch self {
        case .openai: return "https://platform.openai.com/api-keys"
        case .groq: return "https://console.groq.com/keys"
        case .deepseek: return "https://platform.deepseek.com/api_keys"
        case .moonshot: return "https://platform.moonshot.ai/console/api-keys"
        case .gemini: return "https://aistudio.google.com/apikey"
        case .apple: return "https://support.apple.com/zh-tw/121115"
        case .ollama: return "https://ollama.com"
        case .custom: return nil
        }
    }

    var helpText: String {
        switch self {
        case .openai:
            return L("provider.help.openai")
        case .groq:
            return L("provider.help.groq")
        case .deepseek:
            return L("provider.help.deepseek")
        case .moonshot:
            return L("provider.help.moonshot")
        case .gemini:
            return L("provider.help.gemini")
        case .apple:
            return L("provider.help.apple")
        case .ollama:
            return L("provider.help.ollama")
        case .custom:
            return L("provider.help.custom")
        }
    }

    var keychainKey: String {
        return "com.typetop.llm.apikey.\(rawValue)"
    }
}
