//
//  ArchiveEngineIntegrationTests.swift
//  LatZipTests
//

@testable import LatZip
import XCTest

/// Comprobaciones del puente C sin I/O de archivos.
final class ArchiveEnginePathTests: XCTestCase {
    func testEditableArchiveSuffixes() {
        XCTAssertEqual(archive_engine_is_editable_archive_path("/tmp/x.zip"), 1)
        XCTAssertEqual(archive_engine_is_editable_archive_path("/tmp/archive.tar.gz"), 1)
        XCTAssertEqual(archive_engine_is_editable_archive_path("/tmp/y.7z"), 1)
        XCTAssertEqual(archive_engine_is_editable_archive_path("/tmp/z.TAR.XZ"), 1)
    }

    func testNonEditablePaths() {
        XCTAssertEqual(archive_engine_is_editable_archive_path("/tmp/a.rar"), 0)
        XCTAssertEqual(archive_engine_is_editable_archive_path("/tmp/b.iso"), 0)
    }

    func testZipExtensionOnlyForPassphrase() {
        XCTAssertEqual(archive_engine_is_zip_extension("/c/f.zip"), 1)
        XCTAssertEqual(archive_engine_is_zip_extension("/c/f.ZIP"), 1)
        XCTAssertEqual(archive_engine_is_zip_extension("/c/f.tar.gz"), 0)
    }
}

/// Lista un ZIP creado con `/usr/bin/zip` (sin usar `ArchiveWriterService`).
@MainActor
final class ArchiveZipCLIReaderTests: XCTestCase {
    func testReaderListsZipFromSystemZipCLI() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("latzip-cli-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let inner = root.appendingPathComponent("payload.txt")
        try "LatZip integration".write(to: inner, atomically: true, encoding: .utf8)
        let zipURL = root.appendingPathComponent("from-cli.zip")

        guard FileManager.default.fileExists(atPath: "/usr/bin/zip") else {
            throw XCTSkip("/usr/bin/zip no disponible en este entorno")
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        proc.arguments = ["-jq", zipURL.path, inner.path]
        try proc.run()
        proc.waitUntilExit()
        XCTAssertEqual(proc.terminationStatus, 0, "zip CLI should succeed")

        let reader = ArchiveReaderService()
        let loaded = try await reader.load(archiveURL: zipURL, passphrase: nil)
        let files = loaded.index.allRecords.filter { !$0.isFolder }
        XCTAssertFalse(files.isEmpty, "expected at least one file entry")
        XCTAssertTrue(
            files.contains { $0.fullPath == "payload.txt" || $0.name == "payload.txt" },
            "paths: \(files.map(\.fullPath))"
        )
    }

    func testReaderListsTarFromSystemTarCLI() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("latzip-tar-cli-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let inner = root.appendingPathComponent("payload.txt")
        try "tar ball".write(to: inner, atomically: true, encoding: .utf8)
        let tarURL = root.appendingPathComponent("from-cli.tar")

        guard FileManager.default.fileExists(atPath: "/usr/bin/tar") else {
            throw XCTSkip("/usr/bin/tar no disponible en este entorno")
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        proc.arguments = ["cf", tarURL.path, "-C", root.path, "payload.txt"]
        try proc.run()
        proc.waitUntilExit()
        XCTAssertEqual(proc.terminationStatus, 0, "tar CLI should succeed")

        let reader = ArchiveReaderService()
        let loaded = try await reader.load(archiveURL: tarURL, passphrase: nil)
        let files = loaded.index.allRecords.filter { !$0.isFolder }
        XCTAssertFalse(files.isEmpty, "expected at least one file entry in tar")
        XCTAssertTrue(
            files.contains { $0.fullPath == "payload.txt" || $0.name == "payload.txt" },
            "paths: \(files.map(\.fullPath))"
        )
    }
}
