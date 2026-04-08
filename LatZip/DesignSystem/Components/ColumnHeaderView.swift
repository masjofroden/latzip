//
//  ColumnHeaderView.swift
//  LatZip
//

import SwiftUI

/// Botón de cabecera ordenable. Sin `maxHeight: .infinity` (provocaba filas de header gigantes en el `VStack`).
struct ColumnHeaderView: View {
    let title: String
    let sortChevronLeading: Bool
    let isSortActive: Bool
    let sortAscending: Bool
    let helpText: String
    let contentAlignment: Alignment
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button {
            withAnimation(AppAnimation.quick) {
                action()
            }
        } label: {
            Group {
                if sortChevronLeading {
                    HStack(spacing: AppSpacing.xs) {
                        if isSortActive { sortChevron }
                        Text(title)
                            .lineLimit(1)
                    }
                } else {
                    HStack(spacing: AppSpacing.xs) {
                        Text(title)
                            .lineLimit(1)
                        if isSortActive { sortChevron }
                    }
                }
            }
            .font(AppTypography.columnHeader)
            .foregroundStyle(labelForeground)
            .frame(maxWidth: .infinity, alignment: contentAlignment)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .fill(isHovered ? AppColors.crumbIdleFill : Color.clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Altura intrínseca del label; no expandir en vertical dentro del `HStack` del header.
        .fixedSize(horizontal: false, vertical: true)
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
