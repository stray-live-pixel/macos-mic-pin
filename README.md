# macos-mic-pin

Keep your preferred microphone selected on macOS. A tiny Swift/CoreAudio agent — no third-party dependencies, polling, or audio recording.

- Restores your microphone when macOS or an app changes the default input.
- Leaves other devices alone while your microphone is disconnected; restores it when it returns.
- Starts at login. Apps with their own explicit microphone selection are unaffected.

Закрепляет выбранный микрофон в macOS и автоматически возвращает его при переключениях. Запускается при входе в систему; если микрофон отключён — не вмешивается. Без сторонних зависимостей и записи звука.

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
