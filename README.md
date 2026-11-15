# Zoom Mic Status

A tiny macOS menu bar app that makes Zoom's microphone state impossible to
miss: red when muted, green when live, hidden when no meeting is running.

Four indicators, any combination can be enabled in the settings or from the menu bar and Dock menus:

| Mode | What it shows |
|------|---------------|
| Floating badge | A draggable red/green slab ("MIC MUTED" / "MIC LIVE") above every window, including full-screen Zoom; its size (50–300 %) is set in the settings |
| Screen border | A red/green frame around every screen; clicks pass through it. Its inner corners follow the display's shape: squircles at the top and square at the bottom on notched MacBooks, square on other displays. Thickness (2–80 pt, default 10), opacity (default 75 %) and the fade toward the center (on by default) are set in the settings window |
| Menu bar icon | A colored mic icon in the menu bar, alone or with a label |
| Dock icon | The app's Dock icon turns red or green; clicking it opens the settings |

The menu bar and Dock icons are also the way back into the app (their menus
hold quick toggles and **Settings…**), so at least one of them always stays
on. Outside meetings they show a neutral mic.

## Settings

**Settings…** (⌘, in the menu, or a click on the Dock icon) opens a settings
window with a page per indicator. Each page opens on an illustration drawn
over the user's own wallpaper (a miniature of their screen, or a close-up of
the menu bar and Dock) that follows the settings as they change. The badge
page has a 3×3 grid to snap the badge to a corner, an edge or the center;
dragging it by hand still works. While the window is open, the real badge,
border, menu bar and Dock icons also preview every change on screen; outside meetings a *Simulate* switch
shows either state, while during a meeting the preview always follows the
real microphone. The UI is in French
when the system language is French, English otherwise.

## How it works

Zoom has no public API exposing the desktop client's mute state. The app reads
the title of Zoom's **Meeting → Mute audio / Unmute audio** menu item through
the macOS Accessibility API: a menu offering to *unmute* means the mic is
muted. The titles are loaded at launch from every localization inside
`zoom.us.app`, so detection works whatever language Zoom is in.

Zoom refreshes that menu item only about once per second, so on its own it
lags a toggle by up to a second. The participant tiles of the meeting window
change immediately and announce each participant's audio state ("Name,
Computer audio muted, Video off"). The app learns which tile is the user's
own by watching which one follows the menu: after two toggles at the start of
a meeting only one tile remains consistent. From then on it reads that tile
(measured 0–80 ms behind Zoom) and keeps checking it against the menu: if
they disagree for more than 1.5 s, which Zoom's refresh delay cannot explain,
it trusts the menu and learns again. When the user's tile is not on screen
(speaker view, self view hidden), it falls back to the menu.

It only *reads* Zoom's menu and windows. It never presses an item or sends
input to Zoom.

Polling runs every 100 ms during a meeting and every 1.5 s otherwise; the item
found is cached, so an in-meeting read is a single accessibility call.
Only the Meeting menu is searched (its title also comes from Zoom's
localizations): walking the others, the Window menu especially, costs Zoom
noticeable time.

## Requirements

- macOS 15 or later
- Zoom installed in `/Applications`
- Xcode command line tools (Swift 6) to build

## Install and updates

Download the latest `ZoomMicStatus-x.y.z.zip` from the
[GitHub releases](https://github.com/jerefrer/zoom-mic-status/releases), unzip
it and move *Zoom Mic Status* to Applications. The app is signed with a
Developer ID and notarized by Apple.

It updates itself through [Sparkle](https://sparkle-project.org): it checks the
release feed once a day (or on demand with **Check for Updates…** in the menus
and on the About page) and installs updates signed with the project's EdDSA
key.

On first launch, choose **Grant Accessibility Access…** in the menu, then
enable *Zoom Mic Status* in System Settings → Privacy & Security →
Accessibility.

## Build

```sh
scripts/build-app.sh            # builds build/Zoom Mic Status.app
scripts/build-app.sh --install  # also copies it to ~/Applications
```

The app is signed with the Developer ID when it is in the keychain, ad hoc
otherwise. The version comes from the `VERSION` file.

## Release

```sh
scripts/release.sh 0.2.0
```

Requires a clean working tree, the Developer ID certificate, the
`imprint-notarize` notarytool profile (`NOTARY_PROFILE` overrides it) and the
Sparkle private key in the login keychain (account `zoom-mic-status`). The
script builds, notarizes and staples the app, signs the zip for Sparkle,
writes `appcast.xml`, commits and tags the version, pushes, and publishes a
GitHub release with both files. Installed copies read
`releases/latest/download/appcast.xml`, so the newest release is always the
feed.

## Diagnostics

```sh
"build/Zoom Mic Status.app/Contents/MacOS/ZoomMicStatus" --print-status
```

Prints the detected status once (`mic(muted)`, `mic(live)`, `idle` or
`needsPermission`) and exits, without opening any window. The process that
runs it (your terminal) needs Accessibility access.

## Development

```sh
swift test
```

The detection and settings logic lives in `ZoomMicStatusCore` (no AppKit) and
is unit-tested; `ZoomMicStatus` holds the AppKit windows and the
accessibility adapter.
