//
//  PanelCardView.swift
//  LatZip
//

import SwiftUI

/// Contenedor elevado para el panel lateral (preview / inspector).
struct PanelCardView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .fill(.regularMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .strokeBorder(AppColors.hairlineBorder, lineWidth: 1)
            }
            .shadow(
                color: AppShadow.panel.color,
                radius: AppShadow.panel.radius,
                x: AppShadow.panel.x,
                y: AppShadow.panel.y
            )
            .padding(AppSpacing.md)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primary.opacity(0.11),
                                Color.primary.opacity(0.04),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 1)
                    .padding(.vertical, AppSpacing.xl)
                    .padding(.leading, AppSpacing.xs)
                    .allowsHitTesting(false)
            }
    }
}
