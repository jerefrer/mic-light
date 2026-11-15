import Foundation

/// Persists the floating badge's size, as a factor of its default size.
public final class BadgeScaleStore {
    static let key = "badgeScale"
    public static let range: ClosedRange<Double> = 0.5...3

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var scale: Double {
        get {
            guard defaults.object(forKey: Self.key) != nil else { return 1 }
            return defaults.double(forKey: Self.key).clamped(to: Self.range)
        }
        set { defaults.set(newValue.clamped(to: Self.range), forKey: Self.key) }
    }
}
