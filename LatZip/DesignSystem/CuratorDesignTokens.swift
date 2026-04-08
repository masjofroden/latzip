//
//  CuratorDesignTokens.swift
//  LatZip — estética «The Digital Curator» (macOS Sonoma / Sequoia).
//

import SwiftUI

/// Tokens visuales compartidos (acento fijo, radios, materiales).
enum CuratorDesignTokens {
    /// Azul sistema de referencia (#007AFF); usable con `.tint` en botones prominentes.
    static let accentBlue = Color(red: 0, green: 122 / 255, blue: 1)

    static let sidebarMaterial: Material = .ultraThinMaterial

    /// Cabeceras de ventana / título de biblioteca.
    static let libraryTitle = Font.system(size: 18, weight: .semibold)
    static let librarySubtitle = Font.system(size: 12, weight: .medium)

    /// Etiquetas de metadatos (mockup ~11pt medium).
    static let metadataLabel = Font.system(size: 11, weight: .medium)

    static let cardRadius: CGFloat = 12
    static let buttonRadius: CGFloat = 10
    static let rowComfortPadding: CGFloat = 12
}
