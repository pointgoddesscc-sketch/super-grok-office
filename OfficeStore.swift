import Foundation
import Combine
import SwiftUI

struct OfficeKey: Identifiable, Codable, Equatable {
    let id: String
    let value: String
    let module: String
    let scopes: [String]
    let createdAt: Date
}

enum BrainStatus: Equatable {
    case idle, online, thinking, error(String)
}

@MainActor
final class OfficeStore: ObservableObject {
    static let shared = OfficeStore()
    
    @Published var isOfficeActive = false
    @Published var activeKeys: [OfficeKey] = []
    @Published var selectedModule: OfficeModule = .chat
    @Published var brainStatus: BrainStatus = .idle
    @Published var lastError: String?
    
    private let keychain = KeychainManager.shared
    
    // MARK: - Bootstrap: Everything Starts Here (Step 2–4)
    func bootstrapOffice() {
        if keychain.hasMasterKey() {
            isOfficeActive = true
            loadActiveKeys()
            if activeKeys.isEmpty {
                Task { await provisionAllModules() }
            } else {
                brainStatus = .online
            }
        } else {
            brainStatus = .idle
        }
    }
    
    func provisionMasterKey(_ rawKey: String) throws {
        let trimmed = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("xai-") || trimmed.count > 20 else {
            throw OfficeError.invalidMasterKey
        }
        try keychain.saveMasterKey(trimmed)
        isOfficeActive = true
        lastError = nil
        Task { await provisionAllModules() }
    }
    
    // MARK: - API Key Factory (Core)
    func getOrCreateMasterKey() -> String {
        if let existing = keychain.getMasterKey() { return existing }
        fatalError("Master key not provisioned. Call provisionMasterKey first.")
    }
    
    @discardableResult
    func createOfficeSubKey(for module: String, scopes: [String]) -> String {
        let uuid = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8)).lowercased()
        let key = "sk-pse-office-\(module)-\(uuid)"
        let officeKey = OfficeKey(
            id: UUID().uuidString,
            value: key,
            module: module,
            scopes: scopes,
            createdAt: Date()
        )
        keychain.saveSubKey(officeKey)
        if !activeKeys.contains(where: { $0.module == module }) {
            activeKeys.append(officeKey)
        }
        return key
    }
    
    func provisionAllModules() async {
        brainStatus = .thinking
        let modules: [(String, [String])] = [
            ("chat", ["chat", "memory", "tools"]),
            ("docs", ["chat", "vision"]),
            ("projects", ["chat", "tools"]),
            ("inbox", ["chat", "tools"]),
            ("calendar", ["chat", "tools"]),
            ("imagine", ["image", "video"]),
            ("team", ["chat"]),
            ("drive", ["chat", "vision"])
        ]
        for (m, scopes) in modules {
            if !activeKeys.contains(where: { $0.module == m }) {
                _ = createOfficeSubKey(for: m, scopes: scopes)
            }
        }
        brainStatus = .online
    }
    
    func key(for module: String) -> String? {
        activeKeys.first(where: { $0.module == module })?.value
    }
    
    private func loadActiveKeys() {
        activeKeys = keychain.loadAllSubKeys()
    }
    
    func revokeKey(id: String) {
        keychain.revokeSubKey(id: id)
        activeKeys.removeAll { $0.id == id }
    }
}

enum OfficeError: LocalizedError {
    case invalidMasterKey
    var errorDescription: String? {
        switch self {
        case .invalidMasterKey: return "Master key must start with xai- or be a valid xAI API key."
        }
    }
}
