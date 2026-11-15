import AppKit
import ZoomMicStatusCore

/// The floating badge: a draggable red or green slab above every window,
/// including full-screen Zoom.
@MainActor
final class BadgeWindow {
    private static let autosaveName = "Badge"

    private let panel: NSPanel
    private let icon = NSImageView()
    private let label = NSTextField(labelWithString: "")
    private let strings: Strings

    init(strings: Strings) {
        self.strings = strings
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

        label.font = Typography.badge
        label.textColor = Colors.onSignal
        icon.contentTintColor = Colors.onSignal

        let stack = NSStackView(views: [icon, label])
        stack.orientation = .horizontal
        stack.spacing = Spacing.badgeIconGap
        stack.edgeInsets = NSEdgeInsets(
            top: Spacing.badgeVerticalPadding, left: Spacing.badgeHorizontalPadding,
            bottom: Spacing.badgeVerticalPadding, right: Spacing.badgeHorizontalPadding
        )
        stack.wantsLayer = true
        stack.layer?.cornerRadius = Spacing.badgeCornerRadius
        panel.contentView = stack

        if !panel.setFrameUsingName(Self.autosaveName) {
            placeAtDefaultPosition()
        }
        panel.setFrameAutosaveName(Self.autosaveName)
    }

    func show(_ state: MicState) {
        label.stringValue = strings.badgeLabel(state)
        icon.image = Symbols.image(Symbols.mic(state), Typography.badgeIcon)
        panel.contentView?.layer?.backgroundColor = Colors.signal(state).cgColor
        resizeKeepingTopLeft()
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func resetPosition() {
        placeAtDefaultPosition()
    }

    /// Centered just below the menu bar of the main screen.
    private func placeAtDefaultPosition() {
        guard let screen = NSScreen.main else { return }
        let size = panel.contentView?.fittingSize ?? .zero
        let visible = screen.visibleFrame
        panel.setFrameTopLeftPoint(NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.maxY - Spacing.badgeTopMargin
        ))
    }

    /// The label width changes between states; keep the corner the user
    /// dragged the badge to where it is.
    private func resizeKeepingTopLeft() {
        guard let size = panel.contentView?.fittingSize else { return }
        let topLeft = NSPoint(x: panel.frame.minX, y: panel.frame.maxY)
        panel.setContentSize(size)
        panel.setFrameTopLeftPoint(topLeft)
    }
}
