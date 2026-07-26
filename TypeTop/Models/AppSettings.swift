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
        case .rightCommand: return L("key.right-command")
        case .leftCommand: return L("key.left-command")
        case .rightOption: return L("key.right-option")
        case .leftOption: return L("key.left-option")
        case .rightControl: return L("key.right-control")
        case .leftControl: return L("key.left-control")
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

    /// 介面顯示語言（預設跟隨系統）
    var uiLanguage: SupportedLanguage = L10n.systemDefault()

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

    /// 錄音時自動靜音系統音訊
    var muteSystemAudioWhileRecording: Bool = false

    /// Whisper prompt 模板
    var whisperPrompt: String = PromptTemplates.whisperPrompt(for: .zhHant)

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

    /// LLM 取樣溫度（0 = 最穩定，越高越隨機；修正任務建議 0~0.3）
    var llmTemperature: Double = 0.3

    /// 自訂 LLM Base URL（僅 llmProvider == .custom 時使用）
    var customLLMBaseURL: String = ""

    /// 自訂 LLM 模型名稱（僅 llmProvider == .custom 時使用）
    var customLLMModel: String = ""

    static let defaultLLMPrompt = LLMCorrectionLevel.medium.defaultPrompt

    private enum CodingKeys: String, CodingKey {
        case activeProvider, primaryLanguage, uiLanguage, mixedLanguageMode, autoSpaceBetweenCJKAndLatin
        case punctuationStyle, activationKey, launchAtLogin, playSoundEffects, muteSystemAudioWhileRecording
        case whisperPrompt, autoSendDelay, enableLLMPostProcessing, llmProvider
        case llmCorrectionLevel, llmSystemPrompt, llmTemperature, customLLMBaseURL, customLLMModel
        // 舊 key，僅用於向後相容解碼
        case hotkeyKeyCode
    }

    /// 自訂解碼器，確保新增欄位在舊設定檔中有預設值
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeProvider = try container.decodeIfPresent(APIProvider.self, forKey: .activeProvider) ?? .groq
        primaryLanguage = try container.decodeIfPresent(SupportedLanguage.self, forKey: .primaryLanguage) ?? .zhHant
        uiLanguage = try container.decodeIfPresent(SupportedLanguage.self, forKey: .uiLanguage) ?? L10n.systemDefault()
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
        muteSystemAudioWhileRecording = try container.decodeIfPresent(Bool.self, forKey: .muteSystemAudioWhileRecording) ?? false
        whisperPrompt = try container.decodeIfPresent(String.self, forKey: .whisperPrompt) ?? PromptTemplates.whisperPrompt(for: primaryLanguage)
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
        llmTemperature = try container.decodeIfPresent(Double.self, forKey: .llmTemperature) ?? 0.3
        customLLMBaseURL = try container.decodeIfPresent(String.self, forKey: .customLLMBaseURL) ?? ""
        customLLMModel = try container.decodeIfPresent(String.self, forKey: .customLLMModel) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(activeProvider, forKey: .activeProvider)
        try container.encode(primaryLanguage, forKey: .primaryLanguage)
        try container.encode(uiLanguage, forKey: .uiLanguage)
        try container.encode(mixedLanguageMode, forKey: .mixedLanguageMode)
        try container.encode(autoSpaceBetweenCJKAndLatin, forKey: .autoSpaceBetweenCJKAndLatin)
        try container.encode(punctuationStyle, forKey: .punctuationStyle)
        try container.encode(activationKey, forKey: .activationKey)
        try container.encode(launchAtLogin, forKey: .launchAtLogin)
        try container.encode(playSoundEffects, forKey: .playSoundEffects)
        try container.encode(muteSystemAudioWhileRecording, forKey: .muteSystemAudioWhileRecording)
        try container.encode(whisperPrompt, forKey: .whisperPrompt)
        try container.encode(autoSendDelay, forKey: .autoSendDelay)
        try container.encode(enableLLMPostProcessing, forKey: .enableLLMPostProcessing)
        try container.encode(llmProvider, forKey: .llmProvider)
        try container.encode(llmCorrectionLevel, forKey: .llmCorrectionLevel)
        try container.encode(llmSystemPrompt, forKey: .llmSystemPrompt)
        try container.encode(llmTemperature, forKey: .llmTemperature)
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
        case .none: return L("level.none")
        case .light: return L("level.light")
        case .medium: return L("level.medium")
        case .heavy: return L("level.heavy")
        }
    }

    var description: String {
        switch self {
        case .none: return L("level.none.desc")
        case .light: return L("level.light.desc")
        case .medium: return L("level.medium.desc")
        case .heavy: return L("level.heavy.desc")
        }
    }

    /// 指定輸出語言的預設提示詞
    func defaultPrompt(for language: SupportedLanguage) -> String {
        PromptTemplates.correctionPrompt(level: self, language: language)
    }

    /// 繁體中文的預設提示詞（向後相容用）
    var defaultPrompt: String {
        defaultPrompt(for: .zhHant)
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
        case .fullWidth: return L("punct.full")
        case .halfWidth: return L("punct.half")
        case .none: return L("punct.none")
        case .keep: return L("punct.keep")
        }
    }
}
