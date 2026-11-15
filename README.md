# Zoom Mic Status

A tiny macOS menu bar app that makes Zoom's microphone state impossible to
miss: red when muted, green when live, hidden when no meeting is running.

Three display modes, any combination can be enabled from the menu bar icon:

| Mode | What it shows |
|------|---------------|
| Floating badge | A draggable red/green slab ("MIC MUTED" / "MIC LIVE") above every window, including full-screen Zoom |
| Screen border | A red/green frame around every screen; clicks pass through it. Thickness (2–80 pt), opacity and an optional fade toward the center are set under **Border Settings**, with a live preview while that submenu is open |
| Colored menu bar icon | A colored mic icon and label in the menu bar |

The menu bar icon itself is always there, since its menu holds the settings;
with the third mode off it stays a neutral mic glyph. The UI is in French
when the system language is French, English otherwise.

## How it works

Zoom has no public API exposing the desktop client's mute state. The app reads
the title of Zoom's **Meeting → Mute audio / Unmute audio** menu item through
the macOS Accessibility API: a menu offering to *unmute* means the mic is
muted. The titles are loaded at launch from every localization inside
`zoom.us.app`, so detection works whatever language Zoom is in.

It only *reads* the menu. It never presses an item or sends input to Zoom.

Polling runs every 300 ms during a meeting and every 1.5 s otherwise; the item
found is cached, so an in-meeting read is a single accessibility call.

## Requirements

- macOS 14 or later
- Zoom installed in `/Applications`
- Xcode command line tools (Swift 6) to build

## Build and install

```sh
scripts/build-app.sh            # builds build/Zoom Mic Status.app
scripts/build-app.sh --install  # also copies it to ~/Applications
```

On first launch, choose **Grant Accessibility Access…** in the menu, then
enable *Zoom Mic Status* in System Settings → Privacy & Security →
Accessibility.

"Launch at Login" is in the same menu.

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
