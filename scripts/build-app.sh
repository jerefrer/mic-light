#!/bin/sh
# Builds "Zoom Mic Status.app" into build/.
# Usage: scripts/build-app.sh [--install]   (--install copies it to ~/Applications)
set -eu

cd "$(dirname "$0")/.."

APP_NAME="Zoom Mic Status"
BUNDLE_ID="com.jerefrer.zoom-mic-status"
APP="build/$APP_NAME.app"

swift build -c release --product ZoomMicStatus
BIN="$(swift build -c release --show-bin-path)/ZoomMicStatus"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/ZoomMicStatus"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key><string>ZoomMicStatus</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>15.0</string>
    <key>LSUIElement</key><true/>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleLocalizations</key><array><string>en</string><string>fr</string></array>
</dict>
</plist>
PLIST

# Ad-hoc signature. The explicit designated requirement (bundle id only,
# instead of the default cdhash) is meant to let the Accessibility grant
# survive rebuilds.
codesign --force --sign - \
    --requirements "=designated => identifier \"$BUNDLE_ID\"" \
    "$APP"

echo "Built $APP"

if [ "${1:-}" = "--install" ]; then
    mkdir -p "$HOME/Applications"
    rm -rf "$HOME/Applications/$APP_NAME.app"
    cp -R "$APP" "$HOME/Applications/"
    echo "Installed to ~/Applications/$APP_NAME.app"
fi
