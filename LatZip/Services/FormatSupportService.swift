//
//  FormatSupportService.swift
//  LatZip
//

import Foundation

enum FormatSupportService {
    static func capabilities(for url: URL, formatName: String, filterName: String) -> ArchiveFormatCapabilities {
        let path = url.path
        let editable = archive_engine_is_editable_archive_path(path) != 0
        let zipPass = archive_engine_is_zip_extension(path) != 0
        return ArchiveFormatCapabilities(
            formatName: formatName,
            filterName: filterName,
            supportsEditing: editable,
            supportsZipPassphrase: zipPass
        )
    }
}
