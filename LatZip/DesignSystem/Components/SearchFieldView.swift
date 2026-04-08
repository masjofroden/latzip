//
//  SearchFieldView.swift
//  LatZip
//

import SwiftUI

/// Campo de búsqueda compacto para la barra de herramientas.
struct SearchFieldView: View {
    @Binding var text: String
    @Binding var searchEntireArchive: Bool
    @Binding var searchUsesRegex: Bool
    @Binding var searchMinSizeMBText: String
    @Binding var searchMaxSizeMBText: String
    let searchRegexInvalid: Bool
    let placeholder: String
    let scopeAllLabel: String
    let scopeHelp: String
    let onTextChange: () -> Void
    let onScopeChange: () -> Void

    @State private var showFilters = false

    /// Opciones avanzadas (regex, alcance, tamaño) van al popover para no saturar la toolbar de macOS
    /// y evitar solapamientos con el título de ventana cuando hay muchos botones.
    private var toolbarSearchHasExtras: Bool {
        searchUsesRegex || searchEntireArchive
            || !searchMinSizeMBText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !searchMaxSizeMBText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
            Button {
                showFilters = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 13, weight: .medium))
                    if toolbarSearchHasExtras || searchRegexInvalid {
                        Circle()
                            .fill(searchRegexInvalid ? Color.orange : Color.accentColor)
                            .frame(width: 6, height: 6)
                            .offset(x: 3, y: -2)
                    }
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColors.textSecondary)
            .popover(isPresented: $showFilters, arrowEdge: .bottom) {
                searchFiltersPopover
            }
            .help(String(localized: "search.filters_help"))
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

    private var searchFiltersPopover: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(String(localized: "search.filters_title"))
                .font(AppTypography.bodyMedium)
            Toggle(String(localized: "search.regex_short"), isOn: $searchUsesRegex)
                .toggleStyle(.checkbox)
                .controlSize(.small)
                .onChange(of: searchUsesRegex) { _ in onTextChange() }
                .help(String(localized: "search.regex_help"))
            if searchRegexInvalid {
                Label(String(localized: "search.regex_invalid_help"), systemImage: "exclamationmark.triangle.fill")
                    .font(AppTypography.caption)
                    .foregroundStyle(.orange)
            }
            Toggle(scopeAllLabel, isOn: $searchEntireArchive)
                .toggleStyle(.checkbox)
                .controlSize(.small)
                .onChange(of: searchEntireArchive) { _ in onScopeChange() }
                .help(scopeHelp)
            Text(String(localized: "search.filters_size_hint"))
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            HStack {
                Text(String(localized: "search.min_mb"))
                    .frame(width: 88, alignment: .leading)
                TextField("—", text: $searchMinSizeMBText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onChange(of: searchMinSizeMBText) { _ in onTextChange() }
            }
            HStack {
                Text(String(localized: "search.max_mb"))
                    .frame(width: 88, alignment: .leading)
                TextField("—", text: $searchMaxSizeMBText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onChange(of: searchMaxSizeMBText) { _ in onTextChange() }
            }
        }
        .padding(AppSpacing.lg)
        .frame(minWidth: 280)
    }
}
