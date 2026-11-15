import CoreGraphics
import Foundation

/// Corner radii of an outline; displays differ only between top and bottom.
public struct CornerRadii: Equatable, Sendable {
    public let top: CGFloat
    public let bottom: CGFloat

    public init(top: CGFloat, bottom: CGFloat) {
        self.top = top
        self.bottom = bottom
    }

    /// Follows the display's own shape: notched MacBook displays have
    /// rounded top corners and square bottom ones; other displays (iMac,
    /// external monitors, older MacBooks) are rectangular.
    public static func followingDisplay(hasNotch: Bool, radius: CGFloat) -> CornerRadii {
        CornerRadii(top: hasNotch ? radius : 0, bottom: 0)
    }

    public func scaled(by factor: CGFloat) -> CornerRadii {
        CornerRadii(top: top * factor, bottom: bottom * factor)
    }
}

/// A rectangle with superellipse ("squircle") corners, as a polygon.
///
/// Each corner follows |x|ⁿ + |y|ⁿ = rⁿ, which eases into the straight
/// edges more gradually than a circular arc, close to Apple's continuous
/// corners.
public enum Squircle {
    /// Superellipse exponent: 2 is a circle; higher values hug the corner.
    static let exponent: Double = 5
    static let samplesPerCorner = 24

    public static func outline(of rect: CGRect, cornerRadius: CGFloat) -> [CGPoint] {
        outline(of: rect, cornerRadii: CornerRadii(top: cornerRadius, bottom: cornerRadius))
    }

    /// The outline, counterclockwise from the bottom-left corner (AppKit's
    /// y-up coordinates). A corner with a zero radius is a single point.
    public static func outline(of rect: CGRect, cornerRadii: CornerRadii) -> [CGPoint] {
        let limit = min(rect.width, rect.height) / 2
        let bottom = max(0, min(cornerRadii.bottom, limit))
        let top = max(0, min(cornerRadii.top, limit))

        // (corner, radius, x sign, y sign, sweep from the incoming edge to the outgoing one)
        let corners: [(CGPoint, CGFloat, CGFloat, CGFloat, reversed: Bool)] = [
            (CGPoint(x: rect.minX, y: rect.minY), bottom, -1, -1, false),
            (CGPoint(x: rect.maxX, y: rect.minY), bottom, 1, -1, true),
            (CGPoint(x: rect.maxX, y: rect.maxY), top, 1, 1, false),
            (CGPoint(x: rect.minX, y: rect.maxY), top, -1, 1, true),
        ]
        return corners.flatMap { corner, radius, signX, signY, reversed -> [CGPoint] in
            guard radius > 0 else { return [corner] }
            let center = CGPoint(x: corner.x - signX * radius, y: corner.y - signY * radius)
            return (0...samplesPerCorner).map { step in
                let progress = Double(reversed ? samplesPerCorner - step : step) / Double(samplesPerCorner)
                let angle = progress * .pi / 2
                return CGPoint(
                    x: center.x + signX * radius * CGFloat(pow(cos(angle), 2 / exponent)),
                    y: center.y + signY * radius * CGFloat(pow(sin(angle), 2 / exponent))
                )
            }
        }
    }
}
