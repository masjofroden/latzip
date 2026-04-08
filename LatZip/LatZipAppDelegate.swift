//
//  LatZipAppDelegate.swift
//  LatZip
//

import AppKit
import Foundation

/// Registra **Servicios del sistema** (Finder → Servicios / clic derecho) para abrir archivos en LatZip.
final class LatZipAppDelegate: NSObject, NSApplicationDelegate {
    private weak var appState: ArchiveAppState?

    func bind(appState: ArchiveAppState) {
        self.appState = appState
        NSApp.servicesProvider = self
    }

    /// Selector declarado en `InfoAdditions.plist` → `NSMessage` = `openArchivesInLatZip`.
    @objc func openArchivesInLatZip(
        _ pboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) {
        let urls = fileURLs(from: pboard)
        guard !urls.isEmpty else {
            error?.pointee = NSString(string: String(localized: "service.no_files_error"))
            return
        }
        DispatchQueue.main.async { [weak self] in
            NSApp.activate(ignoringOtherApps: true)
            urls.forEach { self?.appState?.openArchive(url: $0) }
        }
    }

    private func fileURLs(from pboard: NSPasteboard) -> [URL] {
        guard let objects = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return []
        }
        return objects.map(\.standardizedFileURL)
    }
}
