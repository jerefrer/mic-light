import SwiftUI
import ZoomMicStatusCore

/// The user's wallpaper, or a gradient when it cannot be read.
struct IllustrationBackdrop: View {
    let wallpaper: NSImage?

    var body: some View {
        if let wallpaper {
            Image(nsImage: wallpaper).resizable().scaledToFill()
        } else {
            LinearGradient(
                colors: [Color(nsColor: Colors.fallbackWallpaper.0), Color(nsColor: Colors.fallbackWallpaper.1)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}

/// The user's main screen in miniature, with the chosen indicators drawn at
/// their real position and size, scaled down.
struct MiniDesktop: View {
    @ObservedObject var model: SettingsViewModel
    let strings: Strings
    var showsBadge = false
    var showsBorder = false
    var showsMenuBar = false
    var showsDock = false
    /// Indicators that are switched off are still drawn, faded.
    var fadesDisabled = true
    /// Keeps the settings below visible; the showcase renderer lifts it.
    var maxHeight = Spacing.illustrationMaxHeight

    private var aspectRatio: CGFloat {
        model.screenFrame.height > 0 ? model.screenFrame.width / model.screenFrame.height : 16 / 10
    }

    var body: some View {
        GeometryReader { geometry in
            let factor = geometry.size.width / max(model.screenFrame.width, 1)
            ZStack(alignment: .topLeading) {
                IllustrationBackdrop(wallpaper: model.wallpaper)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                if showsBorder {
                    BorderPreview(model: model, factor: factor)
                        .opacity(visibility(.border))
                }
                MiniMenuBar(model: model, strings: strings, factor: factor, showsStatusItem: showsMenuBar)
                if showsBadge {
                    BadgeReplica(state: model.previewState, label: strings.badgeLabel(model.previewState),
                                 scale: model.badgeScale * factor)
                        .offset(
                            x: (model.badgeFrame.minX - model.screenFrame.minX) * factor,
                            y: (model.screenFrame.maxY - model.badgeFrame.maxY) * factor
                        )
                        .opacity(visibility(.badge))
                }
                if showsDock {
                    MiniDock(model: model, factor: factor)
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
                        .padding(.bottom, Spacing.miniDockBottomMargin * factor)
                }
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.illustrationCornerRadius, style: .continuous))
        .shadow(color: Color(nsColor: Colors.illustrationShadow), radius: Spacing.illustrationShadowRadius)
        .frame(maxHeight: maxHeight)
        .frame(maxWidth: .infinity)
    }

    private func visibility(_ mode: DisplayModes) -> Double {
        model.isEnabled(mode) || !fadesDisabled ? 1 : Colors.disabledIllustrationOpacity
    }
}

/// A close-up of the top and bottom of the screen: the menu bar and the
/// Dock at their real size.
struct MenuBarDockIllustration: View {
    @ObservedObject var model: SettingsViewModel
    let strings: Strings

    var body: some View {
        ZStack {
            IllustrationBackdrop(wallpaper: model.wallpaper)
                .frame(height: Spacing.menuBarIllustrationHeight)
                .clipped()
            VStack(spacing: 0) {
                MiniMenuBar(model: model, strings: strings, factor: 1, showsStatusItem: true)
                    .opacity(model.isEnabled(.menuBar) ? 1 : Colors.disabledIllustrationOpacity)
                Spacer()
                MiniDock(model: model, factor: 1)
                    .opacity(model.isEnabled(.dock) ? 1 : Colors.disabledIllustrationOpacity)
                    .padding(.bottom, Spacing.miniDockBottomMargin)
            }
        }
        .frame(height: Spacing.menuBarIllustrationHeight)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.illustrationCornerRadius, style: .continuous))
        .shadow(color: Color(nsColor: Colors.illustrationShadow), radius: Spacing.illustrationShadowRadius)
    }
}

/// The badge as drawn by `BadgeWindow`, in SwiftUI.
struct BadgeReplica: View {
    let state: MicState
    let label: String
    let scale: CGFloat

    var body: some View {
        HStack(spacing: Spacing.badgeIconGap * scale) {
            Image(systemName: Symbols.mic(state))
            Text(label)
        }
        .font(Typography.badgeReplica(scale: scale))
        .foregroundStyle(Color(nsColor: Colors.onSignal))
        .padding(.horizontal, Spacing.badgeHorizontalPadding * scale)
        .padding(.vertical, Spacing.badgeVerticalPadding * scale)
        .background(
            RoundedRectangle(cornerRadius: Spacing.badgeCornerRadius * scale)
                .fill(Color(nsColor: Colors.signal(state)))
        )
        .fixedSize()
    }
}

/// A miniature menu bar, including the notch on notched displays.
struct MiniMenuBar: View {
    @ObservedObject var model: SettingsViewModel
    let strings: Strings
    let factor: CGFloat
    let showsStatusItem: Bool

    var body: some View {
        let height = max(model.screenFrame.maxY - model.visibleFrame.maxY, Spacing.miniMenuBarMinHeight) * factor
        HStack(spacing: Spacing.miniMenuBarItemSpacing * factor) {
            Image(systemName: "apple.logo")
            Text(strings.appName).font(Typography.miniMenuBarApp(factor))
            Spacer()
            if showsStatusItem { statusItem }
            Image(systemName: "wifi")
            Image(systemName: "battery.75percent")
            Text(Date.now, format: .dateTime.hour().minute())
        }
        .font(Typography.miniMenuBarItem(factor))
        .padding(.horizontal, Spacing.miniMenuBarHorizontalPadding * factor)
        .foregroundStyle(Color(nsColor: Colors.onSignal))
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .background(Color(nsColor: Colors.miniMenuBar))
        .overlay {
            if model.hasNotch {
                UnevenRoundedRectangle(
                    bottomLeadingRadius: Spacing.notchCornerRadius * factor,
                    bottomTrailingRadius: Spacing.notchCornerRadius * factor
                )
                .fill(.black)
                .frame(width: Spacing.notchWidth * factor, height: height)
            }
        }
    }

    private var statusItem: some View {
        let state = model.previewState
        let color = Color(nsColor: Colors.signal(state))
        return HStack(spacing: Spacing.miniStatusItemGap * factor) {
            Image(systemName: Symbols.mic(state))
            if model.menuBarStyle == .iconAndText {
                Text(strings.menuBarLabel(state)).font(Typography.miniMenuBarStatus(factor))
            }
        }
        .foregroundStyle(color)
    }
}

/// A miniature Dock: a few placeholder apps and, if enabled, ours.
struct MiniDock: View {
    @ObservedObject var model: SettingsViewModel
    let factor: CGFloat

    var body: some View {
        let size = Spacing.miniDockIconSize * factor
        HStack(spacing: Spacing.miniDockPadding * factor) {
            ForEach(0..<Spacing.miniPlaceholderAppCount, id: \.self) { _ in
                RoundedRectangle(cornerRadius: size * Spacing.appIconCornerFraction, style: .continuous)
                    .fill(Color(nsColor: Colors.miniPlaceholderApp))
                    .frame(width: size, height: size)
            }
            if let icon = model.dockIcon(for: model.previewState) {
                // The icon image has Apple's transparent margin around its tile.
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: size / Spacing.appIconTileFraction, height: size / Spacing.appIconTileFraction)
                    .frame(width: size, height: size)
            }
        }
        .padding(Spacing.miniDockPadding * factor)
        .background(
            RoundedRectangle(cornerRadius: Spacing.miniDockCornerRadius * factor, style: .continuous)
                .fill(Color(nsColor: Colors.miniDock))
                .overlay {
                    RoundedRectangle(cornerRadius: Spacing.miniDockCornerRadius * factor, style: .continuous)
                        .strokeBorder(Color(nsColor: Colors.miniDockStroke))
                }
        )
    }
}

/// The real border view, scaled down to the illustration.
struct BorderPreview: NSViewRepresentable {
    @ObservedObject var model: SettingsViewModel
    let factor: CGFloat

    func makeNSView(context: Context) -> BorderView {
        BorderView(cornerRadii: .followingDisplay(
            hasNotch: model.hasNotch, radius: Spacing.borderInnerCornerRadius * factor
        ))
    }

    func updateNSView(_ view: BorderView, context: Context) {
        let style = model.borderStyle
        view.style = BorderStyle(width: style.width * factor, opacity: style.opacity, fades: style.fades)
        view.color = Colors.signal(model.previewState)
    }
}
