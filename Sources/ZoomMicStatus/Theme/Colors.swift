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
    /// Text and icon drawn on top of a signal color.
    static let onSignal = NSColor.white

    static func signal(_ state: MicState) -> NSColor {
        switch state {
        case .muted: muted
        case .live: live
        }
    }
}
