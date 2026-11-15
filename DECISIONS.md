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
