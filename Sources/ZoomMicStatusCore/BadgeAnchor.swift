import CoreGraphics
import Foundation

/// One of the nine positions of the badge position grid.
public enum BadgeAnchor: String, CaseIterable, Sendable {
    case topLeft, top, topRight
    case left, center, right
    case bottomLeft, bottom, bottomRight

    /// 0 = left, 2 = right.
    public var column: Int { Self.allCases.firstIndex(of: self)! % 3 }
    /// 0 = top, 2 = bottom.
    public var row: Int { Self.allCases.firstIndex(of: self)! / 3 }
}

public enum BadgePlacement {
    /// Bottom-left origin (AppKit coordinates) of a badge of `size` placed at
    /// `anchor` inside `visible`, keeping `margin` from the edges it touches.
    public static func origin(for anchor: BadgeAnchor, size: CGSize, in visible: CGRect, margin: CGFloat) -> CGPoint {
        let x: CGFloat = switch anchor.column {
        case 0: visible.minX + margin
        case 1: visible.midX - size.width / 2
        default: visible.maxX - margin - size.width
        }
        let y: CGFloat = switch anchor.row {
        case 0: visible.maxY - margin - size.height
        case 1: visible.midY - size.height / 2
        default: visible.minY + margin
        }
        return CGPoint(x: x, y: y)
    }
}

/// Persists the badge's grid position; `nil` once the user dragged it
/// somewhere else by hand.
public final class BadgeAnchorStore {
    static let key = "badgeAnchor"
    /// A dragged badge keeps its own position, saved with its window frame.
    static let freePosition = "free"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var anchor: BadgeAnchor? {
        get {
            guard let saved = defaults.string(forKey: Self.key) else { return .top }
            return BadgeAnchor(rawValue: saved)
        }
        set { defaults.set(newValue?.rawValue ?? Self.freePosition, forKey: Self.key) }
    }
}
