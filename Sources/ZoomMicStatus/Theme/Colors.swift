import AppKit
import ZoomMicStatusCore

/// Visual direction: a traffic-light signal. Flat, saturated red and green
/// slabs with heavy white type, readable at a glance from across the desk.
/// Both states are equally loud: muted must not be mistaken for live, and
/// live must not be mistaken for muted.
@MainActor
enum Colors {
    static let muted = NSColor(srgbRed: 0.89, green: 0.13, blue: 0.15, alpha: 1)
    static let live = NSColor(srgbRed: 0.09, green: 0.64, blue: 0.29, alpha: 1)
    /// No meeting: the Dock icon stays neutral.
    static let idle = NSColor(srgbRed: 0.42, green: 0.44, blue: 0.48, alpha: 1)
    /// The icon's dark "screen", lit slightly from the top.
    static let dockIconTileTop = NSColor(srgbRed: 0.20, green: 0.21, blue: 0.24, alpha: 1)
    static let dockIconTileBottom = NSColor(srgbRed: 0.08, green: 0.08, blue: 0.10, alpha: 1)
    static let dockIconShadow = NSColor.black.withAlphaComponent(0.3)
    /// Settings sidebar icon tiles, each a top-to-bottom gradient.
    static let pageGeneral = (NSColor(srgbRed: 0.60, green: 0.62, blue: 0.68, alpha: 1),
                              NSColor(srgbRed: 0.40, green: 0.42, blue: 0.48, alpha: 1))
    static let pageBadge = (NSColor(srgbRed: 1.00, green: 0.36, blue: 0.40, alpha: 1), muted)
    static let pageBorder = (NSColor(srgbRed: 1.00, green: 0.62, blue: 0.25, alpha: 1),
                             NSColor(srgbRed: 0.93, green: 0.38, blue: 0.13, alpha: 1))
    static let pageMenuBarDock = (NSColor(srgbRed: 0.35, green: 0.62, blue: 1.00, alpha: 1),
                                  NSColor(srgbRed: 0.16, green: 0.40, blue: 0.93, alpha: 1))
    static let pageAbout = (NSColor(srgbRed: 1.00, green: 0.82, blue: 0.30, alpha: 1),
                            NSColor(srgbRed: 0.96, green: 0.62, blue: 0.10, alpha: 1))
    /// Backdrop of the illustrations when the wallpaper cannot be read.
    static let fallbackWallpaper = (NSColor(srgbRed: 0.33, green: 0.24, blue: 0.62, alpha: 1),
                                    NSColor(srgbRed: 0.10, green: 0.38, blue: 0.62, alpha: 1))
    static let sidebarSelection = NSColor.labelColor.withAlphaComponent(0.1)
    /// Settings cards, slightly lifted from the window background.
    static let cardFill = NSColor.labelColor.withAlphaComponent(0.05)
    static let cardStroke = NSColor.labelColor.withAlphaComponent(0.08)
    /// The miniature menu bar and Dock drawn over the wallpaper.
    static let miniMenuBar = NSColor.black.withAlphaComponent(0.25)
    static let miniDock = NSColor.white.withAlphaComponent(0.22)
    static let miniDockStroke = NSColor.white.withAlphaComponent(0.3)
    static let miniPlaceholderApp = NSColor.white.withAlphaComponent(0.55)
    static let illustrationShadow = NSColor.black.withAlphaComponent(0.25)
    /// Indicators that are switched off, still drawn in the illustrations.
    static let disabledIllustrationOpacity = 0.3
    /// Position grid dots.
    static let gridDot = NSColor.white.withAlphaComponent(0.45)
    static let gridDotSelectedRing = NSColor.white
    /// Text and icon drawn on top of a signal color.
    static let onSignal = NSColor.white

    static func signal(_ state: MicState) -> NSColor {
        switch state {
        case .muted: muted
        case .live: live
        }
    }
}
