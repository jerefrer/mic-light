import AppKit
import ZoomMicStatusCore

MainActor.assumeIsolated {
    // Read-only diagnostic: print what the app would display, then exit.
    if CommandLine.arguments.contains("--print-status") {
        let titles = MuteMenuTitles.load(fromZoomResources: AppDelegate.zoomResources)
        let tiles = ZoomTiles(phrases: TileAudioPhrases.load(fromZoomResources: AppDelegate.zoomResources))
        let probe = ZoomProbe(finder: MuteItemFinder(titles: titles), tiles: tiles)
        print(probe.readStatus())
        // Counts only: tile names are other participants' names.
        if let zoom = NSRunningApplication.runningApplications(withBundleIdentifier: ZoomProbe.bundleIdentifier).first {
            let readings = tiles.readAll(in: AXUIElementCreateApplication(zoom.processIdentifier))
            let muted = readings.filter { $0.audio == .muted }.count
            print("tiles: \(readings.count) (muted: \(muted), live: \(readings.count - muted))")
        }
        exit(0)
    }

    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    // Menu bar utility: no Dock icon, no app menu.
    app.setActivationPolicy(.accessory)
    app.run()
}
