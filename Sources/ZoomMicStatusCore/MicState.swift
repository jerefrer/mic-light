/// Zoom's microphone state while a meeting is in progress.
public enum MicState: Equatable, Sendable {
    case muted
    case live
}

/// Everything the indicators can display.
public enum IndicatorStatus: Equatable, Sendable {
    case mic(MicState)
    /// Zoom is not running, or running without an active meeting.
    case idle
    /// Accessibility access has not been granted, so Zoom cannot be read.
    case needsPermission

    /// The badge and the screen border only appear during a meeting.
    public var showsOverlays: Bool {
        if case .mic = self { return true }
        return false
    }
}
