import AppKit
import ImageIO

/// The user's desktop picture, used as the backdrop of the settings
/// illustrations so they look like the user's own screen.
@MainActor
enum Wallpaper {
    /// Large enough for the biggest illustration on a Retina display.
    private static let maxPixelSize = 1600

    /// `nil` when macOS reports no picture file (e.g. dynamic or aerial
    /// wallpapers without a still image); callers fall back to a gradient.
    static func thumbnail(for screen: NSScreen) -> NSImage? {
        guard let url = NSWorkspace.shared.desktopImageURL(for: screen),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                  kCGImageSourceCreateThumbnailWithTransform: true,
              ] as CFDictionary)
        else { return nil }
        return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    }
}
