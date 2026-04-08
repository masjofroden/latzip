//
//  ArchiveNode.swift
//  LatZip
//
//  Nodo jerárquico con metadatos básicos para el explorador de archivos.
//

import Foundation

/// Representa un elemento dentro de un archivo (carpeta o fichero).
struct ArchiveNode: Identifiable, Hashable, Sendable {
    /// Identificador estable: ruta interna POSIX dentro del archivo.
    var id: String { fullPath }

    var name: String
    /// Ruta interna normalizada con `/`.
    var fullPath: String
    var isFolder: Bool
    var byteSize: Int64
    var modified: Date?
    var permissionsMode: UInt32
    /// Hijos (`nil` en hojas para compatibilidad con `OutlineGroup`).
    var children: [ArchiveNode]?

    /// Extensiones que pueden tratarse como archivo contenedor para abrir en nueva pestaña.
    static let nestedArchiveExtensions: Set<String> = [
        "zip", "jar", "war", "ear",
        "rar",
        "iso",
        "7z",
        "tar", "gz", "tgz", "bz2", "tbz2", "xz", "zst", "lzma",
        "cpio",
        "ar", "cab", "deb", "rpm", "xar", "pkg", "lha", "lzh", "warc", "z",
    ]

    var isNestedArchiveCandidate: Bool {
        guard !isFolder else { return false }
        let ext = (name as NSString).pathExtension.lowercased()
        return Self.nestedArchiveExtensions.contains(ext)
    }

    // MARK: Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(fullPath)
    }

    static func == (lhs: ArchiveNode, rhs: ArchiveNode) -> Bool {
        lhs.fullPath == rhs.fullPath
    }
}
