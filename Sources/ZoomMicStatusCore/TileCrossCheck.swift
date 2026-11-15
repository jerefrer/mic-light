/// Combines the instant but inferred tile state with the authoritative but
/// late menu state (Zoom refreshes its menu about once per second).
public struct TileCrossCheck: Sendable {
    public struct Result: Equatable, Sendable {
        public let state: MicState
        /// The tile disagreed with the menu for longer than Zoom's refresh
        /// delay can explain: it is probably not the user's tile.
        public let tileDistrusted: Bool
    }

    /// Longest lag observed between a tile and the menu was 1.0 s.
    static let maxMenuLag = Duration.milliseconds(1500)

    private var disagreeingSince: ContinuousClock.Instant?

    public init() {}

    public mutating func resolve(menu: MicState, tile: MicState?, now: ContinuousClock.Instant) -> Result {
        guard let tile, tile != menu else {
            disagreeingSince = nil
            return Result(state: tile ?? menu, tileDistrusted: false)
        }
        let since = disagreeingSince ?? now
        disagreeingSince = since
        if now - since > Self.maxMenuLag {
            disagreeingSince = nil
            return Result(state: menu, tileDistrusted: true)
        }
        return Result(state: tile, tileDistrusted: false)
    }
}
