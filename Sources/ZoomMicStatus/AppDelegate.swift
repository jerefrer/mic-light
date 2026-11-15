import AppKit
import ZoomMicStatusCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let zoomResources =
        URL(fileURLWithPath: "/Applications/zoom.us.app/Contents/Resources")

    private let strings = Strings(preferredLanguages: Locale.preferredLanguages)
    private let modeStore = DisplayModeStore()
    private let borderStyleStore = BorderStyleStore()
    private var badge: BadgeWindow!
    private var border: BorderOverlay!
    private var statusItem: StatusItemController!
    private var monitor: StatusMonitor!
    /// True while the border settings submenu is open.
    private var previewingBorder = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        badge = BadgeWindow(strings: strings)
        border = BorderOverlay(style: borderStyleStore.style)
        statusItem = StatusItemController(
            strings: strings,
            modeStore: modeStore,
            borderStyleStore: borderStyleStore,
            onModesChanged: { [weak self] in self?.render() },
            onResetBadgePosition: { [weak self] in self?.badge.resetPosition() },
            onBorderStyleChanged: { [weak self] style in self?.border.style = style },
            onBorderPreview: { [weak self] previewing in
                self?.previewingBorder = previewing
                self?.render()
            }
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

        var micState: MicState?
        if case .mic(let state) = status { micState = state }

        if let micState, modes.contains(.badge) { badge.show(micState) } else { badge.hide() }

        // The preview uses the live state when there is one, red otherwise.
        let borderState = previewingBorder
            ? micState ?? .muted
            : modes.contains(.border) ? micState : nil
        if let borderState { border.show(borderState) } else { border.hide() }
    }
}
