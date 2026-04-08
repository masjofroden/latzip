//
//  StatusBarView.swift
//  LatZip
//

import SwiftUI

/// Barra de estado inferior: solo lectura de datos ya calculados en el view model.
struct StatusBarView: View {
    @ObservedObject var viewModel: ArchiveWorkspaceViewModel

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.md) {
            if let caps = viewModel.formatCaps {
                Text(String(format: String(localized: "status.format_line"), caps.formatName, caps.filterName))
                    .lineLimit(1)
                if let idx = viewModel.index {
                    statusDot()
                    Text(String(format: String(localized: "status.folder_items"), viewModel.listItems.count))
                    statusDot()
                    Text(String(format: String(localized: "status.folder_bytes"), folderBytesFormatted))
                    statusDot()
                    Text(String(format: String(localized: "status.entries_n"), idx.totalEntryCount))
                }
                statusDot()
                if caps.supportsEditing {
                    Label(String(localized: "status.edit_zip"), systemImage: "pencil.circle.fill")
                        .foregroundStyle(AppColors.textSecondary)
                        .symbolRenderingMode(.hierarchical)
                } else {
                    Label(String(localized: "status.edit_readonly"), systemImage: "lock.fill")
                        .foregroundStyle(AppColors.textTertiary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            Spacer(minLength: 0)
        }
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .background(.bar)
    }

    private func statusDot() -> some View {
        Text(verbatim: "·")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(AppColors.textQuaternary)
            .baselineOffset(0.5)
    }

    private var folderBytesFormatted: String {
        let sum = viewModel.listItems.filter { !$0.isFolder }.reduce(Int64(0)) { $0 + max(0, $1.byteSize) }
        return ByteCountFormatter.string(fromByteCount: sum, countStyle: .file)
    }
}
