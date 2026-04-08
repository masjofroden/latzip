//
//  ArchiveKeychainService.swift
//  LatZip
//

import Foundation
import Security

/// Contraseñas por ruta canónica del archivo (genérico, servicio fijo).
enum ArchiveKeychainService {
    private static let service = "com.latzip.LatZip.archivePassphrase"

    private static func account(for url: URL) -> String {
        url.standardizedFileURL.path
    }

    static func passphrase(for archiveURL: URL) -> String? {
        let account = account(for: archiveURL)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(passphrase: String, for archiveURL: URL) {
        delete(for: archiveURL)
        let account = account(for: archiveURL)
        guard let data = passphrase.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func delete(for archiveURL: URL) {
        let account = account(for: archiveURL)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
