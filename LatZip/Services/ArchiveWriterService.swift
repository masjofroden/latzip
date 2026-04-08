//
//  ArchiveWriterService.swift
//  LatZip
//

import Darwin
import Foundation

enum ArchiveWriteError: Error, LocalizedError {
    case unsupportedEditFormat
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedEditFormat:
            return String(localized: "error.not_zip_edit")
        case .operationFailed(let m):
            return m
        }
    }
}

actor ArchiveWriterService {
    /// Crea un `.zip` vacío en disco (sobrescribe si existe).
    func createEmptyZip(at zipURL: URL) async throws {
        guard archive_engine_is_editable_archive_path(zipURL.path) != 0 else {
            throw ArchiveWriteError.unsupportedEditFormat
        }
        try await Task.detached(priority: .userInitiated) {
            var err = [CChar](repeating: 0, count: 1024)
            let rc = zipURL.path.withCString { path in
                archive_engine_zip_create_empty(path, &err, 1024)
            }
            guard rc == 0 else {
                let msg = err.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
                    .trimmingCharacters(in: .controlCharacters)
                throw ArchiveWriteError.operationFailed(msg.isEmpty ? String(localized: "error.zip_write_generic") : msg)
            }
        }.value
    }

    func addItems(zipURL: URL, pairs: [(fileURL: URL, internalPath: String)]) async throws {
        guard archive_engine_is_editable_archive_path(zipURL.path) != 0 else {
            throw ArchiveWriteError.unsupportedEditFormat
        }
        try await Task.detached(priority: .userInitiated) {
            var err = [CChar](repeating: 0, count: 1024)
            var cPairs: [ArchiveZipAddPair] = []
            cPairs.reserveCapacity(pairs.count)
            for p in pairs {
                cPairs.append(ArchiveZipAddPair(
                    filesystem_path: strdup(p.fileURL.path),
                    archive_internal_path: strdup(p.internalPath)
                ))
            }
            defer {
                for pair in cPairs {
                    free(UnsafeMutableRawPointer(mutating: pair.filesystem_path))
                    free(UnsafeMutableRawPointer(mutating: pair.archive_internal_path))
                }
            }
            let rc = cPairs.withUnsafeBufferPointer { buf -> Int32 in
                guard let bp = buf.baseAddress else { return -1 }
                return Int32(archive_engine_zip_add_paths(
                    zipURL.path,
                    bp,
                    buf.count,
                    &err,
                    1024
                ))
            }
            guard rc == 0 else {
                let msg = err.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }.trimmingCharacters(in: .controlCharacters)
                throw ArchiveWriteError.operationFailed(msg.isEmpty ? String(localized: "error.zip_write_generic") : msg)
            }
        }.value
    }

    /// Reescribe el ZIP cifrando todas las entradas con la nueva contraseña.
    func applyPassphrase(zipURL: URL, readPassphrase: String?, newPassphrase: String) async throws {
        guard archive_engine_is_zip_extension(zipURL.path) != 0 else {
            throw ArchiveWriteError.unsupportedEditFormat
        }
        try await Task.detached(priority: .userInitiated) {
            var err = [CChar](repeating: 0, count: 1024)
            let rc: Int32 = zipURL.path.withCString { zpath in
                newPassphrase.withCString { np in
                    if let readPassphrase, !readPassphrase.isEmpty {
                        return readPassphrase.withCString { readp in
                            archive_engine_zip_apply_passphrase(zpath, readp, np, &err, 1024)
                        }
                    }
                    return archive_engine_zip_apply_passphrase(zpath, nil, np, &err, 1024)
                }
            }
            guard rc == 0 else {
                if rc == LATZIP_ERR_ZIP_AES256_UNAVAILABLE {
                    throw ArchiveWriteError.operationFailed(String(localized: "error.zip_aes256_unavailable"))
                }
                let msg = err.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
                    .trimmingCharacters(in: .controlCharacters)
                throw ArchiveWriteError.operationFailed(msg.isEmpty ? String(localized: "error.zip_write_generic") : msg)
            }
        }.value
    }

    /// Normaliza la carpeta actual dentro del ZIP (`browseFolderPath`): sin barras sobrantes.
    static func normalizedArchiveInternalPrefix(_ raw: String) -> String {
        raw.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    /// Expande directorios; las rutas internas incluyen prefijo de carpeta actual del archivo (estilo WinRAR/7-Zip).
    static func pairsForAdding(urls: [URL], archiveInternalPrefix: String = "") -> [(URL, String)] {
        let lead = normalizedArchiveInternalPrefix(archiveInternalPrefix)
        let prefixInZip = lead.isEmpty ? "" : lead + "/"
        var pairs: [(URL, String)] = []
        let fm = FileManager.default
        for root in urls {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: root.path, isDirectory: &isDir) else { continue }
            let rootStandard = root.standardizedFileURL
            let baseName = rootStandard.lastPathComponent
            if isDir.boolValue {
                guard let en = fm.enumerator(at: rootStandard, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { continue }
                while let fileURL = en.nextObject() as? URL {
                    let isSubDir = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    if isSubDir { continue }
                    let pathPrefix = rootStandard.path.hasSuffix("/") ? rootStandard.path : rootStandard.path + "/"
                    guard fileURL.path.hasPrefix(pathPrefix) else { continue }
                    let suffix = String(fileURL.path.dropFirst(pathPrefix.count))
                    let internalPath = prefixInZip + baseName + "/" + suffix
                    pairs.append((fileURL, internalPath))
                }
            } else {
                pairs.append((rootStandard, prefixInZip + baseName))
            }
        }
        return pairs
    }
}
