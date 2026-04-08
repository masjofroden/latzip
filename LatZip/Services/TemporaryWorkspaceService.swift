//
//  TemporaryWorkspaceService.swift
//  LatZip
//

import Foundation

/// Caché de ficheros extraídos para Quick Look (por archivo + entrada).
actor TemporaryWorkspaceService {
    private var pathByKey: [String: URL] = [:]
    private var keysByArchivePath: [String: Set<String>] = [:]
    private let fm = FileManager.default

    private func cacheKey(archive: URL, entryPath: String, passphrase: String?) -> String {
        var hasher = Hasher()
        hasher.combine(archive.path)
        hasher.combine(entryPath)
        hasher.combine(passphrase ?? "")
        return String(hasher.finalize())
    }

    func previewFileURL(
        archiveURL: URL,
        entryPath: String,
        passphrase: String?
    ) async throws -> URL {
        let key = cacheKey(archive: archiveURL, entryPath: entryPath, passphrase: passphrase)
        if let existing = pathByKey[key], fm.fileExists(atPath: existing.path) {
            return existing
        }
        let dir = fm.temporaryDirectory.appendingPathComponent("latzip-\(key)", isDirectory: true)
        if fm.fileExists(atPath: dir.path) {
            try? fm.removeItem(at: dir)
        }
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let safeName = (entryPath as NSString).lastPathComponent.replacingOccurrences(of: "/", with: "_")
        let dest = dir.appendingPathComponent(safeName.isEmpty ? "entry" : safeName)

        var errBuf = [CChar](repeating: 0, count: 1024)
        let rc: Int32 = archiveURL.path.withCString { arch in
            entryPath.withCString { inner in
                dest.path.withCString { outp in
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
            try? fm.removeItem(at: dir)
            let msg = errBuf.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
            throw TemporaryWorkspaceError.extractionFailed(msg)
        }
        pathByKey[key] = dest
        keysByArchivePath[archiveURL.path, default: []].insert(key)
        return dest
    }

    func invalidate(archiveURL: URL) {
        guard let keys = keysByArchivePath.removeValue(forKey: archiveURL.path) else { return }
        for k in keys {
            if let u = pathByKey.removeValue(forKey: k) {
                try? fm.removeItem(at: u.deletingLastPathComponent())
            }
        }
    }

    func purgeSessionCache() {
        for (_, u) in pathByKey {
            try? fm.removeItem(at: u.deletingLastPathComponent())
        }
        pathByKey.removeAll()
        keysByArchivePath.removeAll()
    }
}

enum TemporaryWorkspaceError: Error {
    case extractionFailed(String)
}
