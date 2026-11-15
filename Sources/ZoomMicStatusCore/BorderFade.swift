import Foundation

/// Opacity layout of the fading screen border.
///
/// The border is a family of nested outlines: at depth 0 the screen's square
/// edge, at depth 1 the inner edge, `width` points in with squircle corners
/// of `cornerRadius`; in between, inset and corner radius grow together.
/// A point's depth tells how far through the border it lies, so its opacity
/// can be computed per pixel. Drawing the fade as many adjacent vector bands
/// instead left visible seams along the corner diagonals.
public enum BorderFade {
    private static let bisectionSteps = 20

    /// Depth in 0...1 of a point given by its distances `x` and `y` to the
    /// two screen edges of the nearest corner; 1 means past the inner edge.
    public static func depth(x: Double, y: Double, width: Double, cornerRadius: Double) -> Double {
        func contains(atInset inset: Double) -> Bool {
            guard x >= inset, y >= inset else { return false }
            let radius = cornerRadius * inset / width
            let center = inset + radius
            guard radius > 0, x < center, y < center else { return true }
            let n = Squircle.exponent
            return pow((center - x) / radius, n) + pow((center - y) / radius, n) <= 1
        }

        if contains(atInset: width) { return 1 }
        // Outlines are nested, so "contains" flips exactly once between the
        // screen edge (inset 0) and the inner edge.
        var low = 0.0
        var high = width
        for _ in 0..<bisectionSteps {
            let mid = (low + high) / 2
            if contains(atInset: mid) { low = mid } else { high = mid }
        }
        return low / width
    }
}
