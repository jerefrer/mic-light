import Foundation

/// The titles Zoom gives its "Mute audio" / "Unmute audio" menu item.
///
/// Zoom labels the item with the action it would perform, so a menu that
/// offers to *unmute* means the microphone is currently muted.
public struct MuteMenuTitles: Sendable {
    /// Keys of the entries in Zoom's `Localizable.strings` tables.
    static let muteKey = "Mute Audio"
    static let unmuteKey = "Unmute Audio"
    static let meetingMenuKey = "Meeting"

    /// Used when Zoom's bundle cannot be read (moved, renamed, or a future
    /// release dropped these keys).
    static let builtIn = MuteMenuTitles(
        muteTitles: ["Mute audio", "Désactiver le son"],
        unmuteTitles: ["Unmute audio", "Réactiver le son"],
        meetingMenuTitles: ["Meeting", "Réunion"]
    )

    private let muteTitles: Set<String>
    private let unmuteTitles: Set<String>
    private let meetingMenuTitles: Set<String>

    public init(
        muteTitles: some Sequence<String>,
        unmuteTitles: some Sequence<String>,
        meetingMenuTitles: some Sequence<String> = [String]()
    ) {
        self.muteTitles = Set(muteTitles.map(Self.normalize))
        self.unmuteTitles = Set(unmuteTitles.map(Self.normalize))
        self.meetingMenuTitles = Set(meetingMenuTitles.map(Self.normalize))
    }

    /// Reads the titles from every localization shipped inside Zoom, so the
    /// detection works whatever language Zoom is displayed in.
    public static func load(fromZoomResources resources: URL) -> MuteMenuTitles {
        var mute: [String] = []
        var unmute: [String] = []
        var meetingMenu: [String] = []
        for table in ZoomLocalizations.tables(in: resources) {
            if let title = table[muteKey] { mute.append(title) }
            if let title = table[unmuteKey] { unmute.append(title) }
            if let title = table[meetingMenuKey] { meetingMenu.append(title) }
        }

        guard !mute.isEmpty, !unmute.isEmpty else { return builtIn }
        return MuteMenuTitles(muteTitles: mute, unmuteTitles: unmute, meetingMenuTitles: meetingMenu)
    }

    /// The mic state a menu item with this title reveals, or `nil` when the
    /// title is not Zoom's mute item.
    public func state(forMenuTitle title: String) -> MicState? {
        let key = Self.normalize(title)
        if unmuteTitles.contains(key) { return .muted }
        if muteTitles.contains(key) { return .live }
        return nil
    }

    /// Whether the search can be limited to the Meeting menu.
    public var meetingMenuTitlesKnown: Bool { !meetingMenuTitles.isEmpty }

    public func isMeetingMenu(_ title: String) -> Bool {
        meetingMenuTitles.contains(Self.normalize(title))
    }

    private static func normalize(_ title: String) -> String {
        var trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.hasSuffix("…") || trimmed.hasSuffix(".") {
            trimmed.removeLast()
        }
        return trimmed.lowercased()
    }
}
