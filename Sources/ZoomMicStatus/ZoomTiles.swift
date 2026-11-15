import AppKit
import ApplicationServices
import ZoomMicStatusCore

/// Reads the participant tiles of Zoom's meeting window.
///
/// A tile is a direct child of a Zoom window whose accessibility description
/// announces an audio state; the user's own tile reflects a mute toggle
/// immediately, unlike the menu.
@MainActor
final class ZoomTiles {
    /// Rescanning every tile is far costlier than re-reading one, so while
    /// the user's tile is not on screen (speaker view, self view hidden)
    /// look for it at most this often.
    private static let rescanInterval = Duration.seconds(1)

    private let phrases: TileAudioPhrases
    private var ownTile: AXNode?
    private var lastRescan: ContinuousClock.Instant?

    init(phrases: TileAudioPhrases) {
        self.phrases = phrases
    }

    /// Every tile currently on screen.
    func readAll(in app: AXUIElement) -> [TileReading] {
        tileNodes(in: app).map(\.reading)
    }

    /// The audio state shown on the tile named `name`, or `nil` when that
    /// tile is not on screen.
    func state(ofTileNamed name: String, in app: AXUIElement, now: ContinuousClock.Instant) -> MicState? {
        if let tile = ownTile, let reading = read(tile), reading.name == name {
            return reading.audio
        }
        ownTile = nil
        if let last = lastRescan, now - last < Self.rescanInterval { return nil }
        lastRescan = now

        guard let found = tileNodes(in: app).first(where: { $0.reading.name == name }) else { return nil }
        ownTile = found.node
        return found.reading.audio
    }

    func forgetOwnTile() {
        ownTile = nil
        lastRescan = nil
    }

    private func tileNodes(in app: AXUIElement) -> [(node: AXNode, reading: TileReading)] {
        let windows = (AXNode(app).attribute(kAXWindowsAttribute) as? [AXUIElement]) ?? []
        return windows.flatMap { AXNode($0).children() }.compactMap { node in
            read(node).map { (node, $0) }
        }
    }

    private func read(_ node: AXNode) -> TileReading? {
        (node.attribute(kAXDescriptionAttribute) as? String).flatMap(phrases.parse)
    }
}
