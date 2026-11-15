# Decisions

## 2026-11-15 — Native macOS app instead of cross-platform
**Chosen:** User decision: Swift/AppKit, macOS only.
**Alternatives:** Electron or Tauri with per-OS detection modules.
**Why:** Detection is the hard part and is OS-specific anyway (Accessibility on macOS, UI Automation on Windows, AT-SPI on Linux), so a cross-platform UI layer would only share the trivial part while adding ~100 MB of runtime for a status light.
**Trade-offs:** A Windows version would be a separate program.
**Revisit if:** The indicator is needed on Windows or Linux.

---

## 2026-11-15 — Read the mute state from Zoom's menu item title
**Chosen:** Accessibility API: find the "Mute audio" / "Unmute audio" item in Zoom's menu bar and map its title to a state.
**Alternatives:** CoreAudio "device is running somewhere" (Zoom often keeps the input open while muted, so it cannot tell muted from live); Zoom Meeting SDK / REST API (not available for the user's own desktop client session).
**Why:** It is the only signal that tracks the desktop client's actual mute state, and it is what established tools (MuteDeck, Hammerspoon Zoom spoons) rely on.
**Trade-offs:** Requires the Accessibility permission; breaks if Zoom renames the localization keys `Mute Audio` / `Unmute Audio` (a built-in English/French fallback covers the bundle being unreadable, not a rename).
**Revisit if:** Zoom exposes the state officially, or a Zoom update stops the detection.

---

## 2026-11-15 — Load menu titles from Zoom's own localizations
**Chosen:** Read `Mute Audio` / `Unmute Audio` from every `*.lproj/Localizable.strings` in `zoom.us.app` at launch; match titles exactly after trimming, lowercasing and dropping a trailing ellipsis.
**Alternatives:** Hard-coding English and French titles; matching the ⇧⌘A shortcut (language-independent, but identical for both states).
**Why:** Works in all 17 languages Zoom ships and follows wording changes in Zoom updates. Exact matching is required because in Chinese the unmute title contains the mute title.
**Trade-offs:** Assumes Zoom lives in `/Applications`.
**Revisit if:** Zoom moves to a different localization format.

---

## 2026-11-15 — Menu bar item is always present
**Chosen:** The status item always exists; the "menu bar" display mode only controls whether it is colored.
**Alternatives:** Hide it entirely when the mode is off, exposing settings elsewhere.
**Why:** An LSUIElement app has no Dock icon or app menu, so the status item is the only way to reach the settings.
**Trade-offs:** One neutral icon in the menu bar even when the user only wants the badge or border.
**Revisit if:** A settings window reachable another way is added.

---

## 2026-11-15 — Build with SwiftPM plus a bundling script, ad-hoc signed
**Chosen:** `swift build` and `scripts/build-app.sh` assemble the `.app`; ad-hoc signature with an explicit designated requirement on the bundle identifier.
**Alternatives:** An Xcode project; a Developer ID signature.
**Why:** No Xcode project to maintain, everything buildable from the CLI; no signing identity on this machine. The explicit requirement is meant to keep the Accessibility grant across rebuilds (the default ad-hoc requirement is the cdhash, which changes on every build).
**Trade-offs:** Not notarized; whether TCC honors the custom requirement for an ad-hoc signature is not yet verified — if not, the permission must be re-granted after each rebuild.
**Revisit if:** The app is distributed to other machines.

---

## 2026-11-15 — Build outside the agent sandbox
**Chosen:** `swift build` / `swift test` run without the Claude Code sandbox.
**Why:** SwiftPM fails inside it: `sandbox-exec` cannot nest, and both build systems get "Operation not permitted" writing their own files under `.build/`, even with `--disable-sandbox`.
**Trade-offs:** Build commands need the unsandboxed permission prompt.
**Revisit if:** The sandbox write rules change.

---

## 2026-11-15 — Search only Zoom's Meeting menu
**Chosen:** When the localized title of Zoom's Meeting menu is known (key `Meeting` in Zoom's string tables), only that menu is walked; other menus are never opened.
**Alternatives:** Walking the whole menu bar (previous behavior); keeping the whole walk but slowing idle polling further.
**Why:** Measured against Zoom 7.1.9: the whole walk took ~75 ms and Zoom's Window menu alone up to 585 ms, served on Zoom's main thread every 1.5 s while no meeting runs, which can make Zoom stutter. The scoped walk measured ~1.6 ms.
**Trade-offs:** If Zoom moves the mute item out of the Meeting menu, detection stops (reported as "no meeting"). If the key is missing, the app falls back to the whole walk.
**Revisit if:** A Zoom update stops the detection while a meeting runs.

