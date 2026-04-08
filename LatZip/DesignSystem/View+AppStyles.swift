//
//  View+AppStyles.swift
//  LatZip
//

import AppKit
import SwiftUI

extension View {
    /// Cursor de mano en elementos clicables (macOS).
    func appPointerHover() -> some View {
        modifier(AppPointerHoverModifier())
    }

    /// Tarjeta estándar con fondo de control y borde hairline.
    func appCardChrome(cornerRadius: CGFloat = AppRadius.medium) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppColors.panelBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(AppColors.hairlineBorder, lineWidth: 1)
        }
    }
}

private struct AppPointerHoverModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
