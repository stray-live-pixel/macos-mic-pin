#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/.local/lib/macos-mic-pin"
LABEL="local.macos-mic-pin"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

if [[ "${1:-}" == "--uninstall" ]]; then
    [[ $# -eq 1 ]] || { echo 'Usage: ./install.sh --uninstall' >&2; exit 2; }
    if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
        launchctl bootout "$DOMAIN/$LABEL"
    fi
    rm -f "$PLIST"
    rm -rf "$APP"
    echo "Uninstalled. Current microphone selection is unchanged."
    exit 0
fi

for uid in "$@"; do
    [[ -n "$uid" ]] || { echo 'Device UIDs must not be empty.' >&2; exit 2; }
done

BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
swiftc -O -module-cache-path "$BUILD/cache" "$ROOT/prefer-mic.swift" -o "$BUILD/prefer-mic"

if [[ $# -eq 0 ]]; then
    "$BUILD/prefer-mic" --list
    echo 'Copy device UIDs from the second column in priority order: ./install.sh "FIRST_UID" ["SECOND_UID" ...]'
    exit 0
fi

xml_escape() { printf '%s' "$1" | sed 's/\&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
mkdir -p "$APP" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
cat > "$BUILD/agent.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>$LABEL</string>
<key>ProgramArguments</key><array>
<string>$(xml_escape "$APP/prefer-mic")</string>
PLIST
for uid in "$@"; do
    printf '<string>%s</string>\n' "$(xml_escape "$uid")" >> "$BUILD/agent.plist"
done
cat >> "$BUILD/agent.plist" <<PLIST
</array>
<key>RunAtLoad</key><true/>
<key>KeepAlive</key><true/>
<key>ThrottleInterval</key><integer>10</integer>
<key>StandardErrorPath</key><string>$(xml_escape "$HOME/Library/Logs/macos-mic-pin.log")</string>
</dict></plist>
PLIST
plutil -lint "$BUILD/agent.plist"
if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
    launchctl bootout "$DOMAIN/$LABEL"
fi
install -m 755 "$BUILD/prefer-mic" "$APP/prefer-mic"
install -m 644 "$BUILD/agent.plist" "$PLIST"
launchctl bootstrap "$DOMAIN" "$PLIST"
echo "Installed and running. Starts automatically at login."
