import Foundation
import Testing
@testable import ZoomMicStatusCore

struct BorderStyleTests {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "BorderStyleTests-\(UUID().uuidString)")!
    }

    @Test func shouldDefaultToSolidTenPointBorderWhenNothingSaved() {
        let store = BorderStyleStore(defaults: makeDefaults())

        #expect(store.style == BorderStyle(width: 10, opacity: 1, fades: false))
    }

    @Test func shouldPersistStyle() {
        let defaults = makeDefaults()
        let style = BorderStyle(width: 32, opacity: 0.6, fades: true)

        BorderStyleStore(defaults: defaults).style = style

        #expect(BorderStyleStore(defaults: defaults).style == style)
    }

    @Test func shouldClampValuesOutsideAllowedRanges() {
        let style = BorderStyle(width: 500, opacity: -1, fades: false)

        #expect(style.width == BorderStyle.widthRange.upperBound)
        #expect(style.opacity == BorderStyle.opacityRange.lowerBound)
    }

    @Test func shouldClampValuesReadFromStorage() {
        let defaults = makeDefaults()
        defaults.set(["width": 0.0, "opacity": 7.0, "fades": true], forKey: BorderStyleStore.key)

        let style = BorderStyleStore(defaults: defaults).style

        #expect(style == BorderStyle(width: BorderStyle.widthRange.lowerBound, opacity: 1, fades: true))
    }
}
