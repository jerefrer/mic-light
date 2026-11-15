/// Every user-facing string, in English and French.
public struct Strings: Sendable {
    let french: Bool

    public init(preferredLanguages: [String]) {
        french = preferredLanguages.first?.hasPrefix("fr") ?? false
    }

    private func pick(_ en: String, _ fr: String) -> String { french ? fr : en }

    public func badgeLabel(_ state: MicState) -> String {
        switch state {
        case .muted: pick("MIC MUTED", "MICRO COUPÉ")
        case .live: pick("MIC LIVE", "MICRO OUVERT")
        }
    }

    public func menuBarLabel(_ state: MicState) -> String {
        switch state {
        case .muted: pick("MUTED", "COUPÉ")
        case .live: pick("LIVE", "OUVERT")
        }
    }

    public func statusLine(_ status: IndicatorStatus) -> String {
        switch status {
        case .mic(.muted): pick("Zoom: microphone muted", "Zoom : micro coupé")
        case .mic(.live): pick("Zoom: microphone live", "Zoom : micro ouvert")
        case .idle: pick("No Zoom meeting in progress", "Aucune réunion Zoom en cours")
        case .needsPermission: pick("Accessibility access required", "Accès Accessibilité requis")
        }
    }

    public var displaySection: String { pick("Show the state with", "Afficher l'état avec") }
    public var badgeMode: String { pick("Floating badge", "Pastille flottante") }
    public var borderMode: String { pick("Screen border", "Bordure d'écran") }
    public var menuBarMode: String { pick("Colored menu bar icon", "Icône colorée dans la barre des menus") }
    public var borderWidth: String { pick("Thickness", "Épaisseur") }
    public var borderOpacity: String { pick("Opacity", "Opacité") }
    public var borderFade: String { pick("Fade toward the center", "Dégradé vers l'intérieur") }
    public func points(_ value: Double) -> String { "\(Int(value.rounded())) pt" }
    public func percent(_ value: Double) -> String { "\(Int((value * 100).rounded())) %" }
    public var grantAccess: String { pick("Grant Accessibility Access…", "Autoriser l'accès Accessibilité…") }
    public var resetBadgePosition: String { pick("Reset Badge Position", "Replacer la pastille") }
    public var launchAtLogin: String { pick("Launch at Login", "Ouvrir à la connexion") }
    public var settings: String { pick("Settings…", "Réglages…") }
    public var settingsTitle: String { pick("Zoom Mic Status Settings", "Réglages de Zoom Mic Status") }
    public var appName: String { "Zoom Mic Status" }
    public var previewSection: String { pick("Preview", "Aperçu") }
    public var simulate: String { pick("Simulate", "Simuler") }
    public func stateName(_ state: MicState) -> String {
        switch state {
        case .muted: pick("Muted", "Coupé")
        case .live: pick("Live", "Ouvert")
        }
    }
    public var previewIdleHint: String {
        pick("While this window is open, the indicators are shown on screen exactly as they will appear.",
             "Tant que cette fenêtre est ouverte, les indicateurs s'affichent à l'écran tels qu'ils apparaîtront.")
    }
    public var previewMeetingHint: String {
        pick("A meeting is in progress: the preview follows your real microphone.",
             "Une réunion est en cours : l'aperçu suit l'état réel du micro.")
    }
    public var indicatorsSection: String { pick("Indicators", "Indicateurs") }
    public var menuBarStyle: String { pick("Menu bar shows", "Dans la barre des menus") }
    public func menuBarStyleName(_ style: MenuBarStyle) -> String {
        switch style {
        case .iconOnly: pick("Icon only", "Icône seule")
        case .iconAndText: pick("Icon and text", "Icône et texte")
        }
    }
    public var borderAppearanceSection: String { pick("Border appearance", "Apparence de la bordure") }
    public var badgePosition: String { pick("Badge position", "Position de la pastille") }
    public var reset: String { pick("Reset", "Réinitialiser") }
    public var generalSection: String { pick("General", "Général") }
    public var accessibilityGranted: String { pick("Accessibility access granted", "Accès Accessibilité accordé") }
    public var quit: String { pick("Quit Zoom Mic Status", "Quitter Zoom Mic Status") }
}
