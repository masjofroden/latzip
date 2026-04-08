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
            Label(title, systemImage: systemImage)
                .font(AppTypography.sectionHeader)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(AppLayoutMetrics.sectionTracking)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xs)
        }
    }
}
