#!/bin/sh
# Builds "Mic Light.app" into build/, signed with the Developer ID
# (hardened runtime, as notarization requires) when it is in the keychain,
# ad hoc otherwise.
# Usage: scripts/build-app.sh [--install]   (--install copies it to ~/Applications)
set -eu

cd "$(dirname "$0")/.."

APP_NAME="Mic Light"
# Kept from the app's first name, Zoom Mic Status: changing it would lose the
# users' settings and Accessibility grant, and break update continuity.
BUNDLE_ID="com.jerefrer.zoom-mic-status"
VERSION="$(cat VERSION)"
FEED_URL="https://github.com/jerefrer/mic-light/releases/latest/download/appcast.xml"
SPARKLE_PUBLIC_KEY="Tm3jGamXB+xoCj7tp6J8LZ8D1uAEttdZz/S5F0fQ4Lw="
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Jeremy Frere (3J4HCZ8V25)}"
APP="build/$APP_NAME.app"

swift build -c release --product ZoomMicStatus
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp "$BIN_DIR/ZoomMicStatus" "$APP/Contents/MacOS/ZoomMicStatus"

# Sparkle (auto-updates) is linked as @rpath/Sparkle.framework.
cp -R "$BIN_DIR/Sparkle.framework" "$APP/Contents/Frameworks/"
install_name_tool -add_rpath @executable_path/../Frameworks "$APP/Contents/MacOS/ZoomMicStatus" 2>/dev/null || true

# App icon, drawn by the app itself (the idle Dock icon).
ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
"$APP/Contents/MacOS/ZoomMicStatus" --write-app-icon "$ICONSET/icon_512x512@2x.png"
for size in 16 32 128 256 512; do
    sips -z $size $size "$ICONSET/icon_512x512@2x.png" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z $double $double "$ICONSET/icon_512x512@2x.png" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$(dirname "$ICONSET")"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key><string>ZoomMicStatus</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>15.0</string>
    <key>LSUIElement</key><true/>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleLocalizations</key><array><string>en</string><string>fr</string></array>
    <key>SUFeedURL</key><string>$FEED_URL</string>
    <key>SUPublicEDKey</key><string>$SPARKLE_PUBLIC_KEY</string>
    <key>SUEnableAutomaticChecks</key><true/>
    <key>SUScheduledCheckInterval</key><integer>86400</integer>
</dict>
</plist>
PLIST

if security find-identity -v -p codesigning | grep -qF "$SIGN_IDENTITY"; then
    # Innermost first: signing a bundle does not re-sign what it contains.
    # Forgetting Sparkle's Updater.app makes notarization fail.
    SPARKLE="$APP/Contents/Frameworks/Sparkle.framework"
    for inner in \
        "$SPARKLE/Versions/B/XPCServices/Downloader.xpc" \
        "$SPARKLE/Versions/B/XPCServices/Installer.xpc" \
        "$SPARKLE/Versions/B/Updater.app" \
        "$SPARKLE/Versions/B/Autoupdate" \
        "$SPARKLE" \
        "$APP"; do
        codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$inner"
    done
    codesign --verify --strict "$APP"
    echo "Signed with $SIGN_IDENTITY"
else
    # Without the Developer ID: the explicit designated requirement (bundle
    # id only, instead of the default cdhash) is meant to let the
    # Accessibility grant survive rebuilds.
    codesign --force --deep --sign - \
        --requirements "=designated => identifier \"$BUNDLE_ID\"" \
        "$APP"
    echo "Developer ID not found: signed ad hoc"
fi

echo "Built $APP ($VERSION)"

if [ "${1:-}" = "--install" ]; then
    mkdir -p "$HOME/Applications"
    rm -rf "$HOME/Applications/$APP_NAME.app"
    cp -R "$APP" "$HOME/Applications/"
    echo "Installed to ~/Applications/$APP_NAME.app"
fi
