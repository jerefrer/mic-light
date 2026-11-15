import Foundation

/// The ways the mic state can be shown; any combination can be enabled.
public struct DisplayModes: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// A floating badge above every window.
    public static let badge = DisplayModes(rawValue: 1 << 0)
    /// A colored frame around every screen.
    public static let border = DisplayModes(rawValue: 1 << 1)
    /// A colored icon in the menu bar.
    public static let menuBar = DisplayModes(rawValue: 1 << 2)
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
            return DisplayModes(rawValue: defaults.integer(forKey: Self.key))
        }
        set { defaults.set(newValue.rawValue, forKey: Self.key) }
    }

    public func toggle(_ mode: DisplayModes) {
        modes = modes.symmetricDifference(mode)
    }
}
