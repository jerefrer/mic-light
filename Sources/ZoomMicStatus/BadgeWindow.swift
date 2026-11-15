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
    private let stack: NSStackView
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

        label.textColor = Colors.onSignal
        icon.contentTintColor = Colors.onSignal

        stack = NSStackView(views: [icon, label])
        stack.orientation = .horizontal
        stack.wantsLayer = true
        panel.contentView = stack
        apply(scale: 1)

        if !panel.setFrameUsingName(Self.autosaveName) {
            placeAtDefaultPosition()
        }
        panel.setFrameAutosaveName(Self.autosaveName)
    }

    /// `scale` enlarges text, icon, padding and corners together, so the
    /// badge keeps its proportions at every size.
    func show(_ state: MicState, scale: CGFloat) {
        apply(scale: scale)
        label.stringValue = strings.badgeLabel(state)
        icon.image = Symbols.image(Symbols.mic(state), Typography.badgeIcon(scale: scale))
        panel.contentView?.layer?.backgroundColor = Colors.signal(state).cgColor
        resizeKeepingTopLeft()
        panel.orderFrontRegardless()
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
