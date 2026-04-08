//
//  ArchiveFileListTable.swift
//  LatZip
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Lista central: filas `FileRowView`, cabeceras `ColumnHeaderView`, design system unificado.
struct ArchiveFileListTable: View {
    @ObservedObject var viewModel: ArchiveWorkspaceViewModel
    @EnvironmentObject private var app: ArchiveAppState

    @State private var hoveredRowID: ArchiveEntryRecord.ID?
    @State private var shiftAnchorIndex: Int?

    private let colSize: CGFloat = 100
    private let colCompressed: CGFloat = 96
    private let colModified: CGFloat = 156

    private let sortHelp = String(localized: "toolbar.sort.help")

    var body: some View {
        ZStack {
            AppColors.contentBackground
                .ignoresSafeArea(edges: .bottom)

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
                } else {
                    fileList
                }
            }
            .animation(AppAnimation.standard, value: viewModel.isLoading)
            .animation(AppAnimation.standard, value: viewModel.listItems.count)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xxl)
    }

    private var fileList: some View {
        VStack(spacing: 0) {
            columnHeaderRow
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

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.listItems.enumerated()), id: \.1.id) { index, item in
                        fileRow(index: index, item: item)
                    }
                }
                .padding(.top, AppLayoutMetrics.fileListSectionTop)
                .padding(.bottom, AppSpacing.md)
            }
        }
    }

    private var columnHeaderRow: some View {
        HStack(alignment: .center, spacing: AppLayoutMetrics.fileListColumnGutter) {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                Color.clear
                    .frame(width: AppLayoutMetrics.fileListIconColumnWidth, height: 1)
                    .accessibilityHidden(true)
                ColumnHeaderView(
                    title: String(localized: "col.name"),
                    trailing: false,
                    isSortActive: viewModel.columnSort == .name,
                    sortAscending: viewModel.sortAscending,
                    helpText: sortHelp
                ) {
                    viewModel.setSort(column: .name, ascending: nil)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, AppLayoutMetrics.fileListLeading)

            ColumnHeaderView(
                title: String(localized: "col.size"),
                trailing: true,
                isSortActive: viewModel.columnSort == .size,
                sortAscending: viewModel.sortAscending,
                helpText: sortHelp
            ) {
                viewModel.setSort(column: .size, ascending: nil)
            }
            .frame(width: colSize, alignment: .trailing)

            ColumnHeaderView(
                title: String(localized: "col.compressed"),
                trailing: true,
                isSortActive: viewModel.columnSort == .compressed,
                sortAscending: viewModel.sortAscending,
                helpText: sortHelp
            ) {
                viewModel.setSort(column: .compressed, ascending: nil)
            }
            .frame(width: colCompressed, alignment: .trailing)

            ColumnHeaderView(
                title: String(localized: "col.modified"),
                trailing: true,
                isSortActive: viewModel.columnSort == .modified,
                sortAscending: viewModel.sortAscending,
                helpText: sortHelp
            ) {
                viewModel.setSort(column: .modified, ascending: nil)
            }
            .frame(width: colModified, alignment: .trailing)
            .padding(.trailing, AppLayoutMetrics.fileListLeading)
        }
        .padding(.vertical, AppSpacing.sm)
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
            compressedText: compressedCell(item),
            modifiedText: modifiedText,
            colSize: colSize,
            colCompressed: colCompressed,
            colModified: colModified,
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

    private func compressedCell(_ item: ArchiveEntryRecord) -> String {
        if item.isFolder { return "—" }
        return String(localized: "col.compressed.placeholder")
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
