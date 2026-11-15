import SwiftUI
import ZoomMicStatusCore

/// The pages of the settings window, each with its colored icon.
enum SettingsPage: Hashable, CaseIterable {
    case general, badge, border, menuBarDock, about

    var symbol: String {
        switch self {
        case .general: "gearshape.fill"
        case .badge: "mic.fill"
        case .border: "rectangle.dashed"
        case .menuBarDock: "menubar.dock.rectangle"
        case .about: "info.circle"
        }
    }

    @MainActor
    var tint: (NSColor, NSColor) {
        switch self {
        case .general: Colors.pageGeneral
        case .badge: Colors.pageBadge
        case .border: Colors.pageBorder
        case .menuBarDock: Colors.pageMenuBarDock
        case .about: Colors.pageAbout
        }
    }

    func title(_ strings: Strings) -> String {
        switch self {
        case .general: strings.generalPage
        case .badge: strings.badgePage
        case .border: strings.borderPage
        case .menuBarDock: strings.menuBarDockPage
        case .about: strings.aboutPage
        }
    }
}

/// The translucent sidebar background of System Settings.
struct SidebarMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

/// A white symbol on a rounded gradient tile, as in System Settings.
struct PageIcon: View {
    let page: SettingsPage
    let size: CGFloat
    let cornerRadius: CGFloat
    let font: Font

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(LinearGradient(
                colors: [Color(nsColor: page.tint.0), Color(nsColor: page.tint.1)],
                startPoint: .top, endPoint: .bottom
            ))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: page.symbol)
                    .font(font)
                    .foregroundStyle(Color(nsColor: Colors.onSignal))
            }
    }
}

/// A page: icon and title, an optional introduction, then its content.
struct SettingsPageLayout<Content: View>: View {
    let page: SettingsPage
    let strings: Strings
    let intro: String?
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.settingsSectionSpacing) {
                VStack(alignment: .leading, spacing: Spacing.settingsSectionTitleGap) {
                    HStack(spacing: Spacing.settingsHeaderSpacing) {
                        PageIcon(page: page, size: Spacing.settingsPageIconSize,
                                 cornerRadius: Spacing.settingsPageIconCornerRadius, font: Typography.settingsPageIcon)
                        Text(page.title(strings)).font(Typography.settingsPageTitle)
                    }
                    if let intro {
                        Text(intro).font(Typography.settingsIntro).foregroundStyle(.secondary)
                    }
                }
                content
            }
            .padding(Spacing.settingsPagePadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// A titled group of rows on a lifted, rounded background.
struct SettingsCard<Content: View>: View {
    var title: String?
    var footer: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.settingsSectionTitleGap) {
            if let title {
                Text(title).font(Typography.settingsSectionTitle)
            }
            VStack(spacing: 0) {
                Group(subviews: content) { rows in
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        if index > 0 { Divider() }
                        row.padding(.vertical, Spacing.settingsCardRowPadding)
                    }
                }
            }
            .padding(.horizontal, Spacing.settingsCardPadding)
            .background(
                RoundedRectangle(cornerRadius: Spacing.settingsCardCornerRadius, style: .continuous)
                    .fill(Color(nsColor: Colors.cardFill))
                    .overlay {
                        RoundedRectangle(cornerRadius: Spacing.settingsCardCornerRadius, style: .continuous)
                            .strokeBorder(Color(nsColor: Colors.cardStroke))
                    }
            )
            if let footer {
                Text(footer).font(Typography.settingsHint).foregroundStyle(.secondary)
            }
        }
    }
}

/// A row with a label on the left and its control on the right.
struct SettingsRow<Control: View>: View {
    let label: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack {
            // The label wins over flexible controls such as sliders.
            Text(label).layoutPriority(1)
            Spacer(minLength: Spacing.settingsCardPadding)
            control
        }
    }
}

struct ToggleRow: View {
    let label: String
    let isOn: Binding<Bool>

    var body: some View {
        SettingsRow(label: label) {
            Toggle("", isOn: isOn).toggleStyle(.switch).labelsHidden()
        }
    }
}

/// A continuous slider (a stepped one draws a dense row of tick marks)
/// whose value is rounded to `rounding` and shown on its right.
struct SliderRow: View {
    let label: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let rounding: Double
    let format: (Double) -> String

    var body: some View {
        SettingsRow(label: label) {
            Slider(value: Binding(
                get: { value.wrappedValue },
                set: { value.wrappedValue = ($0 / rounding).rounded() * rounding }
            ), in: range)
            .frame(minWidth: Spacing.settingsSliderMinWidth, maxWidth: Spacing.settingsSliderWidth)
            Text(format(value.wrappedValue))
                .font(Typography.settingsValue)
                .foregroundStyle(.secondary)
                .frame(width: Spacing.settingsValueWidth, alignment: .trailing)
        }
    }
}

/// Nine dots over a miniature of the screen; picking one snaps the badge
/// to that position.
struct AnchorGrid: View {
    @Binding var anchor: BadgeAnchor?
    let wallpaper: NSImage?
    let aspectRatio: CGFloat
    let strings: Strings

    var body: some View {
        IllustrationBackdrop(wallpaper: wallpaper)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .frame(width: Spacing.gridWidth)
            .overlay {
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    ForEach(0..<3, id: \.self) { row in
                        GridRow {
                            ForEach(0..<3, id: \.self) { column in
                                dot(BadgeAnchor.allCases[row * 3 + column])
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                }
                .padding(Spacing.gridInset / 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardCornerRadius, style: .continuous))
    }

    private func dot(_ candidate: BadgeAnchor) -> some View {
        let selected = candidate == anchor
        return Button {
            anchor = candidate
        } label: {
            Circle()
                .fill(selected ? Color.accentColor : Color(nsColor: Colors.gridDot))
                .overlay {
                    if selected {
                        Circle().strokeBorder(Color(nsColor: Colors.gridDotSelectedRing),
                                              lineWidth: Spacing.gridSelectedRingWidth)
                    }
                }
                .frame(width: selected ? Spacing.gridSelectedDotSize : Spacing.gridDotSize,
                       height: selected ? Spacing.gridSelectedDotSize : Spacing.gridDotSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(strings.badgeAnchorName(candidate))
        .accessibilityLabel(strings.badgeAnchorName(candidate))
    }
}
