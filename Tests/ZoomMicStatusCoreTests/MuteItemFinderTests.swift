import Testing
@testable import ZoomMicStatusCore

/// In-memory stand-in for Zoom's accessibility menu tree.
final class FakeNode: MenuNode {
    let title: String?
    let kids: [FakeNode]
    private(set) var childrenReads = 0

    init(_ title: String?, _ kids: [FakeNode] = []) {
        self.title = title
        self.kids = kids
    }

    func children() -> [FakeNode] {
        childrenReads += 1
        return kids
    }
}

struct MuteItemFinderTests {
    let titles = MuteMenuTitles(muteTitles: ["Mute audio"], unmuteTitles: ["Unmute audio"])

    @Test func shouldFindMutedStateInsideMeetingMenu() {
        let item = FakeNode("Unmute audio")
        let menuBar = FakeNode(nil, [
            FakeNode("Apple", [FakeNode(nil, [FakeNode("About")])]),
            FakeNode("Meeting", [FakeNode(nil, [FakeNode("Start video"), item])]),
        ])

        let match = MuteItemFinder(titles: titles).find(in: menuBar)

        #expect(match?.state == .muted)
        #expect(match?.node === item)
    }

    @Test func shouldReturnNilWhenNotInMeeting() {
        let menuBar = FakeNode(nil, [
            FakeNode("zoom.us", [FakeNode(nil, [FakeNode("Preferences")])]),
        ])

        #expect(MuteItemFinder(titles: titles).find(in: menuBar) == nil)
    }

    @Test func shouldStopDescendingBeyondMaxDepth() {
        let deep = FakeNode(nil, [FakeNode(nil, [FakeNode(nil, [FakeNode(nil, [FakeNode(nil, [FakeNode("Mute audio")])])])])])

        #expect(MuteItemFinder(titles: titles, maxDepth: 3).find(in: deep) == nil)
    }

    @Test func shouldNotExpandItemsThatAlreadyMatch() {
        let item = FakeNode("Mute audio", [FakeNode("child")])
        let menuBar = FakeNode(nil, [FakeNode("Meeting", [FakeNode(nil, [item])])])

        _ = MuteItemFinder(titles: titles).find(in: menuBar)

        #expect(item.childrenReads == 0)
    }
}
