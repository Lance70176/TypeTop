import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate!

    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private let pipeline = TranscriptionPipeline.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        setupMenuBar()

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
        let hotkeyItem = NSMenuItem(title: "按住右側 ⌘ 說話", action: nil, keyEquivalent: "")
        hotkeyItem.isEnabled = false
        menu.addItem(hotkeyItem)

        menu.addItem(NSMenuItem.separator())

        // 偏好設定
        let settingsMenuItem = NSMenuItem(title: "偏好設定...", action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsMenuItem.target = self
        menu.addItem(settingsMenuItem)

        menu.addItem(NSMenuItem.separator())

        // 結束
        let quitItem = NSMenuItem(title: "結束 TypeTop", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
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
        window.title = "TypeTop 偏好設定"
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
                self?.statusItem.button?.image = NSImage(systemSymbolName: "mic.badge.plus", accessibilityDescription: "錄音中")
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