---

## 2026-11-15 — Read the user's own tile, checked against the menu
**Chosen:** Identify the user's participant tile by behavior (the only tile whose audio state followed two consecutive menu changes) and read it first; the menu stays the authority, and a tile disagreeing with it for over 1.5 s is dropped and relearned.
**Alternatives:** Menu only (up to 1 s delay); identifying the tile by a display name set in the settings; by tile position.
**Why:** Measured: Zoom refreshes the menu title on a ~1 s timer (tile→menu lag 60 ms–1.0 s, mean ~430 ms), while the tile changes immediately; with the tile the app follows within 0–80 ms. Tile order is not meaningful in Zoom, and the user's display name varies between meetings (e.g. "Jérémy | FR" contains none of their usual name variants), so a name setting would have failed in the very meeting used for testing.
**Trade-offs:** The first two toggles of each meeting still lag. If another participant toggled in lockstep with the user twice, the wrong tile could be picked; the cross-check limits that to 1.5 s of wrong display. Relies on undocumented accessibility descriptions of tiles (localized phrases loaded from Zoom's string tables, keys matched without their numeric suffix).
**Revisit if:** Zoom changes tile descriptions, or the learning proves slow in practice (a display-name hint could seed it).

---

## 2026-11-15 — Border corners follow the display's shape
**Chosen:** User decision: the border's inner corners mirror the physical display: squircle top corners and square bottom corners on notched MacBook displays, square corners elsewhere. A notch is detected by `NSScreen.safeAreaInsets.top > 0`.
**Alternatives:** Squircle inner corners on every display (previous behavior).
**Why:** The border reads as part of the screen when its inner edge parallels the panel's own outline; notched MacBook panels (MacBook Pro 14/16 from 2021, MacBook Air from 2022) have rounded top and square bottom corners, while iMac, external and older MacBook panels are rectangular.
**Trade-offs:** The display corner radius itself is not exposed by macOS, so the inner radius stays a fixed 24 pt rather than matching the panel exactly. A rounded display without a notch would get square corners.
**Revisit if:** Apple ships rounded displays without a notch, or the user wants squircles on external displays.

---

## 2026-11-15 — Settings window previews live on screen
**Chosen:** User decision: a SwiftUI settings window whose preview is the real indicators on screen, shown for as long as the window is open; outside meetings a Simulate switch picks the state, during a meeting the preview follows the real microphone and the switch is disabled.
**Alternatives:** A miniature desktop drawn inside the window; both.
**Why:** The real overlays already redraw instantly, so a live preview costs little and is exact, where a miniature would only approximate them. Never letting a simulation override the real state during a meeting avoids the one failure this app exists to prevent: misreporting the microphone.
**Trade-offs:** The window can hide part of what it previews (e.g. the badge, if dragged under it). The border sliders left the menu, so adjusting them now takes the window.
**Revisit if:** Users want to tune indicators without having them on screen.

---

## 2026-11-15 — Settings window in the style of LookAway
**Chosen:** User decision: a sidebar of pages (General, Badge, Border, Menu Bar & Dock, About) with colored icon tiles; each page opens on an illustration drawn over the user's own wallpaper (`NSWorkspace.desktopImageURL`) that mirrors the current settings — a scaled miniature of the main screen (the border is the real `BorderView`, scaled), or a close-up of the menu bar and Dock. The badge gets a 3×3 position grid; a manual drag switches it to a free position.
**Alternatives:** The previous single grouped form; `NavigationSplitView` for the sidebar.
**Why:** The user found the grouped form too plain and pointed at LookAway. The sidebar is hand-built because `NavigationSplitView` ignored the requested column width (rendered at 145 pt, truncating titles) even with min/ideal/max set. The minimum macOS becomes 15 for SwiftUI's `Group(subviews:)`, used to draw dividers between card rows.
**Trade-offs:** Wallpapers without a still image (dynamic/aerial) fall back to a gradient. Illustrations are faithful in position and scale, so a thin border looks thin in them.
**Revisit if:** Supporting macOS 14 matters, or NavigationSplitView's width handling is fixed.

---
