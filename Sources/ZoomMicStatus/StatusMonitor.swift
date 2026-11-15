import ZoomMicStatusCore

/// Polls Zoom and reports every status change.
@MainActor
final class StatusMonitor {
    /// Fast during a meeting so a mute toggle shows up almost instantly;
    /// slower otherwise, since an idle read walks all of Zoom's menus.
    private static let meetingInterval = Duration.milliseconds(300)
    private static let idleInterval = Duration.milliseconds(1500)

    private let probe: ZoomProbe
    private let onChange: (IndicatorStatus) -> Void
    private var loop: Task<Void, Never>?
    private(set) var status: IndicatorStatus = .idle

    init(probe: ZoomProbe, onChange: @escaping (IndicatorStatus) -> Void) {
        self.probe = probe
        self.onChange = onChange
    }

    deinit {
        loop?.cancel()
    }

    func start() {
        onChange(status)
        loop = Task { [weak self] in
            while !Task.isCancelled {
                guard let interval = self?.tick() else { return }
                try? await Task.sleep(for: interval) // Throws only on cancellation, checked by the loop.
            }
        }
    }

    /// Reads Zoom now instead of waiting for the next tick.
    @discardableResult
    func tick() -> Duration {
        let latest = probe.readStatus()
        if latest != status {
            status = latest
            onChange(latest)
        }
        return status.showsOverlays ? Self.meetingInterval : Self.idleInterval
    }
}
