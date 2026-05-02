// MARK: - NPC Model
// NPCs are not behavioral specifications. They are people. (v3 §5.7)
//
// It is tempting — and it is a trap — to model NPCs as variable configurations.
// A simulation engine that treats an NPC as a state machine produces NPCs who
// feel like state machines. The mechanical layer is necessary. It is not sufficient.
//
// Every named NPC needs:
// - An interior voice — how they narrate their own life to themselves
// - A private truth — something true about them the practitioner may never learn
// - A want the system cannot satisfy — something beyond their mechanical function
// - A wound — what shaped them before the practitioner arrived
// - A register — how they speak, what they reference, what they avoid
// - A threshold — what would break them open

import Foundation

/// The faction an NPC belongs to — determines their social role and suspicion response.
public enum Faction: String, Codable, Hashable, CaseIterable, Sendable {
    case elders          // the village leadership, conservative, protective
    case traders         // merchant class, pragmatic, information-connected
    case priesthood      // religious authority, hostile to necromancy, network of informants
}

/// An NPC's voice register — how they speak, drawn from culture, role, and personality.
public struct VoiceRegister: Codable, Hashable, Sendable {
    /// The vocabulary range and cadence this NPC uses.
    public let style: Style

    /// Topics this NPC references naturally in conversation.
    public let references: [String]

    /// Topics this NPC actively avoids.
    public let avoids: [String]

    public enum Style: String, Codable, Hashable, Sendable {
        case formal       // precise, measured, official
        case vernacular   // common speech, earthy, practical
        case priestly     // ritualistic language, indirect, authoritative
        case merchant     // transactional, evaluating, worldly
        case guarded      // terse, evasive, watching
        case warm         // open, generous, familial
    }

    public init(
        style: Style,
        references: [String] = [],
        avoids: [String] = []
    ) {
        self.style = style
        self.references = references
        self.avoids = avoids
    }
}

/// The interiority of a named NPC — what makes them a person, not a state machine.
public struct NPCInteriority: Codable, Hashable, Sendable {
    /// How they narrate their own life to themselves.
    /// This is what the Expression Layer draws on to render their voice.
    public let interiorVoice: String

    /// Something true about them the practitioner may never learn.
    public let privateTruth: String

    /// Something they want that the system cannot satisfy.
    public let unsatisfiedWant: String

    /// What shaped them before the practitioner arrived.
    public let wound: String

    /// What would break them open — the condition under which they reveal depth.
    public let threshold: String

    public init(
        interiorVoice: String,
        privateTruth: String,
        unsatisfiedWant: String,
        wound: String,
        threshold: String
    ) {
        self.interiorVoice = interiorVoice
        self.privateTruth = privateTruth
        self.unsatisfiedWant = unsatisfiedWant
        self.wound = wound
        self.threshold = threshold
    }
}

