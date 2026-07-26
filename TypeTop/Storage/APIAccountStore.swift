import Foundation

/// 單一 API 帳號（同一供應商可設定多組）
struct APIAccount: Codable, Identifiable, Equatable {
    var id: UUID
    var label: String
    var key: String

    init(id: UUID = UUID(), label: String, key: String) {
        self.id = id
        self.label = label
        self.key = key
    }

    /// 遮蔽顯示用（保留前綴方便辨認）
    var maskedKey: String {
        key.count > 10 ? "\(key.prefix(7))…" : "•••"
    }
}

/// 多帳號 API Key 存儲：每個 scope（供應商）可有多組帳號，達額度時自動切換
///
/// scope 格式："stt.groq"、"llm.openai" 等
/// 存儲位置：~/Library/Application Support/TypeTop/apiaccounts.json（0600）
@Observable
final class APIAccountStore {
    static let shared = APIAccountStore()

    struct ScopeAccounts: Codable {
        var accounts: [APIAccount] = []
        var activeID: UUID?
    }

    private(set) var scopes: [String: ScopeAccounts] = [:]

    private static let fileName = "apiaccounts.json"

    private var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("TypeTop", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent(Self.fileName)
    }

    private init() {
        load()
        migrateLegacyKeysIfNeeded()
    }

    // MARK: - Scope

    static func scope(stt provider: APIProvider) -> String { "stt.\(provider.rawValue)" }
    static func scope(llm provider: LLMProvider) -> String { "llm.\(provider.rawValue)" }

    // MARK: - 查詢

    func accounts(_ scope: String) -> [APIAccount] {
        scopes[scope]?.accounts ?? []
    }

    /// 目前使用中的帳號（未指定時退回第一組）
    func activeAccount(_ scope: String) -> APIAccount? {
        guard let s = scopes[scope], !s.accounts.isEmpty else { return nil }
        if let id = s.activeID, let account = s.accounts.first(where: { $0.id == id }) {
            return account
        }
        return s.accounts.first
    }

    func activeKey(_ scope: String) -> String? {
        activeAccount(scope)?.key
    }

    /// 用量統計 key：綁定使用中的帳號，統計因此分帳號各自累計
    func usageKey(_ scope: String) -> String {
        guard let account = activeAccount(scope) else { return scope }
        return "\(scope)#\(account.id.uuidString)"
    }

    // MARK: - 管理

    func add(key: String, scope: String) {
        var s = scopes[scope] ?? ScopeAccounts()
        let account = APIAccount(label: nextLabel(in: s), key: key)
        s.accounts.append(account)
        if s.activeID == nil { s.activeID = account.id }
        scopes[scope] = s
        save()
    }

    /// 更新既有帳號的名稱與 Key（編輯用；帳號 id 不變，用量統計因此延續）
    /// 傳 nil 表示該欄位不更動；名稱留空則沿用原本的名稱。
    func update(accountID: UUID, label: String? = nil, key: String? = nil, scope: String) {
        guard var s = scopes[scope],
              let index = s.accounts.firstIndex(where: { $0.id == accountID }) else { return }
        if let label {
            let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { s.accounts[index].label = trimmed }
        }
        if let key {
            let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { s.accounts[index].key = trimmed }
        }
        scopes[scope] = s
        save()
    }

    func remove(accountID: UUID, scope: String) {
        guard var s = scopes[scope] else { return }
        s.accounts.removeAll { $0.id == accountID }
        if s.activeID == accountID { s.activeID = s.accounts.first?.id }
        scopes[scope] = s
        save()
    }

    func setActive(accountID: UUID, scope: String) {
        guard var s = scopes[scope], s.accounts.contains(where: { $0.id == accountID }) else { return }
        s.activeID = accountID
        scopes[scope] = s
        save()
    }

    /// 429 時輪替到下一組帳號。只有一組（或沒有）帳號時回傳 nil
    @discardableResult
    func switchToNext(_ scope: String) -> APIAccount? {
        guard var s = scopes[scope], s.accounts.count > 1,
              let current = activeAccount(scope),
              let index = s.accounts.firstIndex(of: current) else { return nil }
        let next = s.accounts[(index + 1) % s.accounts.count]
        s.activeID = next.id
        scopes[scope] = s
        save()
        return next
    }

    private func nextLabel(in s: ScopeAccounts) -> String {
        var number = s.accounts.count + 1
        while s.accounts.contains(where: { $0.label == L("api.account-n", number) }) {
            number += 1
        }
        return L("api.account-n", number)
    }

    // MARK: - 持久化

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([String: ScopeAccounts].self, from: data) else { return }
        scopes = decoded
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(scopes)
            try data.write(to: storageURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: storageURL.path)
        } catch {
            print("[TypeTop] API 帳號儲存失敗: \(error)")
        }
    }

    // MARK: - 舊格式遷移

    private static let migrationFlag = "com.typetop.apiaccounts.migrated"

    /// 將 apikeys.json 的單一 Key 匯入為第一組帳號，並把舊的用量統計併入帳號 key。
    /// 僅執行一次（旗標記錄於 UserDefaults），避免使用者刪除帳號後被重新匯入。
    private func migrateLegacyKeysIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.migrationFlag) else { return }
        for provider in APIProvider.allCases {
            let scope = Self.scope(stt: provider)
            if accounts(scope).isEmpty, let key = KeychainHelper.load(key: provider.keychainKey) {
                add(key: key, scope: scope)
                UsageTracker.shared.migrateUsage(
                    from: scope, to: usageKey(scope),
                    oldLimitKey: provider == .groq ? "stt" : nil
                )
            }
        }
        for provider in LLMProvider.allCases where provider.requiresAPIKey {
            let scope = Self.scope(llm: provider)
            if accounts(scope).isEmpty, let key = KeychainHelper.load(key: provider.keychainKey) {
                add(key: key, scope: scope)
                UsageTracker.shared.migrateUsage(
                    from: scope, to: usageKey(scope),
                    oldLimitKey: provider == .groq ? "llm" : nil
                )
            }
        }
        UserDefaults.standard.set(true, forKey: Self.migrationFlag)
    }
}
