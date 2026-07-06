import Foundation

/// 本地 API 用量統計（app 自行計數，非官方額度）
/// 另保存 Groq 回應 headers 提供的即時剩餘額度
@Observable
final class UsageTracker {
    static let shared = UsageTracker()

    /// 單日用量
    struct DayUsage: Codable {
        /// 請求次數，key 如 "stt.groq"、"llm.gemini"
        var requests: [String: Int] = [:]
        /// LLM tokens 用量，key 同上
        var tokens: [String: Int] = [:]
    }

    /// Groq 回應 headers 中的即時額度資訊
    struct GroqRateLimit: Codable {
        var remainingRequests: Int?
        var limitRequests: Int?
        var remainingTokens: Int?
        var limitTokens: Int?
        var updatedAt: Date
    }

    /// 每日用量，key 為 yyyy-MM-dd
    private(set) var days: [String: DayUsage] = [:]
    /// Groq 即時額度，key 為 "stt" 或 "llm"
    private(set) var groqLimits: [String: GroqRateLimit] = [:]

    private let fileManager = FileManager.default

    private var storageURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("TypeTop", isDirectory: true)
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("usage.json")
    }

    private struct Snapshot: Codable {
        var days: [String: DayUsage]
        var groqLimits: [String: GroqRateLimit]
    }

    private init() {
        if let data = try? Data(contentsOf: storageURL),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            days = decoded.days
            groqLimits = decoded.groqLimits
        }
        pruneOldDays()
    }

    private func save() {
        let snapshot = Snapshot(days: days, groqLimits: groqLimits)
        if let data = try? JSONEncoder().encode(snapshot) {
            try? data.write(to: storageURL, options: .atomic)
        }
    }

    /// 今日日期 key（本地時區）
    static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// 記錄一次請求
    func record(_ key: String, tokens: Int? = nil) {
        DispatchQueue.main.async {
            let today = Self.todayKey()
            var usage = self.days[today] ?? DayUsage()
            usage.requests[key, default: 0] += 1
            if let tokens {
                usage.tokens[key, default: 0] += tokens
            }
            self.days[today] = usage
            self.pruneOldDays()
            self.save()
        }
    }

    /// 從 Groq 回應 headers 更新即時額度（kind: "stt" 或 "llm"）
    func updateGroqLimits(kind: String, response: HTTPURLResponse) {
        func intHeader(_ name: String) -> Int? {
            response.value(forHTTPHeaderField: name).flatMap { Int($0) }
        }
        let limit = GroqRateLimit(
            remainingRequests: intHeader("x-ratelimit-remaining-requests"),
            limitRequests: intHeader("x-ratelimit-limit-requests"),
            remainingTokens: intHeader("x-ratelimit-remaining-tokens"),
            limitTokens: intHeader("x-ratelimit-limit-tokens"),
            updatedAt: Date()
        )
        guard limit.remainingRequests != nil || limit.remainingTokens != nil else { return }
        DispatchQueue.main.async {
            self.groqLimits[kind] = limit
            self.save()
        }
    }

    func todayRequests(_ key: String) -> Int {
        days[Self.todayKey()]?.requests[key] ?? 0
    }

    func todayTokens(_ key: String) -> Int {
        days[Self.todayKey()]?.tokens[key] ?? 0
    }

    /// 只保留最近 30 天
    private func pruneOldDays() {
        guard days.count > 30 else { return }
        let sorted = days.keys.sorted(by: >)
        for key in sorted.dropFirst(30) {
            days.removeValue(forKey: key)
        }
    }
}
