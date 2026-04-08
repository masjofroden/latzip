//
//  FileListSkeletonView.swift
//  LatZip
//

import SwiftUI

/// Skeleton con brillo sutil para carga de la lista.
struct FileListSkeletonView: View {
    var lineCount: Int = 7

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ForEach(0 ..< lineCount, id: \.self) { i in
                FileListSkeletonRow(trailingTrim: CGFloat(40 + i * 12))
            }
        }
    }
}

private struct FileListSkeletonRow: View {
    var trailingTrim: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 2.6) / 2.6

            GeometryReader { geo in
                let w = geo.size.width
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .fill(AppColors.skeletonBase)
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color.clear,
                                AppColors.skeletonHighlight,
                                Color.clear
                            ],
                            startPoint: UnitPoint(x: (t * 1.4) - 0.35, y: 0.5),
                            endPoint: UnitPoint(x: (t * 1.4) + 0.35, y: 0.5)
                        )
                        .blendMode(.plusLighter)
                    }
                    .frame(width: max(40, w - trailingTrim), height: AppLayoutMetrics.skeletonRowHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: AppLayoutMetrics.skeletonRowHeight)
        }
    }
}
