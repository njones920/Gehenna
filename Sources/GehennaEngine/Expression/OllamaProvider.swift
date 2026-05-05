// MARK: - Ollama Expression Provider
// Local LLM generation via Ollama HTTP API.
// Uses the constrained generation pattern:
//   state packet → prompt constitution → model → validation → output
//
// Ollama is free, runs locally, and the lessons learned here
// transfer directly to larger models later.
// The ExpressionProvider protocol means swapping backends is a one-file change.

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Ollama HTTP client implementing ExpressionProvider.
public actor OllamaProvider: ExpressionProvider {
    private let baseURL: String
    private let model: String
    private let validator: ExpressionValidator

    /// Create a provider targeting a local Ollama instance.
    /// - Parameters:
    ///   - baseURL: Ollama server URL (default: http://localhost:11434 or OLLAMA_HOST env var)
    ///   - model: Model name to use (default: gemma4:31b or OLLAMA_MODEL env var)
    public init(
        baseURL: String? = nil,
        model: String? = nil
    ) {
        self.baseURL = baseURL ?? ProcessInfo.processInfo.environment["OLLAMA_HOST"] ?? "http://localhost:11434"
        self.model = model ?? ProcessInfo.processInfo.environment["OLLAMA_MODEL"] ?? "gemma4:31b"
        self.validator = ExpressionValidator()
    }

    // MARK: - ExpressionProvider conformance

    public func generate(from packet: LightExpressionPacket) async -> ExpressionResult {
        let prompt = buildPrompt(from: packet)
        do {
            let response = try await callOllama(prompt: prompt)
            let validated = validator.validate(response, packet: packet)
            switch validated {
            case .valid(let text):
                return .generated(text)
            case .invalid(let text, let issues):
                return .validationFailed(text, reason: issues.joined(separator: "; "))
            }
        } catch {
            return .unavailable("Ollama unavailable: \(error.localizedDescription)")
        }
    }

    public func generate(from packet: FullExpressionPacket) async -> ExpressionResult {
        let prompt = buildPrompt(from: packet)
        do {
            let response = try await callOllama(prompt: prompt)
            let validated = validator.validate(response, packet: packet)
            switch validated {
            case .valid(let text):
                return .generated(text)
            case .invalid(let text, let issues):
                return .validationFailed(text, reason: issues.joined(separator: "; "))
            }
        } catch {
            return .unavailable("Ollama unavailable: \(error.localizedDescription)")
        }
    }

    public nonisolated var isAvailable: Bool {
        get async {
            do {
                let url = URL(string: "\(baseURL)/api/tags")!
                let (_, response) = try await URLSession.shared.data(from: url)
                return (response as? HTTPURLResponse)?.statusCode == 200
            } catch {
                return false
            }
        }
    }

    // MARK: - Prompt Construction

    /// Build a constrained prompt from a light packet.
    private func buildPrompt(from packet: LightExpressionPacket) -> String {
        var lines: [String] = []
        lines.append("You are the voice of a character in GEHENNA, a game set in the Iron Age Levant.")
        lines.append("You produce ONLY the character's speech. No narration. No stage directions. No quotation marks.")
        lines.append("")

        if let name = packet.entityName {
            lines.append("Character: \(name)")
        }
        lines.append("Type: \(packet.entityType.rawValue)")
        if let culture = packet.culture {
            lines.append("Culture: \(culture)")
        }
        if let disposition = packet.disposition {
            lines.append("Current mood: \(disposition)")
        }
        if let trust = packet.trustLevel {
            let trustDesc = trust > 0.7 ? "trusting" : trust < 0.3 ? "distrustful" : "cautious"
            lines.append("Attitude toward speaker: \(trustDesc)")
        }

        lines.append("Event: \(packet.eventType.rawValue)")
        lines.append("")
        lines.append("Respond in 1-3 sentences. Use period-appropriate language. No modern words.")
        lines.append("Be specific — reference real cult objects, deities, and places from the Iron Age southern Levant.")

        return lines.joined(separator: "\n")
    }

    /// Build a constrained prompt from a full packet.
    private func buildPrompt(from packet: FullExpressionPacket) -> String {
        var lines: [String] = []
        lines.append("You are the voice of a character in GEHENNA, a game set in the Iron Age Levant (1200-700 BCE).")
        lines.append("You produce ONLY the character's speech. No narration. No stage directions. No quotation marks.")
        lines.append("")

        // Identity
        if let name = packet.entityName {
            lines.append("Character: \(name)")
        }
        lines.append("Type: \(packet.entityType.rawValue)")
        if let culture = packet.culture {
            lines.append("Culture: \(culture)")
        }
        if let era = packet.era {
            lines.append("Era: \(era.rawValue)")
        }

        // Interiority
        if let voice = packet.interiorVoice {
            lines.append("Inner voice: \(voice)")
        }
        if let wound = packet.wound {
            lines.append("Wound: \(wound)")
        }

        // State
        if let disposition = packet.disposition {
            lines.append("Current mood: \(disposition)")
        }
        if packet.isAtThreshold {
            lines.append("STATE: This character has reached their breaking point. They are about to reveal something deep.")
        }
        if let trust = packet.trustLevel {
            let trustDesc = trust > 0.7 ? "trusting" : trust < 0.3 ? "deeply distrustful" : "cautious"
            lines.append("Attitude toward speaker: \(trustDesc)")
        }

        // Constraints
        if !packet.forbiddenTopics.isEmpty {
            lines.append("FORBIDDEN — do NOT mention: \(packet.forbiddenTopics.joined(separator: ", "))")
        }
        if !packet.knownFacts.isEmpty {
            lines.append("Known facts to reference: \(packet.knownFacts.joined(separator: ", "))")
        }

        // Register
        if let registerKey = packet.registerKey {
            lines.append("Voice style: \(registerKey)")
        }

        lines.append("Event: \(packet.eventType.rawValue)")
        lines.append("")
        lines.append("Respond in \(packet.allowedLengthMin)-\(packet.allowedLengthMax) words.")
        lines.append("Use period-appropriate language. Be specific — reference real deities (Baal, Asherah, Dagon, Yahweh), cult objects (massebah, asherim, teraphim), and places.")
        lines.append("No modern psychology. No anachronisms. The dead do not 'process trauma.'")

        return lines.joined(separator: "\n")
    }

    // MARK: - Ollama HTTP Client

    /// Call the Ollama generate API.
    private func callOllama(prompt: String) async throws -> String {
        let url = URL(string: "\(baseURL)/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.badResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = json["response"] as? String else {
            throw OllamaError.invalidJSON
        }

        return responseText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private enum OllamaError: Error, LocalizedError {
        case badResponse
        case invalidJSON

        var errorDescription: String? {
            switch self {
            case .badResponse: return "Ollama returned a non-200 response"
            case .invalidJSON: return "Ollama response was not valid JSON"
            }
        }
    }
}
