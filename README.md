# macos-mic-pin

Keep your preferred microphone selected on macOS. A tiny Swift/CoreAudio agent — no third-party dependencies, polling, or audio recording.

- Restores your microphone when macOS or an app changes the default input.
- Leaves other devices alone while your microphone is disconnected; restores it when it returns.
- Starts at login. Apps with their own explicit microphone selection are unaffected.

## Install

Requires macOS and Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/stray-live-pixel/macos-mic-pin.git
cd macos-mic-pin
./install.sh                        # list input devices and their UIDs
./install.sh "DEVICE_UID"           # paste the UID from the second column
```

Uses the device UID, not its display name. Manual changes to the default microphone are also reverted while the preferred device is connected.

## Uninstall

```sh
./install.sh --uninstall
```

Installed under `~/.local/lib/macos-mic-pin`; LaunchAgent: `~/Library/LaunchAgents/local.macos-mic-pin.plist`. Errors: `~/Library/Logs/macos-mic-pin.log`.

---

# macos-mic-pin — Русский

Закрепляет предпочтительный микрофон в macOS. Небольшой агент на Swift/CoreAudio — без сторонних зависимостей, периодического опроса и записи звука.

- Возвращает выбранный микрофон, когда macOS или приложение меняет устройство ввода по умолчанию.
- Не вмешивается, пока микрофон отключён; возвращает его после подключения.
- Запускается при входе в систему. Не влияет на приложения, в которых микрофон выбран явно.

## Установка

Нужны macOS и Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/stray-live-pixel/macos-mic-pin.git
cd macos-mic-pin
./install.sh                        # показать устройства ввода и их UID
./install.sh "DEVICE_UID"           # вставить UID из второго столбца
```

Используется UID устройства, а не его название. Пока предпочтительный микрофон подключён, ручные переключения микрофона по умолчанию тоже отменяются.

## Удаление

```sh
./install.sh --uninstall
```

Устанавливается в `~/.local/lib/macos-mic-pin`; LaunchAgent: `~/Library/LaunchAgents/local.macos-mic-pin.plist`. Ошибки: `~/Library/Logs/macos-mic-pin.log`.
