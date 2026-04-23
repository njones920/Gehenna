// MARK: - Rumor Engine
// Rituals, mutations, and taboo acts produce rumor seeds.
// Rumors move between NPCs over time, mutate as they hop, and decay as they age.
// The Expression Layer reads rumor content. It does not invent it.

import Foundation

public enum RumorKind: String, Codable, Hashable, Sendable {
    case ritual
    case mutation
    case bloodOffering
    case tabooViolation
    case spiritSighting
    case siteDisturbance

    public var priestlyInterest: Double {
        switch self {
        case .tabooViolation, .bloodOffering, .mutation: 1.4
        case .ritual, .spiritSighting: 1.2
        case .siteDisturbance: 0.8
        }
    }

    public var traderCarryingRate: Double {
        switch self {
        case .ritual, .siteDisturbance, .spiritSighting: 1.2
        case .bloodOffering, .mutation: 0.9
        case .tabooViolation: 1.0
        }
    }

    public var mutationBias: Double {
        switch self {
        case .mutation: 0.45
        case .tabooViolation: 0.4
        case .bloodOffering, .spiritSighting: 0.25
        case .ritual, .siteDisturbance: 0.18
        }
    }
}

public struct Rumor: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let ancestorID: UUID?
    public let originTick: Int
    public let originSiteID: UUID?
    public let kind: RumorKind

    public var originSiteName: String
    public var subjectDescriptor: String
    public var act: String
    public var timeDescriptor: String
    public var strength: Double
    public var mutationCount: Int
    public var hearers: Set<UUID>
    public var lastPropagatedTick: Int

    public init(
        id: UUID = UUID(),
        ancestorID: UUID? = nil,
        originTick: Int,
        originSiteID: UUID? = nil,
        kind: RumorKind,
        originSiteName: String,
        subjectDescriptor: String,
        act: String,
        timeDescriptor: String,
        strength: Double,
        mutationCount: Int = 0,
        hearers: Set<UUID> = [],
        lastPropagatedTick: Int = 0
    ) {
        self.id = id
        self.ancestorID = ancestorID
        self.originTick = originTick
        self.originSiteID = originSiteID
        self.kind = kind
        self.originSiteName = originSiteName
        self.subjectDescriptor = subjectDescriptor
        self.act = act
        self.timeDescriptor = timeDescriptor
        self.strength = max(0.0, min(1.0, strength))
        self.mutationCount = mutationCount
        self.hearers = hearers
        self.lastPropagatedTick = lastPropagatedTick
    }

    public var sentence: String {
        "\(subjectDescriptor) \(act) at \(originSiteName) \(timeDescriptor)."
    }

    public var isExtinct: Bool { strength < 0.02 }
}

public struct RumorPropagationEvent: Sendable {
    public let rumorID: UUID
    public let fromNPC: UUID
    public let toNPC: UUID
    public let tick: Int
    public let mutated: Bool
    public let newRumorID: UUID?

    public init(
        rumorID: UUID,
        fromNPC: UUID,
        toNPC: UUID,
        tick: Int,
        mutated: Bool,
        newRumorID: UUID? = nil
    ) {
        self.rumorID = rumorID
        self.fromNPC = fromNPC
        self.toNPC = toNPC
        self.tick = tick
        self.mutated = mutated
        self.newRumorID = newRumorID
    }
}

public struct RumorLedger: Codable, Sendable {
    public var rumors: [UUID: Rumor]
    public var propagationCounter: UInt64

    public init(rumors: [UUID: Rumor] = [:], propagationCounter: UInt64 = 0) {
        self.rumors = rumors
        self.propagationCounter = propagationCounter
    }

    public var active: [Rumor] {
        rumors.values
            .filter { !$0.isExtinct }
            .sorted { $0.strength > $1.strength }
    }

    public func carried(by npcID: UUID) -> [Rumor] {
        rumors.values
            .filter { $0.hearers.contains(npcID) && !$0.isExtinct }
            .sorted { $0.strength > $1.strength }
    }

