//
//  FileRowView.swift
//  LatZip
//

import SwiftUI

/// Fila de archivo: misma grilla que el header; altura fija.
struct FileRowView: View {
    let name: String
    let isFolder: Bool
    let sizeText: String
    let typeText: String
    let modifiedText: String
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .fill(rowFill)
                .padding(.horizontal, AppLayoutMetrics.fileListRowInset)
                .padding(.vertical, 2)

            FileListTableColumns.row(
                icon: FileTypeIcon(name: name, isFolder: isFolder, size: AppLayoutMetrics.fileListIconColumnWidth),
                name: {
                    Text(name)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                },
                size: {
                    Text(sizeText)
                        .font(AppTypography.metadata)
                        .monospacedDigit()
                        .foregroundStyle(isFolder ? AppColors.textSecondary : AppColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                },
                type: {
                    Text(typeText)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                },
                modified: {
                    Text(modifiedText)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.85)
                }
            )
            .padding(.vertical, 4)
        }
        .frame(height: AppLayoutMetrics.fileListRowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(AppAnimation.quick, value: isSelected)
        .animation(AppAnimation.quick, value: isHovered)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .strokeBorder(CuratorDesignTokens.accentBlue.opacity(0.35), lineWidth: 1)
                    .padding(.horizontal, AppLayoutMetrics.fileListRowInset)
                    .padding(.vertical, 2)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.rowSeparator)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityAddTraits(isFolder ? [.isButton] : [])
    }

    private var accessibilitySummary: String {
        let role = isFolder ? String(localized: "a11y.role_folder") : String(localized: "a11y.role_file")
        let mod = modifiedText.isEmpty
            ? ""
            : String(format: String(localized: "a11y.modified_suffix"), modifiedText)
        return "\(name), \(role), \(sizeText), \(typeText)\(mod)"
    }

    private var rowFill: Color {
        if isSelected { return CuratorDesignTokens.accentBlue.opacity(0.18) }
        if isHovered { return AppColors.rowHover }
        return .clear
    }
}
