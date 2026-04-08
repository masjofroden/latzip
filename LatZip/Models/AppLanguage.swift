//
//  AppLanguage.swift
//  LatZip
//

import Foundation

/// Idioma de la interfaz (persistido; requiere reinicio de la app vía relanzamiento).
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case en
    case es

    var id: String { rawValue }

    init(persistedValue: String?) {
        switch persistedValue {
        case "en": self = .en
        case "es": self = .es
        default: self = .system
        }
    }

    var persistedString: String {
        switch self {
        case .system: "system"
        case .en: "en"
        case .es: "es"
        }
    }

    var pickerTitle: String {
        switch self {
        case .system:
            String(localized: "prefs.language.system")
        case .en:
            String(localized: "prefs.language.en")
        case .es:
            String(localized: "prefs.language.es")
        }
    }
}
