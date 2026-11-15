import Foundation

/// The `Localizable.strings` tables shipped inside Zoom, one per language.
enum ZoomLocalizations {
    static func tables(in resources: URL) -> [[String: String]] {
        let localizations = (try? FileManager.default.contentsOfDirectory(
            at: resources, includingPropertiesForKeys: nil
        )) ?? []
        return localizations
            .filter { $0.pathExtension == "lproj" }
            .compactMap { NSDictionary(contentsOf: $0.appendingPathComponent("Localizable.strings")) as? [String: String] }
    }
}
