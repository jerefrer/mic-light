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
    public var menuBarMode: String { pick("Menu bar icon", "Icône dans la barre des menus") }
    public var dockMode: String { pick("Dock icon", "Icône dans le Dock") }
    public var waysBackHint: String {
        pick("The menu bar icon or the Dock icon always stays on, so the app remains reachable.",
             "L'icône de la barre des menus ou celle du Dock reste toujours active, pour pouvoir revenir à l'application.")
    }
    public var hide: String { pick("Hide Zoom Mic Status", "Masquer Zoom Mic Status") }
    public var window: String { pick("Window", "Fenêtre") }
    public var close: String { pick("Close", "Fermer") }
    public var borderWidth: String { pick("Thickness", "Épaisseur") }
    public var borderOpacity: String { pick("Opacity", "Opacité") }
    public var borderFade: String { pick("Fade toward the center", "Dégradé vers l'intérieur") }
    public func points(_ value: Double) -> String { "\(Int(value.rounded())) pt" }
    public func percent(_ value: Double) -> String { "\(Int((value * 100).rounded())) %" }
    public var grantAccess: String { pick("Grant Accessibility Access…", "Autoriser l'accès Accessibilité…") }
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
    public var appearance: String { pick("Appearance", "Apparence") }
    public var badgeSize: String { pick("Badge size", "Taille de la pastille") }
    public var badgePosition: String { pick("Badge position", "Position de la pastille") }
    public var badgeFreePosition: String {
        pick("Placed by hand. Pick a dot to snap it back to the grid.",
             "Placée à la main. Choisissez un point pour la recaler sur la grille.")
    }
    public func badgeAnchorName(_ anchor: BadgeAnchor) -> String {
        switch anchor {
        case .topLeft: pick("Top left", "En haut à gauche")
        case .top: pick("Top", "En haut")
        case .topRight: pick("Top right", "En haut à droite")
        case .left: pick("Left", "À gauche")
        case .center: pick("Center", "Au centre")
        case .right: pick("Right", "À droite")
        case .bottomLeft: pick("Bottom left", "En bas à gauche")
        case .bottom: pick("Bottom", "En bas")
        case .bottomRight: pick("Bottom right", "En bas à droite")
        }
    }

    // Settings pages
    public var generalPage: String { pick("General", "Général") }
    public var badgePage: String { pick("Badge", "Pastille") }
    public var borderPage: String { pick("Border", "Bordure") }
    public var menuBarDockPage: String { pick("Menu Bar & Dock", "Barre des menus et Dock") }
    public var aboutPage: String { pick("About", "À propos") }
    public var generalIntro: String {
        pick("Everything currently enabled, on your own desktop.",
             "Tout ce qui est activé, sur votre propre bureau.")
    }
    public var badgeIntro: String {
        pick("A label floating above every window, even full-screen Zoom. Drag it anywhere on screen.",
             "Une étiquette au-dessus de toutes les fenêtres, même Zoom en plein écran. Déplaçable n'importe où.")
    }
    public var borderIntro: String {
        pick("A colored frame around every screen. Clicks pass right through it.",
             "Un cadre coloré autour de chaque écran. Les clics passent au travers.")
    }
    public var menuBarDockIntro: String {
        pick("Colored icons that also open these settings.",
             "Des icônes colorées qui ouvrent aussi ces réglages.")
    }
    public var startupSection: String { pick("Startup", "Démarrage") }
    public var permissionsSection: String { pick("Permissions", "Autorisations") }
    public var showBadge: String { pick("Show the badge", "Afficher la pastille") }
    public var showBorder: String { pick("Show the border", "Afficher la bordure") }
    public var menuBarSection: String { pick("Menu bar", "Barre des menus") }
    public var dockSection: String { pick("Dock", "Dock") }
    public var showInMenuBar: String { pick("Show in the menu bar", "Afficher dans la barre des menus") }
    public var showInDock: String { pick("Show in the Dock", "Afficher dans le Dock") }
    public var display: String { pick("Display", "Affichage") }
    public var dockHint: String {
        pick("Click the Dock icon to open these settings.",
             "Cliquez sur l'icône du Dock pour ouvrir ces réglages.")
    }
    public var aboutTagline: String {
        pick("Makes Zoom's microphone state impossible to miss.",
             "Rend l'état du micro Zoom impossible à manquer.")
    }
    public var aboutPrivacy: String {
        pick("Reads Zoom's menu and meeting window through macOS Accessibility. It never clicks, types or sends anything to Zoom, and nothing leaves your Mac.",
             "Lit le menu et la fenêtre de réunion de Zoom via l'Accessibilité de macOS. Ne clique, ne tape et n'envoie jamais rien à Zoom, et rien ne quitte votre Mac.")
    }
    public func version(_ number: String) -> String { pick("Version \(number)", "Version \(number)") }
    public var generalSection: String { pick("General", "Général") }
    public var accessibilityGranted: String { pick("Accessibility access granted", "Accès Accessibilité accordé") }
    public var quit: String { pick("Quit Zoom Mic Status", "Quitter Zoom Mic Status") }
}
