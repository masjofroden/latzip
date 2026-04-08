//
//  FileTypeIcon.swift
//  LatZip
//

import AppKit
import SwiftUI

/// Icono del sistema según extensión; SF Symbol como respaldo.
struct FileTypeIcon: View {
    let name: String
    let isFolder: Bool
    var size: CGFloat = 18

    var body: some View {
        Group {
            if isFolder {
                Image(systemName: "folder.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppColors.textSecondary)
            } else if let img = workspaceIcon() {
                Image(nsImage: img)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Image(systemName: fallbackSymbol)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(width: size, height: size)
    }

    private var fallbackSymbol: String {
        let ext = (name as NSString).pathExtension.lowercased()
        if ArchiveNode.nestedArchiveExtensions.contains(ext) { return "doc.zipper" }
        return "doc"
    }

    private func workspaceIcon() -> NSImage? {
        let ext = (name as NSString).pathExtension
        guard !ext.isEmpty else { return nil }
        return NSWorkspace.shared.icon(forFileType: ext)
    }
}
