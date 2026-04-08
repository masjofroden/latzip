//
//  BreadcrumbView.swift
//  LatZip
//

import SwiftUI

/// Migas de pan del path actual dentro del archivo.
struct BreadcrumbView: View {
    @ObservedObject var viewModel: ArchiveWorkspaceViewModel
    var forToolbar: Bool = false

    private var rootTitle: String {
        viewModel.archiveURL.deletingPathExtension().lastPathComponent
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                BreadcrumbCrumbButton(
                    title: rootTitle,
                    path: "",
                    isCurrent: viewModel.browseFolderPath.isEmpty,
                    helpRoot: rootTitle
                ) {
                    withAnimation(AppAnimation.standard) {
                        viewModel.selectFolder(path: "")
                    }
                }

                ForEach(Array(viewModel.breadcrumbSegments().enumerated()), id: \.offset) { idx, seg in
                    Image(systemName: "chevron.compact.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.textQuaternary)
                        .frame(width: AppSpacing.md, alignment: .center)

                    let joined = viewModel.breadcrumbSegments().prefix(idx + 1).joined(separator: "/")
                    let isLast = idx == viewModel.breadcrumbSegments().count - 1
                    BreadcrumbCrumbButton(
                        title: seg,
                        path: joined,
                        isCurrent: isLast,
                        helpRoot: rootTitle
                    ) {
                        withAnimation(AppAnimation.standard) {
                            viewModel.selectFolder(path: joined)
                        }
                    }
                }
            }
            .padding(.vertical, forToolbar ? AppSpacing.sm : AppSpacing.md)
            .padding(.horizontal, forToolbar ? AppSpacing.xs : AppSpacing.sm)
        }
    }
}

// MARK: - Crumb chip (hover + selección)

private struct BreadcrumbCrumbButton: View {
    let title: String
    let path: String
    let isCurrent: Bool
    let helpRoot: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.body)
                .fontWeight(isCurrent ? .semibold : .regular)
                .foregroundStyle(isCurrent ? AppColors.textPrimary : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .fill(chipFill)
                }
        }
        .buttonStyle(.plain)
        .help(path.isEmpty ? helpRoot : path)
        .appPointerHover()
        .onHover { isHovered = $0 }
        .animation(AppAnimation.quick, value: isHovered)
    }

    private var chipFill: Color {
        if isCurrent { return AppColors.accentSoftStrong }
        if isHovered { return Color.primary.opacity(0.09) }
        return AppColors.crumbIdleFill
    }
}
