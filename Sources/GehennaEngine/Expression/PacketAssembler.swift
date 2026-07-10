// MARK: - Packet Assembler
// Builds ExpressionPackets from existing engine state.
// The assembler reads NPC, Spirit, PractitionerProfile, and world state
// and produces typed packets that the Expression Layer can render.
// The assembler never generates text — it produces the contract.

import Foundation

/// Assembles expression packets from engine state.
public struct PacketAssembler: Sendable {

    public init() {}

    // MARK: - NPC Packets

    /// Build a light packet for a routine NPC interaction.
    public func lightPacket(
        for npc: NPC,
        event: ExpressionEvent
    ) -> LightExpressionPacket {
        LightExpressionPacket(
            entityType: .npc,
            entityName: npc.name,
            entityTags: npc.tags,
            disposition: npc.behavioralDisposition,
            trustLevel: npc.trust,
            eventType: event,
            culture: npc.culturalAffiliation
        )
    }

    /// Build a full packet for an important NPC interaction (threshold, free-form chat, etc).
    public func fullPacket(
        for npc: NPC,
        event: ExpressionEvent,
        practitionerInput: String? = nil,
        recentEvents: [String] = [],
        interactionCount: Int = 0
    ) -> FullExpressionPacket {
        FullExpressionPacket(
            entityType: .npc,
            entityName: npc.name,
            entityTags: npc.tags,
            disposition: npc.behavioralDisposition,
            trustLevel: npc.trust,
            eventType: event,
            culture: npc.culturalAffiliation,
            suspicionLevel: npc.personalSuspicion,
            isAtThreshold: npc.isAtThreshold,
            era: nil,
            registerKey: npc.register.style.rawValue,
            knownFacts: [],
            forbiddenTopics: npc.register.avoids,
            allowedLengthMin: minLength(for: event),
            allowedLengthMax: maxLength(for: event),
            interactionHistory: interactionCount,
            recentEvents: recentEvents,
            interiorVoice: npc.interiority.interiorVoice,
            privateTruth: npc.interiority.privateTruth,
            wound: npc.interiority.wound,
            unsatisfiedWant: npc.interiority.unsatisfiedWant,
            practitionerInput: practitionerInput
        )
    }

    // MARK: - Spirit Packets

    /// Build a full packet for spirit speech. When the spirit resolves to a
    /// known root identity, its epoch's authored interiority shapes the voice
    /// from the very first words.
    public func spiritPacket(
        for spirit: Spirit,
        event: ExpressionEvent,
        practitioner: PractitionerProfile,
        rootIdentity: RootIdentity? = nil
    ) -> FullExpressionPacket {
        let epoch = rootIdentity?.epochs.first { $0.name == spirit.epochName }
        return FullExpressionPacket(
            entityType: .spirit,
            entityName: spirit.epochName,
            entityTags: spirit.tags,
            disposition: spirit.disposition.rawValue,
            trustLevel: nil,
            eventType: event,
            culture: spirit.culturalAffiliation,
            suspicionLevel: nil,
            isAtThreshold: false,
            era: spirit.era,
            registerKey: cadenceForSpirit(spirit),
            knownFacts: spirit.personalityTraits.map(\.rawValue),
            forbiddenTopics: spirit.tags.tags
                .filter { $0.dimension == .taboo }
                .map(\.value),
            allowedLengthMin: minLength(for: event),
            allowedLengthMax: maxLength(for: event),
            interactionHistory: 0,
            recentEvents: [],
            interiorVoice: epoch?.interiorVoice,
            privateTruth: epoch?.privateTruth,
            wound: epoch?.wound,
            unsatisfiedWant: epoch?.unsatisfiedWant
        )
    }

