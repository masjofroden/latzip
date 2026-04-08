//
//  ArchiveExtractionService.swift
//  LatZip
//

import Foundation

enum ArchiveExtractionError: Error, LocalizedError {
    case cancelled
    case engineFailed(path: String, detail: String)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return String(localized: "error.extraction_cancelled")
        case .engineFailed(_, let detail):
            return detail
        }
    }
}

/// Extracción con política de colisión por fichero; cancelable vía `Task.checkCancellation()`.
struct ArchiveExtractionService: Sendable {
    /// `true` si alguna ruta de destino «lógica» (sin renombrado) ya existe en disco — motivo para preguntar al usuario.
    static func destinationCollisionsExist(
        files: [ArchiveEntryRecord],
        destinationDirectory: URL
    ) -> Bool {
        let fm = FileManager.default
        for file in files {
            let rel = file.fullPath
            guard ArchivePathSanitizer.safeInternalPath(rel) else { continue }
            let destFile = destinationDirectory.appendingPathComponent(rel)
            if fm.fileExists(atPath: destFile.path) {
                return true
            }
        }
        return false
    }

    static func expandForExtraction(selectedPaths: [String], index: ArchiveIndex) -> [ArchiveEntryRecord] {
        var seen = Set<String>()
        var out: [ArchiveEntryRecord] = []
        for p in selectedPaths {
            guard let rec = index.record(forFullPath: p) else { continue }
            if rec.isFolder {
                for f in index.files(underFolder: rec.fullPath) where !seen.contains(f.fullPath) {
                    seen.insert(f.fullPath)
                    out.append(f)
                }
            } else if !seen.contains(rec.fullPath) {
                seen.insert(rec.fullPath)
                out.append(rec)
            }
        }
        return out
    }

    static func extract(
        files: [ArchiveEntryRecord],
        archiveURL: URL,
        passphrase: String?,
        destinationDirectory: URL,
        options: ExtractionOptions,
        progress: Progress,
        onFileStart: (@Sendable (_ index1Based: Int, _ displayName: String) -> Void)? = nil
    ) async throws -> Int {
        let total = files.count
        progress.totalUnitCount = Int64(max(1, total))
        progress.completedUnitCount = 0

        let fm = FileManager.default
        var errBuf = [CChar](repeating: 0, count: 1024)
        var count = 0
        for (i, file) in files.enumerated() {
            try Task.checkCancellation()
            progress.completedUnitCount = Int64(i)
            onFileStart?(i + 1, file.name)

            let rel = file.fullPath
            let destFile = destinationDirectory.appendingPathComponent(rel)
            try fm.createDirectory(at: destFile.deletingLastPathComponent(), withIntermediateDirectories: true)

            let parentDir = destFile.deletingLastPathComponent()
            let baseName = destFile.lastPathComponent
            let policy = options.collisionPolicy

            guard let finalURL = ArchivePathSanitizer.resolvedDestinationURL(
                baseName: baseName,
                directory: parentDir,
                policy: policy,
                fsExists: { u in fm.fileExists(atPath: u.path) }
            ) else { continue }

            if policy == .replace, fm.fileExists(atPath: destFile.path) {
                try? fm.removeItem(at: destFile)
            }

            let targetPath = policy == .replace ? destFile.path : finalURL.path

            let rc: Int32 = archiveURL.path.withCString { arch in
                rel.withCString { inner in
                    targetPath.withCString { outp in
                        if let phrase = passphrase, !phrase.isEmpty {
                            return phrase.withCString { pass in
                                Int32(archive_engine_extract_file_to_path(arch, pass, inner, outp, &errBuf, 1024))
                            }
                        }
                        return Int32(archive_engine_extract_file_to_path(arch, nil, inner, outp, &errBuf, 1024))
                    }
                }
            }

            guard rc == 0 else {
                let msg = errBuf.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
                throw ArchiveExtractionError.engineFailed(
                    path: rel,
                    detail: msg.isEmpty ? String(localized: "error.extract_generic") : msg
                )
            }
            count += 1
        }
        progress.completedUnitCount = Int64(total)
        return count
    }

