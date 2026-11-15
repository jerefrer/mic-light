import AppKit
import SwiftUI
import ZoomMicStatusCore

/// Hosts the settings window and reports when it opens and closes, since
/// the indicators preview the settings for as long as it is open.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let model: SettingsViewModel
    private let strings: Strings
    private let onVisibilityChanged: (Bool) -> Void
    private var window: NSWindow?

    private(set) var isOpen = false

    init(model: SettingsViewModel, strings: Strings, onVisibilityChanged: @escaping (Bool) -> Void) {
        self.model = model
        self.strings = strings
        self.onVisibilityChanged = onVisibilityChanged
    }

    func show() {
        let window = self.window ?? makeWindow()
        self.window = window
        model.windowWillShow()
        // A menu bar app is never active on its own; without this the
        // window would open behind the frontmost app.
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        if !isOpen {
            isOpen = true
            onVisibilityChanged(true)
        }
    }

    func windowWillClose(_ notification: Notification) {
        isOpen = false
        onVisibilityChanged(false)
    }

    private func makeWindow() -> NSWindow {
        let hosting = NSHostingController(rootView: SettingsView(model: model, strings: strings))
        hosting.sizingOptions = .preferredContentSize
        let window = NSWindow(contentViewController: hosting)
        window.title = strings.settingsTitle
        // The sidebar runs up under the traffic lights, as in System Settings.
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        return window
    }
}
