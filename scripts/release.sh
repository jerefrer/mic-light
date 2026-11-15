#!/bin/sh
# Publishes a release that installed copies pick up through Sparkle.
# Usage: scripts/release.sh 0.2.0
#
# Builds and signs the app (Developer ID), has Apple notarize it, signs the
# archive with the Sparkle key kept in the login keychain (account
# "zoom-mic-status"), then publishes a GitHub release holding the archive and
# appcast.xml, the feed every installed copy reads (SUFeedURL).
set -eu

cd "$(dirname "$0")/.."

VERSION="${1:?usage: scripts/release.sh <version>, e.g. 0.2.0}"
REPO="jerefrer/zoom-mic-status"
TAG="v$VERSION"
APP="build/Zoom Mic Status.app"
ZIP="build/ZoomMicStatus-$VERSION.zip"
# notarytool credentials are per Apple ID, not per app: Imprint's profile works.
NOTARY_PROFILE="${NOTARY_PROFILE:-imprint-notarize}"
SIGN_UPDATE=".build/artifacts/sparkle/Sparkle/bin/sign_update"

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Commit or stash your changes before releasing." >&2
    exit 1
fi

echo "$VERSION" > VERSION
scripts/build-app.sh

# Notarize the app, staple the ticket, then archive the stapled app.
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
spctl --assess --type execute -vv "$APP"

# Prints: sparkle:edSignature="..." length="..."
SIGNATURE="$("$SIGN_UPDATE" --account zoom-mic-status "$ZIP")"
cat > build/appcast.xml <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Zoom Mic Status</title>
    <item>
      <title>Zoom Mic Status $VERSION</title>
      <pubDate>$(date -u +"%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$VERSION</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
      <enclosure url="https://github.com/$REPO/releases/download/$TAG/ZoomMicStatus-$VERSION.zip"
                 type="application/octet-stream" $SIGNATURE />
    </item>
  </channel>
</rss>
XML

git add VERSION
git commit -m "chore(release): $TAG"
git tag -a "$TAG" -m "Zoom Mic Status $VERSION"
git push origin HEAD --follow-tags
gh release create "$TAG" "$ZIP" build/appcast.xml \
    --repo "$REPO" --title "Zoom Mic Status $VERSION" --generate-notes

echo "Released $TAG"
