//
//  ArchiveEntryRecord+Curator.swift
//

import Foundation
import UniformTypeIdentifiers

extension ArchiveEntryRecord {
    /// Texto corto para columna «Tipo» (extensión / carpeta).
    var curatorTypeLabel: String {
        if isFolder {
            return String(localized: "kind.folder")
        }
        let ext = (name as NSString).pathExtension.lowercased()
        if ext.isEmpty {
            return "—"
        }
        if let ut = UTType(filenameExtension: ext),
           let desc = ut.localizedDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
           !desc.isEmpty {
            return desc
        }
        return ext.uppercased()
    }

    /// Clave estable para ordenar por tipo.
    var curatorTypeSortKey: String {
        if isFolder { return "\u{0}" + String(localized: "kind.folder") }
        let ext = (name as NSString).pathExtension.lowercased()
        return ext.isEmpty ? "\u{1}" : ext
    }
}
