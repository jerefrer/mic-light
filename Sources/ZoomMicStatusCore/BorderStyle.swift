import Foundation

/// How the screen border is drawn.
public struct BorderStyle: Hashable, Sendable {
    public static let widthRange: ClosedRange<Double> = 2...80
    public static let opacityRange: ClosedRange<Double> = 0.1...1
    public static let standard = BorderStyle(width: 10, opacity: 0.75, fades: true)

    /// Thickness in points.
    public let width: Double
    /// Opacity at the screen edge.
    public let opacity: Double
    /// When on, the color fades from `opacity` at the screen edge to fully
    /// transparent at the inner edge.
    public let fades: Bool

    public init(width: Double, opacity: Double, fades: Bool) {
        self.width = width.clamped(to: Self.widthRange)
        self.opacity = opacity.clamped(to: Self.opacityRange)
        self.fades = fades
    }
}

/// Persists the border style.
public final class BorderStyleStore {
    static let key = "borderStyle"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var style: BorderStyle {
        get {
            guard let saved = defaults.dictionary(forKey: Self.key) else { return .standard }
            let standard = BorderStyle.standard
            return BorderStyle(
                width: saved["width"] as? Double ?? standard.width,
                opacity: saved["opacity"] as? Double ?? standard.opacity,
                fades: saved["fades"] as? Bool ?? standard.fades
            )
        }
        set {
            defaults.set(
                ["width": newValue.width, "opacity": newValue.opacity, "fades": newValue.fades],
                forKey: Self.key
            )
        }
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
