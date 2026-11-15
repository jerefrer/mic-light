import Foundation

/// One participant tile of Zoom's meeting window, as read from its
/// accessibility description ("Name, Computer audio muted, Video off").
public struct TileReading: Equatable, Sendable {
    public let name: String
    /// `nil` when the participant has no audio connected.
    public let audio: MicState?

    public init(name: String, audio: MicState?) {
        self.name = name
        self.audio = audio
    }
}

/// The phrases Zoom puts in a tile's description to announce its audio state.
public struct TileAudioPhrases: Sendable {
    /// Keys in Zoom's string tables, without the numeric suffix Zoom appends
    /// (e.g. `_20044`), which is not stable across releases.
    static let mutedKeys: Set<String> = [
        "LN_Plist_Accessibility_VoIP_Muted",
        "LN_Plist_Accessibility_Tele_Muted",
        "LN_Audio_Muted_Accessibility",
        "LN_AXAudioMutedByHost",
    ]
    static let unmutedKeys: Set<String> = [
        "LN_Plist_Accessibility_VoIP_Unmuted",
        "LN_Plist_Accessibility_Tele_Unmuted",
        "LN_Audio_Unmuted_Accessibility",
    ]

    /// Used when Zoom's bundle cannot be read.
    static let builtIn = TileAudioPhrases(
        mutedPhrases: ["Computer audio muted", "Ordinateur mis en sourdine"],
        unmutedPhrases: ["Computer audio unmuted", "Son de l'ordinateur rétabli"]
    )

    private let mutedPhrases: Set<String>
    private let unmutedPhrases: Set<String>

    public init(mutedPhrases: some Sequence<String>, unmutedPhrases: some Sequence<String>) {
        self.mutedPhrases = Set(mutedPhrases.map(Self.normalize))
        self.unmutedPhrases = Set(unmutedPhrases.map(Self.normalize))
    }

    public static func load(fromZoomResources resources: URL) -> TileAudioPhrases {
        var muted: [String] = []
        var unmuted: [String] = []
        for table in ZoomLocalizations.tables(in: resources) {
            for (key, phrase) in table {
                let base = stripNumericSuffix(key)
                if mutedKeys.contains(base) { muted.append(phrase) }
                if unmutedKeys.contains(base) { unmuted.append(phrase) }
            }
        }
        guard !muted.isEmpty, !unmuted.isEmpty else { return builtIn }
        return TileAudioPhrases(mutedPhrases: muted, unmutedPhrases: unmuted)
    }

    /// Reads a tile description, or returns `nil` when it does not announce
    /// an audio state (so it is not a participant tile with audio).
    public func parse(_ description: String) -> TileReading? {
        let parts = description.components(separatedBy: ", ")
        for (index, part) in parts.enumerated() where index > 0 {
            let phrase = Self.normalize(part)
            let audio: MicState? = mutedPhrases.contains(phrase) ? .muted
                : unmutedPhrases.contains(phrase) ? .live : nil
            if let audio {
                return TileReading(name: parts[..<index].joined(separator: ", "), audio: audio)
            }
        }
        return nil
    }

    private static func stripNumericSuffix(_ key: String) -> String {
        guard let underscore = key.lastIndex(of: "_"),
              !key[key.index(after: underscore)...].isEmpty,
              key[key.index(after: underscore)...].allSatisfy(\.isNumber)
        else { return key }
        return String(key[..<underscore])
    }

    private static func normalize(_ phrase: String) -> String {
        phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
