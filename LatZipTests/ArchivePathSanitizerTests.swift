//
//  ArchivePathSanitizerTests.swift
//  LatZipTests
//

@testable import LatZip
import XCTest

final class ArchivePathSanitizerTests: XCTestCase {
    func testSafeInternalPath_acceptsNormalRelative() {
        XCTAssertTrue(ArchivePathSanitizer.safeInternalPath("folder/file.txt"))
        XCTAssertTrue(ArchivePathSanitizer.safeInternalPath("a/b/c"))
    }

    func testSafeInternalPath_rejectsAbsolute() {
        XCTAssertFalse(ArchivePathSanitizer.safeInternalPath("/etc/passwd"))
    }

    func testSafeInternalPath_rejectsDotDotComponent() {
        XCTAssertFalse(ArchivePathSanitizer.safeInternalPath("../secret"))
        XCTAssertFalse(ArchivePathSanitizer.safeInternalPath("a/../../b"))
    }

    func testSafeInternalPath_rejectsEmptyAfterTrim() {
        XCTAssertFalse(ArchivePathSanitizer.safeInternalPath(""))
        XCTAssertFalse(ArchivePathSanitizer.safeInternalPath("///"))
    }

    func testResolvedDestinationURL_keepBoth() {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        var existsCall = 0
        let url = ArchivePathSanitizer.resolvedDestinationURL(
            baseName: "file.txt",
            directory: dir,
            policy: .keepBoth,
            fsExists: { u in
                existsCall += 1
                return u.lastPathComponent == "file.txt" && existsCall == 1
            }
        )
        XCTAssertEqual(url?.lastPathComponent, "file (1).txt")
    }

    func testResolvedDestinationURL_skipWhenExists() {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let url = ArchivePathSanitizer.resolvedDestinationURL(
            baseName: "exists.bin",
            directory: dir,
            policy: .skip,
            fsExists: { _ in true }
        )
        XCTAssertNil(url)
    }

    func testResolvedDestinationURL_replace() {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let url = ArchivePathSanitizer.resolvedDestinationURL(
            baseName: "out.dat",
            directory: dir,
            policy: .replace,
            fsExists: { _ in true }
        )
        XCTAssertEqual(url?.lastPathComponent, "out.dat")
    }
}
