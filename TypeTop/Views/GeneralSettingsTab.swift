import SwiftUI
import ServiceManagement

/// 一般設定頁面
struct GeneralSettingsTab: View {
    private var settingsStore = SettingsStore.shared

    @State private var accessibilityGranted: Bool = false
    @State private var micPermissionGranted: Bool = false
    @State private var permissionTimer: Timer?

    var body: some View {
        Form {
            Section("快捷鍵") {
                Picker("按住說話快捷鍵", selection: Bindable(settingsStore).settings.activationKey) {
                    ForEach(ActivationKey.allCases) { key in
                        Text(key.displayName).tag(key)
                    }
                }
                .onChange(of: settingsStore.settings.activationKey) { _, newValue in
                    HotkeyManager.shared.updateHotkey(key: newValue)
                }
            }

            Section("權限") {
                HStack {
                    Text("輔助使用權限")
                    Spacer()
                    if accessibilityGranted {
                        Label("已授權", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("前往設定") {
                            openAccessibilitySettings()
                        }
                    }
                }

                HStack {
                    Text("麥克風權限")
                    Spacer()
                    if micPermissionGranted {
                        Label("已授權", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("請求權限") {
                            Task {
                                micPermissionGranted = await AudioRecorder.requestPermission()
                            }
                        }
                        Button("前往設定") {
                            AudioRecorder.openMicrophoneSettings()
                        }
                    }
                }
            }
            .onAppear {
                checkPermissions()
                // 每 2 秒自動檢查一次權限狀態
                permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                    checkPermissions()
                }
            }
            .onDisappear {
                permissionTimer?.invalidate()
                permissionTimer = nil
            }

            Section("行為") {
                Toggle("播放音效提示", isOn: Bindable(settingsStore).settings.playSoundEffects)

                Toggle("開機自動啟動", isOn: Bindable(settingsStore).settings.launchAtLogin)
                    .onChange(of: settingsStore.settings.launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }

            Section("關於") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("TypeTop")
                    Spacer()
                    Text("語音輸入，好好打字")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func checkPermissions() {
        accessibilityGranted = AXIsProcessTrusted()
        micPermissionGranted = AudioRecorder.hasPermission
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("設定開機啟動失敗: \(error)")
        }
    }
}
