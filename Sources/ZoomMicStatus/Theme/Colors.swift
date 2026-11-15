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
    /// Lightens the top of the Dock icon, like the light falling on Apple's icons.
    static let dockIconHighlight = NSColor.white
    static let dockIconHighlightFraction: CGFloat = 0.2
    static let dockIconShadow = NSColor.black.withAlphaComponent(0.3)
    /// Text and icon drawn on top of a signal color.
    static let onSignal = NSColor.white

    static func signal(_ state: MicState) -> NSColor {
        switch state {
        case .muted: muted
        case .live: live
        }
    }
}
