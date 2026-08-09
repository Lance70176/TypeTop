import Foundation
import AppKit

/// 文字注入器：將辨識結果透過剪貼簿 + Cmd+V 貼到目標應用
enum TextInjector {

    /// 貼上前的最小等待（讓剪貼簿寫入對其他行程可見）
    private static let prePasteDelay: UInt64 = 120_000_000 // 120ms
    /// 確認剪貼簿內容寫入成功的最長輪詢時間
    private static let clipboardConfirmTimeout: Double = 0.5 // 500ms
    /// 貼上後等待目標 App 真正讀取剪貼簿的時間
    /// Electron / 瀏覽器 / 遠端桌面等 App 讀取較慢，太短會讓它們讀到還原後的舊內容
    private static let restoreDelay: UInt64 = 1_200_000_000 // 1.2s

    /// 將文字注入到當前焦點的輸入框
    static func inject(_ text: String) async {
        let pasteboard = NSPasteboard.general

        // 1. 備份當前剪貼簿內容
        let backup = backupPasteboard()

        // 2. 設定辨識結果到剪貼簿
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let injectedChangeCount = pasteboard.changeCount

        // 3. 確認剪貼簿真的已經是辨識結果才送出貼上
        //    （寫入失敗時直接放棄，避免把舊剪貼簿內容貼進輸入框）
        guard await waitUntilClipboardMatches(text) else {
            restorePasteboard(backup, expectedChangeCount: injectedChangeCount)
            return
        }
        try? await Task.sleep(nanoseconds: prePasteDelay)

        // 4. 模擬 Cmd+V 貼上
        simulatePaste()

        // 5. 等目標 App 讀完剪貼簿後才還原
        try? await Task.sleep(nanoseconds: restoreDelay)
        restorePasteboard(backup, expectedChangeCount: injectedChangeCount)
    }

    /// 輪詢等待剪貼簿內容變成指定文字
    private static func waitUntilClipboardMatches(_ text: String) async -> Bool {
        let pasteboard = NSPasteboard.general
        let deadline = Date().addingTimeInterval(clipboardConfirmTimeout)

        while Date() < deadline {
            if pasteboard.string(forType: .string) == text {
                return true
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        return pasteboard.string(forType: .string) == text
    }

    /// 模擬 Cmd+V 按鍵組合
    private static func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key code 9 = 'V'
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    // MARK: - 剪貼簿備份與還原

    private struct PasteboardBackup {
        var items: [(type: NSPasteboard.PasteboardType, data: Data)]
    }

    private static func backupPasteboard() -> PasteboardBackup {
        let pasteboard = NSPasteboard.general
        var items: [(type: NSPasteboard.PasteboardType, data: Data)] = []

        for type in pasteboard.types ?? [] {
            if let data = pasteboard.data(forType: type) {
                items.append((type: type, data: data))
            }
        }

        return PasteboardBackup(items: items)
    }

    /// 還原剪貼簿
    /// - Parameter expectedChangeCount: 我們寫入辨識結果時的 changeCount；
    ///   若期間使用者又複製了新內容（changeCount 改變），就不要覆蓋掉他的東西
    private static func restorePasteboard(_ backup: PasteboardBackup, expectedChangeCount: Int) {
        guard !backup.items.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount == expectedChangeCount else { return }

        pasteboard.clearContents()

        for item in backup.items {
            pasteboard.setData(item.data, forType: item.type)
        }
    }
}
