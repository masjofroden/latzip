//
//  CuratorSupportingViews.swift
//  LatZip — componentes UI del rediseño «The Digital Curator».
//

import AppKit
import SwiftUI

// MARK: - Inspector

struct CuratorEncryptedBadge: View {
    var body: some View {
        Text(String(localized: "curator.encrypted_badge"))
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.orange)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(Color.orange.opacity(0.16), in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(Color.orange.opacity(0.35), lineWidth: 1)
            }
    }
}

struct CuratorShareArchiveButton: View {
    let archiveURL: URL

    var body: some View {
        ShareLink(item: archiveURL) {
            Label(String(localized: "inspector.share_archive"), systemImage: "square.and.arrow.up")
                .font(AppTypography.bodyMedium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(.borderedProminent)
        .tint(CuratorDesignTokens.accentBlue)
        .controlSize(.large)
    }
}

// MARK: - Grid (vista alternativa)

struct CuratorFileGridView: View {
    @ObservedObject var viewModel: ArchiveWorkspaceViewModel
    @EnvironmentObject private var app: ArchiveAppState

    private let columns = [
        GridItem(.adaptive(minimum: 104, maximum: 140), spacing: AppSpacing.md)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                ForEach(Array(viewModel.listItems.enumerated()), id: \.1.id) { index, item in
                    CuratorGridCell(
                        item: item,
                        isSelected: viewModel.selection.contains(item.id)
                    )
                    .onTapGesture {
                        applySelection(for: item, at: index)
                    }
                    .contextMenu {
                        gridContextMenu(for: item)
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
    }

    private func applySelection(for item: ArchiveEntryRecord, at index: Int) {
        let flags = NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.command) {
            if viewModel.selection.contains(item.id) {
                viewModel.selection.remove(item.id)
            } else {
                viewModel.selection.insert(item.id)
            }
            return
        }
        viewModel.selection = [item.id]
    }

    @ViewBuilder
    private func gridContextMenu(for item: ArchiveEntryRecord) -> some View {
        Button(String(localized: "menu.extract_to_folder")) {
            viewModel.selection = [item.id]
            viewModel.extractSelected(collision: app.extractionCollisionPolicy)
        }
        Button(String(localized: "menu.preview")) {
            viewModel.selection = [item.id]
            Task {
                await viewModel.preparePreview(for: item)
            }
        }
    }
}

private struct CuratorGridCell: View {
    let item: ArchiveEntryRecord
    let isSelected: Bool

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            FileTypeIcon(name: item.name, isFolder: item.isFolder, size: 40)
            Text(item.name)
                .font(AppTypography.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: CuratorDesignTokens.cardRadius, style: .continuous)
                .fill(isSelected ? CuratorDesignTokens.accentBlue.opacity(0.14) : AppColors.crumbIdleFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CuratorDesignTokens.cardRadius, style: .continuous)
                .strokeBorder(
                    isSelected ? CuratorDesignTokens.accentBlue.opacity(0.45) : AppColors.hairlineBorder,
                    lineWidth: 1
                )
        }
    }
}
