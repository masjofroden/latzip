//
//  PreferencesView.swift
//  LatZip
//

import SwiftUI

/// Ventana de preferencias (macOS ⌘,). Una pestaña por tema (sin pestaña «General»).
struct PreferencesView: View {
    @EnvironmentObject private var app: ArchiveAppState
    @State private var showKeyboardShortcutsSheet = false

    /// Altura del contenido por pestaña (~mitad del tamaño anterior); el `Form` hace scroll si hace falta.
    private static let formMaxHeight: CGFloat = 268
    private static let windowMinHeight: CGFloat = 300

    var body: some View {
        TabView {
            Form {
                Section {
                    Picker(String(localized: "prefs.extraction_collision"), selection: app.extractionCollisionPolicyBinding) {
                        ForEach(
                            [ExtractionCollisionPolicy.replace, .skip, .keepBoth],
                            id: \.rawValue
                        ) { policy in
                            Text(policy.localizedTitle).tag(policy)
                        }
                    }
                    .pickerStyle(.radioGroup)
                } footer: {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(String(localized: "prefs.extraction_footer"))
                        Text(String(localized: "prefs.extraction_collision_prompt_footer"))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .font(AppTypography.caption)
                }
            }
            .formStyle(.grouped)
            .frame(width: 440)
            .frame(maxHeight: Self.formMaxHeight)
            .tabItem {
                Label(String(localized: "prefs.tab_extraction"), systemImage: "square.and.arrow.down")
            }

            Form {
                Section {
                    Picker(String(localized: "prefs.app_language"), selection: app.appLanguageBinding) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.pickerTitle).tag(lang)
                        }
                    }
                    .pickerStyle(.radioGroup)
                } footer: {
                    Text(String(localized: "prefs.language.relaunch_footer"))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .formStyle(.grouped)
            .frame(width: 440)
            .frame(maxHeight: Self.formMaxHeight)
            .tabItem {
                Label(String(localized: "prefs.tab_language"), systemImage: "globe")
            }

            Form {
                Section {
                    Picker(String(localized: "prefs.appearance.label"), selection: app.appearanceModeBinding) {
                        ForEach(AppAppearance.allCases) { mode in
                            Text(mode.pickerTitle).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)
                } footer: {
                    Text(String(localized: "prefs.appearance.footer"))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .formStyle(.grouped)
            .frame(width: 440)
            .frame(maxHeight: Self.formMaxHeight)
            .tabItem {
                Label(String(localized: "prefs.tab_appearance"), systemImage: "circle.lefthalf.filled")
            }

            Form {
                Section {
                    Toggle(String(localized: "prefs.keychain_archive_passwords"), isOn: app.archivePasswordKeychainBinding)
                } footer: {
                    Text(String(localized: "prefs.keychain_footer"))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .formStyle(.grouped)
            .frame(width: 440)
            .frame(maxHeight: Self.formMaxHeight)
            .tabItem {
                Label(String(localized: "prefs.tab_security"), systemImage: "key.fill")
            }

            Form {
                Section {
                    Button(String(localized: "prefs.show_shortcuts")) {
                        showKeyboardShortcutsSheet = true
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(String(localized: "prefs.help_shortcuts_footer"))
                        Text(String(localized: "prefs.finder_service_footer"))
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                }
            }
            .formStyle(.grouped)
            .frame(width: 440)
            .frame(maxHeight: Self.formMaxHeight)
            .tabItem {
                Label(String(localized: "prefs.tab_help"), systemImage: "questionmark.circle")
            }
        }
        .frame(minWidth: 460, minHeight: Self.windowMinHeight)
        .sheet(isPresented: $showKeyboardShortcutsSheet) {
            KeyboardShortcutsGuideView()
        }
    }
}
