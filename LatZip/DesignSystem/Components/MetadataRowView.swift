//
//  MetadataRowView.swift
//  LatZip
//

import SwiftUI

/// Par etiqueta / valor en el panel de metadatos.
struct MetadataRowView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayoutMetrics.metadataLabelGap) {
            Text(title)
                .font(AppTypography.caption)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.textTertiary)
            Text(value)
                .font(AppTypography.metadata)
                .foregroundStyle(AppColors.textPrimary.opacity(0.88))
                .textSelection(.enabled)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
