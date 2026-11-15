#!/bin/sh
# Publishes a release that installed copies pick up through Sparkle.
# Usage: scripts/release.sh 0.2.0
#
# Builds and signs the app (Developer ID), packs it in a drag-to-Applications
# DMG that Apple notarizes, signs the DMG with the Sparkle key kept in the
# login keychain (account "zoom-mic-status"), then publishes a GitHub release
# holding the DMG and appcast.xml, the feed every installed copy reads
# (SUFeedURL). The DMG name never changes, so
# releases/latest/download/MicLight.dmg always serves the newest one.
set -eu

cd "$(dirname "$0")/.."

VERSION="${1:?usage: scripts/release.sh <version>, e.g. 0.2.0}"
REPO="jerefrer/mic-light"
TAG="v$VERSION"
APP="build/Mic Light.app"
DMG="build/MicLight.dmg"
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Jeremy Frere (3J4HCZ8V25)}"
# notarytool credentials are per Apple ID, not per app: Imprint's profile works.
NOTARY_PROFILE="${NOTARY_PROFILE:-imprint-notarize}"
SIGN_UPDATE=".build/artifacts/sparkle/Sparkle/bin/sign_update"

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Commit or stash your changes before releasing." >&2
    exit 1
fi

echo "$VERSION" > VERSION
scripts/build-app.sh

# The DMG shows the app next to a shortcut to Applications; a
# .VolumeIcon.icns at its root gives the mounted volume the app icon.
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
cp "$APP/Contents/Resources/AppIcon.icns" "$STAGE/.VolumeIcon.icns"
rm -f "$DMG"
hdiutil create -volname "Mic Light" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"
codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG"

# Notarizing the DMG covers the app inside it.
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"
spctl --assess --type open --context context:primary-signature -vv "$DMG"

# Prints: sparkle:edSignature="..." length="..."
SIGNATURE="$("$SIGN_UPDATE" --account zoom-mic-status "$DMG")"
cat > build/appcast.xml <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Mic Light</title>
    <item>
      <title>Mic Light $VERSION</title>
      <pubDate>$(date -u +"%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$VERSION</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
      <enclosure url="https://github.com/$REPO/releases/download/$TAG/MicLight.dmg"
                 type="application/octet-stream" $SIGNATURE />
    </item>
  </channel>
</rss>
XML

git add VERSION
# VERSION may already hold this version (e.g. the first release).
git diff --cached --quiet || git commit -m "chore(release): $TAG"
git tag -a "$TAG" -m "Mic Light $VERSION"
git push origin HEAD --follow-tags
gh release create "$TAG" "$DMG" build/appcast.xml \
    --repo "$REPO" --title "Mic Light $VERSION" --generate-notes

echo "Released $TAG"
