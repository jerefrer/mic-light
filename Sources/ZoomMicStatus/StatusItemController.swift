import AppKit
import ServiceManagement
import ZoomMicStatusCore
import os

/// The menu bar item: always present, since its menu holds the settings.
/// When the menu bar mode is on it also shows the state in color.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private static let accessibilitySettingsURL =
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!

    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let strings: Strings
    private let modeStore: DisplayModeStore
    private let borderStyleStore: BorderStyleStore
    private let onModesChanged: () -> Void
    private let onResetBadgePosition: () -> Void
    private let onBorderStyleChanged: (BorderStyle) -> Void
    private let onBorderPreview: (Bool) -> Void
    private let logger = Logger(subsystem: "com.jerefrer.zoom-mic-status", category: "menu")
    private var status: IndicatorStatus = .idle
    private let borderSettingsMenu = NSMenu()

    init(
        strings: Strings,
        modeStore: DisplayModeStore,
        borderStyleStore: BorderStyleStore,
        onModesChanged: @escaping () -> Void,
        onResetBadgePosition: @escaping () -> Void,
        onBorderStyleChanged: @escaping (BorderStyle) -> Void,
        onBorderPreview: @escaping (Bool) -> Void
    ) {
        self.strings = strings
        self.modeStore = modeStore
        self.borderStyleStore = borderStyleStore
        self.onModesChanged = onModesChanged
        self.onResetBadgePosition = onResetBadgePosition
        self.onBorderStyleChanged = onBorderStyleChanged
        self.onBorderPreview = onBorderPreview
        super.init()
        borderSettingsMenu.delegate = self
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
    }

    func show(_ status: IndicatorStatus) {
        self.status = status
        guard let button = item.button else { return }

        if case .mic(let state) = status, modeStore.modes.contains(.menuBar) {
            let color = Colors.signal(state)
            let config = Typography.menuBarIcon.applying(.init(paletteColors: [color]))
            button.image = Symbols.image(Symbols.mic(state), config)
            button.image?.isTemplate = false
            button.attributedTitle = NSAttributedString(
                string: " " + strings.menuBarLabel(state),
                attributes: [.font: Typography.menuBar, .foregroundColor: color]
            )
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
        guard menu === item.menu else { return }
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
        menu.addItem(action(strings.resetBadgePosition, #selector(resetBadgePosition)))
        menu.addItem(borderSettingsItem())

        menu.addItem(.separator())
        let login = action(strings.launchAtLogin, #selector(toggleLaunchAtLogin))
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(action(strings.quit, #selector(NSApplication.terminate(_:)), key: "q"))
    }

    // Shows the border while its settings are open, so the sliders have a
    // visible effect even outside a meeting.
    func menuWillOpen(_ menu: NSMenu) {
        if menu === borderSettingsMenu { onBorderPreview(true) }
    }

    func menuDidClose(_ menu: NSMenu) {
        if menu === borderSettingsMenu { onBorderPreview(false) }
    }

    private func borderSettingsItem() -> NSMenuItem {
        let controls = NSMenuItem()
        controls.view = BorderSettingsView(strings: strings, style: borderStyleStore.style) { [weak self] style in
            self?.borderStyleStore.style = style
            self?.onBorderStyleChanged(style)
        }
        borderSettingsMenu.removeAllItems()
        borderSettingsMenu.addItem(controls)

        let parent = NSMenuItem(title: strings.borderSettings, action: nil, keyEquivalent: "")
        parent.submenu = borderSettingsMenu
        return parent
    }

    private func action(_ title: String, _ selector: Selector, key: String = "") -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: selector, keyEquivalent: key)
        menuItem.target = selector == #selector(NSApplication.terminate(_:)) ? NSApp : self
        return menuItem
    }

    private func modeItem(_ title: String, _ mode: DisplayModes) -> NSMenuItem {
        let menuItem = action(title, #selector(toggleMode(_:)))
        menuItem.tag = mode.rawValue
        menuItem.state = modeStore.modes.contains(mode) ? .on : .off
        return menuItem
    }

    @objc private func toggleMode(_ sender: NSMenuItem) {
        modeStore.toggle(DisplayModes(rawValue: sender.tag))
        onModesChanged()
    }

    @objc private func resetBadgePosition() {
        onResetBadgePosition()
    }

    @objc private func grantAccess() {
        // The prompt only appears the first time; after that the user has to
        // flip the switch in System Settings, so open it directly too.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(options) {
            NSWorkspace.shared.open(Self.accessibilitySettingsURL)
        }
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            logger.error("Launch at login change failed: \(error.localizedDescription)")
        }
    }
}
