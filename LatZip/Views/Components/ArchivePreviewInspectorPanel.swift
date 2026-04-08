//
//  ArchivePreviewInspectorPanel.swift
//  LatZip
//

import SwiftUI

/// Inspector derecho estilo «The Digital Curator»: preview, metadatos, badge cifrado y compartir.
struct ArchivePreviewInspectorPanel: View {
    @ObservedObject var viewModel: ArchiveWorkspaceViewModel

    private var selectedName: String {
        viewModel.firstSelectedRecord()?.name ?? String(localized: "preview.none_selected")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                previewArea

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(selectedName)
                        .font(CuratorDesignTokens.libraryTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)
                    if viewModel.archiveOpenedWithPassphrase {
                        CuratorEncryptedBadge()
                    }
                }

                Text(String(localized: "preview.panel_subtitle"))
                    .font(AppTypography.sectionHeader)
                    .foregroundStyle(AppColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(AppLayoutMetrics.sectionTracking * 0.85)

                metadataArea

                CuratorShareArchiveButton(archiveURL: viewModel.archiveURL)
                    .padding(.top, AppSpacing.sm)
            }
            .padding(AppSpacing.xl)
        }
        .frame(minWidth: 300, idealWidth: 340, maxWidth: 400, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.appBackground)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(width: 1)
                .frame(maxHeight: .infinity)
        }
        .animation(AppAnimation.panelReveal, value: viewModel.selection.first)
        .navigationSplitViewColumnWidth(min: 300, ideal: 340, max: 400)
    }

    @ViewBuilder
    private var previewArea: some View {
        if let record = viewModel.firstSelectedRecord(), !record.isFolder {
            QuickLookPreviewRepresentable(url: viewModel.previewURL)
                .frame(minHeight: 232, idealHeight: 328, maxHeight: 488)
                .clipShape(RoundedRectangle(cornerRadius: CuratorDesignTokens.cardRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: CuratorDesignTokens.cardRadius, style: .continuous)
                        .strokeBorder(AppColors.panelBorder, lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        } else {
            RoundedRectangle(cornerRadius: CuratorDesignTokens.cardRadius, style: .continuous)
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
                MetadataRowView(title: String(localized: "inspector.kind"), value: record.curatorTypeLabel)
                MetadataRowView(title: String(localized: "inspector.size"), value: sizeValue(record))
                MetadataRowView(title: String(localized: "inspector.created"), value: String(localized: "inspector.value_unavailable"))
                MetadataRowView(title: String(localized: "inspector.dimensions"), value: String(localized: "inspector.value_unavailable"))
                MetadataRowView(title: String(localized: "inspector.path"), value: record.fullPath)
                if let d = record.modified {
                    MetadataRowView(
                        title: String(localized: "inspector.modified"),
                        value: d.formatted(date: .abbreviated, time: .shortened)
                    )
                }
            } else {
                Text(String(localized: "inspector.empty"))
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.textTertiary)
            }

            if let caps = viewModel.formatCaps {
                Divider()
                    .padding(.vertical, AppSpacing.xs)
                MetadataRowView(title: String(localized: "inspector.format"), value: caps.formatName)
                MetadataRowView(
                    title: String(localized: "inspector.compressed"),
                    value: String(localized: "col.compressed.placeholder")
                )
            }
        }
    }

    private func sizeValue(_ record: ArchiveEntryRecord) -> String {
        if record.isFolder { return "—" }
        return ByteCountFormatter.string(fromByteCount: record.byteSize, countStyle: .file)
    }
}
