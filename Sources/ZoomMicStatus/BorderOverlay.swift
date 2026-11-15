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

    private var cachedCorner: (key: CornerKey, image: CGImage)?

    override func draw(_ dirtyRect: NSRect) {
        let width = CGFloat(style.width)
        let opacity = CGFloat(style.opacity)

        guard style.fades else {
            let path = outline(inset: 0, width: width)
            path.append(outline(inset: width, width: width))
            path.windingRule = .evenOdd
            color.withAlphaComponent(opacity).setFill()
            path.fill()
            return
        }

        // Straight sides are plain linear gradients; the four corners, where
        // the inner edge curves, are one per-pixel image mirrored into place.
        let scale = window?.backingScaleFactor ?? 2
        let cornerPixels = Int(((width + Spacing.borderInnerCornerRadius) * scale).rounded(.up))
        let cornerSide = CGFloat(cornerPixels) / scale
        guard let context = NSGraphicsContext.current?.cgContext,
              let gradient = NSGradient(starting: color.withAlphaComponent(opacity), ending: color.withAlphaComponent(0)),
              let corner = cornerImage(pixels: cornerPixels, scale: scale)
        else { return }

        let b = bounds
        let along = b.width - 2 * cornerSide
        let across = b.height - 2 * cornerSide
        gradient.draw(in: NSRect(x: b.minX + cornerSide, y: b.minY, width: along, height: width), angle: 90)
        gradient.draw(in: NSRect(x: b.minX + cornerSide, y: b.maxY - width, width: along, height: width), angle: 270)
        gradient.draw(in: NSRect(x: b.minX, y: b.minY + cornerSide, width: width, height: across), angle: 0)
        gradient.draw(in: NSRect(x: b.maxX - width, y: b.minY + cornerSide, width: width, height: across), angle: 180)

        context.interpolationQuality = .none
        let mirrors: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (b.minX, b.minY, 1, 1), (b.maxX, b.minY, -1, 1), (b.minX, b.maxY, 1, -1), (b.maxX, b.maxY, -1, -1),
        ]
        for (x, y, flipX, flipY) in mirrors {
            context.saveGState()
            context.translateBy(x: x, y: y)
            context.scaleBy(x: flipX, y: flipY)
            context.draw(corner, in: CGRect(x: 0, y: 0, width: cornerSide, height: cornerSide))
            context.restoreGState()
        }
    }

    /// The bottom-left corner, one opacity per pixel from `BorderFade`.
    private func cornerImage(pixels: Int, scale: CGFloat) -> CGImage? {
        let key = CornerKey(style: style, color: color, pixels: pixels, scale: scale)
        if let cached = cachedCorner, cached.key == key { return cached.image }

        guard let rgb = color.usingColorSpace(.sRGB), let space = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }
        var bytes = [UInt8](repeating: 0, count: pixels * pixels * 4)
        for row in 0..<pixels {
            // Image rows run top-down; the corner's y axis runs bottom-up.
            let y = (Double(pixels - row) - 0.5) / scale
            for column in 0..<pixels {
                let x = (Double(column) + 0.5) / scale
                let depth = BorderFade.depth(
                    x: x, y: y, width: style.width, cornerRadius: Double(Spacing.borderInnerCornerRadius)
                )
                let alpha = style.opacity * (1 - depth)
                let offset = (row * pixels + column) * 4
                bytes[offset] = UInt8((Double(rgb.redComponent) * alpha * 255).rounded())
                bytes[offset + 1] = UInt8((Double(rgb.greenComponent) * alpha * 255).rounded())
                bytes[offset + 2] = UInt8((Double(rgb.blueComponent) * alpha * 255).rounded())
                bytes[offset + 3] = UInt8((alpha * 255).rounded())
            }
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(
                  width: pixels, height: pixels, bitsPerComponent: 8, bitsPerPixel: 32,
                  bytesPerRow: pixels * 4, space: space,
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                  provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
              )
        else { return nil }
        cachedCorner = (key, image)
        return image
    }

    /// Square at the screen edge, growing to the full corner radius at the
    /// border's inner edge.
    private func outline(inset: CGFloat, width: CGFloat) -> NSBezierPath {
        let radius = Spacing.borderInnerCornerRadius * inset / width
        let points = Squircle.outline(of: bounds.insetBy(dx: inset, dy: inset), cornerRadius: radius)
        let path = NSBezierPath()
        path.move(to: points[0])
        points.dropFirst().forEach(path.line(to:))
        path.close()
        return path
    }
}

private struct CornerKey: Equatable {
    let style: BorderStyle
    let color: NSColor
    let pixels: Int
    let scale: CGFloat
}
