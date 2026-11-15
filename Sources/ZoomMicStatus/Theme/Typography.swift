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
    /// The badge replica in the settings illustrations.
    static func badgeReplica(scale: CGFloat) -> Font { .system(size: badgePointSize * scale, weight: .heavy) }
    static let menuBar = NSFont.systemFont(ofSize: 12, weight: .heavy)
    static let menuBarIcon = NSImage.SymbolConfiguration(pointSize: 14, weight: .bold)
    static let dockIconSymbol = NSImage.SymbolConfiguration(pointSize: 420, weight: .bold)
    static let settingsPageTitle = Font.title2.weight(.bold)
    static let settingsPageIcon = Font.system(size: 16, weight: .semibold)
    static let settingsSidebarIcon = Font.system(size: 12, weight: .semibold)
    static let settingsSidebarSection = Font.subheadline.weight(.semibold)
    static let settingsSectionTitle = Font.headline
    static let settingsIntro = Font.callout
    static let settingsHint = Font.callout
    static let settingsValue = Font.body.monospacedDigit()
    static let aboutTitle = Font.largeTitle.weight(.bold)
    static let aboutTagline = Font.title3
    /// Labels in the miniature menu bar, at `factor` of their real size.
    static func miniMenuBarApp(_ factor: CGFloat) -> Font { .system(size: 13 * factor, weight: .bold) }
    static func miniMenuBarItem(_ factor: CGFloat) -> Font { .system(size: 13 * factor, weight: .semibold) }
    static func miniMenuBarStatus(_ factor: CGFloat) -> Font { .system(size: 12 * factor, weight: .heavy) }
}
