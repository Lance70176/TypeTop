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
        case .apple: return "Apple 本機模型"
        case .ollama: return "Ollama (本地)"
        case .custom: return "自訂"
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
        case .apple: return "系統內建模型（on-device）"
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
        case .custom: return "API Key（若需要）"
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
            return "前往 platform.openai.com → API Keys → Create new secret key。需預先儲值，使用 gpt-4o-mini 費用極低。"
        case .groq:
            return "前往 console.groq.com → API Keys → Create API Key。Groq 提供免費額度，日常使用綽綽有餘。"
        case .deepseek:
            return "前往 platform.deepseek.com → API Keys。DeepSeek 提供高性價比的中文 LLM。"
        case .moonshot:
            return "前往 platform.moonshot.ai → API Keys。Moonshot (Kimi) 支援中文語境最佳化。"
        case .gemini:
            return "前往 aistudio.google.com → Get API Key。Gemini 提供免費額度。"
        case .apple:
            return "使用 macOS 26 內建的 Apple Intelligence 本機模型（約 3B）。免費、離線可用、內容不離開這台電腦。需 Apple Silicon 並在「系統設定」開啟 Apple Intelligence。"
        case .ollama:
            return "請確保 Ollama 已在本機執行（預設 http://localhost:11434）。不需要 API Key。"
        case .custom:
            return "填入相容 OpenAI Chat Completions API 格式的 endpoint URL 和模型名稱。"
        }
    }

    var keychainKey: String {
        return "com.typetop.llm.apikey.\(rawValue)"
    }
}