    public func strongestRumor(for faction: Faction, among npcs: [NPC]) -> Rumor? {
        let members = Set(npcs.filter { $0.faction == faction }.map(\.id))
        return rumors.values
            .filter { !$0.isExtinct && !$0.hearers.isDisjoint(with: members) }
            .max(by: { $0.strength < $1.strength })
    }

    @discardableResult
    public mutating func seed(_ rumor: Rumor) -> UUID {
        var seededRumor = rumor
        if seededRumor.lastPropagatedTick == 0 {
            seededRumor.lastPropagatedTick = seededRumor.originTick
        }
        rumors[seededRumor.id] = seededRumor
        return seededRumor.id
    }

    public mutating func recordHearing(rumorID: UUID, by npcID: UUID, at tick: Int) {
        guard var rumor = rumors[rumorID] else { return }
        rumor.hearers.insert(npcID)
        rumor.lastPropagatedTick = tick
        rumors[rumorID] = rumor
    }

    public mutating func propagate(
        npcs: inout [NPC],
        tick: Int
    ) -> [RumorPropagationEvent] {
        var events: [RumorPropagationEvent] = []
        let orderedCarrierIDs = npcs
            .sorted { $0.stableEventSalt < $1.stableEventSalt }
            .map(\.id)

        for carrierID in orderedCarrierIDs {
            guard let carrier = npcs.first(where: { $0.id == carrierID }) else { continue }

            let candidates = rumors.values
                .filter { rumor in
                    rumor.hearers.contains(carrierID)
                        && !rumor.isExtinct
                        && tick - rumor.lastPropagatedTick >= 1
                }
                .sorted { $0.strength > $1.strength }

            guard let rumor = candidates.first else { continue }
            guard let targetIndex = chooseTarget(carrier: carrier, npcs: npcs, rumor: rumor) else { continue }

            let target = npcs[targetIndex]
            if rumor.hearers.contains(target.id) { continue }

            propagationCounter &+= 1
            let hopSeed = deterministicSeed(
                rumorID: rumor.id,
                fromID: carrierID,
                toID: target.id,
                tick: tick,
                counter: propagationCounter
            )
            let shouldMutate = mutationRoll(seed: hopSeed, bias: rumor.kind.mutationBias)

            if shouldMutate {
                var child = mutate(rumor, seed: hopSeed, tick: tick)
                child.hearers.insert(target.id)
                child.lastPropagatedTick = tick
                rumors[child.id] = child

                if var parent = rumors[rumor.id] {
                    parent.lastPropagatedTick = tick
                    parent.strength = max(0.0, parent.strength - 0.01)
                    rumors[rumor.id] = parent
                }

                npcs[targetIndex].hear(child, at: tick)
                events.append(RumorPropagationEvent(
                    rumorID: rumor.id,
                    fromNPC: carrierID,
                    toNPC: target.id,
                    tick: tick,
                    mutated: true,
                    newRumorID: child.id
                ))
            } else {
                if var parent = rumors[rumor.id] {
                    parent.hearers.insert(target.id)
                    parent.lastPropagatedTick = tick
                    parent.strength = max(0.0, parent.strength * 0.92)
                    rumors[rumor.id] = parent
                }

                npcs[targetIndex].hear(rumors[rumor.id] ?? rumor, at: tick)
                events.append(RumorPropagationEvent(
                    rumorID: rumor.id,
                    fromNPC: carrierID,
                    toNPC: target.id,
                    tick: tick,
                    mutated: false
                ))
            }
        }

        return events
    }

    public mutating func decay(tick: Int) {
        for id in rumors.keys {
            guard var rumor = rumors[id] else { continue }
            let sinceLastHop = Double(max(0, tick - rumor.lastPropagatedTick))
            let ageFactor = 1.0 + min(0.04, sinceLastHop * 0.004)
            rumor.strength = max(0.0, rumor.strength - 0.005 * ageFactor)
            if rumor.isExtinct {
                rumors.removeValue(forKey: id)
            } else {
                rumors[id] = rumor
            }
        }
    }

