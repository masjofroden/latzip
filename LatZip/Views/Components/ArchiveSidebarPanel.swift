//
//  ArchiveSidebarPanel.swift
//  LatZip
//

import SwiftUI

/// Sidebar translúcido: recientes, favoritos y árbol del archivo.
struct ArchiveSidebarPanel: View {
    @EnvironmentObject private var app: ArchiveAppState
    @ObservedObject var viewModel: ArchiveWorkspaceViewModel

    var body: some View {
        List {
            if !app.recentURLs.isEmpty {
                SidebarSectionView(title: String(localized: "sidebar.recents"), systemImage: "clock") {
                    ForEach(app.recentURLs, id: \.path) { url in
                        SidebarItemView(
                            title: url.lastPathComponent,
                            systemImage: "clock.arrow.circlepath",
                            isActive: url.standardizedFileURL == viewModel.archiveURL.standardizedFileURL
                        ) {
                            app.openRecent(url)
                        }
                        .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.lg, bottom: AppSpacing.xs, trailing: AppSpacing.lg))
                    }
                }
            }

            if !app.favoriteURLs.isEmpty {
                SidebarSectionView(title: String(localized: "sidebar.favorites"), systemImage: "star") {
                    ForEach(app.favoriteURLs, id: \.path) { url in
                        SidebarItemView(
                            title: url.lastPathComponent,
                            systemImage: "star.fill",
                            isActive: url.standardizedFileURL == viewModel.archiveURL.standardizedFileURL
                        ) {
                            app.openRecent(url)
                        }
                        .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.lg, bottom: AppSpacing.xs, trailing: AppSpacing.lg))
                        .contextMenu {
                            Button(String(localized: "sidebar.favorite_remove")) {
                                app.toggleFavorite(url)
                            }
                        }
                    }
                }
            }

            SidebarSectionView(title: String(localized: "sidebar.structure"), systemImage: "rectangle.split.3x1") {
                OutlineGroup(viewModel.rootNodes, children: \.children) { node in
                    Group {
                        if node.isFolder {
                            Button {
                                withAnimation(AppAnimation.standard) {
                                    viewModel.selectFolder(path: node.fullPath)
                                }
                            } label: {
                                Label(node.name, systemImage: "folder.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .font(AppTypography.body)
                            }
                            .buttonStyle(.plain)
                            .frame(minHeight: AppLayoutMetrics.sidebarItemMinHeight, alignment: .leading)
                            .contentShape(Rectangle())
                            .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
                            .appPointerHover()
                        } else {
                            Label(node.name, systemImage: sidebarLeafIcon(for: node))
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)
                                .symbolRenderingMode(.hierarchical)
                                .frame(minHeight: AppLayoutMetrics.sidebarItemMinHeight, alignment: .leading)
                                .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
                        }
                    }
                }
                .animation(AppAnimation.standard, value: viewModel.browseFolderPath)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Rectangle()
                    .fill(CuratorDesignTokens.sidebarMaterial)
                LinearGradient(
                    colors: [AppColors.sidebarGradientTop, Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
        }
        .navigationTitle(viewModel.displayTitle)
        .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
    }

    private func sidebarLeafIcon(for node: ArchiveNode) -> String {
        if node.isNestedArchiveCandidate { return "doc.zipper" }
        return "doc"
    }
}
