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

    /// Exposure from a concrete ritual action, not just abstract handling.
    public mutating func handleFragment(_ fragment: Fragment, at site: RitualSite, using libation: Libation?) {
        var contagionDelta = 0.08

        switch fragment.remainsType {
        case .skull, .crematedBone:
            contagionDelta += 0.05
        case .ossuaryChip, .toothFragment:
            contagionDelta += 0.03
        default:
            break
        }

        if fragment.integrity.isCorrupted {
            contagionDelta += 0.12
        } else if fragment.integrity.isDegraded {
            contagionDelta += 0.05
        }

        if site.sanctity > 0.65 {
            contagionDelta += 0.03
        }

        switch site.type {
        case .topheth:
            contagionDelta += 0.10
            purity = max(0.0, purity - 0.06)
        case .ancestorShrine, .burialCave, .ossuaryNiche:
            contagionDelta += 0.02
        default:
            break
        }

        if let libation {
            contagionDelta += libation.corruptionCost * 0.5
            purity = max(0.0, purity - (libation.corruptionCost * 0.25))

            switch libation.type {
            case .water:
                contagionDelta = max(0.03, contagionDelta - 0.02)
            case .fermentedWine, .honeyWine:
                contagionDelta = max(0.03, contagionDelta - 0.01)
            case .bloodOffering, .mimicBlood:
                contagionDelta += 0.04
            case .ritualMixture, .opiumTincture:
                ritualFatigue = min(1.0, ritualFatigue + 0.03)
            }
        }

        corpseContagion = min(1.0, corpseContagion + contagionDelta)
    }

    /// Perform purification — reduces contagion.
    public mutating func purify(strength: Double = 0.5) {
        corpseContagion = max(0.0, corpseContagion - strength)
        ritualFatigue = max(0.0, ritualFatigue - (strength * 0.3))
    }
}

/// Canonical violations of the cosmological order.
public enum Taboo: String, Codable, Hashable, CaseIterable, Sendable {
    case bloodshed          // violence committed at a site or in ritual
    case graveRobbing       // removing fragments without ritual compensation
    case falseName          // attempting to bind a spirit using a deliberately wrong name
    case uncleanSacrifice   // using heavily corrupted fragments at high-sanctity sites
    case oathBreaking       // betraying a loyal spirit
    case tophethPact        // performing sacrifices at a Topheth site
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

    /// Violations that permanently mark the practitioner.
    public var taboosBroken: Set<Taboo>

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
        self.taboosBroken = []
        self.suspicionByRegion = [:]
        self.spiritRelationships = [:]
    }

    /// The Noob Catalyst principle: a completely unburdened practitioner.
    public var cleanHands: Bool {
        totalRituals == 0 && taboosBroken.isEmpty && tokens.corpseContagion == 0.0
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

    /// World-facing identity/accountability accrual from a concrete ritual.
    public mutating func applyRitualConsequences(
        configuration: RitualConfiguration,
        result: RitualResult
    ) {
        tokens.handleFragment(
            configuration.remains,
            at: configuration.site,
            using: configuration.libation
        )

        if configuration.site.type.requiresFuneraryCompensation,
           configuration.libation == nil {
            taboosBroken.insert(.graveRobbing)
        }

        if configuration.site.sanctity > 0.65,
           configuration.remains.integrity.isCorrupted {
            taboosBroken.insert(.uncleanSacrifice)
        }

        if configuration.site.type == .topheth,
           let libation = configuration.libation,
           libation.type == .bloodOffering || libation.type == .mimicBlood {
            taboosBroken.insert(.tophethPact)
        }

        if result.outcomeClass == .hostile {
            tokens.ritualFatigue = min(1.0, tokens.ritualFatigue + 0.05)
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
