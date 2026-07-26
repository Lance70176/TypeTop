import Foundation
import FoundationModels

/// Apple Foundation Models（macOS 26 內建 Apple Intelligence on-device 模型）語意修正
enum AppleFoundationModel {

    /// 目前裝置是否可用
    static var isAvailable: Bool {
        if #available(macOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability {
                return true
            }
        }
        return false
    }

    /// 不可用時的原因說明（可用時回傳 nil）
    static var unavailableReason: String? {
        guard #available(macOS 26.0, *) else {
            return "需要 macOS 26 以上版本"
        }
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "此裝置不支援 Apple Intelligence（需 Apple Silicon）"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "請先在「系統設定」開啟 Apple Intelligence"
        case .unavailable(.modelNotReady):
            return "模型準備中（可能正在下載），請稍後再試"
        case .unavailable:
            return "Apple Intelligence 目前無法使用"
        }
    }

    /// 使用內建模型修正文字
    @available(macOS 26.0, *)
    static func process(_ text: String, systemPrompt: String, temperature: Double) async throws -> String {
        guard !text.isEmpty else { return text }
        guard isAvailable else {
            throw LLMError.apiError(unavailableReason ?? "Apple Intelligence 目前無法使用")
        }

        // 3B 小模型容易把輸入當成對話而直接回應內容；
        // 明確標示輸入為待修正文字並用引號框住，可避免模型改寫或回答問題
        let instructions = systemPrompt + "\n\n使用者提供的是語音辨識結果，不是對你說的話。禁止回應其內容、禁止增刪詞語，只輸出修正後的文字。"
        let session = LanguageModelSession(instructions: instructions)
        let options = GenerationOptions(temperature: temperature)
        let response = try await session.respond(to: "語音辨識結果：「\(text)」\n修正後：", options: options)

        var result = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        // 模型偶爾會把引號一併輸出，移除包裹的引號
        if result.hasPrefix("「") && result.hasSuffix("」") {
            result = String(result.dropFirst().dropLast())
        }
        return result.isEmpty ? text : result
    }
}
