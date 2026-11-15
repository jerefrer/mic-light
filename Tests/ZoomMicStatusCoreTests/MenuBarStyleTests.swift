import Foundation
import Testing
@testable import ZoomMicStatusCore

struct MenuBarStyleTests {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "MenuBarStyleTests-\(UUID().uuidString)")!
    }

    @Test func shouldDefaultToIconAndTextWhenNothingSaved() {
        #expect(MenuBarStyleStore(defaults: makeDefaults()).style == .iconAndText)
    }

    @Test func shouldPersistIconOnly() {
        let defaults = makeDefaults()
        MenuBarStyleStore(defaults: defaults).style = .iconOnly

        #expect(MenuBarStyleStore(defaults: defaults).style == .iconOnly)
    }

    @Test func shouldFallBackToDefaultForUnknownSavedValue() {
        let defaults = makeDefaults()
        defaults.set("sparkles", forKey: MenuBarStyleStore.key)

        #expect(MenuBarStyleStore(defaults: defaults).style == .iconAndText)
    }
}
