import AppKit
import ZoomMicStatusCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let zoomResources =
        URL(fileURLWithPath: "/Applications/zoom.us.app/Contents/Resources")

    private let strings = Strings(preferredLanguages: Locale.preferredLanguages)
    private let modeStore = DisplayModeStore()
    private let borderStyleStore = BorderStyleStore()
    private let menuBarStyleStore = MenuBarStyleStore()
    private let badgeScaleStore = BadgeScaleStore()
    private let badgeAnchorStore = BadgeAnchorStore()
    private var badge: BadgeWindow!
    private var border: BorderOverlay!
    private var statusItem: StatusItemController!
    private var dock: DockController!
    private var settingsModel: SettingsViewModel!
    private var settingsWindow: SettingsWindowController!
    private var monitor: StatusMonitor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        badge = BadgeWindow(strings: strings, anchor: badgeAnchorStore.anchor)
        border = BorderOverlay(style: borderStyleStore.style)
        settingsModel = SettingsViewModel(
            modeStore: modeStore,
            borderStyleStore: borderStyleStore,
            menuBarStyleStore: menuBarStyleStore,
            badgeScaleStore: badgeScaleStore,
            badgeAnchorStore: badgeAnchorStore,
            loginItem: MainAppLoginItem(),
            onChange: { [weak self] in self?.render() }
        )
        settingsModel.update(badgeFrame: badge.frame, draggedByUser: false)
        badge.onFrameChange = { [weak self] frame, draggedByUser in
            self?.settingsModel.update(badgeFrame: frame, draggedByUser: draggedByUser)
        }
        settingsWindow = SettingsWindowController(model: settingsModel, strings: strings) { [weak self] _ in
            self?.render()
        }
        dock = DockController { [weak self] in
            // Switching between Dock app and menu bar utility deactivates
            // the app; keep the settings window in front if it is open.
            guard let self, self.settingsWindow.isOpen else { return }
            self.settingsWindow.show()
        }
        NSApp.mainMenu = MainMenu.make(strings: strings, settingsTarget: self, settingsAction: #selector(openSettings))
        statusItem = StatusItemController(
            strings: strings,
            modes: { [weak self] in self?.modeStore.modes ?? [] },
            canToggle: { [weak self] mode in self?.modeStore.canToggle(mode) ?? false },
            onToggleMode: { [weak self] mode in self?.settingsModel.toggle(mode) },
            onOpenSettings: { [weak self] in self?.settingsWindow.show() }
        )

        let titles = MuteMenuTitles.load(fromZoomResources: Self.zoomResources)
        let tiles = ZoomTiles(phrases: TileAudioPhrases.load(fromZoomResources: Self.zoomResources))
        let probe = ZoomProbe(finder: MuteItemFinder(titles: titles), tiles: tiles)
        monitor = StatusMonitor(probe: probe) { [weak self] status in
            self?.settingsModel.update(status: status)
            self?.render()
        }
        monitor.start()
    }

    @objc private func openSettings() {
        settingsWindow.show()
    }

    /// Clicking the Dock icon opens the settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindow.show()
        return false
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        statusItem.makeDockMenu()
    }

    private func render() {
        let status = monitor.status
        let modes = modeStore.modes
        // While the settings window is open, the indicators preview the
        // settings, showing a simulated state outside meetings.
        let simulated = settingsWindow.isOpen ? settingsModel.simulated : nil
        let shown = SettingsPreview.displayedState(status: status, simulated: simulated)

        statusItem.show(status: status, shown: shown, style: menuBarStyleStore.style)
        dock.show(enabled: modes.contains(.dock), shown: shown, needsPermission: status == .needsPermission)

        badge.anchor = badgeAnchorStore.anchor
        if let shown, modes.contains(.badge) {
            badge.show(shown, scale: badgeScaleStore.scale)
        } else {
            badge.hide()
        }

        let style = borderStyleStore.style
        if border.style != style { border.style = style }
        if let shown, modes.contains(.border) { border.show(shown) } else { border.hide() }
    }
}
