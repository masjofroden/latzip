//
//  SearchFieldView.swift
//  LatZip
//

import SwiftUI

/// Campo de búsqueda compacto para la barra de herramientas.
struct SearchFieldView: View {
    @Binding var text: String
    @Binding var searchEntireArchive: Bool
    let placeholder: String
    let scopeAllLabel: String
    let scopeHelp: String
    let onTextChange: () -> Void
    let onScopeChange: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(AppTypography.body)
                .frame(
                    minWidth: AppLayoutMetrics.toolbarSearchMinWidth,
                    idealWidth: AppLayoutMetrics.toolbarSearchIdealWidth,
                    maxWidth: AppLayoutMetrics.toolbarSearchMaxWidth
                )
                .layoutPriority(-1)
                .onChange(of: text) { _ in onTextChange() }
            Toggle(scopeAllLabel, isOn: $searchEntireArchive)
                .toggleStyle(.checkbox)
                .controlSize(.small)
                .font(AppTypography.caption)
                .onChange(of: searchEntireArchive) { _ in onScopeChange() }
                .help(scopeHelp)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .fill(AppColors.contentBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .strokeBorder(AppColors.hairlineBorder, lineWidth: 1)
        }
        .shadow(
            color: AppShadow.searchField.color,
            radius: AppShadow.searchField.radius,
            x: AppShadow.searchField.x,
            y: AppShadow.searchField.y
        )
    }
}
