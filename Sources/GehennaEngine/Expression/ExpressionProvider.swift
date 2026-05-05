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
