import AppKit
import ZoomMicStatusCore

/// SF Symbols used across the indicators.
enum Symbols {
    static func mic(_ state: MicState) -> String {
        switch state {
        case .muted: "mic.slash.fill"
        case .live: "mic.fill"
        }
    }

    static let idle = "mic"
    static let needsPermission = "exclamationmark.triangle.fill"

    static func image(_ name: String, _ configuration: NSImage.SymbolConfiguration) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
    }
}
