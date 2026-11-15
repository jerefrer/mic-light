import AppKit
import SwiftUI
import ZoomMicStatusCore

/// Renders the images of the README and the website with the app's own
/// views, over a generated backdrop: the user's wallpaper is never published.
/// Each image is a real window captured by `screencapture`, so they appear on
/// screen for a moment while rendering.
@MainActor
enum Showcase {
    private static let desktopWidth: CGFloat = 1280
    private static let backdropSize = NSSize(width: 2880, height: 1864)

    static func render(into folder: URL) {
        NSApplication.shared.setActivationPolicy(.accessory)
        let strings = Strings(preferredLanguages: ["en"])
        let suite = UserDefaults(suiteName: "zoom-mic-status-showcase")!
        suite.removePersistentDomain(forName: "zoom-mic-status-showcase")
        let modes = DisplayModeStore(defaults: suite)
        modes.modes = [.badge, .border, .menuBar, .dock]
        // Thicker than the default so the border reads at illustration scale;
        // a value the settings offer.
        BorderStyleStore(defaults: suite).style = BorderStyle(width: 24, opacity: 0.85, fades: true)
        let model = SettingsViewModel(
            modeStore: modes, borderStyleStore: BorderStyleStore(defaults: suite),
            menuBarStyleStore: MenuBarStyleStore(defaults: suite), badgeScaleStore: BadgeScaleStore(defaults: suite),
            badgeAnchorStore: BadgeAnchorStore(defaults: suite), loginItem: MainAppLoginItem(), onChange: {}
        )
        model.wallpaper = backdrop()
        placeBadge(in: model, strings: strings)
        let updater = Updater(starting: false)

        for state in [MicState.muted, .live] {
            model.simulated = state
            placeBadge(in: model, strings: strings)
            let desktop = MiniDesktop(model: model, strings: strings, showsBadge: true, showsBorder: true,
                                      showsMenuBar: true, showsDock: true, fadesDisabled: false,
                                      maxHeight: .infinity)
                // The miniature's GeometryReader proposes no height of its own.
                .frame(width: desktopWidth,
                       height: desktopWidth * model.screenFrame.height / max(model.screenFrame.width, 1))
                .padding(Spacing.illustrationShadowRadius * 2)
            capture(desktop, framed: false, to: folder.appendingPathComponent("desktop-\(state == .muted ? "muted" : "live").png"))
        }

        model.simulated = .muted
        for (name, page) in [("general", SettingsPage.general), ("badge", .badge), ("border", .border),
                             ("menubar-dock", .menuBarDock)] {
            capture(SettingsView(model: model, updater: updater, strings: strings, initialPage: page),
                    framed: true, to: folder.appendingPathComponent("settings-\(name).png"))
        }

        if let icon = DockIcon.image(shown: .muted, needsPermission: false),
           let bitmap = icon.representations.first as? NSBitmapImageRep {
            try? bitmap.representation(using: .png, properties: [:])?.write(to: folder.appendingPathComponent("icon.png"))
        }
    }

    /// The badge at its default anchor, sized like the real one.
    private static func placeBadge(in model: SettingsViewModel, strings: Strings) {
        guard let screen = NSScreen.main else { return }
        let state = model.previewState
        let size = NSHostingView(rootView: BadgeReplica(state: state, label: strings.badgeLabel(state), scale: 1)).fittingSize
        let origin = BadgePlacement.origin(for: .top, size: size, in: screen.visibleFrame, margin: Spacing.badgeScreenMargin)
        model.update(badgeFrame: CGRect(origin: origin, size: size), draggedByUser: false)
    }

    /// Soft colored glows on a deep blue ground, in the spirit of macOS wallpapers.
    private static func backdrop() -> NSImage {
        let image = NSImage(size: backdropSize)
        image.lockFocus()
        let rect = NSRect(origin: .zero, size: backdropSize)
        NSGradient(starting: NSColor(srgbRed: 0.07, green: 0.09, blue: 0.24, alpha: 1),
                   ending: NSColor(srgbRed: 0.20, green: 0.10, blue: 0.36, alpha: 1))?.draw(in: rect, angle: -60)
        let glows: [(NSColor, CGFloat, CGFloat, CGFloat)] = [
            (NSColor(srgbRed: 0.95, green: 0.35, blue: 0.55, alpha: 0.55), 0.22, 0.30, 0.55),
            (NSColor(srgbRed: 1.00, green: 0.62, blue: 0.30, alpha: 0.45), 0.80, 0.18, 0.45),
            (NSColor(srgbRed: 0.25, green: 0.70, blue: 0.95, alpha: 0.45), 0.70, 0.85, 0.50),
        ]
        for (color, x, y, radius) in glows {
            let center = NSPoint(x: rect.width * x, y: rect.height * y)
            NSGradient(starting: color, ending: color.withAlphaComponent(0))?
                .draw(fromCenter: center, radius: 0, toCenter: center, radius: rect.width * radius, options: [])
        }
        image.unlockFocus()
        return image
    }

    private static func capture(_ view: some View, framed: Bool, to url: URL) {
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        if framed {
            window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
        } else {
            window.styleMask = [.borderless]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
        }
        window.center()
        window.orderFrontRegardless()
        RunLoop.main.run(until: Date().addingTimeInterval(1))
        let screencapture = Process()
        screencapture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        // -o: no window shadow, so the framed screenshots keep a tight crop.
        screencapture.arguments = ["-x", "-o", "-l\(window.windowNumber)", url.path]
        try? screencapture.run()
        screencapture.waitUntilExit()
        window.orderOut(nil)
    }
}
