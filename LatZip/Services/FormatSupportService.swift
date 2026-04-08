//
//  FormatSupportService.swift
//  LatZip
//

import Foundation

enum FormatSupportService {
    static func capabilities(for url: URL, formatName: String, filterName: String) -> ArchiveFormatCapabilities {
        let zip = url.pathExtension.lowercased() == "zip"
        return ArchiveFormatCapabilities(
            formatName: formatName,
            filterName: filterName,
            supportsEditing: zip
        )
    }
}
