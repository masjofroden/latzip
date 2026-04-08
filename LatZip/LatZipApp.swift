//
//  LatZipApp.swift
//  LatZip
//

import SwiftUI

@main
struct LatZipApp: App {
    @StateObject private var appState = ArchiveAppState()
    @NSApplicationDelegateAdaptor(LatZipAppDelegate.self) private var appDelegate

    init() {
        ArchiveAppState.applyLaunchLanguageFromUserDefaults()
        AppAppearance.applyToSharedApplication(
            AppAppearance(persisted: UserDefaults.standard.string(forKey: AppAppearance.storageKey))
        )
    }

    var body: some Scene {
        WindowGroup {
            MainArchiveShellView()
                .environmentObject(appState)
                .preferredColorScheme(appState.preferredColorScheme)
                .onAppear {
                    appDelegate.bind(appState: appState)
                }
        }
        Settings {
            PreferencesView()
                .environmentObject(appState)
                .preferredColorScheme(appState.preferredColorScheme)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(String(localized: "menu.new_empty_zip")) {
                    appState.createNewEmptyZipArchive()
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button(String(localized: "menu.open_archive")) {
                    appState.openPanel()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            CommandMenu(String(localized: "menu.archive")) {
                Button(String(localized: "menu.extract_to_folder")) {
                    appState.selectedWorkspace?.extractSelected(collision: appState.extractionCollisionPolicy)
                }
                .keyboardShortcut("e", modifiers: [.command])

                Button(String(localized: "menu.extract_here")) {
                    appState.selectedWorkspace?.extractSelectedHere(collision: appState.extractionCollisionPolicy)
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])

                Divider()

                Button(String(localized: "menu.extract_all_to_folder")) {
                    appState.selectedWorkspace?.extractEntireArchive(collision: appState.extractionCollisionPolicy)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Button(String(localized: "menu.extract_all_here")) {
                    appState.selectedWorkspace?.extractEntireArchiveHere(collision: appState.extractionCollisionPolicy)
                }
                .keyboardShortcut("e", modifiers: [.command, .option])

                Divider()

                Button(String(localized: "menu.add_files")) {
                    appState.selectedWorkspace?.addFromFinder()
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])

                Button(String(localized: "menu.protect_zip")) {
                    appState.selectedWorkspace?.presentProtectZipSheet()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(appState.selectedWorkspace?.formatCaps?.supportsZipPassphrase != true)
            }
            CommandGroup(after: .help) {
                Button(String(localized: "help.shortcuts_menu")) {
                    appState.showKeyboardShortcuts = true
                }
            }
        }
    }
}
