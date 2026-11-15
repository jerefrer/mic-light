import AppKit
import ApplicationServices
import ZoomMicStatusCore

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

/// Reads Zoom's mic state from the title of its "Mute audio" menu item.
@MainActor
final class ZoomProbe {
    static let bundleIdentifier = "us.zoom.xos"
    /// Caps how long a busy or frozen Zoom can block one read.
    private static let messagingTimeout: Float = 0.25

    private let finder: MuteItemFinder
    private var cachedItem: AXNode?
    private var cachedPID: pid_t?

    init(finder: MuteItemFinder) {
        self.finder = finder
    }

    func readStatus() -> IndicatorStatus {
        guard AXIsProcessTrusted() else { return .needsPermission }
        guard let zoom = NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.bundleIdentifier).first
        else {
            forgetCachedItem()
            return .idle
        }

        // Re-reading the item found last time costs one round-trip instead
        // of a walk through every menu.
        if cachedPID == zoom.processIdentifier, let item = cachedItem,
           let match = finder.find(in: item) {
            return .mic(match.state)
        }

        forgetCachedItem()
        let app = AXUIElementCreateApplication(zoom.processIdentifier)
        AXUIElementSetMessagingTimeout(app, Self.messagingTimeout)
        guard let menuBar = AXNode(app).attribute(kAXMenuBarAttribute) else { return .idle }
        // The attribute is always an AXUIElement when the call succeeds.
        guard let match = finder.find(in: AXNode(menuBar as! AXUIElement)) else { return .idle }

        cachedItem = match.node
        cachedPID = zoom.processIdentifier
        return .mic(match.state)
    }

    private func forgetCachedItem() {
        cachedItem = nil
        cachedPID = nil
    }
}
