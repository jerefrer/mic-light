import Testing
@testable import ZoomMicStatusCore

struct BorderFadeTests {
    let width = 10.0
    let radius = 24.0

    private func depth(_ x: Double, _ y: Double) -> Double {
        BorderFade.depth(x: x, y: y, width: width, cornerRadius: radius)
    }

    @Test func shouldBeZeroAtTheScreenEdge() {
        #expect(abs(depth(0, 200)) < 0.01)
    }

    @Test func shouldGrowLinearlyAwayFromAStraightEdge() {
        #expect(abs(depth(200, 5) - 0.5) < 0.01)
    }

    @Test func shouldBeOnePastTheInnerEdge() {
        #expect(depth(200, 15) == 1)
        #expect(depth(100, 100) == 1)
    }

    @Test func shouldIncreaseSteadilyAlongTheCornerDiagonal() {
        let samples = stride(from: 0.5, through: 20, by: 0.5).map { depth($0, $0) }

        #expect(zip(samples, samples.dropFirst()).allSatisfy { $0 <= $1 })
    }

    @Test func shouldReachTheInnerEdgeOnTheSquircleNotTheSquareCorner() {
        // (11, 11) is past the inner edge of a square-cornered border, but
        // still inside the band once the inner corner is rounded.
        #expect(depth(11, 11) < 1)
    }

    @Test func shouldMatchTheStraightEdgeFarFromTheCorner() {
        #expect(abs(depth(width + radius, 3) - 0.3) < 0.01)
    }
}
