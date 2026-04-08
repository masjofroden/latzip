//
//  ArchiveEntryRecord.swift
//  LatZip
//

import Foundation

/// Fila lógica derivada del listado plano (navegación tipo Finder).
struct ArchiveEntryRecord: Identifiable, Hashable, Sendable {
    var id: String { fullPath }
    var name: String
    var fullPath: String
    var parentPath: String
    var isFolder: Bool
    var byteSize: Int64
    var modified: Date?
    var permissionsMode: UInt32
}
