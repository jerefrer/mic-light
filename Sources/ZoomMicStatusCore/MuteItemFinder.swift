/// A node of an application's menu tree: the menu bar, a menu, or an item.
public protocol MenuNode: AnyObject {
    var title: String? { get }
    /// Fetched lazily: on the real tree every call is an IPC round-trip to Zoom.
    func children() -> [Self]
}

public struct MuteItemMatch<Node: MenuNode> {
    public let node: Node
    public let state: MicState
}

/// Walks Zoom's menu bar looking for the mute / unmute item.
public struct MuteItemFinder: Sendable {
    let titles: MuteMenuTitles
    /// Menu bar → bar item → menu → menu item is depth 3; one extra level
    /// covers the item moving into a submenu.
    let maxDepth: Int

    public init(titles: MuteMenuTitles, maxDepth: Int = 4) {
        self.titles = titles
        self.maxDepth = maxDepth
    }

    /// Searches the menu bar `root`. When the Meeting menu's title is known,
    /// only that menu is opened: walking the others costs Zoom real time
    /// (its Window menu measured at over half a second).
    public func find<Node: MenuNode>(in root: Node) -> MuteItemMatch<Node>? {
        guard titles.meetingMenuTitlesKnown else { return search(root, depth: 0) }
        for menu in root.children() {
            guard let title = menu.title, titles.isMeetingMenu(title) else { continue }
            if let match = search(menu, depth: 1) { return match }
        }
        return nil
    }

    /// Re-checks a previously found item without walking anything.
    public func match<Node: MenuNode>(_ node: Node) -> MuteItemMatch<Node>? {
        guard let title = node.title, let state = titles.state(forMenuTitle: title) else { return nil }
        return MuteItemMatch(node: node, state: state)
    }

    private func search<Node: MenuNode>(_ node: Node, depth: Int) -> MuteItemMatch<Node>? {
        if let match = match(node) { return match }
        guard depth < maxDepth else { return nil }
        for child in node.children() {
            if let match = search(child, depth: depth + 1) { return match }
        }
        return nil
    }
}
