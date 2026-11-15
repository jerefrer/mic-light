import AppKit
import ZoomMicStatusCore

/// A thick colored frame around every screen. Clicks pass through it.
@MainActor
final class BorderOverlay {
    private var windows: [NSWindow] = []
    private var state: MicState?
    private var screenObserver: NSObjectProtocol?

    init() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuild() }
        }
    }

    func show(_ state: MicState) {
        self.state = state
        if windows.isEmpty { rebuild() }
        for window in windows {
            (window.contentView as? BorderView)?.color = Colors.signal(state)
            window.orderFrontRegardless()
        }
    }

    func hide() {
        state = nil
        windows.forEach { $0.orderOut(nil) }
    }

    /// Screens were added, removed or rearranged: one window per screen.
    private func rebuild() {
        windows.forEach { $0.close() }
        windows = NSScreen.screens.map(Self.makeWindow)
        if let state { show(state) }
    }

    private static func makeWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.contentView = BorderView()
        window.setFrame(screen.frame, display: false)
        return window
    }
}

private final class BorderView: NSView {
    var color: NSColor = .clear {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        let inset = Spacing.borderWidth / 2
        let path = NSBezierPath(rect: bounds.insetBy(dx: inset, dy: inset))
        path.lineWidth = Spacing.borderWidth
        color.setStroke()
        path.stroke()
    }
}
