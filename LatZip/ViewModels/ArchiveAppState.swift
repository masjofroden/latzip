//
//  ArchiveAppState.swift
//  LatZip
//

import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class ArchiveAppState: ObservableObject {
    /// Formatos que se pueden crear vacíos con libarchive (`archive_write_set_format_filter_by_ext`).
    private static let newArchiveSaveTypes: [UTType] = [
        .zip,
        UTType(importedAs: "public.tar-archive"),
        UTType(importedAs: "org.gnu.gnu-gzip-archive"),
        UTType(importedAs: "org.bzip2.bzip2-archive"),
        UTType(importedAs: "public.xz-archive"),
        UTType(importedAs: "org.7-zip.7-zip-archive"),
    ]

    private static let extractionCollisionKey = "latzip.extractionCollisionPolicy"
    private static let appLanguageKey = "latzip.appLanguage"

    @Published var workspaces: [ArchiveWorkspaceViewModel] = []
    @Published var selectedWorkspaceId: UUID?

    /// Política por defecto al extraer (toolbar, menú y atajos). Persistida en `UserDefaults`.
    @Published var extractionCollisionPolicy: ExtractionCollisionPolicy

    /// Idioma de la UI; al cambiar se relanza la app. Llamar `applyLaunchLanguageFromUserDefaults()` al arranque.
    @Published var appLanguage: AppLanguage

    /// Apariencia clara / oscura / según sistema (persistida). Sin relanzamiento.
    @Published var appearanceMode: AppAppearance

    /// Presenta la hoja de atajos de teclado (menú Ayuda).
    @Published var showKeyboardShortcuts: Bool = false

    /// Guardar contraseñas de archivos cifrados en el Llavero (opt-in).
    @Published var archivePasswordKeychainEnabled: Bool

    @AppStorage("latzip.recents.json") private var recentsStorage: String = "[]"
    @AppStorage("latzip.favorites.json") private var favoritesStorage: String = "[]"

    private let zipWriter = ArchiveWriterService()

    var selectedWorkspace: ArchiveWorkspaceViewModel? {
        guard let id = selectedWorkspaceId else { return workspaces.first }
        return workspaces.first { $0.id == id }
    }

    var recentURLs: [URL] {
        guard let data = recentsStorage.data(using: .utf8),
              let paths = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return paths.compactMap { path in
            let u = URL(fileURLWithPath: path)
            return FileManager.default.fileExists(atPath: u.path) ? u : nil
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.extractionCollisionKey)
        extractionCollisionPolicy = ExtractionCollisionPolicy(rawValue: raw ?? "") ?? .keepBoth
        appLanguage = AppLanguage(persistedValue: UserDefaults.standard.string(forKey: Self.appLanguageKey))
        appearanceMode = AppAppearance(persisted: UserDefaults.standard.string(forKey: AppAppearance.storageKey))
        archivePasswordKeychainEnabled = UserDefaults.standard.bool(forKey: ArchiveKeychainPreference.userDefaultsKey)
        AppAppearance.applyToSharedApplication(appearanceMode)
    }

    var archivePasswordKeychainBinding: Binding<Bool> {
        Binding(
            get: { self.archivePasswordKeychainEnabled },
            set: { [self] newValue in
                guard newValue != archivePasswordKeychainEnabled else { return }
                archivePasswordKeychainEnabled = newValue
                UserDefaults.standard.set(newValue, forKey: ArchiveKeychainPreference.userDefaultsKey)
            }
        )
    }

    var preferredColorScheme: ColorScheme? {
        appearanceMode.preferredColorScheme
    }

    var appearanceModeBinding: Binding<AppAppearance> {
        Binding(
            get: { self.appearanceMode },
            set: { [self] newValue in
                guard newValue != appearanceMode else { return }
                appearanceMode = newValue
                UserDefaults.standard.set(newValue.persistedString, forKey: AppAppearance.storageKey)
                AppAppearance.applyToSharedApplication(newValue)
            }
        )
    }

    /// Aplicar antes de cargar recursos localizados (p. ej. en `LatZipApp.init()`).
    static func applyLaunchLanguageFromUserDefaults() {
        let lang = AppLanguage(persistedValue: UserDefaults.standard.string(forKey: appLanguageKey))
        switch lang {
        case .en:
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        case .es:
            UserDefaults.standard.set(["es"], forKey: "AppleLanguages")
        case .system:
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }

    private static func relaunchApplication() {
        let bundleURL = Bundle.main.bundleURL
        DispatchQueue.main.async {
            NSWorkspace.shared.open(bundleURL)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            NSApp.terminate(nil)
        }
    }

    var appLanguageBinding: Binding<AppLanguage> {
        Binding(
            get: { self.appLanguage },
            set: { [self] newValue in
                guard newValue != appLanguage else { return }
                appLanguage = newValue
                UserDefaults.standard.set(newValue.persistedString, forKey: Self.appLanguageKey)
                Self.applyLaunchLanguageFromUserDefaults()
                Self.relaunchApplication()
            }
        )
    }

    var extractionCollisionPolicyBinding: Binding<ExtractionCollisionPolicy> {
        Binding(
            get: { self.extractionCollisionPolicy },
            set: { [self] newValue in
                self.extractionCollisionPolicy = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: Self.extractionCollisionKey)
            }
        )
    }

    var favoriteURLs: [URL] {
        guard let data = favoritesStorage.data(using: .utf8),
              let paths = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return paths.compactMap { path in
            let u = URL(fileURLWithPath: path)
            return FileManager.default.fileExists(atPath: u.path) ? u : nil
        }
    }

    func isFavorite(_ url: URL) -> Bool {
        let s = url.standardizedFileURL.path
        return favoriteURLs.contains { $0.standardizedFileURL.path == s }
    }

    func toggleFavorite(_ url: URL) {
        let std = url.standardizedFileURL
        var f = favoriteURLs
        if let i = f.firstIndex(where: { $0.standardizedFileURL.path == std.path }) {
            f.remove(at: i)
        } else {
            f.insert(std, at: 0)
        }
        if f.count > 24 { f = Array(f.prefix(24)) }
        if let data = try? JSONEncoder().encode(f.map(\.path)), let s = String(data: data, encoding: .utf8) {
            favoritesStorage = s
        }
    }

    private func saveRecents(_ urls: [URL]) {
        let paths = urls.map(\.path)
        if let data = try? JSONEncoder().encode(paths), let s = String(data: data, encoding: .utf8) {
            recentsStorage = s
        }
    }

    private func addToRecents(_ url: URL) {
        var r = recentURLs.filter { $0 != url }
        r.insert(url, at: 0)
        if r.count > 12 { r = Array(r.prefix(12)) }
        saveRecents(r)
    }

    func openArchive(url: URL, displayTitle: String? = nil) {
        let standardized = url.standardizedFileURL
        if let existing = workspaces.first(where: { $0.archiveURL == standardized }) {
            selectedWorkspaceId = existing.id
            return
        }
        let ws = ArchiveWorkspaceViewModel(archiveURL: standardized, displayTitle: displayTitle)
        workspaces.append(ws)
        selectedWorkspaceId = ws.id
        addToRecents(standardized)
        Task { await ws.load(forceNewPassword: false) }
    }

    func openNestedChild(tempURL: URL, title: String, parent: ArchiveWorkspaceViewModel) {
        let composed = "\(parent.displayTitle) › \(title)"
        openArchive(url: tempURL, displayTitle: composed)
    }

    func openPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = String(localized: "panel.open_archive")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        openArchive(url: url)
    }

    /// Crea un archivo comprimido vacío (ZIP, tar, 7z, …) y lo abre en una pestaña nueva.
    func createNewEmptyZipArchive() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = Self.newArchiveSaveTypes
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = String(localized: "panel.new_zip")
        panel.nameFieldStringValue = "\(String(localized: "new_zip.default_name")).zip"
        guard panel.runModal() == .OK, var url = panel.url else { return }
        if archive_engine_is_editable_archive_path(url.path) == 0 {
            url = url.deletingPathExtension().appendingPathExtension("zip")
        }
        Task {
            do {
                try await zipWriter.createEmptyZip(at: url)
                await MainActor.run { openArchive(url: url) }
            } catch {
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = String(localized: "alert.error_title")
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                }
            }
        }
    }

    func closeWorkspace(_ ws: ArchiveWorkspaceViewModel) {
        ws.cancelActiveOperation()
        ws.cleanupTemp()
        workspaces.removeAll { $0.id == ws.id }
        if selectedWorkspaceId == ws.id {
            selectedWorkspaceId = workspaces.last?.id
        }
        ensureValidWorkspaceSelection()
    }

    /// Evita un `selectedWorkspaceId` huérfano si la lista de pestañas cambia.
    func ensureValidWorkspaceSelection() {
        if workspaces.isEmpty {
            selectedWorkspaceId = nil
            return
        }
        if let id = selectedWorkspaceId, workspaces.contains(where: { $0.id == id }) {
            return
        }
        selectedWorkspaceId = workspaces.last?.id
    }

    func openRecent(_ url: URL) {
        openArchive(url: url)
    }
}
