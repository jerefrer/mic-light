import AppKit
import ZoomMicStatusCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let zoomResources =
        URL(fileURLWithPath: "/Applications/zoom.us.app/Contents/Resources")

    private let strings = Strings(preferredLanguages: Locale.preferredLanguages)
    private let modeStore = DisplayModeStore()
    private var badge: BadgeWindow!
    private var border: BorderOverlay!
    private var statusItem: StatusItemController!
    private var monitor: StatusMonitor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        badge = BadgeWindow(strings: strings)
        border = BorderOverlay()
        statusItem = StatusItemController(
            strings: strings,
            modeStore: modeStore,
            onModesChanged: { [weak self] in self?.render() },
            onResetBadgePosition: { [weak self] in self?.badge.resetPosition() }
        )

        let titles = MuteMenuTitles.load(fromZoomResources: Self.zoomResources)
        monitor = StatusMonitor(probe: ZoomProbe(finder: MuteItemFinder(titles: titles))) { [weak self] _ in
            self?.render()
        }
        monitor.start()
    }

    private func render() {
        let status = monitor.status
        let modes = modeStore.modes
        statusItem.show(status)

        guard case .mic(let state) = status else {
            badge.hide()
            border.hide()
            return
        }
        if modes.contains(.badge) { badge.show(state) } else { badge.hide() }
        if modes.contains(.border) { border.show(state) } else { border.hide() }
    }
}