    static func extractFolderSubtree(
        folderPath: String,
        archiveURL: URL,
        passphrase: String?,
        destinationDirectory: URL
    ) async throws {
        var errBuf = [CChar](repeating: 0, count: 1024)
        let rc: Int32 = archiveURL.path.withCString { arch in
            folderPath.withCString { sel in
                destinationDirectory.path.withCString { out in
                    if let phrase = passphrase, !phrase.isEmpty {
                        return phrase.withCString { pass in
                            Int32(archive_engine_extract_selection(arch, pass, sel, 1, out, &errBuf, 1024))
                        }
                    }
                    return Int32(archive_engine_extract_selection(arch, nil, sel, 1, out, &errBuf, 1024))
                }
            }
        }
        guard rc == 0 else {
            let msg = errBuf.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
            throw ArchiveExtractionError.engineFailed(path: folderPath, detail: msg)
        }
    }

    /// Exporta la selección (o la fila arrastrada) a rutas bajo una carpeta temporal para `NSItemProvider` / arrastre al Finder.
    static func exportTemporaryRootForDrag(
        records: [ArchiveEntryRecord],
        archiveURL: URL,
        passphrase: String?
    ) async throws -> URL {
        guard !records.isEmpty else {
            throw ArchiveExtractionError.engineFailed(path: "", detail: String(localized: "error.drag_empty"))
        }
        return try await Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            let root = fm.temporaryDirectory.appendingPathComponent(
                "latzip-drag-\(UUID().uuidString)",
                isDirectory: true
            )
            try fm.createDirectory(at: root, withIntermediateDirectories: true)

            if records.count == 1, let only = records.first {
                if only.isFolder {
                    let destDir = root.appendingPathComponent(only.fullPath, isDirectory: true)
                    try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
                    try await extractFolderSubtree(
                        folderPath: only.fullPath,
                        archiveURL: archiveURL,
                        passphrase: passphrase,
                        destinationDirectory: destDir
                    )
                    return destDir
                }
                let destFile = root.appendingPathComponent(only.fullPath)
                try fm.createDirectory(at: destFile.deletingLastPathComponent(), withIntermediateDirectories: true)
                try extractSingleFileSync(
                    archiveURL: archiveURL,
                    passphrase: passphrase,
                    entryPath: only.fullPath,
                    destinationFile: destFile
                )
                return destFile
            }

            for rec in records {
                if rec.isFolder {
                    let destDir = root.appendingPathComponent(rec.fullPath, isDirectory: true)
                    try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
                    try await extractFolderSubtree(
                        folderPath: rec.fullPath,
                        archiveURL: archiveURL,
                        passphrase: passphrase,
                        destinationDirectory: destDir
                    )
                } else {
                    let destFile = root.appendingPathComponent(rec.fullPath)
                    try fm.createDirectory(at: destFile.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try extractSingleFileSync(
                        archiveURL: archiveURL,
                        passphrase: passphrase,
                        entryPath: rec.fullPath,
                        destinationFile: destFile
                    )
                }
            }
            return root
        }.value
    }

    private static func extractSingleFileSync(
        archiveURL: URL,
        passphrase: String?,
        entryPath: String,
        destinationFile: URL
    ) throws {
        var errBuf = [CChar](repeating: 0, count: 1024)
        let rc: Int32 = archiveURL.path.withCString { arch in
            entryPath.withCString { inner in
                destinationFile.path.withCString { outp in
                    if let phrase = passphrase, !phrase.isEmpty {
                        return phrase.withCString { pass in
                            Int32(archive_engine_extract_file_to_path(arch, pass, inner, outp, &errBuf, 1024))
                        }
                    }
                    return Int32(archive_engine_extract_file_to_path(arch, nil, inner, outp, &errBuf, 1024))
                }
            }
        }
        guard rc == 0 else {
            let msg = errBuf.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
            throw ArchiveExtractionError.engineFailed(
                path: entryPath,
                detail: msg.isEmpty ? String(localized: "error.extract_generic") : msg
            )
        }
    }
}