/// A named NPC in the world with behavioral state and authored interiority.
public struct NPC: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let role: String
    public let faction: Faction

    // -- Behavioral Layer (mechanical) --
    /// Trust toward the practitioner. Starts neutral.
    public var trust: Double

    /// How suspicious this NPC is of the practitioner's real activities.
    public var personalSuspicion: Double

    /// Whether this NPC has witnessed or heard about necromantic activity.
    public var hasHeardRumors: Bool

    /// Whether this NPC has directly witnessed the practitioner practicing.
    public var hasWitnessedDirectly: Bool

    /// Specific rumors this NPC carries, keyed by rumor ID.
    /// Authoritative content lives in the ledger; this is the NPC's carrier set.
    public var heardRumorIDs: Set<UUID>

    /// The strongest rumor this NPC last heard.
    /// This is a presentation hint; the ledger remains authoritative.
    public var lastHeardRumorID: UUID?

    /// Voice register for the Expression Layer.
    public let register: VoiceRegister

    /// Narrative tags for procedural generation of unnamed NPCs.
    public let tags: TagConstellation

    // -- Interiority Layer (authored) --
    /// The inner life that makes this NPC a person.
    public let interiority: NPCInteriority

    // -- Temporal State --
    /// When the practitioner last interacted with this NPC.
    public var lastInteractionTick: Int?

    public init(
        id: UUID = UUID(),
        name: String,
        role: String,
        faction: Faction,
        trust: Double = 0.5,
        personalSuspicion: Double = 0.0,
        hasHeardRumors: Bool = false,
        hasWitnessedDirectly: Bool = false,
        heardRumorIDs: Set<UUID> = [],
        lastHeardRumorID: UUID? = nil,
        register: VoiceRegister,
        tags: TagConstellation = TagConstellation(),
        interiority: NPCInteriority
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.faction = faction
        self.trust = trust
        self.personalSuspicion = personalSuspicion
        self.hasHeardRumors = hasHeardRumors
        self.hasWitnessedDirectly = hasWitnessedDirectly
        self.heardRumorIDs = heardRumorIDs
        self.lastHeardRumorID = lastHeardRumorID
        self.register = register
        self.tags = tags
        self.interiority = interiority
        self.lastInteractionTick = nil
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, role, faction, trust, personalSuspicion
        case hasHeardRumors, hasWitnessedDirectly
        case heardRumorIDs, lastHeardRumorID
        case register, tags, interiority, lastInteractionTick
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.role = try c.decode(String.self, forKey: .role)
        self.faction = try c.decode(Faction.self, forKey: .faction)
        self.trust = try c.decode(Double.self, forKey: .trust)
        self.personalSuspicion = try c.decode(Double.self, forKey: .personalSuspicion)
        self.hasHeardRumors = try c.decode(Bool.self, forKey: .hasHeardRumors)
        self.hasWitnessedDirectly = try c.decode(Bool.self, forKey: .hasWitnessedDirectly)
        self.heardRumorIDs = try c.decodeIfPresent(Set<UUID>.self, forKey: .heardRumorIDs) ?? []
        self.lastHeardRumorID = try c.decodeIfPresent(UUID.self, forKey: .lastHeardRumorID)
        self.register = try c.decode(VoiceRegister.self, forKey: .register)
        self.tags = try c.decode(TagConstellation.self, forKey: .tags)
        self.interiority = try c.decode(NPCInteriority.self, forKey: .interiority)
        self.lastInteractionTick = try c.decodeIfPresent(Int.self, forKey: .lastInteractionTick)
    }

    // MARK: - Behavioral Methods

    /// Process a rumor reaching this NPC. Suspicion increases;
    /// how much depends on their faction and existing trust.
    public mutating func hearRumor(strength: Double = 0.1) {
        hasHeardRumors = true
        let factionMultiplier: Double = switch faction {
        case .priesthood: 1.5  // priests are primed to notice
        case .elders:     1.2  // elders protect the community
        case .traders:    0.7  // traders are pragmatic
        }
        personalSuspicion = min(1.0, personalSuspicion + strength * factionMultiplier)
        trust = max(0.0, trust - strength * 0.3)
    }

    /// Record a specific rumor reaching this NPC.
    /// This preserves the carried rumor ID for later rendering and
    /// applies the existing suspicion/trust consequences.
    public mutating func hear(_ rumor: Rumor, at tick: Int) {
        guard !heardRumorIDs.contains(rumor.id) else { return }
        heardRumorIDs.insert(rumor.id)
        lastHeardRumorID = rumor.id
        lastInteractionTick = tick
        hearRumor(strength: rumor.strength * rumorImpactMultiplier(for: rumor.kind))
    }

    private func rumorImpactMultiplier(for kind: RumorKind) -> Double {
        switch (faction, kind) {
        case (.priesthood, .tabooViolation), (.priesthood, .bloodOffering), (.priesthood, .mutation):
            return 1.3
        case (.elders, .tabooViolation), (.elders, .siteDisturbance):
            return 1.1
        case (.traders, .ritual), (.traders, .spiritSighting):
            return 0.85
        default:
            return 1.0
        }
    }

    /// Process a positive interaction — trade, conversation, aid.
    public mutating func positiveInteraction(strength: Double = 0.1) {
        trust = min(1.0, trust + strength)
        // Positive interactions reduce suspicion slightly, but never below what was witnessed
        if !hasWitnessedDirectly {
            personalSuspicion = max(0.0, personalSuspicion - strength * 0.2)
        }
    }

    /// The NPC sees the practitioner doing something suspicious.
    public mutating func witnessActivity(severity: Double = 0.3) {
        hasWitnessedDirectly = true
        personalSuspicion = min(1.0, personalSuspicion + severity)
        trust = max(0.0, trust - severity * 0.5)
    }

    /// Per-tick state processing. Called by the world clock.
    /// Suspicion and trust drift slowly when the practitioner isn't interacting.
    public mutating func tickState() {
        // Suspicion from rumors fades very slowly (not from direct witnessing)
        if !hasWitnessedDirectly && personalSuspicion > 0 {
            personalSuspicion = max(0.0, personalSuspicion - 0.002)
        }

        // Trust drifts toward neutral (0.5) very slowly when not interacting
        if trust > 0.55 {
            trust = max(0.5, trust - 0.001)
        } else if trust < 0.45 {
            trust = min(0.5, trust + 0.001)
        }
    }

    /// Whether this NPC would refuse to interact with the practitioner.
    public var isRefusing: Bool {
        personalSuspicion > 0.7 && trust < 0.3
    }

    /// Whether this NPC would seek the practitioner out.
    /// High trust + some suspicion = they want to talk. Threshold proximity = they need to.
    public var wouldApproach: Bool {
        (trust > 0.75 && personalSuspicion > 0.2) || isAtThreshold
    }

    /// Whether this NPC would leave a location the practitioner enters.
    /// Very high suspicion + low trust = flee on sight.
    public var wouldFlee: Bool {
        personalSuspicion > 0.8 && trust < 0.2
    }

    /// Whether this NPC has reached their threshold — the condition under
    /// which their interiority breaks through and they reveal depth.
    /// This is a narrative opportunity, not a mechanical state.
    public var isAtThreshold: Bool {
        // Thresholds are crossed when trust is very high OR suspicion is very high
        // Combined with specific conditions described in their interiority.threshold
        trust > 0.85 || (personalSuspicion > 0.8 && trust > 0.4)
    }

    /// Behavioral descriptor for diegetic display — no numbers.
    public var behaviorDescription: String {
        if isRefusing {
            return "Steps back. Won't meet your eyes."
        } else if hasWitnessedDirectly {
            return "Watches you carefully. Something has changed in the way they see you."
        } else if personalSuspicion > 0.5 {
            return "Guarded. The easy warmth is gone."
        } else if hasHeardRumors {
            return "Polite but careful. Something they've heard has made them cautious."
        } else if trust > 0.7 {
            return "Open. Willing to talk. There is a warmth here that isn't forced."
        } else {
            return "Neutral. A stranger to a stranger."
        }
    }

    /// Stable-enough local salt for deterministic director scheduling.
    public var stableEventSalt: Int {
        name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
    }
}

