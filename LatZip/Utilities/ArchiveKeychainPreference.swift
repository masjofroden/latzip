//
//  ArchiveKeychainPreference.swift
//  LatZip
//

import Foundation

/// Preferencia global: permitir guardar contraseñas de archivos cifrados en el Llavero.
enum ArchiveKeychainPreference {
    static let userDefaultsKey = "latzip.archivePasswordKeychain"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: userDefaultsKey)
    }
}
