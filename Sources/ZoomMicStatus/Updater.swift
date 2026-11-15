import Combine
import Sparkle

/// Wraps Sparkle's updater, which checks the GitHub release feed
/// (`SUFeedURL` in Info.plist) and installs signed updates.
///
/// Sparkle does not check on every launch: it checks at launch only once
/// `SUScheduledCheckInterval` (one day) has passed since the last check, so
/// relaunching shortly after a check does nothing. "Check for Updates…"
/// forces an immediate check.
@MainActor
final class Updater: ObservableObject {
    @Published private(set) var canCheckForUpdates = false
    @Published var checksAutomatically: Bool {
        didSet { controller.updater.automaticallyChecksForUpdates = checksAutomatically }
    }

    private let controller: SPUStandardUpdaterController
    private var subscription: AnyCancellable?

    init() {
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        checksAutomatically = controller.updater.automaticallyChecksForUpdates
        // Disabled while a check is already running.
        subscription = controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canCheck in self?.canCheckForUpdates = canCheck }
    }

    func checkForUpdates() {
        controller.updater.checkForUpdates()
    }
}
