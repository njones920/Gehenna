// MARK: - Expression Provider Protocol
// The boundary between the Expression Layer and whatever generates text.
// Ollama today. Something else tomorrow. The engine never knows.

import Foundation

/// The result of an expression generation attempt.
public enum ExpressionResult: Sendable {
    /// Successfully generated text that passed validation.
    case generated(String)
    /// Generation succeeded but validation failed; includes the reason.
    case validationFailed(String, reason: String)
    /// The provider could not generate (offline, rate limited, etc).
    /// Falls back to authored lines.
    case unavailable(String)
}

/// Protocol for anything that can turn an expression packet into text.
/// Implementations: OllamaProvider (local LLM), AuthoredLineBank (fallback).
public protocol ExpressionProvider: Sendable {
    /// Generate text from a light packet (routine events).
    func generate(from packet: LightExpressionPacket) async -> ExpressionResult

    /// Generate text from a full packet (important events).
    func generate(from packet: FullExpressionPacket) async -> ExpressionResult

    /// Whether this provider is currently available.
    var isAvailable: Bool { get async }

    /// Classify a practitioner utterance into one intent word from the
    /// `ConversationalIntent` raw-value set. Providers without a model
    /// return nil — the engine degrades to heuristics-only, fail-safe.
    /// Declared as a requirement (not just an extension) so existentials
    /// dispatch to the real implementation.
    func classifyIntent(_ input: String, forbiddenTopics: [String]) async -> String?

    /// Extract concrete new claims a speaker asserted in generated speech
    /// (names, places, events). The Oracle-lane harvest: what the model
    /// improvised becomes recorded simulation input. Providers without a
    /// model return an empty list.
    func harvestClaims(from speech: String, speakerName: String) async -> [String]

    /// Propose one world event from current context — the Conway lane.
    /// The proposal is typed and bounded; the caller validates and commits.
    /// Providers without a model return nil.
    func proposeWorldEvent(context: String, npcNames: [String]) async -> WorldEventProposal?
}

public extension ExpressionProvider {
    /// Default: no model, no classification.
    func classifyIntent(_ input: String, forbiddenTopics: [String]) async -> String? {
        nil
    }

    /// Default: no model, no harvest.
    func harvestClaims(from speech: String, speakerName: String) async -> [String] {
        []
    }

    /// Default: no model, no proposals.
    func proposeWorldEvent(context: String, npcNames: [String]) async -> WorldEventProposal? {
        nil
    }
}

/// The authored-line fallback. Always available. No generation cost.
/// Selects the best matching line from the authored line bank
/// based on the packet's entity type, event type, and disposition.
public struct AuthoredLineProvider: ExpressionProvider {
    private let lineBank: AuthoredLineBank

    public init(lineBank: AuthoredLineBank) {
        self.lineBank = lineBank
    }

    public func generate(from packet: LightExpressionPacket) async -> ExpressionResult {
        let line = lineBank.bestMatch(
            entityType: packet.entityType,
            eventType: packet.eventType,
            culture: packet.culture,
            disposition: packet.disposition
        )
        return .generated(line)
    }

    public func generate(from packet: FullExpressionPacket) async -> ExpressionResult {
        let line = lineBank.bestMatch(
            entityType: packet.entityType,
            eventType: packet.eventType,
            culture: packet.culture,
            disposition: packet.disposition,
            registerKey: packet.registerKey
        )
        return .generated(line)
    }

    public var isAvailable: Bool { true }
}
