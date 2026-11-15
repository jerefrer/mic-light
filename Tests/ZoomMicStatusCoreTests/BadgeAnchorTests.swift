import CoreGraphics
import Foundation
import Testing
@testable import ZoomMicStatusCore

struct BadgePlacementTests {
    // AppKit coordinates: origin at the bottom left, y grows upward.
    let visible = CGRect(x: 0, y: 0, width: 1000, height: 600)
    let size = CGSize(width: 200, height: 50)
    let margin: CGFloat = 12

    private func origin(_ anchor: BadgeAnchor) -> CGPoint {
        BadgePlacement.origin(for: anchor, size: size, in: visible, margin: margin)
    }

    @Test func shouldTuckIntoTheTopLeftCorner() {
        #expect(origin(.topLeft) == CGPoint(x: 12, y: 538))
    }

    @Test func shouldCenterHorizontallyAtTheTop() {
        #expect(origin(.top) == CGPoint(x: 400, y: 538))
    }

    @Test func shouldCenterOnTheScreen() {
        #expect(origin(.center) == CGPoint(x: 400, y: 275))
    }

    @Test func shouldTuckIntoTheBottomRightCorner() {
        #expect(origin(.bottomRight) == CGPoint(x: 788, y: 12))
    }

    @Test func shouldListAnchorsRowByRowFromTheTop() {
        #expect(BadgeAnchor.allCases.first == .topLeft)
        #expect(BadgeAnchor.allCases.last == .bottomRight)
        #expect(BadgeAnchor.right.column == 2 && BadgeAnchor.right.row == 1)
    }
}

struct BadgeAnchorStoreTests {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "BadgeAnchorStoreTests-\(UUID().uuidString)")!
    }

    @Test func shouldDefaultToTopCenterWhenNothingSaved() {
        #expect(BadgeAnchorStore(defaults: makeDefaults()).anchor == .top)
    }

    @Test func shouldPersistAnAnchor() {
        let defaults = makeDefaults()
        BadgeAnchorStore(defaults: defaults).anchor = .bottomLeft

        #expect(BadgeAnchorStore(defaults: defaults).anchor == .bottomLeft)
    }

    @Test func shouldRememberAFreePositionAfterAManualDrag() {
        let defaults = makeDefaults()
        BadgeAnchorStore(defaults: defaults).anchor = nil

        #expect(BadgeAnchorStore(defaults: defaults).anchor == nil)
    }
}
