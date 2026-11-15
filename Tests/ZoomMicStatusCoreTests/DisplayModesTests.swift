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

    @Test func shouldPersistSelectionWithOnlyAWayBack() {
        let defaults = makeDefaults()
        DisplayModeStore(defaults: defaults).modes = [.dock]

        #expect(DisplayModeStore(defaults: defaults).modes == [.dock])
    }

    @Test func shouldToggleOneModeWithoutTouchingOthers() {
        let store = DisplayModeStore(defaults: makeDefaults())

        store.toggle(.border)

        #expect(store.modes == [.badge, .border, .menuBar])
    }
}

struct AccessPointTests {
    private func makeStore(_ modes: DisplayModes) -> DisplayModeStore {
        let store = DisplayModeStore(defaults: UserDefaults(suiteName: "AccessPointTests-\(UUID().uuidString)")!)
        store.modes = modes
        return store
    }

    @Test func shouldRefuseToTurnOffTheLastWayBackIntoTheApp() {
        let store = makeStore([.badge, .menuBar])

        store.toggle(.menuBar)

        #expect(store.modes == [.badge, .menuBar])
        #expect(!store.canToggle(.menuBar))
    }

    @Test func shouldAllowTurningOffTheMenuBarWhenTheDockIsOn() {
        let store = makeStore([.menuBar, .dock])

        store.toggle(.menuBar)

        #expect(store.modes == [.dock])
    }

    @Test func shouldAllowBothMenuBarAndDock() {
        let store = makeStore([.menuBar])

        store.toggle(.dock)

        #expect(store.modes == [.menuBar, .dock])
    }

    @Test func shouldRestoreTheMenuBarWhenNoWayBackWasSaved() {
        let defaults = UserDefaults(suiteName: "AccessPointTests-\(UUID().uuidString)")!
        defaults.set(DisplayModes.badge.rawValue, forKey: DisplayModeStore.key)

        #expect(DisplayModeStore(defaults: defaults).modes == [.badge, .menuBar])
    }

    @Test func shouldAlwaysAllowTogglingIndicatorsThatAreNotWaysBack() {
        #expect(makeStore([.menuBar]).canToggle(.badge))
    }
}
