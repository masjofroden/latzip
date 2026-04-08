//
//  ArchiveExtractionServiceTests.swift
//  LatZipTests
//

@testable import LatZip
import XCTest

final class ArchiveExtractionServiceTests: XCTestCase {
    func testDestinationCollisionsExist_detectsExistingFile() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(
            "latzip-collision-test-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let existing = dir.appendingPathComponent("a/b.txt")
        try FileManager.default.createDirectory(at: existing.deletingLastPathComponent(), withIntermediateDirectories: true)
        XCTAssertTrue(FileManager.default.createFile(atPath: existing.path, contents: Data("x".utf8)))

        let rec = ArchiveEntryRecord(
            name: "b.txt",
            fullPath: "a/b.txt",
            parentPath: "a",
            isFolder: false,
            byteSize: 1,
            modified: nil,
            permissionsMode: 0
        )
        XCTAssertTrue(
            ArchiveExtractionService.destinationCollisionsExist(files: [rec], destinationDirectory: dir)
        )
    }

    func testDestinationCollisionsExist_falseWhenClear() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(
            "latzip-collision-clear-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let rec = ArchiveEntryRecord(
            name: "only.txt",
            fullPath: "only.txt",
            parentPath: "",
            isFolder: false,
            byteSize: 0,
            modified: nil,
            permissionsMode: 0
        )
        XCTAssertFalse(
            ArchiveExtractionService.destinationCollisionsExist(files: [rec], destinationDirectory: dir)
        )
    }
}
