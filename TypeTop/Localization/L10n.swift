import Foundation
import Observation

/// 介面語言管理。字串以英文識別碼當 key（見 `UIStrings`），查不到時退回英文。
///
/// 切換語言只要改 `L10n.shared.language`，所有讀取 `L(...)` 的 SwiftUI 視圖會自動重繪
/// （`@Observable` 會在 body 求值時追蹤 `language` 的讀取）。
@Observable
final class L10n {
    static let shared = L10n()

    var language: SupportedLanguage = L10n.systemDefault()

    private init() {}

    /// 依系統偏好語言推斷預設介面語言，無對應時退回英文
    static func systemDefault() -> SupportedLanguage {
        for code in Locale.preferredLanguages {
            let lower = code.lowercased()
            if lower.hasPrefix("zh") {
                // zh-Hant / zh-TW / zh-HK 視為繁體，其餘 zh 視為簡體
                if lower.contains("hant") || lower.contains("tw") || lower.contains("hk") || lower.contains("mo") {
                    return .zhHant
                }
                return .zhHans
            }
            if lower.hasPrefix("ja") { return .ja }
            if lower.hasPrefix("ko") { return .ko }
            if lower.hasPrefix("en") { return .en }
        }
        return .en
    }

    func t(_ key: String) -> String {
        if let text = UIStrings.table[language]?[key] { return text }
        // 缺漏時退回英文，再退回 key 本身（開發期一眼看得出來哪個 key 沒翻）
        return UIStrings.en[key] ?? key
    }

    func t(_ key: String, _ args: [CVarArg]) -> String {
        String(format: t(key), arguments: args)
    }
}

/// 取得目前語言的字串
func L(_ key: String) -> String {
    L10n.shared.t(key)
}

/// 取得目前語言的字串並套用 `%@` 參數
func L(_ key: String, _ args: CVarArg...) -> String {
    L10n.shared.t(key, args)
}
