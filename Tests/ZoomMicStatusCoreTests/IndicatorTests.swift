import Testing
@testable import ZoomMicStatusCore

struct IndicatorTests {
    @Test func shouldShowOverlaysOnlyDuringMeeting() {
        #expect(IndicatorStatus.mic(.muted).showsOverlays)
        #expect(IndicatorStatus.mic(.live).showsOverlays)
        #expect(!IndicatorStatus.idle.showsOverlays)
        #expect(!IndicatorStatus.needsPermission.showsOverlays)
    }

    @Test func shouldUseFrenchLabelsWhenSystemIsFrench() {
        let strings = Strings(preferredLanguages: ["fr-FR", "en"])

        #expect(strings.badgeLabel(.muted) == "MICRO COUPÉ")
        #expect(strings.badgeLabel(.live) == "MICRO OUVERT")
    }

    @Test func shouldUseEnglishLabelsOtherwise() {
        let strings = Strings(preferredLanguages: ["de-DE", "fr"])

        #expect(strings.badgeLabel(.muted) == "MIC MUTED")
        #expect(strings.badgeLabel(.live) == "MIC LIVE")
    }
}
