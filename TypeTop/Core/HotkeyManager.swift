import Foundation
import Carbon
import Cocoa

/// 全域快捷鍵管理器（按住說話模式）
final class HotkeyManager {
    static let shared = HotkeyManager()

    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?
    var onCancel: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isHotkeyPressed = false

    /// 目前使用的啟動鍵
    var activationKey: ActivationKey = .rightCommand

    private init() {}

    /// 啟動全域快捷鍵監聽
    func start() -> Bool {
        // 檢查輔助使用權限
        guard checkAccessibilityPermission() else {
            return false
        }

        // 監聽修飾鍵變化
        let eventMask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        return true
    }

    /// 停止全域快捷鍵監聽
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isHotkeyPressed = false
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // 如果事件 tap 被停用，重新啟用
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        guard type == .flagsChanged else {
            return Unmanaged.passRetained(event)
        }

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        // 錄音中偵測其他修飾鍵按下 → 取消
        if isHotkeyPressed {
            let isOtherModifier = keyCode != activationKey.rawValue
            if isOtherModifier {
                for mask in activationKey.cancelMasks {
                    if flags.contains(mask) {
                        isHotkeyPressed = false
                        DispatchQueue.main.async { [weak self] in
                            self?.onCancel?()
                        }
                        return nil
                    }
                }
            }
        }

        // 檢查是否為目標啟動鍵
        guard keyCode == activationKey.rawValue else {
            return Unmanaged.passRetained(event)
        }

        let isTargetPressed = flags.contains(activationKey.flagMask)

        if isTargetPressed && !isHotkeyPressed {
            isHotkeyPressed = true
            DispatchQueue.main.async { [weak self] in
                self?.onKeyDown?()
            }
            return nil
        } else if !isTargetPressed && isHotkeyPressed {
            isHotkeyPressed = false
            DispatchQueue.main.async { [weak self] in
                self?.onKeyUp?()
            }
            return nil
        }

        return Unmanaged.passRetained(event)
    }

    /// 檢查輔助使用權限（不彈出提示）
    func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// 檢查輔助使用權限並彈出系統提示
    func requestAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// 更新快捷鍵設定
    func updateHotkey(key: ActivationKey) {
        let wasRunning = eventTap != nil
        if wasRunning { stop() }
        activationKey = key
        if wasRunning { _ = start() }
    }
}
