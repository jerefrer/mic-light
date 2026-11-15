import Testing
@testable import ZoomMicStatusCore

struct PreviewTests {
    @Test func shouldShowNothingOutsideMeetingsWithoutPreview() {
        #expect(SettingsPreview.displayedState(status: .idle, simulated: nil) == nil)
    }

    @Test func shouldShowTheSimulatedStateOutsideMeetings() {
        #expect(SettingsPreview.displayedState(status: .idle, simulated: .live) == .live)
        #expect(SettingsPreview.displayedState(status: .needsPermission, simulated: .muted) == .muted)
    }

    @Test func shouldAlwaysShowTheRealStateDuringAMeeting() {
        // A simulation must never misreport the real microphone.
        #expect(SettingsPreview.displayedState(status: .mic(.muted), simulated: .live) == .muted)
    }

    @Test func shouldAllowSimulationOnlyOutsideMeetings() {
        #expect(SettingsPreview.canSimulate(status: .idle))
        #expect(!SettingsPreview.canSimulate(status: .mic(.live)))
    }
}
