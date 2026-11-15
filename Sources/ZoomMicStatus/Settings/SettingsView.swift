import SwiftUI
import ZoomMicStatusCore

/// The settings window: a sidebar of pages, each opening on an illustration
/// of the user's own desktop that follows the settings as they change.
struct SettingsView: View {
    @ObservedObject var model: SettingsViewModel
    let strings: Strings
    @State private var page: SettingsPage? = .general

    // A hand-built sidebar rather than NavigationSplitView, which ignored
    // the requested column width and truncated the page titles.
    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: Spacing.settingsSidebarWidth)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(SidebarMaterial())
            Divider()
            Group {
                switch page ?? .general {
                case .general: GeneralPage(model: model, strings: strings)
                case .badge: BadgePage(model: model, strings: strings)
                case .border: BorderPage(model: model, strings: strings)
                case .menuBarDock: MenuBarDockPage(model: model, strings: strings)
                case .about: AboutPage(model: model, strings: strings)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .frame(width: Spacing.settingsWindowWidth, height: Spacing.settingsWindowHeight)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: Spacing.settingsSidebarRowSpacing) {
            sidebarRow(.general)
            sidebarSection(strings.indicatorsSection)
            sidebarRow(.badge)
            sidebarRow(.border)
            sidebarRow(.menuBarDock)
            sidebarSection(strings.appName)
            sidebarRow(.about)
        }
        .padding(.horizontal, Spacing.settingsSidebarPadding)
        // Clears the traffic lights, which sit over the sidebar.
        .padding(.top, Spacing.settingsSidebarTopInset)
    }

    private func sidebarSection(_ title: String) -> some View {
        Text(title)
            .font(Typography.settingsSidebarSection)
            .foregroundStyle(.secondary)
            .padding(.horizontal, Spacing.settingsSidebarRowPadding)
            .padding(.top, Spacing.settingsSidebarSectionGap)
    }

    private func sidebarRow(_ candidate: SettingsPage) -> some View {
        Button {
            page = candidate
        } label: {
            HStack(spacing: Spacing.settingsSidebarIconGap) {
                PageIcon(page: candidate, size: Spacing.settingsSidebarIconSize,
                         cornerRadius: Spacing.settingsSidebarIconCornerRadius, font: Typography.settingsSidebarIcon)
                Text(candidate.title(strings))
                Spacer(minLength: 0)
            }
            .padding(Spacing.settingsSidebarRowPadding)
            .background(
                RoundedRectangle(cornerRadius: Spacing.settingsSidebarSelectionCornerRadius, style: .continuous)
                    .fill(candidate == page ? Color(nsColor: Colors.sidebarSelection) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct GeneralPage: View {
    @ObservedObject var model: SettingsViewModel
    let strings: Strings

    var body: some View {
        SettingsPageLayout(page: .general, strings: strings, intro: strings.generalIntro) {
            MiniDesktop(model: model, strings: strings, showsBadge: model.isEnabled(.badge),
                        showsBorder: model.isEnabled(.border), showsMenuBar: model.isEnabled(.menuBar),
                        showsDock: model.isEnabled(.dock), fadesDisabled: false)

            SettingsCard(title: strings.previewSection,
                         footer: model.canSimulate ? strings.previewIdleHint : strings.previewMeetingHint) {
                SettingsRow(label: strings.simulate) {
                    Picker(strings.simulate, selection: shownState) {
                        ForEach([MicState.muted, .live], id: \.self) { state in
                            Text(strings.stateName(state)).tag(state)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: Spacing.settingsSliderWidth)
                    .disabled(!model.canSimulate)
                }
            }

            HStack(alignment: .top, spacing: Spacing.settingsCardSpacing) {
                SettingsCard(title: strings.startupSection, footer: model.errorMessage) {
                    ToggleRow(label: strings.launchAtLogin, isOn: Binding(
                        get: { model.launchesAtLogin },
                        set: { model.setLaunchesAtLogin($0) }
                    ))
                }
                SettingsCard(title: strings.permissionsSection) {
                    if model.accessibilityGranted {
                        SettingsRow(label: strings.accessibilityGranted) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(nsColor: Colors.live))
                        }
                    } else {
                        SettingsRow(label: strings.statusLine(.needsPermission)) {
                            Button(strings.grantAccess) { model.grantAccess() }
                        }
                    }
                }
            }
        }
    }

    /// During a meeting the disabled picker shows the real state, not the
    /// last simulated one.
    private var shownState: Binding<MicState> {
        Binding(get: { model.previewState }, set: { model.simulated = $0 })
    }
}

private struct BadgePage: View {
    @ObservedObject var model: SettingsViewModel
    let strings: Strings

    var body: some View {
        SettingsPageLayout(page: .badge, strings: strings, intro: strings.badgeIntro) {
            MiniDesktop(model: model, strings: strings, showsBadge: true)

            HStack(alignment: .top, spacing: Spacing.settingsCardSpacing) {
                SettingsCard(title: strings.appearance) {
                    ToggleRow(label: strings.showBadge, isOn: model.binding(for: .badge))
                    SliderRow(label: strings.badgeSize, value: $model.badgeScale,
                              range: BadgeScaleStore.range, rounding: 0.05, format: strings.percent)
                        .disabled(!model.isEnabled(.badge))
                }
                SettingsCard(title: strings.badgePosition,
                             footer: model.badgeAnchor.map(strings.badgeAnchorName) ?? strings.badgeFreePosition) {
                    AnchorGrid(anchor: $model.badgeAnchor, wallpaper: model.wallpaper,
                               aspectRatio: model.screenFrame.width / max(model.screenFrame.height, 1),
                               strings: strings)
                        .frame(maxWidth: .infinity)
                }
                .frame(width: Spacing.gridWidth + 2 * Spacing.settingsCardPadding)
                .disabled(!model.isEnabled(.badge))
            }
        }
    }
}

private struct BorderPage: View {
    @ObservedObject var model: SettingsViewModel
    let strings: Strings

    var body: some View {
        SettingsPageLayout(page: .border, strings: strings, intro: strings.borderIntro) {
            MiniDesktop(model: model, strings: strings, showsBorder: true)

            SettingsCard {
                ToggleRow(label: strings.showBorder, isOn: model.binding(for: .border))
                Group {
                    SliderRow(label: strings.borderWidth, value: $model.borderWidth,
                              range: BorderStyle.widthRange, rounding: 1, format: strings.points)
                    SliderRow(label: strings.borderOpacity, value: $model.borderOpacity,
                              range: BorderStyle.opacityRange, rounding: 0.01, format: strings.percent)
                    ToggleRow(label: strings.borderFade, isOn: $model.borderFades)
                }
                .disabled(!model.isEnabled(.border))
            }
        }
    }
}

private struct MenuBarDockPage: View {
    @ObservedObject var model: SettingsViewModel
    let strings: Strings

    var body: some View {
        SettingsPageLayout(page: .menuBarDock, strings: strings, intro: strings.menuBarDockIntro) {
            MenuBarDockIllustration(model: model, strings: strings)

            HStack(alignment: .top, spacing: Spacing.settingsCardSpacing) {
                SettingsCard(title: strings.menuBarSection) {
                    ToggleRow(label: strings.showInMenuBar, isOn: model.binding(for: .menuBar))
                        .disabled(!model.canToggle(.menuBar))
                    SettingsRow(label: strings.display) {
                        Picker(strings.display, selection: $model.menuBarStyle) {
                            ForEach(MenuBarStyle.allCases, id: \.self) { style in
                                Text(strings.menuBarStyleName(style)).tag(style)
                            }
                        }
                        .labelsHidden()
                        .fixedSize()
                    }
                    .disabled(!model.isEnabled(.menuBar))
                }
                SettingsCard(title: strings.dockSection, footer: strings.dockHint) {
                    ToggleRow(label: strings.showInDock, isOn: model.binding(for: .dock))
                        .disabled(!model.canToggle(.dock))
                }
            }

            Text(strings.waysBackHint).font(Typography.settingsHint).foregroundStyle(.secondary)
        }
    }
}

private struct AboutPage: View {
    @ObservedObject var model: SettingsViewModel
    let strings: Strings

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    var body: some View {
        SettingsPageLayout(page: .about, strings: strings, intro: nil) {
            VStack(spacing: Spacing.settingsSectionTitleGap) {
                if let icon = model.dockIcon(for: model.previewState) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: Spacing.aboutIconSize, height: Spacing.aboutIconSize)
                }
                Text(strings.appName).font(Typography.aboutTitle)
                Text(strings.version(version)).foregroundStyle(.secondary)
                Text(strings.aboutTagline).font(Typography.aboutTagline)
            }
            .frame(maxWidth: .infinity)

            SettingsCard {
                Text(strings.aboutPrivacy)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
