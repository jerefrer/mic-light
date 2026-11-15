import AppKit
import ZoomMicStatusCore

/// A colored frame around every screen. Clicks pass through it.
@MainActor
final class BorderOverlay {
    private var windows: [NSWindow] = []
    private var state: MicState?
    private var screenObserver: NSObjectProtocol?

    var style: BorderStyle {
        didSet { windows.forEach { ($0.contentView as? BorderView)?.style = style } }
    }

    init(style: BorderStyle) {
        self.style = style
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
        windows = NSScreen.screens.map { makeWindow(for: $0) }
        if let state { show(state) }
    }

    private func makeWindow(for screen: NSScreen) -> NSWindow {
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
        let view = BorderView()
        view.style = style
        window.contentView = view
        window.setFrame(screen.frame, display: false)
        return window
    }
}

private final class BorderView: NSView {
    var color: NSColor = .clear {
        didSet { needsDisplay = true }
    }

    var style = BorderStyle.standard {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        let width = CGFloat(style.width)
        let edgeColor = color.withAlphaComponent(CGFloat(style.opacity))

        guard style.fades else {
            let inset = width / 2
            let path = NSBezierPath(rect: bounds.insetBy(dx: inset, dy: inset))
            path.lineWidth = width
            edgeColor.setStroke()
            path.stroke()
            return
        }

        // Concentric one-pixel rings, fading toward the center. Each ring is
        // a whole rectangle, so the corners have no seam, and every pixel's
        // opacity depends only on its distance to the nearest screen edge.
        let pixel = 1 / (window?.backingScaleFactor ?? 2)
        let rings = max(1, Int((width / pixel).rounded()))
        for ring in 0..<rings {
            let progress = (CGFloat(ring) + 0.5) / CGFloat(rings)
            let inset = (CGFloat(ring) + 0.5) * pixel
            let path = NSBezierPath(rect: bounds.insetBy(dx: inset, dy: inset))
            path.lineWidth = pixel
            edgeColor.withAlphaComponent(CGFloat(style.opacity) * (1 - progress)).setStroke()
            path.stroke()
        }
    }
}
