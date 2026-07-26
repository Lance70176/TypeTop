import Foundation

/// 詞彙庫本地存儲
@Observable
final class VocabularyStore {
    static let shared = VocabularyStore()

    private let fileManager = FileManager.default
    var library: VocabularyLibrary

    private var storageURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("TypeTop", isDirectory: true)
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("vocabulary.json")
    }

    private init() {
        if let data = try? Data(contentsOf: VocabularyStore.defaultStorageURL()),
           let decoded = try? JSONDecoder().decode(VocabularyLibrary.self, from: data) {
            self.library = decoded
        } else {
            self.library = VocabularyLibrary()
            loadDefaultVocabulary()
        }
    }

    private static func defaultStorageURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("TypeTop", isDirectory: true)
        return appDir.appendingPathComponent("vocabulary.json")
    }

    /// 載入內建預設詞彙
    private func loadDefaultVocabulary() {
        if let url = Bundle.main.url(forResource: "default_vocabulary", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([VocabularyEntry].self, from: data) {
            library.entries = decoded
            save()
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(library) {
            try? data.write(to: storageURL, options: .atomic)
        }
    }

    func add(source: String, target: String, note: String = "") {
        let entry = VocabularyEntry(source: source, target: target, note: note)
        library.add(entry)
        save()
    }

    func remove(at offsets: IndexSet) {
        library.remove(at: offsets)
        save()
    }

    func update(_ entry: VocabularyEntry) {
        library.update(entry)
        save()
    }

    /// 匯出詞彙庫為 JSON Data
    func exportJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(library.entries)
    }

    /// 從注音輸入法個人詞庫匯入（TSV 格式：詞<TAB>注音，每行一詞）
    /// 匯入為常用詞（source == target），注音存入備註
    func importZhuyinTXT(_ data: Data) throws {
        guard let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        var existingWords = Set(library.entries.map(\.target))
        for line in text.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "\t", maxSplits: 1)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard let word = parts.first, !word.isEmpty,
                  !existingWords.contains(word) else { continue }
            let zhuyin = parts.count > 1 ? parts[1] : ""
            library.entries.append(VocabularyEntry(source: word, target: word, note: zhuyin))
            existingWords.insert(word)
        }
        library.lastModified = Date()
        save()
    }

    /// 匯出為注音輸入法個人詞庫格式（詞<TAB>注音；備註非注音時僅輸出詞）
    func exportZhuyinTXT() -> Data? {
        let lines = library.entries.map { entry -> String in
            let isZhuyin = entry.note.unicodeScalars.contains { (0x3105...0x312F).contains($0.value) }
            return isZhuyin ? "\(entry.target)\t\(entry.note)" : entry.target
        }
        return lines.joined(separator: "\n").data(using: .utf8)
    }

    /// 從 JSON Data 匯入詞彙
    func importJSON(_ data: Data, replace: Bool = false) throws {
        let entries = try JSONDecoder().decode([VocabularyEntry].self, from: data)
        if replace {
            library.entries = entries
        } else {
            library.entries.append(contentsOf: entries)
        }
        library.lastModified = Date()
        save()
    }
}
