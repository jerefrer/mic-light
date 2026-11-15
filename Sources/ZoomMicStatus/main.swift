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

    // Build tooling: writes the app icon (the muted Dock icon) as a 1024 px PNG.
    if let index = CommandLine.arguments.firstIndex(of: "--write-app-icon") {
        guard let image = DockIcon.image(shown: .muted, needsPermission: false),
              let bitmap = image.representations.first as? NSBitmapImageRep,
              let png = bitmap.representation(using: .png, properties: [:]),
              (try? png.write(to: URL(fileURLWithPath: CommandLine.arguments[index + 1]))) != nil
        else { exit(1) }
        exit(0)
    }

    // Build tooling: renders the README and website images into a folder.
    if let index = CommandLine.arguments.firstIndex(of: "--render-showcase") {
        Showcase.render(into: URL(fileURLWithPath: CommandLine.arguments[index + 1]))
        exit(0)
    }

    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    // Menu bar utility: no Dock icon, no app menu.
    app.setActivationPolicy(.accessory)
    app.run()
}
