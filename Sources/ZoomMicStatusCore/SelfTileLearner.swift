/// Works out which participant tile is the user's own, without knowing
/// their name: it is the tile whose audio state followed every change of
/// Zoom's mute menu.
///
/// Tile order carries no meaning in Zoom and display names change between
/// meetings, so matching on behavior is the only reliable signal.
public struct SelfTileLearner: Sendable {
    public private(set) var selfName: String?
    /// Tiles consistent with every menu change seen so far.
    private var candidates: Set<String>?

    public init() {}

    /// Call when Zoom's menu reports a new state, with the tiles read at
    /// that moment. The menu lags the tiles, so they already show the
    /// new state.
    public mutating func menuChanged(to state: MicState, tiles: [TileReading]) {
        guard selfName == nil else { return }
        let matching = Set(tiles.filter { $0.audio == state }.map(\.name))

        guard let previous = candidates else {
            // A single change could match by coincidence: never decide on it.
            candidates = matching
            return
        }
        let narrowed = previous.intersection(matching)
        if narrowed.count == 1 {
            selfName = narrowed.first
        }
        // An empty intersection means the observations were inconsistent
        // (toggling faster than Zoom refreshes its menu): start over.
        candidates = narrowed.isEmpty ? matching : narrowed
    }

    public mutating func forget() {
        selfName = nil
        candidates = nil
    }
}
