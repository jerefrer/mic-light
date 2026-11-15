import Testing
@testable import ZoomMicStatusCore

struct TileCrossCheckTests {
    let start = ContinuousClock.now

    @Test func shouldTrustTheTileWhenItAgreesWithTheMenu() {
        var check = TileCrossCheck()

        let result = check.resolve(menu: .muted, tile: .muted, now: start)

        #expect(result == TileCrossCheck.Result(state: .muted, tileDistrusted: false))
    }

    @Test func shouldFallBackToTheMenuWithoutATile() {
        var check = TileCrossCheck()

        #expect(check.resolve(menu: .live, tile: nil, now: start).state == .live)
    }

    @Test func shouldTrustTheTileAheadOfTheMenuDuringZoomsRefreshDelay() {
        var check = TileCrossCheck()

        _ = check.resolve(menu: .muted, tile: .live, now: start)
        let result = check.resolve(menu: .muted, tile: .live, now: start + .milliseconds(1400))

        #expect(result == TileCrossCheck.Result(state: .live, tileDistrusted: false))
    }

    @Test func shouldDistrustTheTileWhenItDisagreesForTooLong() {
        var check = TileCrossCheck()

        _ = check.resolve(menu: .muted, tile: .live, now: start)
        let result = check.resolve(menu: .muted, tile: .live, now: start + .milliseconds(1600))

        #expect(result == TileCrossCheck.Result(state: .muted, tileDistrusted: true))
    }

    @Test func shouldRestartTheDisagreementTimerOnceTheyAgreeAgain() {
        var check = TileCrossCheck()

        _ = check.resolve(menu: .muted, tile: .live, now: start)
        _ = check.resolve(menu: .live, tile: .live, now: start + .milliseconds(900))
        _ = check.resolve(menu: .live, tile: .muted, now: start + .milliseconds(1000))
        let result = check.resolve(menu: .live, tile: .muted, now: start + .milliseconds(2000))

        #expect(result == TileCrossCheck.Result(state: .muted, tileDistrusted: false))
    }
}
