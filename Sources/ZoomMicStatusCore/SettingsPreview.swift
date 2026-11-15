/// What the indicators show while the settings window is open.
public enum SettingsPreview {
    /// The state to display: the real one during a meeting, otherwise the
    /// simulated one, if any. A simulation must never misreport the real
    /// microphone.
    public static func displayedState(status: IndicatorStatus, simulated: MicState?) -> MicState? {
        if case .mic(let state) = status { return state }
        return simulated
    }

    public static func canSimulate(status: IndicatorStatus) -> Bool {
        !status.showsOverlays
    }
}
