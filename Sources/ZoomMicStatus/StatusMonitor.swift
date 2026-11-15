import ZoomMicStatusCore
import os

/// Polls Zoom and reports every status change.
@MainActor
final class StatusMonitor {
    /// Fast during a meeting so a mute toggle shows up within ~100 ms: an
    /// in-meeting read is one cached accessibility call (~0.04 ms measured).
    /// Slower otherwise, since an idle read walks all of Zoom's menus
    /// (~75 ms measured).
    private static let meetingInterval = Duration.milliseconds(100)
    private static let idleInterval = Duration.milliseconds(1500)
    /// Lets the system coalesce wake-ups without a noticeable delay.
    private static let wakeTolerance = Duration.milliseconds(20)

    private let logger = Logger(subsystem: "com.jerefrer.zoom-mic-status", category: "monitor")
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
            let clock = ContinuousClock()
            while !Task.isCancelled {
                guard let interval = self?.tick() else { return }
                let start = clock.now
                try? await Task.sleep(for: interval, tolerance: Self.wakeTolerance) // Throws only on cancellation, checked by the loop.
                let slept = clock.now - start
                if slept > interval * 2 {
                    self?.logger.debug("Late wake-up: slept \(slept, privacy: .public) for \(interval, privacy: .public)")
                }
            }
        }
    }

    /// Reads Zoom now instead of waiting for the next tick.
    @discardableResult
    func tick() -> Duration {
        let latest = probe.readStatus()
        if latest != status {
            logger.debug("Status changed to \(String(describing: latest), privacy: .public)")
            status = latest
            onChange(latest)
        }
        return status.showsOverlays ? Self.meetingInterval : Self.idleInterval
    }
}
