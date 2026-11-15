import AppKit
import ApplicationServices
import ServiceManagement

/// Launching the app when the user logs in.
@MainActor
protocol LoginItem {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

@MainActor
struct MainAppLoginItem: LoginItem {
    var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

@MainActor
enum AccessibilityAccess {
    private static let settingsURL =
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!

    static var isGranted: Bool { AXIsProcessTrusted() }

    static func request() {
        // The prompt only appears the first time; after that the user has to
        // flip the switch in System Settings, so open it directly too.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(options) {
            NSWorkspace.shared.open(settingsURL)
        }
    }
}
