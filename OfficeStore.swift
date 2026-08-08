import Foundation
import Combine
import SwiftUI

struct OfficeKey: Identifiable, Codable {
    let id: String
    let value: String
    let module: String
    let scopes: [String]
    let createdAt: Date
}

enum BrainStatus {
    case idle, online, thinking, error(String)
}

@MainActor
final class OfficeStore: ObservableObject {
    static let shared = OfficeStore()
    
    @Published var isOfficeActive = false
    @Published var activeKeys: [OfficeKey] = []
    @Published var selectedModule: OfficeModule = .chat
    @Published var brainStatus: BrainStatus = .idle
    
    private let keychain = KeychainManager.shared
    private let masterService = "services.psemanagement.supergrok.master"
    
    // MARK: - Bootstrap: Everything Starts There
    func bootstrapOffice() {
        if keychain.hasMasterKey() {
            isOfficeActive = true
            loadActiveKeys()
            brainStatus = .online
        }
    }
    
    func provisionMasterKey(_ rawKey: String) throws {
        try keychain.saveMasterKey(rawKey)
        isOfficeActive = true
        Task { await provisionAllModules() }
    }
    
    // MARK: - API Key Factory (Core)
    func getOrCreateMasterKey() -> String {
        if let existing = keychain.getMasterKey() { return existing }
        fatalError("Master key not provisioned. Call provisionMasterKey first.")
    }
    
    func createOfficeSubKey(for module: String, scopes: [String]) -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8).lowercased()
        let key = "sk-pse-office-\(module)-\(uuid)"
        let officeKey = OfficeKey(id: UUID().uuidString, value: key, module: module, scopes: scopes, createdAt: Date())
        keychain.saveSubKey(officeKey)
        activeKeys.append(officeKey)
        return key
    }
    
    func provisionAllModules() async {
        let modules = ["chat", "docs", "projects", "inbox", "calendar", "imagine", "team", "drive"]
        for m in modules {
            if !activeKeys.contains(where: { $0.module == m }) {
                _ = createOfficeSubKey(for: m, scopes: defaultScopes(for: m))
            }
        }
        brainStatus = .online
    }
    
    private func defaultScopes(for module: String) -> [String] {
        switch module {
        case "chat": return ["chat", "memory"]
        case "imagine": return ["image", "video"]
        case "docs": return ["chat", "vision"]
        default: return ["chat"]
        }
    }
    
    private func loadActiveKeys() {
        activeKeys = keychain.loadAllSubKeys()
    }
}
