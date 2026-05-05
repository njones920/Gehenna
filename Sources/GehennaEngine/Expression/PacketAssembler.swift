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

    /// Build a full packet for an important NPC interaction (threshold, etc).
    public func fullPacket(
        for npc: NPC,
        event: ExpressionEvent,
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
            unsatisfiedWant: npc.interiority.unsatisfiedWant
        )
    }

    // MARK: - Spirit Packets

    /// Build a full packet for spirit speech.
    public func spiritPacket(
        for spirit: Spirit,
        event: ExpressionEvent,
        practitioner: PractitionerProfile
    ) -> FullExpressionPacket {
        FullExpressionPacket(
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
            recentEvents: []
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
