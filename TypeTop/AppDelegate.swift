import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate!

    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var editShortcutMonitor: Any?
    private let pipeline = TranscriptionPipeline.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        setupMenuBar()
        setupEditShortcutMonitor()

        // 首次啟動時彈出輔助使用權限提示
        _ = HotkeyManager.shared.requestAccessibilityPermission()

        // 啟動快捷鍵（若權限未授權會自動定時重試）
        pipeline.activate()

        // 請求麥克風權限
        Task {
            _ = await AudioRecorder.requestPermission()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        pipeline.deactivate()
        if let monitor = editShortcutMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - 編輯快捷鍵

    /// LSUIElement App 沒有主選單，⌘A/⌘C/⌘V 等編輯快捷鍵不會自動分派，
    /// 需自行攔截並沿 responder chain 送出標準編輯動作
    private func setupEditShortcutMonitor() {
        editShortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard let key = event.charactersIgnoringModifiers?.lowercased() else { return event }

            let action: Selector?
            switch (flags, key) {
            case (.command, "a"): action = #selector(NSText.selectAll(_:))
            case (.command, "c"): action = #selector(NSText.copy(_:))
            case (.command, "v"): action = #selector(NSText.paste(_:))
            case (.command, "x"): action = #selector(NSText.cut(_:))
            case (.command, "z"): action = Selector(("undo:"))
            case ([.command, .shift], "z"): action = Selector(("redo:"))
            default: action = nil
            }

            guard let action else { return event }
            return NSApp.sendAction(action, to: nil, from: nil) ? nil : event
        }
    }

    // MARK: - MenuBar 設定

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "TypeTop")
        }

        rebuildMenu()
    }

    /// 重建選單內容（每次點擊時呼叫以更新狀態）
    func rebuildMenu() {
        let menu = NSMenu()
        let settingsStore = SettingsStore.shared

        // 狀態
        let statusText = pipeline.state.statusText
        let statusItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        // 最近辨識結果
        if let result = pipeline.lastResult {
            let resultItem = NSMenuItem(title: result.processedText, action: nil, keyEquivalent: "")
            resultItem.isEnabled = false
            menu.addItem(resultItem)
        }

        menu.addItem(NSMenuItem.separator())

        // 快捷鍵提示
        let hotkeyItem = NSMenuItem(title: L("menu.hold-to-speak", SettingsStore.shared.settings.activationKey.displayName), action: nil, keyEquivalent: "")
        hotkeyItem.isEnabled = false
        menu.addItem(hotkeyItem)

        menu.addItem(NSMenuItem.separator())

        // 偏好設定
        let settingsMenuItem = NSMenuItem(title: L("menu.preferences"), action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsMenuItem.target = self
        menu.addItem(settingsMenuItem)

        menu.addItem(NSMenuItem.separator())

        // 結束
        let quitItem = NSMenuItem(title: L("menu.quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        menu.delegate = self
        self.statusItem.menu = menu
    }

    @objc private func openSettingsAction() {
        openSettings()
    }

    // MARK: - 設定視窗

    func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsWindow()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 450),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = L("window.preferences")
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    /// 更新 MenuBar 圖示狀態
    func updateStatusIcon(isRecording: Bool) {
        DispatchQueue.main.async { [weak self] in
            if isRecording {
                self?.statusItem.button?.image = NSImage(systemSymbolName: "mic.badge.plus", accessibilityDescription: L("state.recording"))
            } else {
                self?.statusItem.button?.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "TypeTop")
            }
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu()
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) == settingsWindow {
            settingsWindow = nil
        }
    }
}
