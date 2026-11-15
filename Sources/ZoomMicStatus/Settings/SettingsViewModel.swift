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
    /// `nil` once the user dragged the badge by hand.
    @Published var badgeAnchor: BadgeAnchor? {
        didSet {
            badgeAnchorStore.anchor = badgeAnchor
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

    /// What the illustrations need to draw a faithful miniature desktop.
    @Published private(set) var screenFrame = NSScreen.main?.frame ?? .zero
    @Published private(set) var visibleFrame = NSScreen.main?.visibleFrame ?? .zero
    @Published private(set) var badgeFrame: CGRect = .zero
    /// The user's wallpaper; the showcase renderer substitutes its own.
    @Published var wallpaper: NSImage?
    let hasNotch = (NSScreen.main?.safeAreaInsets.top ?? 0) > 0

    private let modeStore: DisplayModeStore
    private let borderStyleStore: BorderStyleStore
    private let menuBarStyleStore: MenuBarStyleStore
    private let badgeScaleStore: BadgeScaleStore
    private let badgeAnchorStore: BadgeAnchorStore
    private let loginItem: LoginItem
    private let onChange: () -> Void
    private var dockIcons: [MicState?: NSImage] = [:]

    init(
        modeStore: DisplayModeStore,
        borderStyleStore: BorderStyleStore,
        menuBarStyleStore: MenuBarStyleStore,
        badgeScaleStore: BadgeScaleStore,
        badgeAnchorStore: BadgeAnchorStore,
        loginItem: LoginItem,
        onChange: @escaping () -> Void
    ) {
        self.modeStore = modeStore
        self.borderStyleStore = borderStyleStore
        self.menuBarStyleStore = menuBarStyleStore
        self.badgeScaleStore = badgeScaleStore
        self.badgeAnchorStore = badgeAnchorStore
        self.loginItem = loginItem
        self.onChange = onChange
        modes = modeStore.modes
        let style = borderStyleStore.style
        borderWidth = style.width
        borderOpacity = style.opacity
        borderFades = style.fades
        menuBarStyle = menuBarStyleStore.style
        badgeScale = badgeScaleStore.scale
        badgeAnchor = badgeAnchorStore.anchor
        launchesAtLogin = loginItem.isEnabled
    }

    var canSimulate: Bool { SettingsPreview.canSimulate(status: status) }
    var accessibilityGranted: Bool { status != .needsPermission }
    var borderStyle: BorderStyle { BorderStyle(width: borderWidth, opacity: borderOpacity, fades: borderFades) }

    /// The state the illustrations show: the real one during a meeting,
    /// otherwise the simulated one.
    var previewState: MicState {
        SettingsPreview.displayedState(status: status, simulated: simulated) ?? simulated
    }

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

    /// Called whenever the badge window moves or resizes.
    func update(badgeFrame: CGRect, draggedByUser: Bool) {
        self.badgeFrame = badgeFrame
        if draggedByUser, badgeAnchor != nil { badgeAnchor = nil }
    }

    /// Refreshes what may have changed while the window was closed.
    func windowWillShow() {
        launchesAtLogin = loginItem.isEnabled
        if let screen = NSScreen.main {
            screenFrame = screen.frame
            visibleFrame = screen.visibleFrame
            wallpaper = Wallpaper.thumbnail(for: screen)
        }
    }

    func dockIcon(for state: MicState?) -> NSImage? {
        if let cached = dockIcons[state] { return cached }
        let icon = DockIcon.image(shown: state, needsPermission: false)
        dockIcons[state] = icon
        return icon
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

    func grantAccess() {
        AccessibilityAccess.request()
    }

    private func saveBorderStyle() {
        borderStyleStore.style = borderStyle
        onChange()
    }
}
