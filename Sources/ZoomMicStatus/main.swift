import AppKit
import ZoomMicStatusCore

MainActor.assumeIsolated {
    // Read-only diagnostic: print what the app would display, then exit.
    if CommandLine.arguments.contains("--print-status") {
        let titles = MuteMenuTitles.load(fromZoomResources: AppDelegate.zoomResources)
        let probe = ZoomProbe(finder: MuteItemFinder(titles: titles))
        print(probe.readStatus())
        exit(0)
    }

    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    // Menu bar utility: no Dock icon, no app menu.
    app.setActivationPolicy(.accessory)
    app.run()
}
