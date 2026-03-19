import CoreAudio

/// 系統音訊靜音管理：錄音時自動靜音，結束後恢復
enum SystemAudioManager {

    /// 錄音前是否已經靜音（用於判斷結束後是否需要恢復）
    private static var wasMutedBeforeRecording = false

    /// 靜音系統音訊（記住先前狀態）
    static func muteSystemAudio() {
        wasMutedBeforeRecording = isSystemMuted()
        if !wasMutedBeforeRecording {
            setSystemMute(true)
        }
    }

    /// 恢復系統音訊到錄音前的狀態
    static func restoreSystemAudio() {
        if !wasMutedBeforeRecording {
            setSystemMute(false)
        }
    }

    // MARK: - CoreAudio 底層操作

    private static func defaultOutputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0, nil,
            &size,
            &deviceID
        )

        return status == noErr ? deviceID : nil
    }

    private static func isSystemMuted() -> Bool {
        guard let deviceID = defaultOutputDeviceID() else { return false }

        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &muted)
        return status == noErr && muted == 1
    }

    private static func setSystemMute(_ mute: Bool) {
        guard let deviceID = defaultOutputDeviceID() else { return }

        var muted: UInt32 = mute ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &muted)
    }
}
