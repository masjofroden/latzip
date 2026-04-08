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

    func makeNSView(context: Context) -> QLPreviewView {
        let preview = QLPreviewView(frame: .zero, style: .normal)!
        preview.autostarts = true
        preview.shouldCloseWithWindow = false
        return preview
    }

    func updateNSView(_ preview: QLPreviewView, context: Context) {
        guard let url else {
            preview.previewItem = nil
            return
        }
        let item = url as NSURL
        if (preview.previewItem as? NSURL)?.path != item.path {
            preview.previewItem = item
        }
        preview.refreshPreviewItem()
    }
}
