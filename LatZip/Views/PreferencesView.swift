//
//  PreferencesView.swift
//  LatZip
//

import SwiftUI

/// Ventana de preferencias (macOS ⌘,).
struct PreferencesView: View {
    @EnvironmentObject private var app: ArchiveAppState

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
                } header: {
                    Text(String(localized: "prefs.extraction_section"))
                } footer: {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(String(localized: "prefs.extraction_footer"))
                        Text(String(localized: "prefs.extraction_collision_prompt_footer"))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .font(AppTypography.caption)
                }

                Section {
                    Picker(String(localized: "prefs.app_language"), selection: app.appLanguageBinding) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.pickerTitle).tag(lang)
                        }
                    }
                    .pickerStyle(.radioGroup)
                } header: {
                    Text(String(localized: "prefs.language_section"))
                } footer: {
                    Text(String(localized: "prefs.language.relaunch_footer"))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .formStyle(.grouped)
            .frame(width: 440, height: 420)
            .tabItem {
                Label(String(localized: "prefs.tab_general"), systemImage: "gearshape")
            }
        }
        .frame(minWidth: 460, minHeight: 460)
    }
}
