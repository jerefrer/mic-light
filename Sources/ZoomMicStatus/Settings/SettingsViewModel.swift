import SwiftUI
import ZoomMicStatusCore

/// State behind the settings window. Every change is saved and applied to
/// the on-screen indicators right away, so the window is its own preview.
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var modes: DisplayModes
    @Published var borderWidth: Double { didSet { saveBorderStyle() } }
    @Published var borderOpacity: Double { didSet { saveBorderStyle() } }
    @Published var borderFades: Bool { didSet { saveBorderStyle() } }
    @Published var badgeScale: Double {
        didSet {
            badgeScaleStore.scale = badgeScale
            onChange()
        }
    }
    @Published var menuBarStyle: MenuBarStyle {
        didSet {
            menuBarStyleStore.style = menuBarStyle
            onChange()
        }
    }
    /// The state shown outside meetings while the window is open.
    @Published var simulated: MicState = .muted { didSet { onChange() } }
    @Published private(set) var status: IndicatorStatus = .idle
    @Published private(set) var launchesAtLogin: Bool
    @Published private(set) var errorMessage: String?

    private let modeStore: DisplayModeStore
    private let borderStyleStore: BorderStyleStore
    private let menuBarStyleStore: MenuBarStyleStore
    private let badgeScaleStore: BadgeScaleStore
    private let loginItem: LoginItem
    private let onChange: () -> Void
    private let onResetBadgePosition: () -> Void

    init(
        modeStore: DisplayModeStore,
        borderStyleStore: BorderStyleStore,
        menuBarStyleStore: MenuBarStyleStore,
        badgeScaleStore: BadgeScaleStore,
        loginItem: LoginItem,
        onChange: @escaping () -> Void,
        onResetBadgePosition: @escaping () -> Void
    ) {
        self.modeStore = modeStore
        self.borderStyleStore = borderStyleStore
        self.menuBarStyleStore = menuBarStyleStore
        self.badgeScaleStore = badgeScaleStore
        self.loginItem = loginItem
        self.onChange = onChange
        self.onResetBadgePosition = onResetBadgePosition
        modes = modeStore.modes
        let style = borderStyleStore.style
        borderWidth = style.width
        borderOpacity = style.opacity
        borderFades = style.fades
        menuBarStyle = menuBarStyleStore.style
        badgeScale = badgeScaleStore.scale
        launchesAtLogin = loginItem.isEnabled
    }

    var canSimulate: Bool { SettingsPreview.canSimulate(status: status) }
    var accessibilityGranted: Bool { status != .needsPermission }

    func isEnabled(_ mode: DisplayModes) -> Bool { modes.contains(mode) }

    /// False for the last way back into the app (menu bar or Dock icon).
    func canToggle(_ mode: DisplayModes) -> Bool {
        modeStore.canToggle(mode)
    }

    func binding(for mode: DisplayModes) -> Binding<Bool> {
        Binding(
            get: { [weak self] in self?.modes.contains(mode) ?? false },
            set: { [weak self] enabled in
                guard let self, enabled != self.modes.contains(mode) else { return }
                self.toggle(mode)
            }
        )
    }

    /// Also used by the menu bar menu, so both stay in sync.
    func toggle(_ mode: DisplayModes) {
        modeStore.toggle(mode)
        modes = modeStore.modes
        onChange()
    }

    func update(status: IndicatorStatus) {
        self.status = status
    }

    func setLaunchesAtLogin(_ enabled: Bool) {
        do {
            try loginItem.setEnabled(enabled)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        launchesAtLogin = loginItem.isEnabled
    }

    /// The login item can be changed elsewhere (System Settings).
    func refreshLaunchesAtLogin() {
        launchesAtLogin = loginItem.isEnabled
    }

    func resetBadgePosition() {
        onResetBadgePosition()
    }

    func grantAccess() {
        AccessibilityAccess.request()
    }

    private func saveBorderStyle() {
        borderStyleStore.style = BorderStyle(width: borderWidth, opacity: borderOpacity, fades: borderFades)
        onChange()
    }
}
