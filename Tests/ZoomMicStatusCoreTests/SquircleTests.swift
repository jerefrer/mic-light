import CoreGraphics
import Testing
@testable import ZoomMicStatusCore

struct SquircleTests {
    let rect = CGRect(x: 10, y: 20, width: 200, height: 100)

    @Test func shouldBePlainRectangleWhenRadiusIsZero() {
        let points = Squircle.outline(of: rect, cornerRadius: 0)

        #expect(points == [
            CGPoint(x: 10, y: 20), CGPoint(x: 210, y: 20),
            CGPoint(x: 210, y: 120), CGPoint(x: 10, y: 120),
        ])
    }

    @Test func shouldStayInsideTheRectAndTouchEveryEdge() {
        let points = Squircle.outline(of: rect, cornerRadius: 30)

        #expect(points.allSatisfy { rect.insetBy(dx: -1e-9, dy: -1e-9).contains($0) })
        #expect(abs(points.map(\.x).min()! - rect.minX) < 1e-9)
        #expect(abs(points.map(\.x).max()! - rect.maxX) < 1e-9)
        #expect(abs(points.map(\.y).min()! - rect.minY) < 1e-9)
        #expect(abs(points.map(\.y).max()! - rect.maxY) < 1e-9)
    }

    @Test func shouldLeaveTheRectCornerItselfUncovered() {
        let points = Squircle.outline(of: rect, cornerRadius: 30)

        #expect(!points.contains(CGPoint(x: rect.minX, y: rect.minY)))
    }

    @Test func shouldBulgeFurtherThanACircularCorner() {
        // Squircle corners hug the rectangle more than a circle of the same
        // radius: the midpoint of the curve lies outside the circular arc.
        let radius: CGFloat = 30
        let points = Squircle.outline(of: rect, cornerRadius: radius)
        let center = CGPoint(x: rect.maxX - radius, y: rect.maxY - radius)

        let farthest = points
            .filter { $0.x > center.x && $0.y > center.y }
            .map { hypot($0.x - center.x, $0.y - center.y) }
            .max()!

        #expect(farthest > radius * 1.1)
    }

    @Test func shouldClampTheRadiusToHalfTheShortSide() {
        let points = Squircle.outline(of: rect, cornerRadius: 500)

        #expect(points.allSatisfy { rect.insetBy(dx: -1e-9, dy: -1e-9).contains($0) })
    }
}
