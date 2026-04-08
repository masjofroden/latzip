//
//  ArchiveReaderService.swift
//  LatZip
//

import Darwin
import Foundation

enum ArchiveLoadError: Error, LocalizedError {
    case needsPassword
    case listingFailed(code: Int32, detail: String)
    case emptyArchive

    var errorDescription: String? {
        switch self {
        case .needsPassword:
            return String(localized: "error.needs_password")
        case .listingFailed(let code, let detail):
            if detail.isEmpty {
                return String(format: String(localized: "error.list_code %lld"), Int64(code))
            }
            return detail
        case .emptyArchive:
            return String(localized: "error.empty_archive")
        }
    }
}

/// Lectura y volcado de índices (actor para operaciones en segundo plano).
actor ArchiveReaderService {
    func load(
        archiveURL: URL,
        passphrase: String?
    ) async throws -> (
        index: ArchiveIndex,
        rootNodes: [ArchiveNode],
        formatName: String,
        filterName: String
    ) {
        try await Task.detached(priority: .userInitiated) {
            var errBuf = [CChar](repeating: 0, count: 1024)
            var result = ArchiveListResult()
            let code: Int32 = archiveURL.path.withCString { ap in
                if let phrase = passphrase, !phrase.isEmpty {
                    return phrase.withCString { pass in
                        Int32(archive_engine_list(ap, pass, &result, &errBuf, 1024))
                    }
                }
                return Int32(archive_engine_list(ap, nil, &result, &errBuf, 1024))
            }
            let detail = errBuf.withUnsafeBufferPointer { ptr in
                String(cString: ptr.baseAddress!)
            }.trimmingCharacters(in: .whitespacesAndNewlines)
            guard code == 0 else {
                archive_engine_list_free(&result)
                let low = detail.lowercased()
                if low.contains("passphrase") || low.contains("password") || low.contains("incorrect") || low.contains("wrong") {
                    throw ArchiveLoadError.needsPassword
                }
                throw ArchiveLoadError.listingFailed(code: code, detail: detail)
            }
            defer { archive_engine_list_free(&result) }

            let count = Int(result.count)
            guard count > 0 else {
                throw ArchiveLoadError.emptyArchive
            }

            var paths: [(String, Bool, Int64, Date?, UInt32)] = []
            paths.reserveCapacity(count)
            if let base = result.entries {
                for i in 0 ..< count {
                    let info = base[i]
                    guard let cPath = info.pathname else { continue }
                    let path = String(cString: cPath)
                    guard ArchivePathSanitizer.safeInternalPath(path) else { continue }
                    let date: Date? = info.mtime_sec > 0
                        ? Date(timeIntervalSince1970: TimeInterval(info.mtime_sec))
                        : nil
                    paths.append((path, info.is_dir != 0, info.size, date, info.mode))
                }
            }

            let fmt = result.format_name.map { String(cString: $0) } ?? ""
            let flt = result.filter_name.map { String(cString: $0) } ?? ""
            guard !paths.isEmpty else {
                throw ArchiveLoadError.emptyArchive
            }
            let index = ArchiveIndex(flatPaths: paths)
            let tree = ArchiveTreeBuilder.buildTree(fromPaths: paths)
            return (index, tree, fmt, flt)
        }.value
    }
}
