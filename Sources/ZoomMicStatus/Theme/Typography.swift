import AppKit

@MainActor
enum Typography {
    static let badge = NSFont.systemFont(ofSize: 22, weight: .heavy)
    static let badgeIcon = NSImage.SymbolConfiguration(pointSize: 22, weight: .heavy)
    static let menuBar = NSFont.systemFont(ofSize: 12, weight: .heavy)
    static let menuBarIcon = NSImage.SymbolConfiguration(pointSize: 14, weight: .bold)
}
