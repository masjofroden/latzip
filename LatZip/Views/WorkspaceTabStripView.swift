//
//  WorkspaceTabStripView.swift
//  LatZip
//
//  Pestañas bajo la barra de título (no `TabView` nativo) para no competir con la toolbar de `NavigationSplitView`.
//

import SwiftUI

struct WorkspaceTabStripView: View {
    @EnvironmentObject private var app: ArchiveAppState

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(app.workspaces) { ws in
                        WorkspaceTabPill(
                            title: ws.displayTitle,
                            isSelected: app.selectedWorkspaceId == ws.id,
                            onSelect: {
                                app.selectedWorkspaceId = ws.id
                            },
                            onClose: {
                                app.closeWorkspace(ws)
                            }
                        )
                        .id(ws.id)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
            }
            .background(AppColors.panelBackground)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppColors.separator)
                    .frame(height: 1)
            }
            .onChange(of: app.selectedWorkspaceId) { newId in
                guard let newId else { return }
                withAnimation(AppAnimation.quick) {
                    proxy.scrollTo(newId, anchor: .center)
                }
            }
        }
        .frame(height: 44)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "tabs.strip.accessibility"))
    }
}

private struct WorkspaceTabPill: View {
    let title: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            Button(action: onSelect) {
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(AppTypography.metadata)
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                    .frame(maxWidth: 200, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
            .help(String(localized: "toolbar.close_tab_help"))
            .accessibilityLabel(String(localized: "tabs.close.accessibility"))
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .fill(isSelected ? AppColors.accentSoft : AppColors.crumbIdleFill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .strokeBorder(
                    isSelected ? Color.accentColor.opacity(0.38) : AppColors.hairlineBorder,
                    lineWidth: 1
                )
        }
    }
}
