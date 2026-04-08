//
//  ArchiveWorkspaceViewModel.swift
//  LatZip
//

import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class ArchiveWorkspaceViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let archiveURL: URL

    @Published var displayTitle: String
    @Published private(set) var index: ArchiveIndex?
    @Published private(set) var rootNodes: [ArchiveNode] = []
    @Published private(set) var formatCaps: ArchiveFormatCapabilities?

    @Published var browseFolderPath: String = ""
    @Published var listItems: [ArchiveEntryRecord] = []
    @Published var selection: Set<ArchiveEntryRecord.ID> = []

    @Published var searchText: String = ""
    @Published var searchEntireArchive: Bool = false

    @Published var sortFoldersFirst: Bool = true
    @Published var columnSort: ArchiveColumn = .name
    @Published var sortAscending: Bool = true

    @Published var isLoading = false
    @Published var loadError: String?
    @Published var showPasswordSheet = false
    @Published var passwordField: String = ""
    @Published var showProtectZipSheet = false
    @Published var protectZipPassword: String = ""
    @Published var protectZipConfirm: String = ""
    @Published var protectZipFormError: String?
    /// No persistido en disco — solo memoria de proceso si el usuario activa «recordar sesión».
    @Published var rememberPasswordForSession = false

    private var sessionPassphrase: String?

    @Published var previewURL: URL?
    @Published var showPreviewPanel = true

    @Published var toast: String?
    @Published var activeExtractionProgress: Progress?
    private var extractionTask: Task<Void, Never>?

    private let reader = ArchiveReaderService()
    private let writer = ArchiveWriterService()
    private let tempWorkspace = TemporaryWorkspaceService()

    enum ArchiveColumn: String, CaseIterable {
        case name, size, compressed, modified, kind
    }

    func setSort(column: ArchiveColumn, ascending: Bool? = nil) {
        if column == columnSort, ascending == nil {
            sortAscending.toggle()
        } else if let ascending {
            columnSort = column
            sortAscending = ascending
        } else {
            columnSort = column
            sortAscending = column == .name || column == .kind
        }
        applyListFilterAndSort()
    }

    init(archiveURL: URL, displayTitle: String? = nil) {
        self.archiveURL = archiveURL
        self.displayTitle = displayTitle ?? archiveURL.lastPathComponent
    }

    func load(forceNewPassword: Bool = false) async {
        if forceNewPassword {
            sessionPassphrase = nil
        }
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        let pass = sessionPassphrase
        do {
            let loaded = try await reader.load(archiveURL: archiveURL, passphrase: pass)
            index = loaded.index
            rootNodes = loaded.rootNodes
            formatCaps = FormatSupportService.capabilities(
                for: archiveURL,
                formatName: loaded.formatName,
                filterName: loaded.filterName
            )
            browseFolderPath = ""
            selection = []
            applyListFilterAndSort()
            await tempWorkspace.invalidate(archiveURL: archiveURL)
            previewURL = nil
            showPasswordSheet = false
        } catch ArchiveLoadError.needsPassword {
            showPasswordSheet = true
            passwordField = ""
        } catch {
            loadError = error.localizedDescription
        }
    }

    func submitPassword() async {
        sessionPassphrase = passwordField.isEmpty ? nil : passwordField
        if rememberPasswordForSession {} /* explícito: credencial solo en RAM */
        await load(forceNewPassword: false)
    }

    func selectFolder(path: String) {
        browseFolderPath = path
        selection = []
        applyListFilterAndSort()
    }

    func goUp() {
        if browseFolderPath.isEmpty { return }
        browseFolderPath = (browseFolderPath as NSString).deletingLastPathComponent
        selection = []
        applyListFilterAndSort()
    }

    func breadcrumbSegments() -> [String] {
        if browseFolderPath.isEmpty { return [] }
        return browseFolderPath.split(separator: "/").map(String.init)
    }

    func navigateBreadcrumb(upToIndex idx: Int) {
        let segs = breadcrumbSegments()
        guard idx >= 0, idx < segs.count else { return }
        browseFolderPath = segs[0 ... idx].joined(separator: "/")
        selection = []
        applyListFilterAndSort()
    }

    func applyListFilterAndSort() {
        guard let index else {
            listItems = []
            return
        }
        var rows: [ArchiveEntryRecord]
        if searchEntireArchive, !searchText.isEmpty {
            let q = searchText.lowercased()
            rows = index.allRecords.filter { $0.fullPath.lowercased().contains(q) }
        } else {
            rows = index.children(ofParent: browseFolderPath)
            if !searchText.isEmpty {
                let q = searchText.lowercased()
                rows = rows.filter { $0.name.lowercased().contains(q) }
            }
        }
        rows.sort { a, b in
            if sortFoldersFirst, a.isFolder != b.isFolder {
                return a.isFolder && !b.isFolder
            }
            let cmp: ComparisonResult
            switch columnSort {
            case .name:
                cmp = a.name.localizedCaseInsensitiveCompare(b.name)
            case .size, .compressed:
                if a.byteSize == b.byteSize { cmp = .orderedSame }
                else { cmp = a.byteSize < b.byteSize ? .orderedAscending : .orderedDescending }
            case .modified:
                let ad = a.modified ?? .distantPast
                let bd = b.modified ?? .distantPast
                cmp = ad.compare(bd)
            case .kind:
                cmp = a.name.localizedCaseInsensitiveCompare(b.name)
            }
            if cmp == .orderedSame { return a.fullPath < b.fullPath }
            switch (sortAscending, cmp) {
            case (true, .orderedAscending), (false, .orderedDescending):
                return true
            default:
                return false
            }
        }
        listItems = rows
    }

    /// Doble clic / Enter: carpeta entra; fichero prepara vista previa.
    func openOrDrillDown(_ item: ArchiveEntryRecord, onNestedArchive: @escaping (URL, String) -> Void) async {
        if item.isFolder {
            browseFolderPath = item.fullPath
            selection = []
            applyListFilterAndSort()
            return
        }
        if isNestedArchiveCandidate(item) {
            await openNested(item, onNestedArchive: onNestedArchive)
            return
        }
        await preparePreview(for: item)
    }

    private func isNestedArchiveCandidate(_ item: ArchiveEntryRecord) -> Bool {
        let ext = (item.name as NSString).pathExtension.lowercased()
        return ArchiveNode.nestedArchiveExtensions.contains(ext)
    }

    private func openNested(_ item: ArchiveEntryRecord, onNestedArchive: (URL, String) -> Void) async {
        var errBuf = [CChar](repeating: 0, count: 512)
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(
            "latzip-nested-\(id.uuidString)-\(item.name.replacingOccurrences(of: "/", with: "_"))"
        )
        let rc: Int32 = archiveURL.path.withCString { arch in
            item.fullPath.withCString { inner in
                dest.path.withCString { outp in
                    if let p = sessionPassphrase, !p.isEmpty {
                        return p.withCString { pass in
                            Int32(archive_engine_extract_file_to_path(arch, pass, inner, outp, &errBuf, 512))
                        }
                    }
                    return Int32(archive_engine_extract_file_to_path(arch, nil, inner, outp, &errBuf, 512))
                }
            }
        }
        guard rc == 0 else {
            loadError = errBuf.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
            return
        }
        onNestedArchive(dest, item.name)
    }

    func preparePreview(for item: ArchiveEntryRecord) async {
        guard !item.isFolder else { return }
        selection = [item.id]
        do {
            previewURL = try await tempWorkspace.previewFileURL(
                archiveURL: archiveURL,
                entryPath: item.fullPath,
                passphrase: sessionPassphrase
            )
        } catch {
            previewURL = nil
            toast = String(localized: "toast.preview_failed")
        }
    }

    func extractSelected(collision: ExtractionCollisionPolicy = .keepBoth) {
        guard let index, !selection.isEmpty else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.prompt = String(localized: "panel.extract_to_folder")
        guard panel.runModal() == .OK, let dest = panel.url else { return }

        let paths = Array(selection)
        let files = ArchiveExtractionService.expandForExtraction(selectedPaths: paths, index: index)
        guard !files.isEmpty else { return }
        runExtraction(files: files, destination: dest, collision: collision)
    }

    /// Extrae la selección en la misma carpeta que el archivo comprimido (comportamiento tipo 7-Zip / WinRAR «aquí»).
    func extractSelectedHere(collision: ExtractionCollisionPolicy = .keepBoth) {
        guard let index, !selection.isEmpty else { return }
        let paths = Array(selection)
        let files = ArchiveExtractionService.expandForExtraction(selectedPaths: paths, index: index)
        guard !files.isEmpty else { return }
        let dest = archiveURL.deletingLastPathComponent()
        runExtraction(files: files, destination: dest, collision: collision)
    }

    func extractEntireArchive(collision: ExtractionCollisionPolicy = .keepBoth) {
        guard let index else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.prompt = String(localized: "panel.extract_all_folder")
        guard panel.runModal() == .OK, let dest = panel.url else { return }

        let files = index.allRecords.filter { !$0.isFolder }.sorted { $0.fullPath < $1.fullPath }
        runExtraction(files: files, destination: dest, collision: collision)
    }

    /// Extrae todo el contenido junto al archivo `.zip` / comprimido en disco.
    func extractEntireArchiveHere(collision: ExtractionCollisionPolicy = .keepBoth) {
        guard let index else { return }
        let files = index.allRecords.filter { !$0.isFolder }.sorted { $0.fullPath < $1.fullPath }
        guard !files.isEmpty else { return }
        let dest = archiveURL.deletingLastPathComponent()
        runExtraction(files: files, destination: dest, collision: collision)
    }

    /// Si hay colisión en destino, muestra un panel con la preferencia como opción por defecto (Retorno).
    private func promptCollisionPolicyIfNeeded(
        files: [ArchiveEntryRecord],
        destination: URL,
        defaultPolicy: ExtractionCollisionPolicy
    ) -> ExtractionCollisionPolicy? {
        guard ArchiveExtractionService.destinationCollisionsExist(
            files: files,
            destinationDirectory: destination
        ) else {
            return defaultPolicy
        }
        let alert = NSAlert()
        alert.messageText = String(localized: "collision.alert_title")
        alert.informativeText = String(localized: "collision.alert_message")
        alert.addButton(withTitle: String(localized: "prefs.collision.replace"))
        alert.addButton(withTitle: String(localized: "prefs.collision.skip"))
        alert.addButton(withTitle: String(localized: "prefs.collision.keep_both"))
        alert.addButton(withTitle: String(localized: "action.cancel"))

        let defaultIndex: Int = switch defaultPolicy {
        case .replace: 0
        case .skip: 1
        case .keepBoth: 2
        }
        for btn in alert.buttons {
            btn.keyEquivalent = ""
        }
        alert.buttons[defaultIndex].keyEquivalent = "\r"
        alert.buttons[3].keyEquivalent = "\u{1b}"

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn: return .replace
        case .alertSecondButtonReturn: return .skip
        case .alertThirdButtonReturn: return .keepBoth
        default: return nil
        }
    }

    private func runExtraction(
        files: [ArchiveEntryRecord],
        destination: URL,
        collision: ExtractionCollisionPolicy
    ) {
        guard let policy = promptCollisionPolicyIfNeeded(
            files: files,
            destination: destination,
            defaultPolicy: collision
        ) else { return }

        let progress = Progress()
        activeExtractionProgress = progress
        extractionTask?.cancel()
        extractionTask = Task {
            defer { activeExtractionProgress = nil }
            do {
                let n = try await ArchiveExtractionService.extract(
                    files: files,
                    archiveURL: archiveURL,
                    passphrase: sessionPassphrase,
                    destinationDirectory: destination,
                    options: ExtractionOptions(collisionPolicy: policy),
                    progress: progress
                )
                toast = String(format: String(localized: "toast.extracted_n"), n)
            } catch is CancellationError {
                toast = String(localized: "toast.extraction_cancelled")
            } catch {
                loadError = error.localizedDescription
            }
        }
    }

    func cancelActiveOperation() {
        extractionTask?.cancel()
        extractionTask = nil
        activeExtractionProgress = nil
    }

    func addFromFinder() {
        guard formatCaps?.supportsEditing == true else {
            toast = String(localized: "toast.edit_not_supported")
            return
        }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.prompt = String(localized: "panel.add_items")
        guard panel.runModal() == .OK else { return }
        let urls = panel.urls
        guard !urls.isEmpty else { return }
        Task { await performAdd(urls: urls) }
    }

    func addDropped(urls: [URL]) {
        guard formatCaps?.supportsEditing == true else {
            toast = String(localized: "toast.edit_not_supported")
            return
        }
        Task { await performAdd(urls: urls) }
    }

    private func performAdd(urls: [URL]) async {
        let pairs = ArchiveWriterService.pairsForAdding(urls: urls, archiveInternalPrefix: browseFolderPath)
        guard !pairs.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await writer.addItems(zipURL: archiveURL, pairs: pairs)
            toast = String(format: String(localized: "toast.added_n"), pairs.count)
            await load(forceNewPassword: false)
        } catch {
            loadError = error.localizedDescription
        }
    }

    func presentProtectZipSheet() {
        protectZipPassword = ""
        protectZipConfirm = ""
        protectZipFormError = nil
        showProtectZipSheet = true
    }

    func submitProtectZipPassword() async {
        protectZipFormError = nil
        guard protectZipPassword == protectZipConfirm else {
            protectZipFormError = String(localized: "error.password_mismatch")
            return
        }
        guard !protectZipPassword.isEmpty else {
            protectZipFormError = String(localized: "error.password_empty")
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await writer.applyPassphrase(
                zipURL: archiveURL,
                readPassphrase: sessionPassphrase,
                newPassphrase: protectZipPassword
            )
            sessionPassphrase = protectZipPassword
            showProtectZipSheet = false
            protectZipPassword = ""
            protectZipConfirm = ""
            toast = String(localized: "toast.zip_protected")
            await load(forceNewPassword: false)
        } catch {
            loadError = error.localizedDescription
        }
    }

    /// Orden estable según la lista visible (evita que `Set.first` desincronice inspector / vista previa).
    func firstSelectedRecord() -> ArchiveEntryRecord? {
        guard !selection.isEmpty else { return nil }
        if let row = listItems.first(where: { selection.contains($0.id) }) {
            return row
        }
        guard let id = selection.first else { return nil }
        return index?.record(forFullPath: id)
    }

    /// Si hay varias filas seleccionadas y esta está entre ellas, se arrastran todas (orden de lista); si no, solo `item`.
    func recordsForDrag(from item: ArchiveEntryRecord) -> [ArchiveEntryRecord] {
        if selection.count > 1, selection.contains(item.id) {
            return listItems.filter { selection.contains($0.id) }
        }
        return [item]
    }

    /// Arrastra al Finder: copia temporal vía libarchive; varios ítems → carpeta temporal con la estructura de rutas internas.
    func itemProviderForDrag(from item: ArchiveEntryRecord) -> NSItemProvider {
        let records = recordsForDrag(from: item)
        let arch = archiveURL
        let pass = sessionPassphrase
        let provider = NSItemProvider()
        provider.registerFileRepresentation(
            forTypeIdentifier: UTType.item.identifier,
            fileOptions: [],
            visibility: .all
        ) { completion in
            Task {
                do {
                    let url = try await ArchiveExtractionService.exportTemporaryRootForDrag(
                        records: records,
                        archiveURL: arch,
                        passphrase: pass
                    )
                    completion(url, true, nil)
                } catch {
                    completion(nil, false, error)
                }
            }
            return nil
        }
        return provider
    }

    func cleanupTemp() {
        Task { await tempWorkspace.invalidate(archiveURL: archiveURL) }
    }
}
