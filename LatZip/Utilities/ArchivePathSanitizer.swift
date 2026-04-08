//
//  ArchivePathSanitizer.swift
//  LatZip
//

import Foundation

enum ArchivePathSanitizer {
    /// Evita salidas fuera del destino cuando el archivo declara rutas relativas peligrosas.
    static func safeInternalPath(_ path: String) -> Bool {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmed.isEmpty { return false }
        if path.hasPrefix("/") { return false }
        for component in trimmed.split(separator: "/").map(String.init) {
            if component == ".." { return false }
        }
        return true
    }

    /// Resuelve colisiones en disco. `.skip` devuelve `nil` si ya existe.
    static func resolvedDestinationURL(
        baseName: String,
        directory: URL,
        policy: ExtractionCollisionPolicy,
        fsExists: (URL) -> Bool
    ) -> URL? {
        var name = baseName
        var candidate = directory.appendingPathComponent(name)
        var serial = 1
        switch policy {
        case .replace:
            return candidate
        case .skip:
            if fsExists(candidate) { return nil }
            return candidate
        case .keepBoth:
            while fsExists(candidate) {
                let ns = name as NSString
                let stem = ns.deletingPathExtension
                let ext = ns.pathExtension
                name = ext.isEmpty ? "\(stem) (\(serial))" : "\(stem) (\(serial)).\(ext)"
                serial += 1
                candidate = directory.appendingPathComponent(name)
            }
            return candidate
        }
    }
}
