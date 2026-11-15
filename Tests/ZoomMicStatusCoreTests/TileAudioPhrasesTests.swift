import Foundation
import Testing
@testable import ZoomMicStatusCore

struct TileAudioPhrasesTests {
    let phrases = TileAudioPhrases(
        mutedPhrases: ["Computer audio muted", "Audio muted by host"],
        unmutedPhrases: ["Computer audio unmuted"]
    )

    @Test func shouldReadNameAndMutedState() {
        let tile = phrases.parse("Songtsen | Luciano, Computer audio muted, Video off")

        #expect(tile == TileReading(name: "Songtsen | Luciano", audio: .muted))
    }

    @Test func shouldReadLiveState() {
        #expect(phrases.parse("Jérémy | FR, Computer audio unmuted, Video off")?.audio == .live)
    }

    @Test func shouldKeepCommasThatArePartOfTheName() {
        #expect(phrases.parse("Frère, Jérémy, Computer audio muted")?.name == "Frère, Jérémy")
    }

    @Test func shouldTreatMutedByHostAsMuted() {
        #expect(phrases.parse("Lekshe, Audio muted by host")?.audio == .muted)
    }

    @Test func shouldIgnoreDescriptionsWithoutAudioState() {
        #expect(phrases.parse("Songtsen | Luciano, 10:59") == nil)
    }

    @Test func shouldLoadPhrasesWhateverTheNumericKeySuffix() throws {
        let resources = try ZoomResourcesFixture.make([
            "fr": [
                "LN_Plist_Accessibility_VoIP_Muted_20044": "Ordinateur mis en sourdine",
                "LN_Plist_Accessibility_VoIP_Unmuted_99999": "Son de l'ordinateur rétabli",
            ],
        ])

        let loaded = TileAudioPhrases.load(fromZoomResources: resources)

        #expect(loaded.parse("Jérémy, Ordinateur mis en sourdine")?.audio == .muted)
        #expect(loaded.parse("Jérémy, Son de l'ordinateur rétabli")?.audio == .live)
    }
}

enum ZoomResourcesFixture {
    static func make(_ tables: [String: [String: String]]) throws -> URL {
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
