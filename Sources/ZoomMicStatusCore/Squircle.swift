import CoreGraphics
import Foundation

/// A rectangle with superellipse ("squircle") corners, as a polygon.
///
/// Each corner follows |x|ⁿ + |y|ⁿ = rⁿ, which eases into the straight
/// edges more gradually than a circular arc, close to Apple's continuous
/// corners.
public enum Squircle {
    /// Superellipse exponent: 2 is a circle; higher values hug the corner.
    static let exponent: Double = 5
    static let samplesPerCorner = 24

    /// The outline, counterclockwise from the left end of the bottom-left
    /// corner (AppKit's y-up coordinates).
    public static func outline(of rect: CGRect, cornerRadius: CGFloat) -> [CGPoint] {
        let radius = min(cornerRadius, rect.width / 2, rect.height / 2)
        guard radius > 0 else {
            return [
                CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY),
            ]
        }

        // (corner center, x sign, y sign, sweep from the incoming edge to the outgoing one)
        let corners: [(CGPoint, CGFloat, CGFloat, reversed: Bool)] = [
            (CGPoint(x: rect.minX + radius, y: rect.minY + radius), -1, -1, false),
            (CGPoint(x: rect.maxX - radius, y: rect.minY + radius), 1, -1, true),
            (CGPoint(x: rect.maxX - radius, y: rect.maxY - radius), 1, 1, false),
            (CGPoint(x: rect.minX + radius, y: rect.maxY - radius), -1, 1, true),
        ]
        return corners.flatMap { center, signX, signY, reversed in
            (0...samplesPerCorner).map { step in
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
