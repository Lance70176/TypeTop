import Foundation
import CoreGraphics

/// 啟動快捷鍵選項
enum ActivationKey: UInt16, Codable, CaseIterable, Identifiable {
    case rightCommand = 54
    case leftCommand = 55
    case rightOption = 61
    case leftOption = 58
    case rightControl = 62
    case leftControl = 59
    case fn = 63

    var id: UInt16 { rawValue }

    var displayName: String {
        switch self {
        case .rightCommand: return "右側 ⌘"
        case .leftCommand: return "左側 ⌘"
        case .rightOption: return "右側 ⌥"
        case .leftOption: return "左側 ⌥"
        case .rightControl: return "右側 ⌃"
        case .leftControl: return "左側 ⌃"
        case .fn: return "fn"
        }
    }

    /// 對應的 CGEventFlags mask
    var flagMask: CGEventFlags {
        switch self {
        case .rightCommand, .leftCommand: return .maskCommand
        case .rightOption, .leftOption: return .maskAlternate
        case .rightControl, .leftControl: return .maskControl
        case .fn: return .maskSecondaryFn
        }
    }

    /// 除了自身 flagMask 以外的所有修飾鍵 mask，用於偵測取消
    var cancelMasks: [CGEventFlags] {
        let allMasks: [CGEventFlags] = [.maskCommand, .maskAlternate, .maskControl, .maskSecondaryFn]
        return allMasks.filter { $0 != self.flagMask }
    }
}

/// 應用程式設定
struct AppSettings: Codable {
    init() {}

    /// 目前使用的 API 供應商
    var activeProvider: APIProvider = .groq

    /// 主要辨識語言
    var primaryLanguage: SupportedLanguage = .zhHant

    /// 是否啟用中英混合模式
    var mixedLanguageMode: Bool = true

    /// 中英文之間自動加空格
    var autoSpaceBetweenCJKAndLatin: Bool = true

    /// 標點符號偏好
    var punctuationStyle: PunctuationStyle = .fullWidth

    /// 按住說話啟動鍵
    var activationKey: ActivationKey = .rightCommand

    /// 是否開機自啟動
    var launchAtLogin: Bool = false

    /// 是否播放音效
    var playSoundEffects: Bool = true

    /// Whisper prompt 模板
    var whisperPrompt: String = "繁體中文語音輸入，可能包含英文單字如 API、iPhone、React、TypeScript、macOS 等技術術語。"

    /// 錄音後自動送出的延遲（秒）
    var autoSendDelay: Double = 0.3

    /// 是否啟用 LLM 語意後處理
    var enableLLMPostProcessing: Bool = true

    /// LLM 使用的供應商（獨立於語音辨識供應商）
    var llmProvider: LLMProvider = .openai

    /// LLM 修正程度
    var llmCorrectionLevel: LLMCorrectionLevel = .medium

    /// LLM 後處理系統提示詞
    var llmSystemPrompt: String = LLMCorrectionLevel.medium.defaultPrompt

    /// 自訂 LLM Base URL（僅 llmProvider == .custom 時使用）
    var customLLMBaseURL: String = ""

    /// 自訂 LLM 模型名稱（僅 llmProvider == .custom 時使用）
    var customLLMModel: String = ""

    static let defaultLLMPrompt = LLMCorrectionLevel.medium.defaultPrompt

    private enum CodingKeys: String, CodingKey {
        case activeProvider, primaryLanguage, mixedLanguageMode, autoSpaceBetweenCJKAndLatin
        case punctuationStyle, activationKey, launchAtLogin, playSoundEffects
        case whisperPrompt, autoSendDelay, enableLLMPostProcessing, llmProvider
        case llmCorrectionLevel, llmSystemPrompt, customLLMBaseURL, customLLMModel
        // 舊 key，僅用於向後相容解碼
        case hotkeyKeyCode
    }

