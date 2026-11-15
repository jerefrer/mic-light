import Foundation
import Testing
@testable import ZoomMicStatusCore

struct MuteMenuTitlesTests {
    let titles = MuteMenuTitles(
        muteTitles: ["Mute audio", "Désactiver le son", "静音"],
        unmuteTitles: ["Unmute audio", "Réactiver le son", "解除静音"]
    )

    @Test func shouldReportLiveWhenMenuOffersToMute() {
        #expect(titles.state(forMenuTitle: "Mute audio") == .live)
    }

    @Test func shouldReportMutedWhenMenuOffersToUnmute() {
        #expect(titles.state(forMenuTitle: "Réactiver le son") == .muted)
    }

    @Test func shouldIgnoreCaseWhitespaceAndEllipsis() {
        #expect(titles.state(forMenuTitle: "  UNMUTE Audio… ") == .muted)
    }

    @Test func shouldNotConfuseTitleThatContainsAnother() {
        // "解除静音" (unmute) contains "静音" (mute): matching must be exact.
        #expect(titles.state(forMenuTitle: "解除静音") == .muted)
    }

    @Test func shouldReturnNilForUnrelatedTitle() {
        #expect(titles.state(forMenuTitle: "Start video") == nil)
    }

    @Test func shouldLoadTitlesFromEveryLocalizationInZoomResources() throws {
        let resources = try makeResources([
            "en": ["Mute Audio": "Mute audio", "Unmute Audio": "Unmute audio"],
            "fr": ["Mute Audio": "Désactiver le son", "Unmute Audio": "Réactiver le son", "Other": "x"],
        ])

        let loaded = MuteMenuTitles.load(fromZoomResources: resources)

        #expect(loaded.state(forMenuTitle: "Désactiver le son") == .live)
        #expect(loaded.state(forMenuTitle: "Unmute audio") == .muted)
    }

    @Test func shouldFallBackToBuiltInTitlesWhenZoomIsMissing() {
        let loaded = MuteMenuTitles.load(fromZoomResources: URL(fileURLWithPath: "/nonexistent"))

        #expect(loaded.state(forMenuTitle: "Unmute audio") == .muted)
        #expect(loaded.state(forMenuTitle: "Réactiver le son") == .muted)
    }

    private func makeResources(_ tables: [String: [String: String]]) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("zoom-resources-\(UUID().uuidString)")
        for (language, table) in tables {
            let dir = root.appendingPathComponent("\(language).lproj")
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try PropertyListSerialization.data(fromPropertyList: table, format: .binary, options: 0)
            try data.write(to: dir.appendingPathComponent("Localizable.strings"))
        }
        return root
    }
}
