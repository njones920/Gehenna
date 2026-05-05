// MARK: - Expression Packet
// The contract between the engine and the Expression Layer.
// The Expression Layer renders this into language. It never decides what the state is.
//
// Two tiers:
// - LightPacket: routine events (greetings, simple responses)
// - FullPacket:  important moments (ritual autopsy, spirit speech, threshold)

import Foundation

// MARK: - Entity and Event Types

/// What kind of entity is speaking.
public enum ExpressionEntity: String, Codable, Sendable {
    case spirit
    case npc
    case practitioner
    case world
    case codex
}

/// What kind of expression event this is.
public enum ExpressionEvent: String, Codable, Sendable {
    // NPC interactions
    case greeting
    case friendlyResponse
    case regionResponse
    case deadResponse
    case thresholdResponse
    // Ritual
    case ritualAutopsy
    case codexEntry
    // World
    case worldNarration
    case rumorContent
    // Spirit
    case spiritSpeech
    case spiritRefusal
    case spiritDeparture
}

/// Cadence style for voice register rendering.
public enum CadenceStyle: String, Codable, Sendable {
    case spare       // short sentences, few adjectives (soldiers, ancient dead)
    case flowing     // longer, warmer (women, priests)
    case clipped     // terse, practical (traders, smiths)
    case liturgical  // formal, rhythmic (priests, prophets)
    case fractured   // broken, confused (recently dead, mutated spirits)
}

// MARK: - Light Packet

/// Minimal context for routine expression events.
/// Used for greetings, simple responses, and other low-stakes rendering.
public struct LightExpressionPacket: Sendable, Codable, Hashable {
    /// Who is speaking.
    public let entityType: ExpressionEntity
    public let entityName: String?
    public let entityTags: TagConstellation

    /// Current emotional baseline.
    public let disposition: String?

    /// NPC trust toward practitioner (0-1).
    public let trustLevel: Double?

    /// What kind of event to render.
    public let eventType: ExpressionEvent

    /// Culture for voice register selection.
    public let culture: String?

    public init(
        entityType: ExpressionEntity,
        entityName: String? = nil,
        entityTags: TagConstellation = TagConstellation(),
        disposition: String? = nil,
        trustLevel: Double? = nil,
        eventType: ExpressionEvent,
        culture: String? = nil
    ) {
        self.entityType = entityType
        self.entityName = entityName
        self.entityTags = entityTags
        self.disposition = disposition
        self.trustLevel = trustLevel
        self.eventType = eventType
        self.culture = culture
    }
}

// MARK: - Full Packet

/// Complete context for important expression events.
/// Used for ritual autopsy, spirit speech, threshold responses, Codex entries.
public struct FullExpressionPacket: Sendable, Codable, Hashable {
    // -- Core (same as light) --
    public let entityType: ExpressionEntity
    public let entityName: String?
    public let entityTags: TagConstellation
    public let disposition: String?
    public let trustLevel: Double?
    public let eventType: ExpressionEvent
    public let culture: String?

    // -- Extended context --
    /// NPC suspicion level (0-1).
    public let suspicionLevel: Double?

    /// Whether the NPC has reached their narrative threshold.
    public let isAtThreshold: Bool

    /// Era for temporal register selection.
    public let era: Era?

    /// Voice register key for constitution lookup.
    public let registerKey: String?

    // -- Content constraints --
    /// Things this entity knows and can reference.
    public let knownFacts: [String]

    /// Things this entity will NOT say (taboos, avoidances).
    public let forbiddenTopics: [String]

    /// Allowed word count range for the output.
    public let allowedLengthMin: Int
    public let allowedLengthMax: Int

    // -- Relationship context --
    /// Number of previous interactions with the practitioner.
    public let interactionHistory: Int

    /// Recent journal events relevant to this entity.
    public let recentEvents: [String]

    // -- Interiority (NPC only) --
    public let interiorVoice: String?
    public let privateTruth: String?
    public let wound: String?
    public let unsatisfiedWant: String?

    public init(
        entityType: ExpressionEntity,
        entityName: String? = nil,
        entityTags: TagConstellation = TagConstellation(),
        disposition: String? = nil,
        trustLevel: Double? = nil,
        eventType: ExpressionEvent,
        culture: String? = nil,
        suspicionLevel: Double? = nil,
        isAtThreshold: Bool = false,
        era: Era? = nil,
        registerKey: String? = nil,
        knownFacts: [String] = [],
        forbiddenTopics: [String] = [],
        allowedLengthMin: Int = 5,
        allowedLengthMax: Int = 80,
        interactionHistory: Int = 0,
        recentEvents: [String] = [],
        interiorVoice: String? = nil,
        privateTruth: String? = nil,
        wound: String? = nil,
        unsatisfiedWant: String? = nil
    ) {
        self.entityType = entityType
        self.entityName = entityName
        self.entityTags = entityTags
        self.disposition = disposition
        self.trustLevel = trustLevel
        self.eventType = eventType
        self.culture = culture
        self.suspicionLevel = suspicionLevel
        self.isAtThreshold = isAtThreshold
        self.era = era
        self.registerKey = registerKey
        self.knownFacts = knownFacts
        self.forbiddenTopics = forbiddenTopics
        self.allowedLengthMin = allowedLengthMin
        self.allowedLengthMax = allowedLengthMax
        self.interactionHistory = interactionHistory
        self.recentEvents = recentEvents
        self.interiorVoice = interiorVoice
        self.privateTruth = privateTruth
        self.wound = wound
        self.unsatisfiedWant = unsatisfiedWant
    }
}
