import Foundation

/// 語音辨識結果
struct TranscriptionResult {
    /// 辨識出的原始文字
    let rawText: String
    /// 經過後處理的文字
    var processedText: String
    /// 使用的 API 供應商
    let provider: APIProvider
    /// 辨識耗時（秒）
    let duration: TimeInterval
    /// 偵測到的語言
    let detectedLanguage: String?

    init(rawText: String, provider: APIProvider, duration: TimeInterval, detectedLanguage: String? = nil) {
        self.rawText = rawText
        self.processedText = rawText
        self.provider = provider
        self.duration = duration
        self.detectedLanguage = detectedLanguage
    }
}

/// 辨識狀態
enum TranscriptionState: Equatable {
    case idle
    case recording
    case processing
    case completed(String)
    case cancelled
    case error(String)

    var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }

    var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }

    var statusText: String {
        switch self {
        case .idle: return L("state.idle")
        case .recording: return L("state.recording-ellipsis")
        case .processing: return L("state.transcribing-ellipsis")
        case .completed(let text): return L("state.done", String(text.prefix(20)))
        case .cancelled: return L("state.cancelled")
        case .error(let msg): return L("state.error", msg)
        }
    }
}
