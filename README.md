# macos-mic-pin

Keep the highest-priority available microphone selected on macOS. A tiny Swift/CoreAudio agent — no third-party dependencies, polling, or audio recording.

- Chooses the first connected input from your ordered list of device UIDs.
- Switches to the next preferred microphone when a higher-priority one disconnects, and back when it returns.
- Leaves the system's microphone selection alone when none of the preferred inputs are connected.
- Starts at login. Apps with their own explicit microphone selection are unaffected.

## Install

Requires macOS and Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/stray-live-pixel/macos-mic-pin.git
cd macos-mic-pin
./install.sh                        # list input devices and their UIDs
./install.sh "DEVICE_UID"           # paste the UID from the second column
./install.sh "BOYA_UID" "LOGITECH_UID" # BOYA first, then Logitech, then system selection
```

Replace the example UIDs with values from `./install.sh`. Uses device UIDs, not display names; list them from highest to lowest priority. A single UID still works. Manual changes to the default microphone are reverted while any preferred device is connected. If none are connected, choose any input in System Settings; the agent does not force a fallback device or restore an earlier selection.

## Uninstall

```sh
./install.sh --uninstall
```

Installed under `~/.local/lib/macos-mic-pin`; LaunchAgent: `~/Library/LaunchAgents/local.macos-mic-pin.plist`. Errors: `~/Library/Logs/macos-mic-pin.log`.

---

# macos-mic-pin — Русский

Выбирает доступный микрофон с наивысшим приоритетом в macOS. Небольшой агент на Swift/CoreAudio — без сторонних зависимостей, периодического опроса и записи звука.

- Выбирает первый подключённый вход из списка UID по приоритету.
- При отключении переключается на следующий доступный микрофон из списка, при подключении более приоритетного — возвращается к нему.
- Если ни один из предпочтительных микрофонов не подключён, не вмешивается в системный выбор.
- Запускается при входе в систему. Не влияет на приложения, в которых микрофон выбран явно.

## Установка

Нужны macOS и Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/stray-live-pixel/macos-mic-pin.git
cd macos-mic-pin
./install.sh                        # показать устройства ввода и их UID
./install.sh "DEVICE_UID"           # вставить UID из второго столбца
./install.sh "BOYA_UID" "LOGITECH_UID" # сначала BOYA, затем Logitech, затем системный выбор
```

Вместо примеров подставь UID из вывода `./install.sh`, начиная с самого приоритетного. Используется UID устройства, а не его название. Запуск с одним UID по-прежнему работает. Пока хотя бы один предпочтительный микрофон подключён, ручные переключения отменяются. Если не подключён ни один, можно выбрать вход через настройки системы: агент не назначает запасное устройство и не восстанавливает предыдущий выбор.

## Удаление

```sh
./install.sh --uninstall
```

Устанавливается в `~/.local/lib/macos-mic-pin`; LaunchAgent: `~/Library/LaunchAgents/local.macos-mic-pin.plist`. Ошибки: `~/Library/Logs/macos-mic-pin.log`.
