import SwiftUI
import ZoomMicStatusCore

/// The settings window, in the grouped style of System Settings.
struct SettingsView: View {
    @ObservedObject var model: SettingsViewModel
    let strings: Strings

    var body: some View {
        Form {
            Section { header }

            Section {
                Picker(strings.simulate, selection: shownState) {
                    ForEach([MicState.muted, .live], id: \.self) { state in
                        Text(strings.stateName(state)).tag(state)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!model.canSimulate)
            } header: {
                Text(strings.previewSection)
            } footer: {
                hint(model.canSimulate ? strings.previewIdleHint : strings.previewMeetingHint)
            }

            Section {
                Toggle(strings.badgeMode, isOn: model.binding(for: .badge))
                Group {
                    valueSlider(strings.badgeSize, value: $model.badgeScale,
                                range: BadgeScaleStore.range, rounding: 0.05, format: strings.percent)
                    LabeledContent(strings.badgePosition) {
                        Button(strings.reset) { model.resetBadgePosition() }
                    }
                }
                .disabled(!model.isEnabled(.badge))
                Toggle(strings.menuBarMode, isOn: model.binding(for: .menuBar))
                    .disabled(!model.canToggle(.menuBar))
                Picker(strings.menuBarStyle, selection: $model.menuBarStyle) {
                    ForEach(MenuBarStyle.allCases, id: \.self) { style in
                        Text(strings.menuBarStyleName(style)).tag(style)
                    }
                }
                .disabled(!model.isEnabled(.menuBar))
                Toggle(strings.dockMode, isOn: model.binding(for: .dock))
                    .disabled(!model.canToggle(.dock))
                Toggle(strings.borderMode, isOn: model.binding(for: .border))
            } header: {
                Text(strings.indicatorsSection)
            } footer: {
                hint(strings.waysBackHint)
            }

            Section(strings.borderAppearanceSection) {
                valueSlider(strings.borderWidth, value: $model.borderWidth,
                            range: BorderStyle.widthRange, rounding: 1, format: strings.points)
                valueSlider(strings.borderOpacity, value: $model.borderOpacity,
                            range: BorderStyle.opacityRange, rounding: 0.01, format: strings.percent)
                Toggle(strings.borderFade, isOn: $model.borderFades)
            }
            .disabled(!model.isEnabled(.border))

            Section {
                Toggle(strings.launchAtLogin, isOn: Binding(
                    get: { model.launchesAtLogin },
                    set: { model.setLaunchesAtLogin($0) }
                ))
                if model.accessibilityGranted {
                    LabeledContent(strings.accessibilityGranted) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(nsColor: Colors.live))
                    }
                } else {
                    LabeledContent(strings.statusLine(.needsPermission)) {
                        Button(strings.grantAccess) { model.grantAccess() }
                    }
                }
            } header: {
                Text(strings.generalSection)
            } footer: {
                if let error = model.errorMessage { hint(error).foregroundStyle(Color(nsColor: Colors.muted)) }
            }
        }
        .formStyle(.grouped)
        .frame(width: Spacing.settingsWidth)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// The app's identity and the state the indicators currently show.
    private var header: some View {
        let shown = SettingsPreview.displayedState(status: model.status, simulated: model.simulated)
        return HStack(spacing: Spacing.settingsHeaderSpacing) {
            RoundedRectangle(cornerRadius: Spacing.settingsHeaderIconCornerRadius, style: .continuous)
                .fill(shown.map { Color(nsColor: Colors.signal($0)) } ?? Color.secondary)
                .frame(width: Spacing.settingsHeaderIconSize, height: Spacing.settingsHeaderIconSize)
                .overlay {
                    Image(systemName: shown.map(Symbols.mic) ?? Symbols.idle)
                        .font(Typography.settingsHeaderIcon)
                        .foregroundStyle(Color(nsColor: Colors.onSignal))
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(strings.appName).font(Typography.settingsTitle)
                Text(strings.statusLine(model.status))
                    .font(Typography.settingsSubtitle)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// During a meeting the disabled picker shows the real state, not the
    /// last simulated one.
    private var shownState: Binding<MicState> {
        Binding(
            get: { SettingsPreview.displayedState(status: model.status, simulated: model.simulated) ?? model.simulated },
            set: { model.simulated = $0 }
        )
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.settingsHintInset)
    }

    /// A continuous slider (a stepped one draws a dense row of tick marks)
    /// whose value is rounded to `rounding`.
    private func valueSlider(
        _ title: String, value: Binding<Double>, range: ClosedRange<Double>, rounding: Double,
        format: @escaping (Double) -> String
    ) -> some View {
        let rounded = Binding(
            get: { value.wrappedValue },
            set: { value.wrappedValue = ($0 / rounding).rounded() * rounding }
        )
        return LabeledContent(title) {
            HStack {
                Slider(value: rounded, in: range)
                Text(format(value.wrappedValue))
                    .font(Typography.settingsValue)
                    .foregroundStyle(.secondary)
                    .frame(width: Spacing.settingsValueWidth, alignment: .trailing)
            }
        }
    }
}
