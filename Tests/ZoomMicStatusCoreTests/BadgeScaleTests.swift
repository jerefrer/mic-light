import Foundation
import Testing
@testable import ZoomMicStatusCore

struct BadgeScaleTests {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "BadgeScaleTests-\(UUID().uuidString)")!
    }

    @Test func shouldDefaultToActualSizeWhenNothingSaved() {
        #expect(BadgeScaleStore(defaults: makeDefaults()).scale == 1)
    }

    @Test func shouldPersistScale() {
        let defaults = makeDefaults()
        BadgeScaleStore(defaults: defaults).scale = 2.5

        #expect(BadgeScaleStore(defaults: defaults).scale == 2.5)
    }

    @Test func shouldClampScaleToAllowedRange() {
        let store = BadgeScaleStore(defaults: makeDefaults())

        store.scale = 10
        #expect(store.scale == BadgeScaleStore.range.upperBound)

        store.scale = 0
        #expect(store.scale == BadgeScaleStore.range.lowerBound)
    }
}
