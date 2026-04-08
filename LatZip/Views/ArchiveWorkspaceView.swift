//
//  ArchiveWorkspaceView.swift
//  LatZip
//

import SwiftUI
import UniformTypeIdentifiers

struct ArchiveWorkspaceView: View {
    @ObservedObject var viewModel: ArchiveWorkspaceViewModel
    @EnvironmentObject private var app: ArchiveAppState

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isDropTargeted = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ArchiveSidebarPanel(viewModel: viewModel)
        } content: {
            contentColumn
        } detail: {
            ArchivePreviewInspectorPanel(viewModel: viewModel)
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            syncColumnVisibility()
        }
        .onChange(of: viewModel.showPreviewPanel) { _ in
            withAnimation(AppAnimation.standard) {
                syncColumnVisibility()
            }
        }
        // Migas en `breadcrumbBar` (columna central). Toolbar solo iconos para que no desaparezca al cambiar de archivo.
        .toolbar(content: workspaceToolbarContent)
        .sheet(isPresented: $viewModel.showPasswordSheet) {
            passwordSheet
        }
        .sheet(isPresented: $viewModel.showProtectZipSheet) {
            protectZipSheet
        }
        .alert(String(localized: "alert.error_title"), isPresented: errorBinding, actions: {
            Button("OK", role: .cancel) { viewModel.loadError = nil }
        }, message: {
            Text(viewModel.loadError ?? "")
        })
        .overlay { progressOverlay }
        .safeAreaInset(edge: .bottom) { toastBar }
        .onChange(of: viewModel.selection) { _ in
            Task { @MainActor in
                guard let r = viewModel.firstSelectedRecord() else {
                    viewModel.previewURL = nil
                    return
                }
                guard !r.isFolder else {
                    viewModel.previewURL = nil
                    return
                }
                await viewModel.preparePreview(for: r)
            }
        }
    }

    private func syncColumnVisibility() {
        columnVisibility = viewModel.showPreviewPanel ? .all : .doubleColumn
    }

    @ToolbarContentBuilder
    private func workspaceToolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Group {
                AppToolbarButton(
                    title: String(localized: "toolbar.up"),
                    systemImage: "arrow.up.square",
                    helpText: String(localized: "toolbar.up.help"),
                    disabled: viewModel.browseFolderPath.isEmpty
                ) {
                    withAnimation(AppAnimation.standard) {
                        viewModel.goUp()
                    }
                }
            }
            .labelStyle(.iconOnly)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Group {
                AppToolbarButton(
                    title: String(localized: "toolbar.open"),
                    systemImage: "folder.badge.plus",
                    helpText: String(localized: "toolbar.open.help")
                ) {
                    app.openPanel()
                }

                Menu {
                    Button(String(localized: "menu.extract_to_folder")) {
                        viewModel.extractSelected(collision: app.extractionCollisionPolicy)
                    }
                    .disabled(viewModel.selection.isEmpty)
                    Button(String(localized: "menu.extract_here")) {
                        viewModel.extractSelectedHere(collision: app.extractionCollisionPolicy)
                    }
                    .disabled(viewModel.selection.isEmpty)
                } label: {
                    Label(String(localized: "toolbar.extract"), systemImage: "arrow.down.circle")
                }
                .help(String(localized: "toolbar.extract.help"))

                AppToolbarButton(
                    title: String(localized: "toolbar.add"),
                    systemImage: "plus.circle",
                    helpText: viewModel.formatCaps?.supportsEditing == true
                        ? String(localized: "toolbar.add.help")
                        : String(localized: "toolbar.add_help_zip_only"),
                    disabled: viewModel.formatCaps?.supportsEditing != true
                ) {
                    viewModel.addFromFinder()
                }

                AppToolbarButton(
                    title: String(localized: "toolbar.protect_zip"),
                    systemImage: "lock.fill",
                    helpText: String(localized: "toolbar.protect_zip.help"),
                    disabled: viewModel.formatCaps?.supportsEditing != true || viewModel.index == nil
                ) {
                    viewModel.presentProtectZipSheet()
                }

                Menu {
                    Button(String(localized: "menu.extract_all_to_folder")) {
                        viewModel.extractEntireArchive(collision: app.extractionCollisionPolicy)
                    }
                    .disabled(viewModel.index == nil)
                    Button(String(localized: "menu.extract_all_here")) {
                        viewModel.extractEntireArchiveHere(collision: app.extractionCollisionPolicy)
                    }
                    .disabled(viewModel.index == nil)
                } label: {
                    Label(String(localized: "toolbar.extract_all"), systemImage: "arrow.down.to.line.circle")
                }
                .help(String(localized: "toolbar.extract_all.help"))

                Button {
                    Task {
                        if let r = viewModel.firstSelectedRecord() { await viewModel.preparePreview(for: r) }
                    }
                } label: {
                    Label(String(localized: "toolbar.ql"), systemImage: "eye")
                }
                .keyboardShortcut(.space, modifiers: [])
                .help(String(localized: "toolbar.ql.help"))
                .disabled(viewModel.selection.isEmpty)

                AppToolbarButton(
                    title: String(localized: "toolbar.favorite"),
                    systemImage: app.isFavorite(viewModel.archiveURL) ? "star.fill" : "star",
                    helpText: app.isFavorite(viewModel.archiveURL)
                        ? String(localized: "toolbar.favorite.remove_help")
                        : String(localized: "toolbar.favorite.add_help")
                ) {
                    app.toggleFavorite(viewModel.archiveURL)
                }

                AppToolbarButton(
                    title: String(localized: "toolbar.close_tab"),
                    systemImage: "xmark.circle.fill",
                    helpText: String(localized: "toolbar.close_tab_help")
                ) {
                    app.closeWorkspace(viewModel)
                }
            }
            .labelStyle(.iconOnly)
        }

        ToolbarItemGroup(placement: .automatic) {
            Group {
                sortMenu
                    .labelStyle(.iconOnly)

                SearchFieldView(
                    text: $viewModel.searchText,
                    searchEntireArchive: $viewModel.searchEntireArchive,
                    placeholder: String(localized: "search.placeholder"),
                    scopeAllLabel: String(localized: "search.scope_all_short"),
                    scopeHelp: String(localized: "search.scope_all"),
                    onTextChange: { viewModel.applyListFilterAndSort() },
                    onScopeChange: { viewModel.applyListFilterAndSort() }
                )
            }
        }

        ToolbarItem {
            Group {
                AppToolbarButton(
                    title: String(localized: "toolbar.preview_panel"),
                    systemImage: "rectangle.split.2x1",
                    helpText: String(localized: "toolbar.preview_panel.help")
                ) {
                    withAnimation(AppAnimation.standard) {
                        viewModel.showPreviewPanel.toggle()
                    }
                }
            }
            .labelStyle(.iconOnly)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.loadError != nil && !viewModel.showPasswordSheet },
            set: { if !$0 { viewModel.loadError = nil } }
        )
    }

    private var contentColumn: some View {
        VStack(spacing: 0) {
            breadcrumbBar

            ArchiveFileListTable(viewModel: viewModel)
                .overlay { dropHighlightOverlay }
                .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                    handleAddDrop(providers)
                }

            StatusBarView(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.appBackground)
    }

    /// Barra de ruta bajo el toolbar de la ventana: ancho completo de la columna central, sin competir con los botones.
    private var breadcrumbBar: some View {
        HStack(spacing: 0) {
            BreadcrumbView(viewModel: viewModel, forToolbar: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.listHeaderTint)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var dropHighlightOverlay: some View {
        if isDropTargeted, viewModel.formatCaps?.supportsEditing == true {
            ZStack {
                AppColors.dropHighlight
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                    Text(String(localized: "drop.add_to_archive"))
                        .font(AppTypography.bodyMedium)
                }
                .foregroundStyle(AppColors.textPrimary)
            }
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }

    private func handleAddDrop(_ items: [NSItemProvider]) -> Bool {
        guard viewModel.formatCaps?.supportsEditing == true, let item = items.first else { return false }
        item.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
            guard let data = data as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            DispatchQueue.main.async {
                viewModel.addDropped(urls: [url])
            }
        }
        return true
    }

    private var sortMenu: some View {
        Menu {
            sortButton(.name, label: String(localized: "col.name"))
            sortButton(.size, label: String(localized: "col.size"))
            sortButton(.compressed, label: String(localized: "col.compressed"))
            sortButton(.modified, label: String(localized: "col.modified"))
            sortButton(.kind, label: String(localized: "inspector.kind"))
        } label: {
            Label(String(localized: "toolbar.sort"), systemImage: "arrow.up.arrow.down.circle")
        }
        .help(String(localized: "toolbar.sort.help"))
    }

    private func sortButton(_ column: ArchiveWorkspaceViewModel.ArchiveColumn, label: String) -> some View {
        Button {
            viewModel.setSort(column: column, ascending: nil)
        } label: {
            HStack {
                Text(label)
                Spacer()
                if viewModel.columnSort == column {
                    Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                }
            }
        }
    }

    private var progressOverlay: some View {
        Group {
            if let p = viewModel.activeExtractionProgress {
                ZStack {
                    AppColors.overlayDim
                        .ignoresSafeArea()
                    VStack(spacing: AppSpacing.lg) {
                        Text(String(localized: "extraction.progress"))
                            .font(AppTypography.bodyMedium)
                        ProgressView(value: p.fractionCompleted)
                            .progressViewStyle(.linear)
                            .frame(width: 280)
                        Text(String(localized: "extraction.progress_hint"))
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Button(String(localized: "action.cancel")) {
                            viewModel.cancelActiveOperation()
                        }
                        .keyboardShortcut(.escape, modifiers: [])
                    }
                    .padding(AppSpacing.xxl)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous)
                            .strokeBorder(AppColors.hairlineBorder, lineWidth: 1)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(AppAnimation.standard, value: viewModel.activeExtractionProgress != nil)
    }

    private var toastBar: some View {
        HStack {
            if let t = viewModel.toast {
                Text(t)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(AppColors.hairlineBorder, lineWidth: 1)
                    }
                Spacer()
            }
        }
        .padding(.horizontal)
        .onChange(of: viewModel.toast) { new in
            guard let new, !new.isEmpty else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                if viewModel.toast == new { viewModel.toast = nil }
            }
        }
    }

    private var passwordSheet: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text(String(localized: "password.title"))
                .font(.title2.bold())
            Text(String(localized: "password.body"))
                .foregroundStyle(AppColors.textSecondary)
                .font(AppTypography.body)
            SecureField(String(localized: "password.field"), text: $viewModel.passwordField)
                .textFieldStyle(.roundedBorder)
            Toggle(String(localized: "password.remember_session"), isOn: $viewModel.rememberPasswordForSession)
            HStack {
                Spacer()
                Button(String(localized: "action.cancel"), role: .cancel) {
                    viewModel.showPasswordSheet = false
                }
                Button(String(localized: "action.unlock")) {
                    Task { await viewModel.submitPassword() }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(AppSpacing.xxl)
        .frame(minWidth: 420)
    }

    private var protectZipSheet: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text(String(localized: "protect_zip.title"))
                .font(.title2.bold())
            Text(String(localized: "protect_zip.body"))
                .foregroundStyle(AppColors.textSecondary)
                .font(AppTypography.body)
            SecureField(String(localized: "protect_zip.password"), text: $viewModel.protectZipPassword)
                .textFieldStyle(.roundedBorder)
            SecureField(String(localized: "protect_zip.confirm"), text: $viewModel.protectZipConfirm)
                .textFieldStyle(.roundedBorder)
            if let err = viewModel.protectZipFormError {
                Text(err)
                    .font(AppTypography.caption)
                    .foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button(String(localized: "action.cancel"), role: .cancel) {
                    viewModel.showProtectZipSheet = false
                }
                Button(String(localized: "protect_zip.apply")) {
                    Task { await viewModel.submitProtectZipPassword() }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(AppSpacing.xxl)
        .frame(minWidth: 420)
    }
}
