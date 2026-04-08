//
//  AppTypography.swift
//  LatZip
//

import SwiftUI

/// Tipografía semántica de la app.
enum AppTypography {
    static let appTitle = Font.system(size: 17, weight: .semibold)
    static let sectionHeader = Font.system(size: 11, weight: .semibold)
    static let body = Font.system(size: 13, weight: .regular)
    static let bodyMedium = Font.system(size: 13, weight: .medium)
    static let metadata = Font.system(size: 12, weight: .regular)
    static let caption = Font.system(size: 11, weight: .regular)
    static let columnHeader = Font.system(size: 12, weight: .semibold)
    static let columnChevron = Font.system(size: 9, weight: .bold)
    static let welcomeTitle = Font.system(size: 20, weight: .semibold)
    static let emptyTitle = Font.system(size: 17, weight: .semibold)
}
