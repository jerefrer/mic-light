import AppKit
import SwiftUI

@MainActor
enum Typography {
    static let badge = NSFont.systemFont(ofSize: 22, weight: .heavy)
    static let badgeIcon = NSImage.SymbolConfiguration(pointSize: 22, weight: .heavy)
    static let menuBar = NSFont.systemFont(ofSize: 12, weight: .heavy)
    static let menuBarIcon = NSImage.SymbolConfiguration(pointSize: 14, weight: .bold)
    static let settingsTitle = Font.title2.weight(.semibold)
    static let settingsSubtitle = Font.callout
    static let settingsHeaderIcon = Font.system(size: 24, weight: .bold)
    static let settingsValue = Font.body.monospacedDigit()
}
