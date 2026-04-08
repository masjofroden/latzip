//
//  ColumnHeaderView.swift
//  LatZip
//

import SwiftUI

/// Cabecera de columna ordenable en la lista de archivos.
struct ColumnHeaderView: View {
    let title: String
    let trailing: Bool
    let isSortActive: Bool
    let sortAscending: Bool
    let helpText: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button {
            withAnimation(AppAnimation.quick) {
                action()
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if trailing { Spacer(minLength: 0) }
                if isSortActive && trailing {
                    sortChevron
                }
                Text(title)
                if isSortActive && !trailing {
                    sortChevron
                }
                if !trailing { Spacer(minLength: 0) }
            }
            .font(AppTypography.columnHeader)
            .foregroundStyle(labelForeground)
            .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .leading)
            .padding(.vertical, AppSpacing.sm)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .fill(isHovered ? AppColors.crumbIdleFill : Color.clear)
            }
        }
        .buttonStyle(.plain)
        .help(helpText)
        .onHover { isHovered = $0 }
        .animation(AppAnimation.quick, value: isHovered)
    }

    private var labelForeground: Color {
        if isSortActive { return AppColors.textPrimary }
        return AppColors.textSecondary
    }

    private var sortChevron: some View {
        Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
            .font(AppTypography.columnChevron)
            .foregroundStyle(isSortActive ? AppColors.textPrimary.opacity(0.75) : AppColors.textSecondary.opacity(0.85))
    }
}
