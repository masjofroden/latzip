//
//  ArchivePreviewInspectorPanel.swift
//  LatZip
//

import SwiftUI

/// Columna derecha: envuelve `PreviewPanelView` + Quick Look + metadatos.
struct ArchivePreviewInspectorPanel: View {
    @ObservedObject var viewModel: ArchiveWorkspaceViewModel

    private var selectedName: String {
        viewModel.firstSelectedRecord()?.name ?? String(localized: "preview.none_selected")
    }

    var body: some View {
        PreviewPanelView(
            title: selectedName,
            subtitle: String(localized: "preview.panel_subtitle"),
            preview: { previewArea },
            metadata: { metadataArea }
        )
        .animation(AppAnimation.panelReveal, value: viewModel.selection.first)
        .navigationSplitViewColumnWidth(min: 272, ideal: 312, max: 432)
    }

    @ViewBuilder
    private var previewArea: some View {
        if let record = viewModel.firstSelectedRecord(), !record.isFolder {
            QuickLookPreviewRepresentable(url: viewModel.previewURL)
                .frame(minHeight: 232, idealHeight: 328, maxHeight: 488)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.previewChrome, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.previewChrome, style: .continuous)
                        .strokeBorder(AppColors.panelBorder, lineWidth: 1)
                }
        } else {
            RoundedRectangle(cornerRadius: AppRadius.previewChrome, style: .continuous)
                .fill(AppColors.crumbIdleFill)
                .frame(minHeight: 212)
                .overlay {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 36, weight: .thin))
                            .foregroundStyle(AppColors.textTertiary)
                            .symbolRenderingMode(.hierarchical)
                        Text(String(localized: "preview.pick_file"))
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.lg)
                    }
                }
        }
    }

    private var metadataArea: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(String(localized: "inspector.metadata_section"))
                .font(AppTypography.sectionHeader)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(AppLayoutMetrics.sectionTracking)

            if let record = viewModel.firstSelectedRecord() {
                MetadataRowView(title: String(localized: "inspector.path"), value: record.fullPath)
                MetadataRowView(
                    title: String(localized: "inspector.size"),
                    value: record.isFolder ? "—" : ByteCountFormatter.string(fromByteCount: record.byteSize, countStyle: .file)
                )
                MetadataRowView(
                    title: String(localized: "inspector.compressed"),
                    value: String(localized: "col.compressed.placeholder")
                )
                if let d = record.modified {
                    MetadataRowView(
                        title: String(localized: "inspector.modified"),
                        value: d.formatted(date: .abbreviated, time: .shortened)
                    )
                }
                MetadataRowView(
                    title: String(localized: "inspector.kind"),
                    value: record.isFolder ? String(localized: "kind.folder") : String(localized: "kind.file")
                )
            } else {
                Text(String(localized: "inspector.empty"))
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.textTertiary)
            }

            if let caps = viewModel.formatCaps {
                Divider()
                    .padding(.vertical, AppSpacing.xs)
                MetadataRowView(title: String(localized: "inspector.format"), value: caps.formatName)
            }
        }
    }
}
