import Testing
@testable import ZoomMicStatusCore

struct SelfTileLearnerTests {
    private func tiles(_ states: [String: MicState?]) -> [TileReading] {
        states.map { TileReading(name: $0.key, audio: $0.value) }
    }

    @Test func shouldNotDecideAfterASingleMenuChange() {
        var learner = SelfTileLearner()

        learner.menuChanged(to: .live, tiles: tiles(["Host": .live, "Me": .live, "Other": .muted]))

        #expect(learner.selfName == nil)
    }

    @Test func shouldLearnTheOnlyTileThatFollowedTheMenuBothWays() {
        var learner = SelfTileLearner()

        learner.menuChanged(to: .live, tiles: tiles(["Host": .live, "Me": .live, "Other": .muted]))
        learner.menuChanged(to: .muted, tiles: tiles(["Host": .live, "Me": .muted, "Other": .muted]))

        #expect(learner.selfName == "Me")
    }

    @Test func shouldKeepWaitingWhileSeveralTilesFollowedTheMenu() {
        var learner = SelfTileLearner()

        learner.menuChanged(to: .live, tiles: tiles(["Me": .live, "Twin": .live]))
        learner.menuChanged(to: .muted, tiles: tiles(["Me": .muted, "Twin": .muted]))
        #expect(learner.selfName == nil)

        learner.menuChanged(to: .live, tiles: tiles(["Me": .live, "Twin": .muted]))
        #expect(learner.selfName == "Me")
    }

    @Test func shouldStartOverWhenNoTileFollowedTheMenu() {
        var learner = SelfTileLearner()

        // A toggle faster than Zoom's menu refresh leaves no consistent tile.
        learner.menuChanged(to: .live, tiles: tiles(["Me": .muted, "Other": .live]))
        learner.menuChanged(to: .muted, tiles: tiles(["Me": .muted, "Other": .live]))
        learner.menuChanged(to: .live, tiles: tiles(["Me": .live, "Other": .live]))

        #expect(learner.selfName == "Me")
    }

    @Test func shouldIgnoreTilesWithoutAudioState() {
        var learner = SelfTileLearner()

        learner.menuChanged(to: .live, tiles: tiles(["Me": .live, "NoAudio": nil]))
        learner.menuChanged(to: .muted, tiles: tiles(["Me": .muted, "NoAudio": nil]))

        #expect(learner.selfName == "Me")
    }

    @Test func shouldRelearnFromScratchAfterForgetting() {
        var learner = SelfTileLearner()
        learner.menuChanged(to: .live, tiles: tiles(["Me": .live, "Other": .muted]))
        learner.menuChanged(to: .muted, tiles: tiles(["Me": .muted, "Other": .muted]))

        learner.forget()

        #expect(learner.selfName == nil)
    }
}
