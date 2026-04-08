//
//  AppAppearance.swift
//  LatZip
//

import AppKit
import SwiftUI

/// Modo de apariencia de la app (persistido). «Sistema» sigue macOS; claro/oscuro fuerza el estilo.
enum AppAppearance: String, CaseIterable, Identifiable {
    static let storageKey = "latzip.appearance"

    case system
    case light
    case dark

    var id: String { rawValue }

    init(persisted: String?) {
        switch persisted {
        case "light": self = .light
        case "dark": self = .dark
        default: self = .system
        }
    }

    var persistedString: String {
        switch self {
        case .system: "system"
        case .light: "light"
        case .dark: "dark"
        }
    }

    var pickerTitle: String {
        switch self {
        case .system:
            String(localized: "prefs.appearance.system")
        case .light:
            String(localized: "prefs.appearance.light")
        case .dark:
            String(localized: "prefs.appearance.dark")
        }
    }

    /// `nil` = seguir el sistema (SwiftUI).
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    /// `NSApp` puede ser `nil` durante el `init` temprano de `App` / `StateObject`. Se aplaza al siguiente ciclo del run loop principal.
    static func applyToSharedApplication(_ mode: AppAppearance) {
        DispatchQueue.main.async {
            let appearance: NSAppearance?
            switch mode {
            case .system:
                appearance = nil
            case .light:
                appearance = NSAppearance(named: .aqua)
            case .dark:
                appearance = NSAppearance(named: .darkAqua)
            }
            NSApplication.shared.appearance = appearance
        }
    }
}
