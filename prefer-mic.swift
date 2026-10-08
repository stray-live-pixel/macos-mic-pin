import Foundation
import CoreAudio

let system = AudioObjectID(kAudioObjectSystemObject)
func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
}
func stringProperty(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
    var a = address(selector)
    var value: CFString = "" as CFString
    var size = UInt32(MemoryLayout<CFString>.size)
    guard AudioObjectGetPropertyData(id, &a, 0, nil, &size, &value) == noErr else { return nil }
    return value as String
}
func devices() -> [AudioObjectID] {
    var a = address(kAudioHardwarePropertyDevices)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(system, &a, 0, nil, &size) == noErr else { return [] }
    guard size > 0 else { return [] }
    var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    let status = ids.withUnsafeMutableBytes { AudioObjectGetPropertyData(system, &a, 0, nil, &size, $0.baseAddress!) }
    return status == noErr ? ids : []
}
func hasInput(_ id: AudioObjectID) -> Bool {
    var a = address(kAudioDevicePropertyStreams)
    a.mScope = kAudioDevicePropertyScopeInput
    var size: UInt32 = 0
    return AudioObjectGetPropertyDataSize(id, &a, 0, nil, &size) == noErr && size > 0
}
if CommandLine.arguments.contains("--list") {
    for id in devices() where hasInput(id) {
        print("\(stringProperty(id, kAudioObjectPropertyName) ?? "?")\t\(stringProperty(id, kAudioDevicePropertyDeviceUID) ?? "?")")
    }
    exit(0)
}
guard CommandLine.arguments.count == 2 else {
    fputs("Usage: prefer-mic DEVICE_UID | --list\n", stderr)
    exit(2)
}
let uid = CommandLine.arguments[1]
func restore() {
    guard var preferred = devices().first(where: { stringProperty($0, kAudioDevicePropertyDeviceUID) == uid && hasInput($0) }) else { return }
    var a = address(kAudioHardwarePropertyDefaultInputDevice)
    var current = AudioObjectID(0)
    var size = UInt32(MemoryLayout<AudioObjectID>.size)
    guard AudioObjectGetPropertyData(system, &a, 0, nil, &size, &current) == noErr, current != preferred else { return }
    let status = AudioObjectSetPropertyData(system, &a, 0, nil, size, &preferred)
    if status != noErr { fputs("Cannot set preferred microphone: \(status)\n", stderr) }
}
// CoreAudio events only: no polling and no microphone audio capture.
var pending: DispatchWorkItem?
let listener: AudioObjectPropertyListenerBlock = { _, _ in
    pending?.cancel()
    let work = DispatchWorkItem { restore() }
    pending = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
}
for selector in [kAudioHardwarePropertyDevices, kAudioHardwarePropertyDefaultInputDevice] {
    var a = address(selector)
    let status = AudioObjectAddPropertyListenerBlock(system, &a, DispatchQueue.main, listener)
    guard status == noErr else {
        fputs("Cannot watch audio devices: \(status)\n", stderr)
        exit(1)
    }
}
restore()
dispatchMain()
