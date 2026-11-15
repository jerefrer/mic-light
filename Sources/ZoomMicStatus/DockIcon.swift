import AppKit
import ZoomMicStatusCore

/// The app icon and Dock icon: a dark screen framed by the app's own fading
/// border, in the state's color, around a white microphone. Drawn at runtime
/// since the Dock icon follows the mic state; the app icon is the muted one.
@MainActor
enum DockIcon {
    static func image(shown: MicState?, needsPermission: Bool) -> NSImage? {
        let side = Int(Spacing.dockIconCanvas)
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0
        ) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

        let canvas = NSRect(x: 0, y: 0, width: side, height: side)
        let body = canvas.insetBy(dx: Spacing.dockIconInset, dy: Spacing.dockIconInset)
        let tile = path(Squircle.outline(of: body, cornerRadius: Spacing.dockIconCornerRadius))

        let shadow = NSShadow()
        shadow.shadowColor = Colors.dockIconShadow
        shadow.shadowBlurRadius = Spacing.dockIconShadowBlur
        shadow.shadowOffset = NSSize(width: 0, height: Spacing.dockIconShadowOffset)
        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        Colors.dockIconTileBottom.setFill()
        tile.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSGraphicsContext.saveGraphicsState()
        tile.addClip()
        NSGradient(starting: Colors.dockIconTileTop, ending: Colors.dockIconTileBottom)?.draw(in: tile, angle: -90)
        // The frame fades inward like the screen border: one thin outline per
        // step, each a little smaller and fainter.
        let frameColor = shown.map(Colors.signal) ?? Colors.idle
        var inset: CGFloat = 0
        while inset < Spacing.dockIconFrameWidth {
            let fade = 1 - inset / Spacing.dockIconFrameWidth
            let radius = max(Spacing.dockIconCornerRadius - inset * Spacing.dockIconFrameRadiusShrink,
                             Spacing.dockIconFrameMinRadius)
            let ring = path(Squircle.outline(of: body.insetBy(dx: inset, dy: inset), cornerRadius: radius))
            ring.lineWidth = Spacing.dockIconFrameLineWidth
            frameColor.withAlphaComponent(fade * fade).setStroke()
            ring.stroke()
            inset += 1
        }
        NSGraphicsContext.restoreGraphicsState()

        let name = needsPermission ? Symbols.needsPermission : Symbols.mic(shown ?? .live)
        let config = Typography.dockIconSymbol.applying(.init(paletteColors: [Colors.onSignal]))
        if let symbol = Symbols.image(name, config) {
            let size = symbol.size
            symbol.draw(in: NSRect(
                x: body.midX - size.width / 2, y: body.midY - size.height / 2,
                width: size.width, height: size.height
            ))
        }

        let image = NSImage(size: canvas.size)
        image.addRepresentation(bitmap)
        return image
    }

    private static func path(_ points: [CGPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: points[0])
        points.dropFirst().forEach(path.line(to:))
        path.close()
        return path
    }
}

/// Shows or hides the Dock icon, which also decides whether the app is a
/// regular app (Dock icon, app menu) or a menu bar utility.
@MainActor
final class DockController {
    private let onPolicyChanged: () -> Void
    private var enabled = false
    private var drawn: (shown: MicState?, needsPermission: Bool)?

    init(onPolicyChanged: @escaping () -> Void) {
        self.onPolicyChanged = onPolicyChanged
    }

    func show(enabled: Bool, shown: MicState?, needsPermission: Bool) {
        if enabled != self.enabled {
            self.enabled = enabled
            drawn = nil
            NSApp.setActivationPolicy(enabled ? .regular : .accessory)
            onPolicyChanged()
        }
        guard enabled else { return }
        if let drawn, drawn.shown == shown, drawn.needsPermission == needsPermission { return }
        drawn = (shown, needsPermission)
        NSApp.applicationIconImage = DockIcon.image(shown: shown, needsPermission: needsPermission)
    }
}
