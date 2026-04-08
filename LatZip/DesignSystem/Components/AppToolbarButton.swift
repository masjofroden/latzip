//
//  AppToolbarButton.swift
//  LatZip
//

import SwiftUI

/// Botón de toolbar con `Label` + ayuda consistente.
struct AppToolbarButton: View {
    let title: String
    let systemImage: String
    let helpText: String
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .disabled(disabled)
        .help(helpText)
    }
}
