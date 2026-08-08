import Security
import Foundation

/// PSE OFFICE OS — Layer 0 Key Forge
/// Bundle: services.psemanagement.supergrok
/// Master never leaves Keychain (ThisDeviceOnly). Sub-keys are internal office identifiers.
final class KeychainManager {
    static let shared = KeychainManager()
    
    private let masterService = "services.psemanagement.supergrok.master"
    private let officeService = "services.psemanagement.supergrok.office"
    private let subKeyService = "services.psemanagement.supergrok.subkeys"
    private let accessGroup: String? = nil
    private let accessibility = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    
    func saveMasterKey(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("xai-") || trimmed.count > 20 else {
            throw KeychainError.invalidMasterKey
        }
        let data = Data(trimmed.utf8)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: masterService,
            kSecAttrAccount as String: "xai-master",
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility
        ]
        applyAccessGroup(&query)
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }
        
        var officeQuery = query
        officeQuery[kSecAttrService as String] = officeService
        officeQuery[kSecAttrAccount as String] = "master"
        SecItemDelete(officeQuery as CFDictionary)
        SecItemAdd(officeQuery as CFDictionary, nil)
    }
    
    func getMasterKey() -> String? {
        if let k = readPassword(service: masterService, account: "xai-master") { return k }
        return readPassword(service: officeService, account: "master")
    }
    
    func hasMasterKey() -> Bool { getMasterKey() != nil }
    
    func saveSubKey(_ key: OfficeKey) {
        guard let data = try? JSONEncoder().encode(key) else { return }
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: subKeyService,
            kSecAttrAccount as String: key.id,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility
        ]
        applyAccessGroup(&query)
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
        
        var modQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(officeService).\(key.module)",
            kSecAttrAccount as String: key.value,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility
        ]
        applyAccessGroup(&modQuery)
        SecItemDelete(modQuery as CFDictionary)
        SecItemAdd(modQuery as CFDictionary, nil)
    }
    
    func loadAllSubKeys() -> [OfficeKey] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: subKeyService,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        applyAccessGroup(&query)
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let items = item as? [Data] else { return [] }
        return items.compactMap { try? JSONDecoder().decode(OfficeKey.self, from: $0) }
    }
    
    func revokeSubKey(id: String) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: subKeyService,
            kSecAttrAccount as String: id
        ]
        applyAccessGroup(&query)
        SecItemDelete(query as CFDictionary)
    }
    
    func mintOfficeSubKey(module: String, scopes: [String]) -> OfficeKey {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8).lowercased()
        let value = "sk-pse-office-\(module)-\(uuid)"
        return OfficeKey(
            id: UUID().uuidString,
            value: value,
            module: module,
            scopes: scopes,
            createdAt: Date()
        )
    }
    
    private func readPassword(service: String, account: String) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        applyAccessGroup(&query)
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func applyAccessGroup(_ query: inout [String: Any]) {
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
    }
}

enum KeychainError: LocalizedError {
    case invalidMasterKey
    case saveFailed(OSStatus)
    var errorDescription: String? {
        switch self {
        case .invalidMasterKey:
            return "Master key must be a valid xAI key (xai-…)."
        case .saveFailed(let s):
            return "Keychain save failed (OSStatus \(s)). Check entitlements / Keychain Sharing."
        }
    }
}
