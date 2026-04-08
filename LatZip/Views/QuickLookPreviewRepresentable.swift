//
//  QuickLookPreviewRepresentable.swift
//  LatZip
//
//  Vista previa nativa mediante Quick Look (QLPreviewView).
//

import AppKit
import QuickLookUI
import SwiftUI

struct QuickLookPreviewRepresentable: NSViewRepresentable {
    var url: URL?

    /// Tamaño inicial distinto de cero: con `.zero` SwiftUI/AppKit a veces deja el `QLPreviewView` sin layout útil.
    private static let bootstrappingFrame = NSRect(x: 0, y: 0, width: 400, height: 300)

    func makeNSView(context: Context) -> QLPreviewView {
        let preview = QLPreviewView(frame: Self.bootstrappingFrame, style: .normal)!
        preview.autoresizingMask = [.width, .height]
        preview.autostarts = true
        preview.shouldCloseWithWindow = false
        return preview
    }

    func updateNSView(_ preview: QLPreviewView, context: Context) {
        guard let url else {
            if preview.previewItem != nil {
                preview.previewItem = nil
            }
            return
        }
        let item = url as NSURL
        let newPath = item.path
        let oldPath = (preview.previewItem as? NSURL)?.path
        /// `refreshPreviewItem()` relanza generadores Quick Look / WebKit; llamarlo en cada pasada de SwiftUI satura procesos y ensucia la consola.
        guard oldPath != newPath else { return }
        preview.previewItem = item
        preview.refreshPreviewItem()
    }
}
