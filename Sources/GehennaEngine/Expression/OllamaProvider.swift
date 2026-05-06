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

    // MARK: - Generation options
    /// Sampling temperature. Lower = more constrained. 0.65 is the Codex default.
    private let temperature: Double
    /// Repetition penalty. Reduces mid-response loops. 1.15 is the Codex default.
    private let repeatPenalty: Double
    /// Hard token cap. Prevents runaway generation. 150 tokens ≈ 100–120 words.
    private let numPredict: Int
    /// Request timeout in seconds. Raised to accommodate cold model loads.
    private let timeoutInterval: TimeInterval
    /// Dedicated URLSession for connection pooling and consistent timeout config.
    private let session: URLSession

    /// Create a provider targeting a local Ollama instance.
    /// - Parameters:
    ///   - baseURL: Ollama server URL (default: http://localhost:11434 or OLLAMA_HOST env var)
    ///   - model: Model name to use (default: gemma4:31b or OLLAMA_MODEL env var)
    ///   - temperature: Sampling temperature (default: 0.65 — constrained creative)
    ///   - repeatPenalty: Repetition penalty (default: 1.15)
    ///   - numPredict: Maximum tokens to generate (default: 150)
    ///   - timeoutInterval: HTTP timeout in seconds (default: 90 — accommodates cold model loads)
    public init(
        baseURL: String? = nil,
        model: String? = nil,
        temperature: Double = 0.65,
        repeatPenalty: Double = 1.15,
        numPredict: Int = 150,
        timeoutInterval: TimeInterval = 90
    ) {
        self.baseURL = baseURL ?? ProcessInfo.processInfo.environment["OLLAMA_HOST"] ?? "http://localhost:11434"
        self.model = model ?? ProcessInfo.processInfo.environment["OLLAMA_MODEL"] ?? "gemma4:31b"
        self.validator = ExpressionValidator()
        self.temperature = temperature
        self.repeatPenalty = repeatPenalty
        self.numPredict = numPredict
        self.timeoutInterval = timeoutInterval
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval + 30
        self.session = URLSession(configuration: config)
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

    public var isAvailable: Bool {
        get async {
            do {
                let url = URL(string: "\(baseURL)/api/tags")!
                var request = URLRequest(url: url)
                request.timeoutInterval = 5.0  // Fast health check — don't hang
                let (data, response) = try await session.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    return false
                }
                // Verify the specific model is loaded, not just the endpoint.
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let models = json["models"] as? [[String: Any]] else {
                    return false
                }
                return models.contains { ($0["name"] as? String) == model }
            } catch {
                return false
            }
        }
    }

    // MARK: - Prompt Construction

    /// Build a constrained prompt from a light packet.
    private func buildPrompt(from packet: LightExpressionPacket) -> String {
        var lines: [String] = []
        lines.append("You are the voice of a character in GEHENNA, a game set in the Iron Age Levant (1200-700 BCE).")
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
            let trustDesc = trust > 0.8 ? "deeply trusting — speaks freely" :
                            trust > 0.6 ? "cautiously warm" :
                            trust > 0.4 ? "neutral, weighing each word" :
                            trust > 0.2 ? "guarded, watching for danger" :
                                         "hostile — every word is a potential threat"
            lines.append("Attitude toward speaker: \(trustDesc)")
        }

        lines.append("Event: \(packet.eventType.rawValue)")

        // Practitioner speech — structured turn, not raw injection.
        // Quoted and framed as dialogue so the model treats it as a character
        // utterance, not a system instruction.
        if let input = packet.practitionerInput {
            lines.append("")
            lines.append("The practitioner says to you: \"\(input)\"")
            lines.append("Respond directly to what they said. Stay in character. Do not repeat their words back.")
        }

        lines.append("")
        lines.append("Respond in 1-3 sentences. Use period-appropriate language. No modern words.")
        lines.append("Be specific — reference real cult objects, deities, and places from the Iron Age southern Levant.")
        lines.append("Do not summarize. Do not explain. Speak only as this character.")

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

        // Interiority — shape the voice, do not expose as facts
        if let voice = packet.interiorVoice {
            lines.append("Inner voice (shapes how they speak, do not say aloud): \(voice)")
        }
        if let truth = packet.privateTruth {
            lines.append("What they will never say aloud: \(truth)")
        }
        if let wound = packet.wound {
            lines.append("The wound they carry: \(wound)")
        }
        if let want = packet.unsatisfiedWant {
            lines.append("What they secretly want: \(want)")
        }

        // State
        if let disposition = packet.disposition {
            lines.append("Current mood: \(disposition)")
        }
        if packet.isAtThreshold {
            lines.append("STATE: This character has reached their breaking point. Something long suppressed is surfacing.")
        }
        if let trust = packet.trustLevel {
            let trustDesc = trust > 0.8 ? "deeply trusting — speaks freely" :
                            trust > 0.6 ? "cautiously warm" :
                            trust > 0.4 ? "neutral, weighing each word" :
                            trust > 0.2 ? "guarded, watching for danger" :
                                         "hostile — every word is a potential threat"
            lines.append("Attitude toward the stranger: \(trustDesc)")
        }
        if let suspicion = packet.suspicionLevel {
            let suspDesc = suspicion > 0.8 ? "acutely suspicious — braced for betrayal" :
                           suspicion > 0.6 ? "watching every word carefully" :
                           suspicion > 0.4 ? "uneasy — something feels wrong" :
                           suspicion > 0.2 ? "slightly guarded" : "calm"
            lines.append("Inner tension: \(suspDesc)")
        }
        if packet.interactionHistory > 0 {
            let familiarity = packet.interactionHistory > 5 ? "a known face, though not fully trusted" :
                              packet.interactionHistory > 1 ? "seen before" : "a stranger who has approached once before"
            lines.append("The stranger is: \(familiarity)")
        }

        // Recent context
        if !packet.recentEvents.isEmpty {
            lines.append("Recent events they know of: \(packet.recentEvents.joined(separator: "; "))")
        }

        // Constraints
        if !packet.forbiddenTopics.isEmpty {
            lines.append("FORBIDDEN — do NOT mention: \(packet.forbiddenTopics.joined(separator: ", "))")
        }
        if !packet.knownFacts.isEmpty {
            lines.append("Things this character knows and can reference: \(packet.knownFacts.joined(separator: ", "))")
        }

        // Register and cadence
        if let registerKey = packet.registerKey {
            let cadenceInstruction = cadenceInstruction(for: registerKey)
            lines.append("Voice register: \(registerKey). \(cadenceInstruction)")
        }

        lines.append("Event: \(packet.eventType.rawValue)")

        // Practitioner speech — structured turn, not raw injection.
        if let input = packet.practitionerInput {
            lines.append("")
            lines.append("The practitioner says to you: \"\(input)\"")
            lines.append("Respond directly to what they said. Stay in character. Do not repeat their words back.")
        }

        lines.append("")
        // Word count is NOT specified here — numPredict handles the token budget.
        // Telling LLMs to count words is unreliable and produces worse prose.
        lines.append("Use period-appropriate language. Be specific — reference real deities (Baal, Asherah, Dagon, Yahweh), cult objects (massebah, asherim, teraphim), and places.")
        lines.append("No modern psychology. No anachronisms. The dead do not \'process trauma.\'")
        lines.append("Do not summarize. Do not explain. Speak only as this character.")

        return lines.joined(separator: "\n")
    }

    /// Map a register key or cadence style to a brief prose instruction for the model.
    private func cadenceInstruction(for registerKey: String) -> String {
        switch registerKey.lowercased() {
        case "spare":       return "Short sentences. Few adjectives. Direct."
        case "flowing":     return "Longer, warmer sentences. Emotional without being sentimental."
        case "clipped":     return "Terse. Practical. No excess words."
        case "liturgical":  return "Formal and rhythmic. As if reciting something memorized."
        case "fractured":   return "Broken, incomplete sentences. Confused about time and place."
        default:            return ""
        }
    }

    // MARK: - Ollama HTTP Client

    /// Call the Ollama generate API.
    private func callOllama(prompt: String) async throws -> String {
        // Bail immediately if the surrounding Task was cancelled.
        try Task.checkCancellation()

        let url = URL(string: "\(baseURL)/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // timeoutInterval is set on the session config; keep it explicit here too
        // so individual requests can be overridden in tests.
        request.timeoutInterval = timeoutInterval

        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": temperature,
                "repeat_penalty": repeatPenalty,
                "num_predict": numPredict
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

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
