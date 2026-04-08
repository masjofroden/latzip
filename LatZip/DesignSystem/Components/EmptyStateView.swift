//
//  EmptyStateView.swift
//  LatZip
//

import SwiftUI

/// Estado vacío centrado con icono, título y subtítulo.
struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(AppColors.textQuaternary)
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(AppTypography.emptyTitle)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, AppSpacing.lg)
            Text(subtitle)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, AppSpacing.sm)
                .frame(maxWidth: 340)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
