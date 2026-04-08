//
//  HelpViews.swift
//  LatZip
//

import SwiftUI

// MARK: - Capability banner

struct ArchiveCapabilityBannerView: View {
    let caps: ArchiveFormatCapabilities
    let onShowHelp: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            Image(systemName: bannerIcon)
                .foregroundStyle(AppColors.textSecondary)
                .symbolRenderingMode(.hierarchical)
            Text(bannerText)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: AppSpacing.sm)
            Button(String(localized: "caps.more_info")) {
                onShowHelp()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.contentBackground.opacity(0.92))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
        }
    }

    private var bannerIcon: String {
        if caps.supportsEditing { return "info.circle" }
        return "lock.circle"
    }

    private var bannerText: String {
        if caps.supportsEditing, caps.supportsZipPassphrase {
            return String(localized: "caps.zip_full")
        }
        if caps.supportsEditing {
            return String(localized: "caps.editable_non_zip")
        }
        return String(localized: "caps.readonly")
    }
}

// MARK: - Formats & limits (sheet)

struct FormatsHelpSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack {
                Text(String(localized: "help.formats_title"))
                    .font(.title2.bold())
                Spacer()
                Button(String(localized: "action.close")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            ScrollView {
                Text(String(localized: "help.formats_body"))
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 280)
        }
        .padding(AppSpacing.xxl)
        .frame(minWidth: 440, minHeight: 400)
    }
}

// MARK: - Keyboard shortcuts (global sheet)

struct KeyboardShortcutsGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack {
                Text(String(localized: "help.shortcuts_title"))
                    .font(.title2.bold())
                Spacer()
                Button(String(localized: "action.close")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    shortcutRow(String(localized: "help.sk.new_archive"), "⌘N")
                    shortcutRow(String(localized: "help.sk.open"), "⌘O")
                    shortcutRow(String(localized: "help.sk.extract_folder"), "⌘E")
                    shortcutRow(String(localized: "help.sk.extract_here"), "⌘⇧H")
                    shortcutRow(String(localized: "help.sk.extract_all_folder"), "⌘⇧E")
                    shortcutRow(String(localized: "help.sk.extract_all_here"), "⌘⌥E")
                    shortcutRow(String(localized: "help.sk.add_files"), "⌘⇧A")
                    shortcutRow(String(localized: "help.sk.protect_zip"), "⌘⇧P")
                    shortcutRow(String(localized: "help.sk.preview"), String(localized: "help.sk.space"))
                    shortcutRow(String(localized: "help.sk.prefs"), "⌘,")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppSpacing.xxl)
        .frame(minWidth: 420, minHeight: 460)
    }

    private func shortcutRow(_ title: String, _ keys: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppTypography.body)
            Spacer()
            Text(keys)
                .font(AppTypography.metadata)
                .monospaced()
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.vertical, 4)
    }
}
