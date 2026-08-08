import Security
import Foundation

final class KeychainManager {
    static let shared = KeychainManager()
    
    private let masterService = "services.psemanagement.supergrok.master"
    private let subKeyService = "services.psemanagement.supergrok.subkeys"
    private let accessGroup = "services.psemanagement.supergrok"
    
    // MARK: - Master Key (Admin only, never leaves this Mac's Keychain)
    func saveMasterKey(_ key: String) throws {
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: masterService,
            kSecAttrAccount as String: "xai-master",
            kSecAttrAccessGroup as String: accessGroup,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }
    }
    
    func getMasterKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: masterService,
            kSecAttrAccount as String: "xai-master",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func hasMasterKey() -> Bool { getMasterKey() != nil }
    
    // MARK: - Sub Keys
    func saveSubKey(_ key: OfficeKey) {
        guard let data = try? JSONEncoder().encode(key) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: subKeyService,
            kSecAttrAccount as String: key.id,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func loadAllSubKeys() -> [OfficeKey] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: subKeyService,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let items = item as? [Data] else { return [] }
        return items.compactMap { try? JSONDecoder().decode(OfficeKey.self, from: $0) }
    }
    
    func revokeSubKey(id: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: subKeyService,
            kSecAttrAccount as String: id
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
}
