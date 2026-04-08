//
//  FileListTableColumns.swift
//  LatZip
//

import SwiftUI

/// Una sola función de layout para la fila de cabecera y cada fila de datos.
enum FileListTableColumns {
    @ViewBuilder
    static func row<Icon: View, Name: View, Size: View, TypeCol: View, Modified: View>(
        icon: Icon,
        @ViewBuilder name: () -> Name,
        @ViewBuilder size: () -> Size,
        @ViewBuilder type: () -> TypeCol,
        @ViewBuilder modified: () -> Modified
    ) -> some View {
        HStack(alignment: .center, spacing: AppLayoutMetrics.fileListColumnGutter) {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                icon
                name()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            .padding(.leading, AppLayoutMetrics.fileListLeading)

            size()
                .frame(width: AppLayoutMetrics.fileListColSize, alignment: .trailing)

            type()
                .frame(width: AppLayoutMetrics.fileListColType, alignment: .leading)

            modified()
                .frame(width: AppLayoutMetrics.fileListColModified, alignment: .leading)
                .padding(.trailing, AppLayoutMetrics.fileListLeading)
        }
    }
}
