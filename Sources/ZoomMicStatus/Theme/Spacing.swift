import CoreGraphics

enum Spacing {
    static let badgeHorizontalPadding: CGFloat = 22
    static let badgeVerticalPadding: CGFloat = 12
    static let badgeIconGap: CGFloat = 10
    static let badgeCornerRadius: CGFloat = 14
    /// Gap between the badge and the screen edges it is anchored to.
    static let badgeScreenMargin: CGFloat = 12
    /// Squircle radius of the screen border's inner corners.
    static let borderInnerCornerRadius: CGFloat = 24
    /// Dock icon drawn on Apple's 1024 pt app icon grid.
    static let dockIconCanvas: CGFloat = 1024
    static let dockIconInset: CGFloat = 100
    static let dockIconCornerRadius: CGFloat = 260
    static let dockIconShadowBlur: CGFloat = 24
    static let dockIconShadowOffset: CGFloat = -10
    /// The fading frame of the icon (variant "A3" picked by the user).
    static let dockIconFrameWidth: CGFloat = 200
    static let dockIconFrameRadiusShrink: CGFloat = 0.6
    static let dockIconFrameMinRadius: CGFloat = 10
    static let dockIconFrameLineWidth: CGFloat = 1.5
    /// Settings window, sidebar and pages.
    static let settingsWindowWidth: CGFloat = 880
    static let settingsWindowHeight: CGFloat = 660
    static let settingsSidebarWidth: CGFloat = 250
    static let settingsSidebarIconGap: CGFloat = 10
    static let settingsPagePadding: CGFloat = 28
    static let settingsSectionSpacing: CGFloat = 24
    static let settingsCardSpacing: CGFloat = 16
    static let settingsCardPadding: CGFloat = 16
    static let settingsCardRowPadding: CGFloat = 11
    static let settingsCardCornerRadius: CGFloat = 12
    static let settingsSectionTitleGap: CGFloat = 8
    static let settingsPageIconSize: CGFloat = 32
    static let settingsPageIconCornerRadius: CGFloat = 8
    static let settingsSidebarIconSize: CGFloat = 24
    static let settingsSidebarIconCornerRadius: CGFloat = 6
    static let settingsSidebarRowPadding: CGFloat = 6
    static let settingsSidebarRowSpacing: CGFloat = 2
    static let settingsSidebarPadding: CGFloat = 10
    static let settingsSidebarTopInset: CGFloat = 52
    static let settingsSidebarSectionGap: CGFloat = 14
    static let settingsSidebarSelectionCornerRadius: CGFloat = 8
    static let settingsHeaderSpacing: CGFloat = 12
    /// Keeps slider values from shifting the slider as digits change.
    static let settingsValueWidth: CGFloat = 52
    static let settingsSliderWidth: CGFloat = 200
    static let settingsSliderMinWidth: CGFloat = 100
    /// Illustrations: a miniature desktop at the top of each page.
    static let illustrationCornerRadius: CGFloat = 14
    /// Keeps the settings below an illustration visible without scrolling.
    static let illustrationMaxHeight: CGFloat = 300
    static let illustrationShadowRadius: CGFloat = 10
    static let menuBarIllustrationHeight: CGFloat = 230
    static let miniMenuBarItemSpacing: CGFloat = 14
    static let miniDockPadding: CGFloat = 8
    static let miniDockIconSize: CGFloat = 46
    static let miniDockCornerRadius: CGFloat = 18
    static let miniDockBottomMargin: CGFloat = 12
    static let miniPlaceholderAppCount = 4
    /// Apple's app icon grid: the tile fills 824 of 1024 points.
    static let appIconTileFraction: CGFloat = 824 / 1024
    static let appIconCornerFraction: CGFloat = 0.225
    static let miniMenuBarHorizontalPadding: CGFloat = 14
    static let miniMenuBarMinHeight: CGFloat = 24
    static let miniStatusItemGap: CGFloat = 3
    /// Camera housing of notched MacBook displays.
    static let notchWidth: CGFloat = 190
    static let notchCornerRadius: CGFloat = 10
    static let aboutIconSize: CGFloat = 128
    /// Position grid.
    static let gridWidth: CGFloat = 220
    static let gridDotSize: CGFloat = 18
    static let gridSelectedDotSize: CGFloat = 24
    static let gridSelectedRingWidth: CGFloat = 3
    static let gridInset: CGFloat = 26
}
