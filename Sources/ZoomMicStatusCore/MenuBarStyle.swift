import Foundation

/// How the menu bar indicator shows the mic state.
public enum MenuBarStyle: String, CaseIterable, Sendable {
    case iconOnly
    case iconAndText
}

/// Persists the menu bar style.
public final class MenuBarStyleStore {
    static let key = "menuBarStyle"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var style: MenuBarStyle {
        get { defaults.string(forKey: Self.key).flatMap(MenuBarStyle.init(rawValue:)) ?? .iconAndText }
        set { defaults.set(newValue.rawValue, forKey: Self.key) }
    }
}
