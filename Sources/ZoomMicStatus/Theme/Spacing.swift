import CoreGraphics

enum Spacing {
    static let badgeHorizontalPadding: CGFloat = 22
    static let badgeVerticalPadding: CGFloat = 12
    static let badgeIconGap: CGFloat = 10
    static let badgeCornerRadius: CGFloat = 14
    /// Gap between the menu bar and the badge's default position.
    static let badgeTopMargin: CGFloat = 12
    /// Squircle radius of the screen border's inner corners.
    static let borderInnerCornerRadius: CGFloat = 24
    static let settingsWidth: CGFloat = 480
    static let settingsHeaderIconSize: CGFloat = 52
    static let settingsHeaderIconCornerRadius: CGFloat = 12
    static let settingsHeaderSpacing: CGFloat = 14
    /// Keeps slider values from shifting the slider as digits change.
    static let settingsValueWidth: CGFloat = 52
    /// Aligns section footers with the section titles above them.
    static let settingsHintInset: CGFloat = 10
}
