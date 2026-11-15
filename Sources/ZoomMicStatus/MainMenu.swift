import AppKit
import ZoomMicStatusCore

/// The app menu shown while the app is in the Dock and frontmost. A menu
/// bar utility never shows it, but the shortcuts (⌘, ⌘H ⌘Q ⌘W) need it.
@MainActor
enum MainMenu {
    static func make(strings: Strings, settingsTarget: AnyObject, settingsAction: Selector) -> NSMenu {
        let appMenu = NSMenu()
        let settings = NSMenuItem(title: strings.settings, action: settingsAction, keyEquivalent: ",")
        settings.target = settingsTarget
        appMenu.addItem(settings)
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: strings.hide, action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(NSMenuItem(title: strings.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        let windowMenu = NSMenu(title: strings.window)
        windowMenu.addItem(NSMenuItem(title: strings.close, action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))

        let main = NSMenu()
        for submenu in [appMenu, windowMenu] {
            let item = NSMenuItem()
            item.submenu = submenu
            main.addItem(item)
        }
        return main
    }
}
