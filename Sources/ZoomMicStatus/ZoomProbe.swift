import AppKit
import ApplicationServices
import ZoomMicStatusCore
import os

/// An element of Zoom's accessibility tree, adapted to `MenuNode`.
final class AXNode: MenuNode {
    let element: AXUIElement

    init(_ element: AXUIElement) {
        self.element = element
    }

    var title: String? {
        attribute(kAXTitleAttribute) as? String
    }

    func children() -> [AXNode] {
        (attribute(kAXChildrenAttribute) as? [AXUIElement])?.map(AXNode.init) ?? []
    }

    func attribute(_ name: String) -> AnyObject? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
            return nil
        }
        return value
    }
}

/// Reads Zoom's mic state.
///
/// The authoritative source is the title of the "Mute audio" menu item, but
/// Zoom refreshes it only about once per second. The user's own participant
/// tile changes immediately, so once that tile has been identified it is
/// read first, and checked against the menu.
@MainActor
final class ZoomProbe {
    static let bundleIdentifier = "us.zoom.xos"
    /// Caps how long a busy or frozen Zoom can block one read.
    private static let messagingTimeout: Float = 0.25

    private let finder: MuteItemFinder
    private let tiles: ZoomTiles
    private let logger = Logger(subsystem: "com.jerefrer.zoom-mic-status", category: "probe")
    private var cachedItem: AXNode?
    private var cachedPID: pid_t?
    private var learner = SelfTileLearner()
    private var crossCheck = TileCrossCheck()
    private var lastMenuState: MicState?

    init(finder: MuteItemFinder, tiles: ZoomTiles) {
        self.finder = finder
        self.tiles = tiles
    }

    func readStatus() -> IndicatorStatus {
        guard AXIsProcessTrusted() else { return .needsPermission }
        guard let zoom = NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.bundleIdentifier).first
        else {
            leaveMeeting()
            return .idle
        }

        let app = AXUIElementCreateApplication(zoom.processIdentifier)
        AXUIElementSetMessagingTimeout(app, Self.messagingTimeout)
        guard let menuState = readMenuState(app: app, pid: zoom.processIdentifier) else {
            leaveMeeting()
            return .idle
        }

        // The first reading of a meeting is not a change: tiles may still be
        // loading, and nothing was toggled.
        if let previous = lastMenuState, previous != menuState, learner.selfName == nil {
            learner.menuChanged(to: menuState, tiles: tiles.readAll(in: app))
            if learner.selfName != nil { logger.debug("Identified the user's own tile") }
        }
        lastMenuState = menuState

        let now = ContinuousClock.now
        let tileState = learner.selfName.flatMap { tiles.state(ofTileNamed: $0, in: app, now: now) }
        let result = crossCheck.resolve(menu: menuState, tile: tileState, now: now)
        if result.tileDistrusted {
            logger.debug("Own tile disagreed with the menu for too long; relearning")
            learner.forget()
            tiles.forgetOwnTile()
        }
        return .mic(result.state)
    }

    private func readMenuState(app: AXUIElement, pid: pid_t) -> MicState? {
        // Re-reading the item found last time costs one round-trip instead
        // of a walk through the Meeting menu.
        if cachedPID == pid, let item = cachedItem, let match = finder.match(item) {
            return match.state
        }

        forgetCachedItem()
        guard let menuBar = AXNode(app).attribute(kAXMenuBarAttribute) else { return nil }
        // The attribute is always an AXUIElement when the call succeeds.
        guard let match = finder.find(in: AXNode(menuBar as! AXUIElement)) else { return nil }

        cachedItem = match.node
        cachedPID = pid
        return match.state
    }

    private func leaveMeeting() {
        forgetCachedItem()
        learner.forget()
        tiles.forgetOwnTile()
        crossCheck = TileCrossCheck()
        lastMenuState = nil
    }

    private func forgetCachedItem() {
        cachedItem = nil
        cachedPID = nil
    }
}
