import AppKit
import SwiftUI

@MainActor
enum Typography {
    /// Badge text and icon at the default size; scaled by the badge size setting.
    static let badgePointSize: CGFloat = 22
    static func badge(scale: CGFloat) -> NSFont { .systemFont(ofSize: badgePointSize * scale, weight: .heavy) }
    static func badgeIcon(scale: CGFloat) -> NSImage.SymbolConfiguration {
        NSImage.SymbolConfiguration(pointSize: badgePointSize * scale, weight: .heavy)
    }
    static let menuBar = NSFont.systemFont(ofSize: 12, weight: .heavy)
    static let menuBarIcon = NSImage.SymbolConfiguration(pointSize: 14, weight: .bold)
    static let dockIconSymbol = NSImage.SymbolConfiguration(pointSize: 420, weight: .bold)
    static let settingsTitle = Font.title2.weight(.semibold)
    static let settingsSubtitle = Font.callout
    static let settingsHeaderIcon = Font.system(size: 24, weight: .bold)
    static let settingsValue = Font.body.monospacedDigit()
}
