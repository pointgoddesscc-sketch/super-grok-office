import Foundation

struct XAIResponse: Decodable {
    let id: String?
    let output: [XAIOutput]?
    let output_text: String?
    let model: String?
    let choices: [XAIChoice]?
    
    var text: String {
        if let output_text, !output_text.isEmpty { return output_text }
        if let output, let first = output.first {
            return first.content?.first?.text ?? first.text ?? ""
        }
        return choices?.first?.message?.content ?? ""
    }
}

struct XAIOutput: Decodable {
    let type: String?
    let role: String?
    let content: [XAIContentPart]?
    let text: String?
}

struct XAIContentPart: Decodable {
    let type: String?
    let text: String?
}

struct XAIChoice: Decodable {
    let message: XAIMessage?
}

struct XAIMessage: Decodable {
    let role: String?
    let content: String?
}

struct ImageGenerationResponse: Decodable {
    let data: [ImageData]?
    struct ImageData: Decodable {
        let url: String?
        let b64_json: String?
    }
}

struct VideoStartResponse: Decodable {
    let request_id: String?
    let id: String?
}

struct VideoStatusResponse: Decodable {
    let status: String?
    let state: String?
    let video: VideoInfo?
    let video_url: String?
    let url: String?
    struct VideoInfo: Decodable {
        let url: String?
    }
    
    var resolvedStatus: String { status ?? state ?? "" }
    var resolvedURL: String? { video?.url ?? video_url ?? url }
}

@MainActor
final class XAIClient {
    static let shared = XAIClient()
    private let base = "https://api.x.ai/v1"
    private let session = URLSession.shared
    
    /// Master key from Keychain only (matches office-api-kit.sh)
    private var apiKey: String {
        KeychainManager.shared.getMasterKey() ?? ""
    }
    
    // Defaults aligned with scripts/office-api-kit.sh
    func respond(input: String, model: String = "grok-4") async throws -> String {
        let data = try await post(path: "/responses", body: ["model": model, "input": input])
        return try JSONDecoder().decode(XAIResponse.self, from: data).text
    }
    
    func respond(messages: [[String: String]], model: String = "grok-4") async throws -> String {
        let data = try await post(path: "/responses", body: ["model": model, "input": messages])
        return try JSONDecoder().decode(XAIResponse.self, from: data).text
    }
    
    func chat(system: String, user: String, model: String = "grok-4") async throws -> String {
        try await respond(messages: [
            ["role": "system", "content": system],
            ["role": "user", "content": user]
        ], model: model)
    }
    
    func generateImage(prompt: String, model: String = "grok-imagine-image") async throws -> URL? {
        let data = try await post(path: "/images/generations", body: ["model": model, "prompt": prompt])
        let decoded = try JSONDecoder().decode(ImageGenerationResponse.self, from: data)
        if let urlStr = decoded.data?.first?.url { return URL(string: urlStr) }
        return nil
    }
    
    func generateVideo(prompt: String, model: String = "grok-imagine-video", pollInterval: TimeInterval = 5) async throws -> URL {
        let startData = try await post(path: "/videos/generations", body: ["model": model, "prompt": prompt])
        let start = try JSONDecoder().decode(VideoStartResponse.self, from: startData)
        guard let requestId = start.request_id ?? start.id else { throw XAIError.missingRequestId }
        
        while true {
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
            let statusData = try await get(path: "/videos/\(requestId)")
            let status = try JSONDecoder().decode(VideoStatusResponse.self, from: statusData)
            let s = status.resolvedStatus
            if ["done", "completed", "succeeded"].contains(s) {
                if let urlStr = status.resolvedURL, let url = URL(string: urlStr) { return url }
                throw XAIError.missingVideoURL
            }
            if ["failed", "expired", "error"].contains(s) {
                throw XAIError.videoFailed(s)
            }
        }
    }
    
    private func post(path: String, body: [String: Any]) async throws -> Data {
        guard !apiKey.isEmpty else { throw XAIError.noMasterKey }
        var req = URLRequest(url: URL(string: base + path)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw XAIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw XAIError.apiError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }
    
    private func get(path: String) async throws -> Data {
        guard !apiKey.isEmpty else { throw XAIError.noMasterKey }
        var req = URLRequest(url: URL(string: base + path)!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw XAIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw XAIError.apiError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }
}

enum XAIError: LocalizedError {
    case noMasterKey, invalidResponse, apiError(Int, String), missingRequestId, missingVideoURL, videoFailed(String)
    var errorDescription: String? {
        switch self {
        case .noMasterKey: return "No master xAI key in Keychain. Run onboarding first."
        case .invalidResponse: return "Invalid response from xAI."
        case .apiError(let c, let b): return "xAI \(c): \(b)"
        case .missingRequestId: return "Video generation did not return request_id."
        case .missingVideoURL: return "Video done but no URL."
        case .videoFailed(let s): return "Video generation \(s)."
        }
    }
}