    /// Build a full packet for free-form conversation with a bound spirit.
    /// What the spirit can say is simulation truth: facts are assembled from
    /// its tags and root identity, gated by its Knowledge attribute — a
    /// diminished shade holds fragments of its own life; a strong one holds
    /// the shape of it. The Expression Layer phrases; it does not invent.
    public func spiritChatPacket(
        for bound: BoundSpirit,
        input: String?,
        rootIdentity: RootIdentity? = nil,
        relationship: SpiritRelationship? = nil,
        recentEvents: [String] = []
    ) -> FullExpressionPacket {
        let spirit = bound.spirit
        let epoch = rootIdentity?.epochs.first { $0.name == spirit.epochName }

        var facts: [String] = []
        if let trueName = rootIdentity?.trueName {
            facts.append("in life they were called \(trueName)")
        }
        for dimension in [NarrativeTag.Dimension.identity, .deathContext, .relational, .cultural, .disposition] {
            facts.append(contentsOf: spirit.tags.tags(in: dimension).map(\.value))
        }
        facts.append(contentsOf: spirit.personalityTraits.map(\.rawValue))

        // Knowledge gates how much of themselves the dead can still reach.
        let factCap = spirit.attributes.knowledge < 0.3 ? 4
                    : spirit.attributes.knowledge < 0.6 ? 7
                    : 12

        // Relationship memory is not gated by Knowledge — the dead may
        // forget their own lives, but they remember how they were treated.
        // These are concrete moments the Expression Layer can phrase.
        var relationshipFacts: [String] = []
        let stage = relationship?.stage(traits: spirit.personalityTraits)
        if let relationship, let stage {
            relationshipFacts.append("to you, this practitioner is \(stage.descriptor)")
            if relationship.timesSummoned > 1 {
                relationshipFacts.append("this practitioner has called you back \(relationship.timesSummoned) times")
            }
            if let parting = relationship.lastParting {
                switch parting.kind {
                case .releasedWithLibation:
                    relationshipFacts.append("at your last parting they poured an offering and released you properly")
                case .banished:
                    relationshipFacts.append("at your last parting they banished you — torn away without ceremony; you remember it")
                case .leftToFade:
                    relationshipFacts.append("at your last parting they let you dissolve when your strength ran out")
                default:
                    break
                }
            }
            if let name = relationship.nameGiven {
                relationshipFacts.append("they gave you their true name: \(name) — you may speak it")
            }
            // The dead stay consistent with their own inventions: canon
            // this spirit spoke into being returns to it as memory.
            for claim in (relationship.spokenClaims ?? []).suffix(5) {
                relationshipFacts.append("you have said before: \(claim)")
            }
        }

        return FullExpressionPacket(
            entityType: .spirit,
            entityName: spirit.epochName,
            entityTags: spirit.tags,
            disposition: spirit.disposition.rawValue,
            trustLevel: stage?.promptTrust,
            eventType: .spiritChat,
            culture: spirit.culturalAffiliation,
            suspicionLevel: nil,
            isAtThreshold: false,
            era: spirit.era,
            registerKey: cadenceForSpirit(spirit),
            knownFacts: relationshipFacts + Array(facts.prefix(factCap)),
            forbiddenTopics: spirit.tags.tags
                .filter { $0.dimension == .taboo }
                .map(\.value),
            allowedLengthMin: minLength(for: .spiritChat),
            allowedLengthMax: maxLength(for: .spiritChat),
            interactionHistory: max(relationship?.totalExchanges ?? 0, bound.exchangeCount),
            recentEvents: recentEvents,
            interiorVoice: epoch?.interiorVoice,
            privateTruth: epoch?.privateTruth,
            wound: epoch?.wound,
            unsatisfiedWant: epoch?.unsatisfiedWant,
            practitionerInput: input
        )
    }

    // MARK: - World Packets

    /// Build a light packet for world narration.
    public func worldPacket(
        event: ExpressionEvent,
        siteName: String? = nil
    ) -> LightExpressionPacket {
        LightExpressionPacket(
            entityType: .world,
            entityName: siteName,
            eventType: event
        )
    }

    // MARK: - Helpers

    private func minLength(for event: ExpressionEvent) -> Int {
        switch event {
        case .greeting, .friendlyResponse: return 5
        case .regionResponse, .deadResponse: return 10
        case .thresholdResponse: return 15
        case .playerChat: return 5
        case .spiritChat: return 3
        case .ritualAutopsy, .codexEntry: return 20
        case .spiritSpeech: return 3
        case .spiritRefusal, .spiritDeparture: return 3
        case .worldNarration, .rumorContent: return 5
        }
    }

    private func maxLength(for event: ExpressionEvent) -> Int {
        switch event {
        case .greeting, .friendlyResponse: return 40
        case .regionResponse, .deadResponse: return 60
        case .thresholdResponse: return 80
        case .playerChat: return 60
        case .spiritChat: return 70
        case .ritualAutopsy, .codexEntry: return 100
        case .spiritSpeech: return 30
        case .spiritRefusal, .spiritDeparture: return 20
        case .worldNarration, .rumorContent: return 50
        }
    }

    private func cadenceForSpirit(_ spirit: Spirit) -> String {
        // Ancient spirits speak in fragments; recent ones are more fluent
        switch spirit.era {
        case .earlyBronze, .middleBronze: return "spare"
        case .lateBronze: return "liturgical"
        case .ironAgeI, .ironAgeII: return "flowing"
        case .antediluvian: return "spare"
        }
    }
}

// MARK: - NPC Convenience Extensions

extension NPC {
    /// Derive the NPC's current behavioral disposition as a string
    /// for expression packet assembly.
    var behavioralDisposition: String {
        if isRefusing { return "hostile" }
        if hasWitnessedDirectly { return "suspicious" }
        if personalSuspicion > 0.5 { return "guarded" }
        if trust > 0.7 { return "warm" }
        return "neutral"
    }

    /// Derive the NPC's cultural affiliation from their tags.
    var culturalAffiliation: String? {
        tags.tags.first(where: { $0.dimension == .cultural })?.value
    }
}

extension Spirit {
    /// Derive the spirit's cultural affiliation from their tags.
    var culturalAffiliation: String? {
        tags.tags.first(where: { $0.dimension == .cultural })?.value
    }
}
