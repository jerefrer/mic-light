import AppKit
import ZoomMicStatusCore

/// The menu bar item: always present, since its menu leads to the settings.
/// When the menu bar mode is on it also shows the state in color.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let strings: Strings
    private let modes: () -> DisplayModes
    private let onToggleMode: (DisplayModes) -> Void
    private let onOpenSettings: () -> Void
    private var status: IndicatorStatus = .idle

    init(
        strings: Strings,
        modes: @escaping () -> DisplayModes,
        onToggleMode: @escaping (DisplayModes) -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.strings = strings
        self.modes = modes
        self.onToggleMode = onToggleMode
        self.onOpenSettings = onOpenSettings
        super.init()
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
    }

    /// `shown` is the state to display in color, which differs from the
    /// real status while the settings window previews a simulated state.
    func show(status: IndicatorStatus, shown: MicState?, style: MenuBarStyle) {
        self.status = status
        guard let button = item.button else { return }

        if let state = shown, modes().contains(.menuBar) {
            let color = Colors.signal(state)
            let config = Typography.menuBarIcon.applying(.init(paletteColors: [color]))
            button.image = Symbols.image(Symbols.mic(state), config)
            button.image?.isTemplate = false
            button.attributedTitle = style == .iconAndText
                ? NSAttributedString(
                    string: " " + strings.menuBarLabel(state),
                    attributes: [.font: Typography.menuBar, .foregroundColor: color]
                )
                : NSAttributedString()
        } else {
            let name = status == .needsPermission ? Symbols.needsPermission : Symbols.idle
            button.image = Symbols.image(name, Typography.menuBarIcon)
            button.image?.isTemplate = true
            button.attributedTitle = NSAttributedString()
        }
        button.imagePosition = .imageLeading
        button.toolTip = strings.statusLine(status)
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(NSMenuItem(title: strings.statusLine(status), action: nil, keyEquivalent: ""))

        if status == .needsPermission {
            menu.addItem(action(strings.grantAccess, #selector(grantAccess)))
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem.sectionHeader(title: strings.displaySection))
        menu.addItem(modeItem(strings.badgeMode, .badge))
        menu.addItem(modeItem(strings.borderMode, .border))
        menu.addItem(modeItem(strings.menuBarMode, .menuBar))

        menu.addItem(.separator())
        menu.addItem(action(strings.settings, #selector(openSettings), key: ","))
        menu.addItem(action(strings.quit, #selector(NSApplication.terminate(_:)), key: "q"))
    }

    private func action(_ title: String, _ selector: Selector, key: String = "") -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: selector, keyEquivalent: key)
        menuItem.target = selector == #selector(NSApplication.terminate(_:)) ? NSApp : self
        return menuItem
    }

    private func modeItem(_ title: String, _ mode: DisplayModes) -> NSMenuItem {
        let menuItem = action(title, #selector(toggleMode(_:)))
        menuItem.tag = mode.rawValue
        menuItem.state = modes().contains(mode) ? .on : .off
        return menuItem
    }

    @objc private func toggleMode(_ sender: NSMenuItem) {
        onToggleMode(DisplayModes(rawValue: sender.tag))
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func grantAccess() {
        AccessibilityAccess.request()
    }
}
