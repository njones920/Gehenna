// MARK: - Practitioner Profile
// The game's internal model of who the practitioner has become.
// A record built from observed behavior. Not a character sheet.
// Not displayed. Spirits read it. NPCs respond to it.
// The Profile mirrors — it does not mold.

import Foundation

/// Authority tokens — the practitioner's credentials for ritual access.
public struct AuthorityTokens: Codable, Hashable, Sendable {

    /// Hardware tokens — physical artifacts granting authority.
    /// Cylinder seals, priestly implements, inherited ritual objects.
    public var hardwareTokens: [String]

    /// Intrinsic tokens — the practitioner's current bodily state.
    public var purity: Double          // 0.0 = heavily contaminated, 1.0 = ritually pure
    public var corpseContagion: Double  // accumulates from handling fragments
    public var ritualFatigue: Double    // increases with ritual frequency

    /// Relational tokens — authority derived from accumulated behavior.
    public var relationalTokens: [String: Double]  // e.g., "Authorized Cupbearer" -> strength

    public init(
        hardwareTokens: [String] = [],
        purity: Double = 0.8,
        corpseContagion: Double = 0.0,
        ritualFatigue: Double = 0.0,
        relationalTokens: [String: Double] = [:]
    ) {
        self.hardwareTokens = hardwareTokens
        self.purity = purity
        self.corpseContagion = corpseContagion
        self.ritualFatigue = ritualFatigue
        self.relationalTokens = relationalTokens
    }

    /// Effective purity after contagion and fatigue.
    public var effectivePurity: Double {
        max(0.0, purity - corpseContagion - (ritualFatigue * 0.5))
    }

    /// Apply contagion from handling a fragment.
    public mutating func handleFragment() {
        corpseContagion = min(1.0, corpseContagion + 0.1)
    }

    /// Perform purification — reduces contagion.
    public mutating func purify(strength: Double = 0.5) {
        corpseContagion = max(0.0, corpseContagion - strength)
        ritualFatigue = max(0.0, ritualFatigue - (strength * 0.3))
    }
}

/// The practitioner's accumulated behavioral record.
public struct PractitionerProfile: Codable, Sendable, Identifiable {
    public let id: UUID

    // -- Progression (hidden) --
    /// How many spirits the practitioner can sustain simultaneously.
    public var summonerCapacity: Int

    /// Reduces outcome variance on well-constructed configurations. Invisible.
    public var summonerSkill: Double

    // -- Behavioral Record --
    /// Total rituals performed.
    public var totalRituals: Int

    /// Rituals by outcome class.
    public var successfulRituals: Int
    public var failedRituals: Int
    public var mutationRituals: Int

    /// Domain affinity — derived distribution across the five domains.
    public var domainExperience: [Domain: Double]

    /// Cumulative impact on world state.
    public var entropyFootprint: Double

    /// Authority credentials.
    public var tokens: AuthorityTokens

    /// Per-region suspicion history.
    public var suspicionByRegion: [UUID: Double]

    /// Per-spirit relationship memory.
    public var spiritRelationships: [UUID: Double]

    public init(id: UUID = UUID()) {
        self.id = id
        self.summonerCapacity = 1
        self.summonerSkill = 0.0
        self.totalRituals = 0
        self.successfulRituals = 0
        self.failedRituals = 0
        self.mutationRituals = 0
        self.domainExperience = [:]
        self.entropyFootprint = 0.0
        self.tokens = AuthorityTokens()
        self.suspicionByRegion = [:]
        self.spiritRelationships = [:]
    }

    /// Record a completed ritual and update the profile.
    public mutating func recordRitual(
        success: Bool,
        wasMutation: Bool,
        domain: Domain,
        entropyCost: Double
    ) {
        totalRituals += 1
        if success { successfulRituals += 1 } else { failedRituals += 1 }
        if wasMutation { mutationRituals += 1 }

        domainExperience[domain, default: 0.0] += 1.0
        entropyFootprint += entropyCost

        tokens.ritualFatigue = min(1.0, tokens.ritualFatigue + 0.05)

        // Summoner skill improves with diverse successful configurations
        if success {
            summonerSkill = min(1.0, summonerSkill + 0.005)
        }

        // Capacity grows at milestones
        if summonerCapacity == 1 && successfulRituals >= 10 {
            summonerCapacity = 2
        } else if summonerCapacity == 2 && successfulRituals >= 40 {
            summonerCapacity = 3
        }
    }

    /// The practitioner's dominant domain, if any.
    public var dominantDomain: Domain? {
        domainExperience.max(by: { $0.value < $1.value })?.key
    }

    /// Mastery phase based on accumulated experience.
    public var masteryPhase: MasteryPhase {
        switch totalRituals {
        case 0..<10:   return .apprentice
        case 10..<40:  return .practitioner
        case 40..<120: return .adept
        default:       return .master
        }
    }
}

/// The four phases of the mastery arc (§6.6).
public enum MasteryPhase: String, Codable, Hashable, Sendable {
    case apprentice   // learning the basic vocabulary
    case practitioner // perceiving the grammar
    case adept        // understanding both layers
    case master       // composing rituals like a programmer writes functions
}
