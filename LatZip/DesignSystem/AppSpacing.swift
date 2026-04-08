//
//  AppSpacing.swift
//  LatZip
//

import CoreGraphics

/// Escala de espaciado fija. Usar en padding, gaps y stacks.
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

/// Medidas de layout que no son “escala” (columnas, filas).
enum AppLayoutMetrics {
    static let fileListRowVertical: CGFloat = 10
    static let fileListLeading: CGFloat = 16
    static let fileListRowInset: CGFloat = 8
    /// Espacio entre bloque “nombre” y columnas numéricas (alinea cabeceras con celdas).
    static let fileListColumnGutter: CGFloat = 12
    /// Ancho reservado para el icono en fila y cabecera (debe coincidir con `FileTypeIcon`).
    static let fileListIconColumnWidth: CGFloat = 20
    static let fileListSectionTop: CGFloat = 0
    static let sidebarItemMinHeight: CGFloat = 34
    static let sidebarIconColumn: CGFloat = 20
    static let toolbarSearchWidth: CGFloat = 176
    static let toolbarSearchMinWidth: CGFloat = 96
    static let toolbarSearchIdealWidth: CGFloat = 152
    static let toolbarSearchMaxWidth: CGFloat = 220
    static let skeletonRowHeight: CGFloat = 34
    static let metadataLabelGap: CGFloat = 4
    static let sectionTracking: Double = 0.35
}