    private func mutate(_ rumor: Rumor, seed: UInt64, tick: Int) -> Rumor {
        var child = Rumor(
            id: UUID(),
            ancestorID: rumor.ancestorID ?? rumor.id,
            originTick: rumor.originTick,
            originSiteID: rumor.originSiteID,
            kind: rumor.kind,
            originSiteName: rumor.originSiteName,
            subjectDescriptor: rumor.subjectDescriptor,
            act: rumor.act,
            timeDescriptor: rumor.timeDescriptor,
            strength: max(0.05, rumor.strength * 0.8),
            mutationCount: rumor.mutationCount + 1,
            hearers: [],
            lastPropagatedTick: tick
        )

        switch Int(seed % 3) {
        case 0:
            child.subjectDescriptor = distortSubject(seed: seed)
        case 1:
            child.timeDescriptor = distortTime(seed: seed)
        default:
            child.originSiteName = distortSite(seed: seed)
        }

        return child
    }

    private func chooseTarget(
        carrier: NPC,
        npcs: [NPC],
        rumor: Rumor
    ) -> Int? {
        var best: (index: Int, score: Double)?
        for (index, candidate) in npcs.enumerated() {
            if candidate.id == carrier.id { continue }
            if rumor.hearers.contains(candidate.id) { continue }

            let factionWeight: Double = {
                if candidate.faction == carrier.faction { return 1.0 }
                // Traders are the natural bridge between faction silos. Give them a
                // slightly stronger cross-faction rumor intake so village chatter
                // can actually move instead of stalling inside the first witness set.
                if candidate.faction == .traders { return 0.6 }
                return 0.45
            }()
            let kindWeight: Double = switch candidate.faction {
            case .priesthood: rumor.kind.priestlyInterest
            case .traders: rumor.kind.traderCarryingRate
            case .elders: 1.0
            }
            let trustWeight: Double = 0.6 + candidate.trust * 0.4
            let carrierPush: Double = 0.5 + carrier.personalSuspicion * 0.8
            let score = factionWeight * kindWeight * trustWeight * carrierPush * rumor.strength

            if best == nil || score > best!.score {
                best = (index, score)
            }
        }

        guard let picked = best, picked.score > 0.05 else { return nil }
        return picked.index
    }

    private func mutationRoll(seed: UInt64, bias: Double) -> Bool {
        Double(seed % 1000) / 1000.0 < bias
    }

    private func deterministicSeed(
        rumorID: UUID,
        fromID: UUID,
        toID: UUID,
        tick: Int,
        counter: UInt64
    ) -> UInt64 {
        var seed = counter
        seed &+= UInt64(tick)
        seed &+= UInt64(rumorID.uuid.0) << 32
        seed &+= UInt64(rumorID.uuid.7) << 24
        seed &+= UInt64(fromID.uuid.0) << 16
        seed &+= UInt64(toID.uuid.0) << 8
        seed &+= UInt64(rumorID.uuid.15)
        return seed
    }

    private func distortSubject(seed: UInt64) -> String {
        let alternatives = [
            "a stranger",
            "a foreigner",
            "someone from outside",
            "a young one",
            "a scholar from the coast",
            "a quiet one who asks after graves",
            "one of the travelers",
            "the one who stays up at night",
        ]
        return alternatives[Int(seed % UInt64(alternatives.count))]
    }

    private func distortTime(seed: UInt64) -> String {
        let alternatives = [
            "under a dark moon",
            "on the deep night",
            "when the stars were wrong",
            "at the turning of the month",
            "during the last new moon",
            "in the hour before dawn",
            "at dusk",
            "when everyone else was asleep",
        ]
        return alternatives[Int(seed % UInt64(alternatives.count))]
    }

    private func distortSite(seed: UInt64) -> String {
        let alternatives = [
            "the caves above the wadi",
            "the old ruin on the hill",
            "the ash place",
            "the battlefield stones",
            "the hollow by the spring",
            "a place the elders do not name",
        ]
        return alternatives[Int(seed % UInt64(alternatives.count))]
    }
}
