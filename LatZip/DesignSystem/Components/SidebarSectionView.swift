//
//  SidebarSectionView.swift
//  LatZip
//

import SwiftUI

/// Cabecera de sección del sidebar con estilo unificado.
struct SidebarSectionView<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        Section {
            content()
        } header: {
            HStack(alignment: .center, spacing: AppSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: AppLayoutMetrics.sidebarIconColumn, alignment: .center)
                Text(title)
                    .font(AppTypography.sectionHeader)
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(AppLayoutMetrics.sectionTracking)
                Spacer(minLength: 0)
            }
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.xs)
            .padding(.horizontal, AppLayoutMetrics.sidebarSectionHeaderHorizontalInset)
        }
    }
}
