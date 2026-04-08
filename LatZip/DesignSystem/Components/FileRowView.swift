//
//  FileRowView.swift
//  LatZip
//

import SwiftUI

/// Fila de archivo: solo presentación; gestos y menú los añade el contenedor.
struct FileRowView: View {
    let name: String
    let isFolder: Bool
    let sizeText: String
    let compressedText: String
    let modifiedText: String
    let colSize: CGFloat
    let colCompressed: CGFloat
    let colModified: CGFloat
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .fill(rowFill)
                .padding(.horizontal, AppLayoutMetrics.fileListRowInset)
                .padding(.vertical, 2)
                .animation(AppAnimation.quick, value: isSelected)
                .animation(AppAnimation.quick, value: isHovered)

            HStack(alignment: .center, spacing: AppLayoutMetrics.fileListColumnGutter) {
                HStack(alignment: .center, spacing: AppSpacing.md) {
                    FileTypeIcon(name: name, isFolder: isFolder, size: AppLayoutMetrics.fileListIconColumnWidth)
                    Text(name)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, AppLayoutMetrics.fileListLeading)

                Text(sizeText)
                    .font(AppTypography.metadata)
                    .monospacedDigit()
                    .foregroundStyle(isFolder ? AppColors.textSecondary : AppColors.textPrimary)
                    .frame(width: colSize, alignment: .trailing)

                Text(compressedText)
                    .font(AppTypography.metadata)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: colCompressed, alignment: .trailing)

                Text(modifiedText)
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: colModified, alignment: .trailing)
                    .padding(.trailing, AppLayoutMetrics.fileListLeading)
            }
            .padding(.vertical, AppLayoutMetrics.fileListRowVertical)
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.28), lineWidth: 1)
                    .padding(.horizontal, AppLayoutMetrics.fileListRowInset)
                    .padding(.vertical, 2)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .bottomLeading) {
            Rectangle()
                .fill(AppColors.rowSeparator)
                .frame(height: 1)
                .padding(.leading, AppLayoutMetrics.fileListLeading + AppLayoutMetrics.fileListRowInset)
        }
    }

    private var rowFill: Color {
        if isSelected { return AppColors.rowSelection }
        if isHovered { return AppColors.rowHover }
        return .clear
    }
}
