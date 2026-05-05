// MARK: - Authored Line Bank
// Tier 1 expression: pre-authored lines that require no generation.
// Used for critical beats and as the fallback when the LLM is unavailable.
//
// The line bank is keyed by (entityType, eventType) with optional
// refinements for culture, disposition, and register key.

import Foundation

/// A single authored line with its selection metadata.
public struct AuthoredLine: Codable, Sendable {
    /// Which entity type this line is for.
    public let entityType: String
    /// Which event type this line is for.
    public let eventType: String
    /// Optional culture filter (Philistine, Israelite, Canaanite, etc.)
    public let culture: String?
    /// Optional disposition filter (wrathful, sorrowful, neutral, etc.)
    public let disposition: String?
    /// Optional voice register key.
    public let registerKey: String?
    /// The authored text.
    public let text: String
    /// Priority — higher priority lines are selected first.
    public let priority: Int

    public init(
        entityType: String,
        eventType: String,
        culture: String? = nil,
        disposition: String? = nil,
        registerKey: String? = nil,
        text: String,
        priority: Int = 0
    ) {
        self.entityType = entityType
        self.eventType = eventType
        self.culture = culture
        self.disposition = disposition
        self.registerKey = registerKey
        self.text = text
        self.priority = priority
    }
}

/// The authored line bank — loads from JSON, provides best-match lookup.
public struct AuthoredLineBank: Sendable {
    private let lines: [AuthoredLine]

    public init(lines: [AuthoredLine] = []) {
        self.lines = lines
    }

    /// Load the line bank from the bundled JSON resource.
    public static func loadFromBundle() -> AuthoredLineBank {
        guard let url = Bundle.module.url(forResource: "authored_lines", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let lines = try? JSONDecoder().decode([AuthoredLine].self, from: data) else {
            // If no authored lines exist yet, return empty bank.
            // The system will use Display.swift's existing functions as fallback.
            return AuthoredLineBank()
        }
        return AuthoredLineBank(lines: lines)
    }

    /// Find the best matching line for the given context.
    /// Scoring: exact culture match (+3), exact disposition match (+2),
    /// exact register key match (+1), plus the line's priority.
    public func bestMatch(
        entityType: ExpressionEntity,
        eventType: ExpressionEvent,
        culture: String? = nil,
        disposition: String? = nil,
        registerKey: String? = nil
    ) -> String {
        let entityStr = entityType.rawValue
        let eventStr = eventType.rawValue

        let candidates = lines.filter { line in
            line.entityType == entityStr && line.eventType == eventStr
        }

        if candidates.isEmpty {
            return fallbackLine(for: eventType)
        }

        let scored = candidates.map { line -> (AuthoredLine, Int) in
            var score = line.priority
            if let culture, line.culture == culture { score += 3 }
            if let disposition, line.disposition == disposition { score += 2 }
            if let registerKey, line.registerKey == registerKey { score += 1 }
            return (line, score)
        }

        let best = scored.max(by: { $0.1 < $1.1 })
        return best?.0.text ?? fallbackLine(for: eventType)
    }

    /// Minimal fallback when no authored line matches at all.
    private func fallbackLine(for eventType: ExpressionEvent) -> String {
        switch eventType {
        case .greeting:
            return "Eyes meet. A moment passes."
        case .friendlyResponse:
            return "A nod. Words are exchanged."
        case .regionResponse:
            return "They speak of the land, the weather, the roads."
        case .deadResponse:
            return "A pause. The subject of the dead is never easy."
        case .thresholdResponse:
            return "Something shifts. For a moment, you see them clearly."
        case .ritualAutopsy:
            return "The rite is complete. What remains tells its own story."
        case .codexEntry:
            return "You record what you observed."
        case .worldNarration:
            return "The world turns."
        case .rumorContent:
            return "Words travel."
        case .spiritSpeech:
            return "A voice, thin as smoke."
        case .spiritRefusal:
            return "Silence. The dead do not always answer."
        case .spiritDeparture:
            return "Gone. As if they were never here."
        }
    }
}
