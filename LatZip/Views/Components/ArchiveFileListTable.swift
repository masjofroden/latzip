//
//  ArchiveFileListTable.swift
//  LatZip
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Lista en columnas: cabecera fija (altura fija) + `ScrollView` + `LazyVStack`; columnas vía `FileListTableColumns.row`.
struct ArchiveFileListTable: View {
    @ObservedObject var viewModel: ArchiveWorkspaceViewModel
    @EnvironmentObject private var app: ArchiveAppState

    @State private var hoveredRowID: ArchiveEntryRecord.ID?
    @State private var shiftAnchorIndex: Int?

    private let sortHelp = String(localized: "toolbar.sort.help")

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingState
            } else if viewModel.index == nil {
                EmptyStateView(
                    title: String(localized: "empty.not_loaded_title"),
                    subtitle: String(localized: "empty.not_loaded_subtitle"),
                    systemImage: "tray"
                )
            } else if viewModel.listItems.isEmpty {
                emptyFolderState
            } else if viewModel.fileListUsesGridLayout {
                CuratorFileGridView(viewModel: viewModel)
            } else {
                fileListStack
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.contentBackground)
        .animation(AppAnimation.standard, value: viewModel.isLoading)
        .animation(AppAnimation.standard, value: viewModel.listItems.count)
        .onChange(of: viewModel.browseFolderPath) { _ in
            shiftAnchorIndex = nil
        }
    }

    private var emptyFolderState: some View {
        EmptyStateView(
            title: String(localized: "empty.no_files_title"),
            subtitle: viewModel.searchText.isEmpty
                ? String(localized: "empty.no_files_subtitle")
                : String(localized: "empty.search_no_results"),
            systemImage: viewModel.searchText.isEmpty ? "folder" : "magnifyingglass"
        )
        .padding(AppSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var loadingState: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .controlSize(.large)
            Text(String(localized: "state.loading_archive"))
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            FileListSkeletonView()
                .frame(maxWidth: 480)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(AppSpacing.xxl)
    }

    private var fileListStack: some View {
        VStack(spacing: 0) {
            fixedColumnHeader
                .frame(height: AppLayoutMetrics.fileListHeaderHeight)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.listItems.enumerated()), id: \.1.id) { index, item in
                        fileRow(index: index, item: item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var fixedColumnHeader: some View {
        FileListTableColumns.row(
            icon: Color.clear
                .frame(
                    width: AppLayoutMetrics.fileListIconColumnWidth,
                    height: AppLayoutMetrics.fileListIconColumnWidth
                )
                .accessibilityHidden(true),
            name: {
                ColumnHeaderView(
                    title: String(localized: "col.name"),
                    sortChevronLeading: false,
                    isSortActive: viewModel.columnSort == .name,
                    sortAscending: viewModel.sortAscending,
                    helpText: sortHelp,
                    contentAlignment: .leading,
                    action: { viewModel.setSort(column: .name, ascending: nil) }
                )
            },
            size: {
                ColumnHeaderView(
                    title: String(localized: "col.size"),
                    sortChevronLeading: true,
                    isSortActive: viewModel.columnSort == .size,
                    sortAscending: viewModel.sortAscending,
                    helpText: sortHelp,
                    contentAlignment: .trailing,
                    action: { viewModel.setSort(column: .size, ascending: nil) }
                )
            },
            type: {
                ColumnHeaderView(
                    title: String(localized: "col.type"),
                    sortChevronLeading: true,
                    isSortActive: viewModel.columnSort == .kind,
                    sortAscending: viewModel.sortAscending,
                    helpText: sortHelp,
                    contentAlignment: .leading,
                    action: { viewModel.setSort(column: .kind, ascending: nil) }
                )
            },
            modified: {
                ColumnHeaderView(
                    title: String(localized: "col.modified"),
                    sortChevronLeading: true,
                    isSortActive: viewModel.columnSort == .modified,
                    sortAscending: viewModel.sortAscending,
                    helpText: sortHelp,
                    contentAlignment: .leading,
                    action: { viewModel.setSort(column: .modified, ascending: nil) }
                )
            }
        )
        .padding(.vertical, 4)
        .background { AppColors.listHeaderTint }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.separatorStrong)
                .frame(height: 1)
        }
        .clipped()
    }

    private func fileRow(index: Int, item: ArchiveEntryRecord) -> some View {
        let isSelected = viewModel.selection.contains(item.id)
        let isHovered = hoveredRowID == item.id
        let modifiedText: String = {
            if let d = item.modified {
                return d.formatted(date: .abbreviated, time: .shortened)
            }
            return "—"
        }()

        return FileRowView(
            name: item.name,
            isFolder: item.isFolder,
            sizeText: sizeCell(item),
            typeText: item.curatorTypeLabel,
            modifiedText: modifiedText,
            isSelected: isSelected,
            isHovered: isHovered
        )
        .contentShape(Rectangle())
        .onHover { inside in
            if inside {
                hoveredRowID = item.id
            } else if hoveredRowID == item.id {
                hoveredRowID = nil
            }
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded { _ in
                Task {
                    await viewModel.openOrDrillDown(item) { url, name in
                        app.openNestedChild(tempURL: url, title: name, parent: viewModel)
                    }
                }
            }
        )
        .onTapGesture {
            applySelection(for: item, at: index)
        }
        .onDrag {
            guard !viewModel.isLoading, viewModel.index != nil else {
                return NSItemProvider()
            }
            return viewModel.itemProviderForDrag(from: item)
        }
        .contextMenu { contextItems }
    }

    private func applySelection(for item: ArchiveEntryRecord, at index: Int) {
        let flags = NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.command) {
            if viewModel.selection.contains(item.id) {
                viewModel.selection.remove(item.id)
            } else {
                viewModel.selection.insert(item.id)
            }
            shiftAnchorIndex = viewModel.listItems.firstIndex(where: { $0.id == item.id })
            return
        }
        if flags.contains(.shift), let anchor = shiftAnchorIndex {
            let lo = min(anchor, index)
            let hi = max(anchor, index)
            let ids = viewModel.listItems[lo ... hi].map(\.id)
            viewModel.selection = Set(ids)
            return
        }
        viewModel.selection = [item.id]
        shiftAnchorIndex = index
    }

    private func sizeCell(_ item: ArchiveEntryRecord) -> String {
        if item.isFolder { return "—" }
        return ByteCountFormatter.string(fromByteCount: item.byteSize, countStyle: .file)
    }

    @ViewBuilder
    private var contextItems: some View {
        Button(String(localized: "menu.extract_to_folder")) {
            viewModel.extractSelected(collision: app.extractionCollisionPolicy)
        }
        .disabled(viewModel.selection.isEmpty)

        Button(String(localized: "menu.extract_here")) {
            viewModel.extractSelectedHere(collision: app.extractionCollisionPolicy)
        }
        .disabled(viewModel.selection.isEmpty)

        Button(String(localized: "menu.preview")) {
            Task {
                if let r = viewModel.firstSelectedRecord() { await viewModel.preparePreview(for: r) }
            }
        }
        .disabled(viewModel.selection.isEmpty)

        if viewModel.formatCaps?.supportsEditing == true {
            Divider()
            Button(String(localized: "menu.add_files")) {
                viewModel.addFromFinder()
            }
        }
        if viewModel.formatCaps?.supportsZipPassphrase == true {
            Divider()
            Button(String(localized: "menu.protect_zip")) {
                viewModel.presentProtectZipSheet()
            }
        }

        Divider()

        Button {
            app.toggleFavorite(viewModel.archiveURL)
        } label: {
            Label(
                app.isFavorite(viewModel.archiveURL)
                    ? String(localized: "menu.remove_favorite")
                    : String(localized: "menu.add_favorite"),
                systemImage: app.isFavorite(viewModel.archiveURL) ? "star.slash" : "star"
            )
        }
    }
}
