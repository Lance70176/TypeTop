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
            Section(L("general.section.shortcut")) {
                Picker(L("general.push-to-talk-key"), selection: Bindable(settingsStore).settings.activationKey) {
                    ForEach(ActivationKey.allCases) { key in
                        Text(key.displayName).tag(key)
                    }
                }
                .onChange(of: settingsStore.settings.activationKey) { _, newValue in
                    HotkeyManager.shared.updateHotkey(key: newValue)
                    AppDelegate.shared?.rebuildMenu()
                }

                Picker(L("general.interface-language"), selection: Bindable(settingsStore).settings.uiLanguage) {
                    ForEach(SupportedLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .onChange(of: settingsStore.settings.uiLanguage) { _, newValue in
                    L10n.shared.language = newValue
                    AppDelegate.shared?.rebuildMenu()
                }
            }

            Section(L("general.section.permissions")) {
                HStack {
                    Text(L("general.accessibility"))
                    Spacer()
                    if accessibilityGranted {
                        Label(L("general.granted"), systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button(L("general.open-settings")) {
                            openAccessibilitySettings()
                        }
                    }
                }

                HStack {
                    Text(L("general.microphone"))
                    Spacer()
                    if micPermissionGranted {
                        Label(L("general.granted"), systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button(L("general.request-access")) {
                            Task {
                                micPermissionGranted = await AudioRecorder.requestPermission()
                            }
                        }
                        Button(L("general.open-settings")) {
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

            Section(L("general.section.behavior")) {
                Toggle(L("general.play-sounds"), isOn: Bindable(settingsStore).settings.playSoundEffects)

                Toggle(L("general.mute-system-audio"), isOn: Bindable(settingsStore).settings.muteSystemAudioWhileRecording)

                Toggle(L("general.launch-at-login"), isOn: Bindable(settingsStore).settings.launchAtLogin)
                    .onChange(of: settingsStore.settings.launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }

            Section(L("general.section.about")) {
                HStack {
                    Text(L("general.version"))
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("TypeTop")
                    Spacer()
                    Text(L("general.tagline"))
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
