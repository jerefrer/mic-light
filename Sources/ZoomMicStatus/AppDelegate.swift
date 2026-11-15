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
    private var badge: BadgeWindow!
    private var border: BorderOverlay!
    private var statusItem: StatusItemController!
    private var settingsModel: SettingsViewModel!
    private var settingsWindow: SettingsWindowController!
    private var monitor: StatusMonitor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        badge = BadgeWindow(strings: strings)
        border = BorderOverlay(style: borderStyleStore.style)
        settingsModel = SettingsViewModel(
            modeStore: modeStore,
            borderStyleStore: borderStyleStore,
            menuBarStyleStore: menuBarStyleStore,
            loginItem: MainAppLoginItem(),
            onChange: { [weak self] in self?.render() },
            onResetBadgePosition: { [weak self] in self?.badge.resetPosition() }
        )
        settingsWindow = SettingsWindowController(model: settingsModel, strings: strings) { [weak self] _ in
            self?.render()
        }
        statusItem = StatusItemController(
            strings: strings,
            modes: { [weak self] in self?.modeStore.modes ?? [] },
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

    private func render() {
        let status = monitor.status
        let modes = modeStore.modes
        // While the settings window is open, the indicators preview the
        // settings, showing a simulated state outside meetings.
        let simulated = settingsWindow.isOpen ? settingsModel.simulated : nil
        let shown = SettingsPreview.displayedState(status: status, simulated: simulated)

        statusItem.show(status: status, shown: shown, style: menuBarStyleStore.style)

        if let shown, modes.contains(.badge) { badge.show(shown) } else { badge.hide() }

        let style = borderStyleStore.style
        if border.style != style { border.style = style }
        if let shown, modes.contains(.border) { border.show(shown) } else { border.hide() }
    }
}
