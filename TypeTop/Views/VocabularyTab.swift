import SwiftUI

/// 自訂詞彙管理頁面
struct VocabularyTab: View {
    private var vocabularyStore = VocabularyStore.shared

    @State private var showAddSheet = false
    @State private var editingEntry: VocabularyEntry?
    @State private var searchText = ""
    @State private var showImportAlert = false
    @State private var importError: String?

    private var filteredEntries: [VocabularyEntry] {
        if searchText.isEmpty {
            return vocabularyStore.library.entries
        }
        return vocabularyStore.library.entries.filter {
            $0.source.localizedCaseInsensitiveContains(searchText) ||
            $0.target.localizedCaseInsensitiveContains(searchText) ||
            $0.note.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 工具列
            HStack {
                TextField(L("vocab.search"), text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)

                Spacer()

                Text(L("vocab.count", String(vocabularyStore.library.entries.count)))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }

                Menu {
                    Button(L("vocab.export-json")) { exportVocabulary() }
                    Button(L("vocab.export-zhuyin")) { exportZhuyinTXT() }
                    Button(L("vocab.import")) { importVocabulary() }
                    Divider()
                    Button(L("common.reset-default"), role: .destructive) {
                        vocabularyStore.library = VocabularyLibrary()
                        vocabularyStore.save()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .padding()

            Divider()

            // 詞彙列表
            if filteredEntries.isEmpty {
                ContentUnavailableView {
                    Label(L("vocab.empty-title"), systemImage: "text.book.closed")
                } description: {
                    VStack(spacing: 6) {
                        Text(L("vocab.empty-line1"))
                        Text(L("vocab.empty-line2"))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        VocabularyRow(entry: entry)
                            .onTapGesture {
                                editingEntry = entry
                            }
                    }
                    .onDelete { offsets in
                        vocabularyStore.remove(at: offsets)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            VocabularyEditSheet { entry in
                vocabularyStore.add(source: entry.source, target: entry.target, note: entry.note)
            }
        }
        .sheet(item: $editingEntry) { entry in
            VocabularyEditSheet(entry: entry) { updated in
                vocabularyStore.update(updated)
            }
        }
        .alert(L("vocab.import-error"), isPresented: $showImportAlert, presenting: importError) { _ in
            Button(L("common.ok")) {}
        } message: { error in
            Text(error)
        }
    }

    private func exportVocabulary() {
        guard let data = vocabularyStore.exportJSON() else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "typetop_vocabulary.json"
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }

    private func exportZhuyinTXT() {
        guard let data = vocabularyStore.exportZhuyinTXT() else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = L("vocab.default-filename")
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }

    private func importVocabulary() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json, .plainText]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                if url.pathExtension.lowercased() == "json" {
                    try vocabularyStore.importJSON(data, replace: false)
                } else {
                    try vocabularyStore.importZhuyinTXT(data)
                }
            } catch {
                importError = error.localizedDescription
                showImportAlert = true
            }
        }
    }
}

/// 詞彙列表行
struct VocabularyRow: View {
    let entry: VocabularyEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    if entry.source == entry.target {
                        // 常用詞（非替換規則）
                        Text(entry.target)
                            .fontWeight(.medium)
                    } else {
                        Text(entry.source)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(entry.target)
                            .fontWeight(.medium)
                    }
                }

                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Circle()
                .fill(entry.isEnabled ? .green : .gray)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 2)
    }
}

/// 詞彙編輯表單
struct VocabularyEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var source: String
    @State private var target: String
    @State private var note: String
    @State private var isEnabled: Bool

    private let existingEntry: VocabularyEntry?
    private let onSave: (VocabularyEntry) -> Void

    init(entry: VocabularyEntry? = nil, onSave: @escaping (VocabularyEntry) -> Void) {
        self.existingEntry = entry
        self.onSave = onSave
        _source = State(initialValue: entry?.source ?? "")
        _target = State(initialValue: entry?.target ?? "")
        _note = State(initialValue: entry?.note ?? "")
        _isEnabled = State(initialValue: entry?.isEnabled ?? true)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(existingEntry == nil ? L("vocab.new-entry") : L("vocab.edit-entry"))
                .font(.headline)

            Form {
                TextField(L("vocab.source"), text: $source)
                TextField(L("vocab.target"), text: $target)
                TextField(L("vocab.note"), text: $note)
                Toggle(L("vocab.enabled"), isOn: $isEnabled)
            }

            HStack {
                Button(L("common.cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button(existingEntry == nil ? L("common.add") : L("common.save")) {
                    var entry = existingEntry ?? VocabularyEntry(source: source, target: target)
                    entry.source = source
                    entry.target = target
                    entry.note = note
                    entry.isEnabled = isEnabled
                    onSave(entry)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(source.isEmpty || target.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 280)
    }
}
