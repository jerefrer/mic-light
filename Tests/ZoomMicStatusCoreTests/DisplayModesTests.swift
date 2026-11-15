import Foundation
import Testing
@testable import ZoomMicStatusCore

struct DisplayModesTests {
    private func makeDefaults() -> UserDefaults {
        let name = "DisplayModesTests-\(UUID().uuidString)"
        return UserDefaults(suiteName: name)!
    }

    @Test func shouldDefaultToBadgeAndMenuBarWhenNothingSaved() {
        let store = DisplayModeStore(defaults: makeDefaults())

        #expect(store.modes == [.badge, .menuBar])
    }

    @Test func shouldPersistAnyCombination() {
        let defaults = makeDefaults()
        DisplayModeStore(defaults: defaults).modes = [.border, .menuBar]

        #expect(DisplayModeStore(defaults: defaults).modes == [.border, .menuBar])
    }

    @Test func shouldPersistEmptySelection() {
        let defaults = makeDefaults()
        DisplayModeStore(defaults: defaults).modes = []

        #expect(DisplayModeStore(defaults: defaults).modes.isEmpty)
    }

    @Test func shouldToggleOneModeWithoutTouchingOthers() {
        let store = DisplayModeStore(defaults: makeDefaults())

        store.toggle(.border)

        #expect(store.modes == [.badge, .border, .menuBar])
    }
}
