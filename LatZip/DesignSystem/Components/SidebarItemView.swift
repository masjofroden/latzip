//
//  SidebarItemView.swift
//  LatZip
//

import SwiftUI

/// Fila del sidebar (recientes / favoritos): icono alineado + título + selección suave.
struct SidebarItemView: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isActive ? Color.accentColor : AppColors.textSecondary)
                    .frame(width: AppLayoutMetrics.sidebarIconColumn, alignment: .center)
                Text(title)
                    .font(AppTypography.body)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .fill(AppColors.accentSoft)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .appPointerHover()
    }
}
