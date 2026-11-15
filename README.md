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

**Settings…** (⌘, in the menu) opens a settings window: display modes, menu
bar style, badge position, border appearance, launch at login and the
Accessibility status. While it is open, the real badge, border and menu bar
icon preview every change on screen; outside meetings a *Simulate* switch
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
