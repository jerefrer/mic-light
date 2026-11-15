import Foundation

/// The ways the mic state can be shown; any combination can be enabled.
public struct DisplayModes: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// A floating badge above every window.
    public static let badge = DisplayModes(rawValue: 1 << 0)
    /// A colored frame around every screen.
    public static let border = DisplayModes(rawValue: 1 << 1)
    /// An icon in the menu bar, colored by the mic state.
    public static let menuBar = DisplayModes(rawValue: 1 << 2)
    /// The app's Dock icon, colored by the mic state.
    public static let dock = DisplayModes(rawValue: 1 << 3)

    /// The indicators that are also the way back into the app: at least
    /// one must stay on, or the settings would become unreachable.
    public static let waysBack: DisplayModes = [.menuBar, .dock]
}

/// Persists the selected display modes.
public final class DisplayModeStore {
    static let key = "displayModes"
    static let defaultModes: DisplayModes = [.badge, .menuBar]

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var modes: DisplayModes {
        get {
            guard defaults.object(forKey: Self.key) != nil else { return Self.defaultModes }
            var saved = DisplayModes(rawValue: defaults.integer(forKey: Self.key))
            if saved.isDisjoint(with: DisplayModes.waysBack) { saved.insert(.menuBar) }
            return saved
        }
        set { defaults.set(newValue.rawValue, forKey: Self.key) }
    }

    /// False only for the last way back into the app.
    public func canToggle(_ mode: DisplayModes) -> Bool {
        !modes.symmetricDifference(mode).isDisjoint(with: DisplayModes.waysBack)
    }

    public func toggle(_ mode: DisplayModes) {
        guard canToggle(mode) else { return }
        modes = modes.symmetricDifference(mode)
    }
}
