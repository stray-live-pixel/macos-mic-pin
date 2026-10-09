// Выбираем первый доступный микрофон из списка UID по приоритету,
// следим за изменениями устройств и возвращаем его как системный вход.
// Сам звук программа не читает и не записывает.
//
// Несколько обозначений Swift для чтения этого файла:
// let — значение без последующего изменения, var — изменяемая переменная.
// func — функция; return завершает её. guard проверяет условие:
// если оно не выполнено, выполняется блок else.
// Тип с ? допускает отсутствие значения (nil); ?? задаёт запасное значение.
// & перед переменной позволяет системной функции записать в неё результат.
//
// Foundation даёт строки, таймеры и другие базовые средства.
// CoreAudio — интерфейс macOS для работы с аудиоустройствами.
import Foundation
import CoreAudio

// Это идентификатор всей аудиосистемы macOS, а не отдельного микрофона.
let system = AudioObjectID(kAudioObjectSystemObject)
// У CoreAudio каждое свойство имеет «адрес»: какое свойство читаем,
// в какой области и для какого элемента. Здесь создаём общий адрес;
// для проверки входов ниже отдельно меняем область на Input.
func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
}
// Читаем текстовое свойство устройства: название или постоянный UID.
// String? означает: вернём строку, а при ошибке — nil.
func stringProperty(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
    var a = address(selector)
    var value: CFString = "" as CFString
    // Системному API нужен размер места для ссылки на строку в байтах.
    var size = UInt32(MemoryLayout<CFString>.size)
    // noErr означает успех. Остальные коды считаем ошибкой чтения.
    guard AudioObjectGetPropertyData(id, &a, 0, nil, &size, &value) == noErr else { return nil }
    return value as String
}
// Получаем список временных числовых ID всех аудиоустройств.
// Сначала узнаём размер списка в байтах, затем выделяем массив и читаем его.
func devices() -> [AudioObjectID] {
    var a = address(kAudioHardwarePropertyDevices)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(system, &a, 0, nil, &size) == noErr else { return [] }
    guard size > 0 else { return [] }
    var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    // Передаём CoreAudio память массива для заполнения. $0 — эта память.
    // baseAddress! допустим здесь: выше проверили, что размер не равен нулю.
    let status = ids.withUnsafeMutableBytes { AudioObjectGetPropertyData(system, &a, 0, nil, &size, $0.baseAddress!) }
    // Запись «условие ? A : B» выбирает A при успехе, иначе B.
    return status == noErr ? ids : []
}
// Отбираем устройства, способные принимать звук. У обычных колонок
// входных потоков нет, поэтому они не попадут в список микрофонов.
func hasInput(_ id: AudioObjectID) -> Bool {
    var a = address(kAudioDevicePropertyStreams)
    a.mScope = kAudioDevicePropertyScopeInput
    var size: UInt32 = 0
    return AudioObjectGetPropertyDataSize(id, &a, 0, nil, &size) == noErr && size > 0
}
// Режим --list только печатает название и UID через табуляцию и завершается.
// UID из второго столбца передаём программе в порядке приоритета.
if Array(CommandLine.arguments.dropFirst()) == ["--list"] {
    for id in devices() where hasInput(id) {
        print("\(stringProperty(id, kAudioObjectPropertyName) ?? "?")\t\(stringProperty(id, kAudioDevicePropertyDeviceUID) ?? "?")")
    }
    exit(0)
}
// После имени программы идёт один или несколько UID: самый важный первым.
let preferredUIDs = Array(CommandLine.arguments.dropFirst())
guard !preferredUIDs.isEmpty, preferredUIDs.allSatisfy({ !$0.isEmpty }) else {
    fputs("Usage: prefer-mic DEVICE_UID [DEVICE_UID ...] | --list\n", stderr)
    exit(2)
}
// Основное действие: вернуть нужный микрофон, только если это необходимо.
func restore() {
    // Один раз читаем подключённые входы, затем проверяем UID по приоритету.
    // Порядок устройств CoreAudio не должен влиять на наш выбор.
    let inputs = devices().filter { hasInput($0) }
    var selected: AudioObjectID?
    for uid in preferredUIDs {
        if let input = inputs.first(where: { stringProperty($0, kAudioDevicePropertyDeviceUID) == uid }) {
            selected = input
            break
        }
    }
    // Если ни одного предпочтительного входа нет, оставляем выбор macOS
    // и пользователя в настройках системы без изменений.
    guard var preferred = selected else { return }
    var a = address(kAudioHardwarePropertyDefaultInputDevice)
    // Узнаём, какой микрофон сейчас выбран входом по умолчанию.
    var current = AudioObjectID(0)
    var size = UInt32(MemoryLayout<AudioObjectID>.size)
    // При ошибке чтения или если нужный микрофон уже выбран — выходим.
    guard AudioObjectGetPropertyData(system, &a, 0, nil, &size, &current) == noErr, current != preferred else { return }
    // Меняем только системный вход. Выход звука не трогаем.
    // Приложение с собственным выбором микрофона может использовать другой.
    let status = AudioObjectSetPropertyData(system, &a, 0, nil, size, &preferred)
    if status != noErr { fputs("Cannot set preferred microphone: \(status)\n", stderr) }
}
// Дальше подписываемся на события: постоянного опроса по таймеру нет.
// pending хранит отложенную попытку вернуть микрофон.
var pending: DispatchWorkItem?
// Этот блок macOS вызывает при изменении устройств или выбранного входа.
// Два _ означают, что сведения самого события нам не нужны: перечитаем их.
let listener: AudioObjectPropertyListenerBlock = { _, _ in
    // Одно подключение может вызвать несколько событий подряд.
    // Отменяем предыдущую отложенную попытку (если она есть) и ждём
    // полсекунды после последнего события, чтобы устройства успели появиться.
    pending?.cancel()
    let work = DispatchWorkItem { restore() }
    pending = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
}
// Следим за двумя изменениями: состав устройств и вход по умолчанию.
// Обработчики выполняются в одной очереди, последовательно.
for selector in [kAudioHardwarePropertyDevices, kAudioHardwarePropertyDefaultInputDevice] {
    var a = address(selector)
    let status = AudioObjectAddPropertyListenerBlock(system, &a, DispatchQueue.main, listener)
    // Без подписки программа не сможет удерживать микрофон — завершаемся
    // с ошибкой. Установленный LaunchAgent запустит её повторно.
    guard status == noErr else {
        fputs("Cannot watch audio devices: \(status)\n", stderr)
        exit(1)
    }
}
// Сразу применяем предпочтение, затем остаёмся работать и ждать событий.
// При ручных переключениях тоже возвращаем первый доступный UID из списка.
// Автозапуск при входе настраивает install.sh, а не этот Swift-файл.
restore()
dispatchMain()
