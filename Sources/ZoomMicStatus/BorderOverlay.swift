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
        // Only notched displays report a top safe-area inset.
        let view = BorderView(cornerRadii: .followingDisplay(
            hasNotch: screen.safeAreaInsets.top > 0, radius: Spacing.borderInnerCornerRadius
        ))
        view.style = style
        window.contentView = view
        window.setFrame(screen.frame, display: false)
        return window
    }
}

/// Also embedded, scaled down, in the settings illustrations.
final class BorderView: NSView {
    var color: NSColor = .clear {
        didSet { needsDisplay = true }
    }

    var style = BorderStyle.standard {
        didSet { needsDisplay = true }
    }

    /// The inner edge's corners follow the display's own shape.
    private let cornerRadii: CornerRadii
    private var cachedCorners: [CornerKey: CGImage] = [:]

    init(cornerRadii: CornerRadii) {
        self.cornerRadii = cornerRadii
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

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

        // Straight sides are plain linear gradients; each corner, where the
        // inner edge may curve, is a per-pixel image mirrored into place.
        let scale = window?.backingScaleFactor ?? 2
        let cornerPixels = Int(((width + max(cornerRadii.top, cornerRadii.bottom)) * scale).rounded(.up))
        let cornerSide = CGFloat(cornerPixels) / scale
        guard let context = NSGraphicsContext.current?.cgContext,
              let gradient = NSGradient(starting: color.withAlphaComponent(opacity), ending: color.withAlphaComponent(0)),
              let bottomCorner = cornerImage(radius: cornerRadii.bottom, pixels: cornerPixels, scale: scale),
              let topCorner = cornerImage(radius: cornerRadii.top, pixels: cornerPixels, scale: scale)
        else { return }

        let b = bounds
        let along = b.width - 2 * cornerSide
        let across = b.height - 2 * cornerSide
        gradient.draw(in: NSRect(x: b.minX + cornerSide, y: b.minY, width: along, height: width), angle: 90)
        gradient.draw(in: NSRect(x: b.minX + cornerSide, y: b.maxY - width, width: along, height: width), angle: 270)
        gradient.draw(in: NSRect(x: b.minX, y: b.minY + cornerSide, width: width, height: across), angle: 0)
        gradient.draw(in: NSRect(x: b.maxX - width, y: b.minY + cornerSide, width: width, height: across), angle: 180)

        context.interpolationQuality = .none
        let mirrors: [(CGImage, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (bottomCorner, b.minX, b.minY, 1, 1), (bottomCorner, b.maxX, b.minY, -1, 1),
            (topCorner, b.minX, b.maxY, 1, -1), (topCorner, b.maxX, b.maxY, -1, -1),
        ]
        for (corner, x, y, flipX, flipY) in mirrors {
            context.saveGState()
            context.translateBy(x: x, y: y)
            context.scaleBy(x: flipX, y: flipY)
            context.draw(corner, in: CGRect(x: 0, y: 0, width: cornerSide, height: cornerSide))
            context.restoreGState()
        }
    }

    /// A bottom-left corner, one opacity per pixel from `BorderFade`.
    private func cornerImage(radius: CGFloat, pixels: Int, scale: CGFloat) -> CGImage? {
        let key = CornerKey(style: style, color: color, radius: radius, pixels: pixels, scale: scale)
        if let cached = cachedCorners[key] { return cached }

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
                    x: x, y: y, width: style.width, cornerRadius: Double(radius)
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
        // Only the current style matters: drop corners of earlier ones.
        cachedCorners = cachedCorners.filter { $0.key.style == style && $0.key.color == color }
        cachedCorners[key] = image
        return image
    }

    /// Square at the screen edge, growing to the full corner radii at the
    /// border's inner edge.
    private func outline(inset: CGFloat, width: CGFloat) -> NSBezierPath {
        let points = Squircle.outline(
            of: bounds.insetBy(dx: inset, dy: inset), cornerRadii: cornerRadii.scaled(by: inset / width)
        )
        let path = NSBezierPath()
        path.move(to: points[0])
        points.dropFirst().forEach(path.line(to:))
        path.close()
        return path
    }
}

private struct CornerKey: Hashable {
    let style: BorderStyle
    let color: NSColor
    let radius: CGFloat
    let pixels: Int
    let scale: CGFloat
}