    /// 自訂解碼器，確保新增欄位在舊設定檔中有預設值
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeProvider = try container.decodeIfPresent(APIProvider.self, forKey: .activeProvider) ?? .groq
        primaryLanguage = try container.decodeIfPresent(SupportedLanguage.self, forKey: .primaryLanguage) ?? .zhHant
        mixedLanguageMode = try container.decodeIfPresent(Bool.self, forKey: .mixedLanguageMode) ?? true
        autoSpaceBetweenCJKAndLatin = try container.decodeIfPresent(Bool.self, forKey: .autoSpaceBetweenCJKAndLatin) ?? true
        punctuationStyle = try container.decodeIfPresent(PunctuationStyle.self, forKey: .punctuationStyle) ?? .fullWidth
        // 向後相容：若舊設定有 hotkeyKeyCode，映射為 ActivationKey
        if let key = try container.decodeIfPresent(ActivationKey.self, forKey: .activationKey) {
            activationKey = key
        } else if let oldKeyCode = try container.decodeIfPresent(UInt16.self, forKey: .hotkeyKeyCode) {
            activationKey = ActivationKey(rawValue: oldKeyCode) ?? .rightCommand
        } else {
            activationKey = .rightCommand
        }
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        playSoundEffects = try container.decodeIfPresent(Bool.self, forKey: .playSoundEffects) ?? true
        whisperPrompt = try container.decodeIfPresent(String.self, forKey: .whisperPrompt) ?? "繁體中文語音輸入，可能包含英文單字如 API、iPhone、React、TypeScript、macOS 等技術術語。"
        autoSendDelay = try container.decodeIfPresent(Double.self, forKey: .autoSendDelay) ?? 0.3
        enableLLMPostProcessing = try container.decodeIfPresent(Bool.self, forKey: .enableLLMPostProcessing) ?? true
        // 向後相容：先嘗試解碼新的 LLMProvider，失敗則嘗試舊的 APIProvider 並映射
        if let newProvider = try? container.decodeIfPresent(LLMProvider.self, forKey: .llmProvider) {
            llmProvider = newProvider
        } else if let oldProvider = try? container.decodeIfPresent(APIProvider.self, forKey: .llmProvider) {
            switch oldProvider {
            case .openai: llmProvider = .openai
            case .groq: llmProvider = .groq
            }
        } else {
            llmProvider = .openai
        }
        llmCorrectionLevel = try container.decodeIfPresent(LLMCorrectionLevel.self, forKey: .llmCorrectionLevel) ?? .medium
        llmSystemPrompt = try container.decodeIfPresent(String.self, forKey: .llmSystemPrompt) ?? llmCorrectionLevel.defaultPrompt
        customLLMBaseURL = try container.decodeIfPresent(String.self, forKey: .customLLMBaseURL) ?? ""
        customLLMModel = try container.decodeIfPresent(String.self, forKey: .customLLMModel) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(activeProvider, forKey: .activeProvider)
        try container.encode(primaryLanguage, forKey: .primaryLanguage)
        try container.encode(mixedLanguageMode, forKey: .mixedLanguageMode)
        try container.encode(autoSpaceBetweenCJKAndLatin, forKey: .autoSpaceBetweenCJKAndLatin)
        try container.encode(punctuationStyle, forKey: .punctuationStyle)
        try container.encode(activationKey, forKey: .activationKey)
        try container.encode(launchAtLogin, forKey: .launchAtLogin)
        try container.encode(playSoundEffects, forKey: .playSoundEffects)
        try container.encode(whisperPrompt, forKey: .whisperPrompt)
        try container.encode(autoSendDelay, forKey: .autoSendDelay)
        try container.encode(enableLLMPostProcessing, forKey: .enableLLMPostProcessing)
        try container.encode(llmProvider, forKey: .llmProvider)
        try container.encode(llmCorrectionLevel, forKey: .llmCorrectionLevel)
        try container.encode(llmSystemPrompt, forKey: .llmSystemPrompt)
        try container.encode(customLLMBaseURL, forKey: .customLLMBaseURL)
        try container.encode(customLLMModel, forKey: .customLLMModel)
    }
}

