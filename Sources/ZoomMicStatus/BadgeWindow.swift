import AppKit
import ZoomMicStatusCore

/// The floating badge: a draggable red or green slab above every window,
/// including full-screen Zoom. It sits at one of the nine grid anchors, or
/// wherever the user dragged it.
@MainActor
final class BadgeWindow {
    private static let autosaveName = "Badge"

    private let panel: NSPanel
    private let icon = NSImageView()
    private let label = NSTextField(labelWithString: "")
    private let stack: NSStackView
    private let strings: Strings
    private var moveObserver: NSObjectProtocol?
    /// Our own moves must not be mistaken for a drag by the user.
    private var placing = false

    /// `nil` keeps the badge where the user dragged it.
    var anchor: BadgeAnchor? {
        didSet { if anchor != oldValue { placeAtAnchor() } }
    }

    /// Called when the user drags the badge, and whenever its frame changes.
    var onFrameChange: ((_ frame: NSRect, _ draggedByUser: Bool) -> Void)?

    var frame: NSRect { panel.frame }

    init(strings: Strings, anchor: BadgeAnchor?) {
        self.strings = strings
        self.anchor = anchor
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true

        label.textColor = Colors.onSignal
        icon.contentTintColor = Colors.onSignal

        stack = NSStackView(views: [icon, label])
        stack.orientation = .horizontal
        stack.wantsLayer = true
        panel.contentView = stack
        apply(scale: 1)

        panel.setFrameUsingName(Self.autosaveName)
        panel.setFrameAutosaveName(Self.autosaveName)
        placeAtAnchor()

        moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification, object: panel, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.panelMoved() }
        }
    }

    /// `scale` enlarges text, icon, padding and corners together, so the
    /// badge keeps its proportions at every size.
    func show(_ state: MicState, scale: CGFloat) {
        apply(scale: scale)
        label.stringValue = strings.badgeLabel(state)
        icon.image = Symbols.image(Symbols.mic(state), Typography.badgeIcon(scale: scale))
        panel.contentView?.layer?.backgroundColor = Colors.signal(state).cgColor
        resize()
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func apply(scale: CGFloat) {
        label.font = Typography.badge(scale: scale)
        stack.spacing = Spacing.badgeIconGap * scale
        stack.edgeInsets = NSEdgeInsets(
            top: Spacing.badgeVerticalPadding * scale, left: Spacing.badgeHorizontalPadding * scale,
            bottom: Spacing.badgeVerticalPadding * scale, right: Spacing.badgeHorizontalPadding * scale
        )
        stack.layer?.cornerRadius = Spacing.badgeCornerRadius * scale
    }

    /// The size changes with the state's label and the size setting. An
    /// anchored badge stays aligned to its anchor (a right-anchored badge
    /// grows leftward); a dragged one keeps its top-left corner.
    private func resize() {
        guard let size = panel.contentView?.fittingSize, size != panel.frame.size else { return }
        let topLeft = NSPoint(x: panel.frame.minX, y: panel.frame.maxY)
        place {
            panel.setContentSize(size)
            panel.setFrameTopLeftPoint(topLeft)
        }
        placeAtAnchor()
    }

    private func placeAtAnchor() {
        guard let anchor, let screen = panel.screen ?? NSScreen.main else { return }
        let size = panel.contentView?.fittingSize ?? panel.frame.size
        let origin = BadgePlacement.origin(
            for: anchor, size: size, in: screen.visibleFrame, margin: Spacing.badgeScreenMargin
        )
        place { panel.setFrameOrigin(origin) }
    }

    private func place(_ move: () -> Void) {
        placing = true
        move()
        placing = false
        onFrameChange?(panel.frame, false)
    }

    private func panelMoved() {
        guard !placing else { return }
        onFrameChange?(panel.frame, true)
    }
}
