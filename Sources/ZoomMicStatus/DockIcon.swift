import AppKit
import ZoomMicStatusCore

/// The app's Dock icon: a squircle tile in the state's color with a white
/// microphone, drawn at runtime since it changes with the mic state.
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
        let points = Squircle.outline(of: body, cornerRadius: Spacing.dockIconCornerRadius)
        let tile = NSBezierPath()
        tile.move(to: points[0])
        points.dropFirst().forEach(tile.line(to:))
        tile.close()

        let color = shown.map(Colors.signal) ?? Colors.idle
        let shadow = NSShadow()
        shadow.shadowColor = Colors.dockIconShadow
        shadow.shadowBlurRadius = Spacing.dockIconShadowBlur
        shadow.shadowOffset = NSSize(width: 0, height: Spacing.dockIconShadowOffset)
        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        color.setFill()
        tile.fill()
        NSGraphicsContext.restoreGraphicsState()

        let top = color.blended(withFraction: Colors.dockIconHighlightFraction, of: Colors.dockIconHighlight) ?? color
        NSGradient(starting: top, ending: color)?.draw(in: tile, angle: -90)

        let name = needsPermission ? Symbols.needsPermission : shown.map(Symbols.mic) ?? Symbols.idle
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