/// 支援的語言
enum SupportedLanguage: String, Codable, CaseIterable, Identifiable {
    case zhHant = "zh-Hant"
    case zhHans = "zh-Hans"
    case en = "en"
    case ja = "ja"
    case ko = "ko"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zhHant: return "繁體中文"
        case .zhHans: return "簡體中文"
        case .en: return "English"
        case .ja: return "日本語"
        case .ko: return "한국어"
        }
    }

    /// Whisper API 使用的語言代碼
    var whisperCode: String {
        switch self {
        case .zhHant, .zhHans: return "zh"
        case .en: return "en"
        case .ja: return "ja"
        case .ko: return "ko"
        }
    }

    var tag: String { rawValue }
}

/// LLM 修正程度
enum LLMCorrectionLevel: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case light = "light"
    case medium = "medium"
    case heavy = "heavy"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "無修正"
        case .light: return "輕微"
        case .medium: return "中等"
        case .heavy: return "重度"
        }
    }

    var description: String {
        switch self {
        case .none: return "僅加標點符號，完全保留原文"
        case .light: return "修正錯字、加標點，保留口語風格"
        case .medium: return "改寫為書面語，去除贅詞"
        case .heavy: return "大幅精煉，重組句子結構"
        }
    }

    var defaultPrompt: String {
        switch self {
        case .none:
            return """
                你是語音輸入的標點助手。使用者透過語音輸入文字，你只需要加上標點符號。

                規則：
                1. 完全保留原文的每一個字，不要刪除、替換或改寫任何詞語
                2. 只加上適當的標點符號（逗號、句號、問號、驚嘆號）
                3. 使用繁體中文標點
                4. 英文專有名詞保持正確拼寫（如 API、iPhone、React、TypeScript、macOS）
                5. 直接輸出結果，不要加任何解釋
                """
        case .light:
            return """
                你是語音輸入的修正助手。使用者透過語音輸入文字，你要做最小幅度的修正。

                規則：
                1. 保留原文的語氣和用詞風格，包括口語表達
                2. 只修正明顯的錯字和語音辨識錯誤
                3. 加上適當的標點符號
                4. 使用繁體中文，不要用簡體
                5. 英文專有名詞保持正確拼寫（如 API、iPhone、React、TypeScript、macOS）
                6. 不要刪除任何內容，不要改變語序
                7. 直接輸出修正後的文字，不要加任何解釋
                """
        case .medium:
            return """
                你是語音輸入的改寫助手。使用者透過語音輸入文字，你要理解他的意思，然後用通順的書面語重新寫出來。

                規則：
                1. 先理解語意，再用清晰的書面中文改寫，去除口語贅詞（嗯、那個、就是說）
                2. 使用繁體中文，不要用簡體
                3. 加上適當的標點符號，讓句子結構清晰
                4. 英文專有名詞保持正確拼寫（如 API、iPhone、React、TypeScript、macOS）
                5. 保持原意，但可以調整語序和用詞讓表達更精確
                6. 直接輸出改寫後的文字，不要加任何解釋
                """
        case .heavy:
            return """
                你是語音輸入的精煉助手。使用者透過語音輸入文字，你要將內容大幅精煉為精確、簡潔的書面語。

                規則：
                1. 深度理解語意後，用最精煉的書面中文重新表達
                2. 刪除所有口語贅詞、重複表達和不必要的修飾
                3. 重組句子結構，讓邏輯更清晰
                4. 使用繁體中文，不要用簡體
                5. 加上適當的標點符號
                6. 英文專有名詞保持正確拼寫（如 API、iPhone、React、TypeScript、macOS）
                7. 直接輸出精煉後的文字，不要加任何解釋
                """
        }
    }
}

/// 標點符號風格
enum PunctuationStyle: String, Codable, CaseIterable {
    case fullWidth = "fullWidth"   // 全形：，。！？
    case halfWidth = "halfWidth"   // 半形：,.!?
    case none = "none"             // 移除所有標點符號
    case keep = "keep"             // 保持 API 回傳的原樣

    var displayName: String {
        switch self {
        case .fullWidth: return "全形標點"
        case .halfWidth: return "半形標點"
        case .none: return "無標點符號"
        case .keep: return "保持原樣"
        }
    }
}
