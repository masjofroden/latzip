//
//  ArchiveFormatCapabilities.swift
//  LatZip
//

import Foundation

struct ArchiveFormatCapabilities: Sendable {
    var formatName: String
    var filterName: String
    var supportsSelectiveExtraction: Bool = true
    var supportsEditing: Bool
    /// Cifrado con contraseña vía reempaquetado ZIP (solo archivos `.zip`).
    var supportsZipPassphrase: Bool = false
    var supportsQuickLookPreview: Bool = true
}

enum ExtractionCollisionPolicy: String, CaseIterable, Sendable {
    case skip
    case replace
    case keepBoth

    var localizedTitle: String {
        switch self {
        case .keepBoth:
            String(localized: "prefs.collision.keep_both")
        case .replace:
            String(localized: "prefs.collision.replace")
        case .skip:
            String(localized: "prefs.collision.skip")
        }
    }
}

struct ExtractionOptions: Sendable {
    var collisionPolicy: ExtractionCollisionPolicy = .keepBoth
    var applyCollisionPolicyToAll: Bool = false
}
