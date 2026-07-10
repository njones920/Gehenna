// MARK: - Spirit Relationships
// The dead remember. Every summoning, parting, promise, and slight is a
// typed moment in an append-only record. Familiarity is computed from the
// record — deterministically — and the Expression Layer renders it as an
// evolving voice. The LLM never writes here. This ledger is simulation
// truth; the tenth summoning sounds different from the first because of
// what this file remembers.

import Foundation

/// One thing that happened between a practitioner and a spirit.
public struct RelationalMoment: Codable, Hashable, Sendable {
    public let kind: Kind
    public let tick: Int
    /// Optional specifics — a topic, a name, an epoch.
    public let detail: String?

    public init(kind: Kind, tick: Int, detail: String? = nil) {
        self.kind = kind
        self.tick = tick
        self.detail = detail
    }

    public enum Kind: String, Codable, Hashable, Sendable, CaseIterable {
        // Mechanical acts (0.4.30)
        case anchored               // called back and held
        case releasedWithLibation   // respectful parting
        case banished               // torn away mid-breath
        case leftToFade             // allowed to dissolve
        case gaveTrueName           // the practitioner's name, given freely
        // Conversational acts (0.4.31 intent extraction writes these)
        case spokeRespectfully
        case insulted
        case comforted
        case askedForbidden
        case promiseMade
        case promiseKept
        case promiseBroken
    }

    /// How this moment lands, relationally. Deterministic per kind —
    /// the single source of valence truth.
    public var valence: Double {
        switch kind {
        case .anchored: return 0.05
        case .releasedWithLibation: return 0.35
        case .banished: return -0.5
        case .leftToFade: return -0.15
        case .gaveTrueName: return 0.5
        case .spokeRespectfully: return 0.1
        case .insulted: return -0.4
        case .comforted: return 0.25
        case .askedForbidden: return -0.2
        case .promiseMade: return 0.0
        case .promiseKept: return 0.6
        case .promiseBroken: return -0.8
        }
    }
}

/// Where the relationship stands. One axis, two directions: familiarity
/// deepens with contact; regard sours or warms with treatment.
public enum FamiliarityStage: String, Codable, Sendable {
    case stranger
    case named
    case acquainted
    case bonded
    case wary
    case cold
    case hostile

    /// Mapping into the Expression Layer's trust vocabulary.
    public var promptTrust: Double {
        switch self {
        case .stranger: return 0.4
        case .named: return 0.55
        case .acquainted: return 0.7
        case .bonded: return 0.9
        case .wary: return 0.3
        case .cold: return 0.15
        case .hostile: return 0.05
        }
    }

    /// A concrete fact the Expression Layer can phrase.
    public var descriptor: String {
        switch self {
        case .stranger: return "a stranger who has called you back once"
        case .named: return "someone whose call you now recognize"
        case .acquainted: return "a familiar voice among the living — you know their manner"
        case .bonded: return "one of the few living voices you know well; something like an old correspondent"
        case .wary: return "someone you watch carefully; their handling of you has been careless"
        case .cold: return "someone you answer reluctantly; they have treated you poorly"
        case .hostile: return "someone who has wronged you; you remember every slight"
        }
    }
}

/// The accumulated relationship between one practitioner and one spirit,
/// keyed by root identity so every epoch aspect shares the same memory —
/// the Captain remembers what was done to the Butcher.
public struct SpiritRelationship: Codable, Sendable {
    /// rootIdentityID when known, otherwise the spirit's own ID.
    public let rootKey: UUID
    /// Last known name for display — an epoch name or template.
    public var displayName: String

    public var timesSummoned: Int
    public var firstSummonTick: Int
    public var lastSummonTick: Int
    /// Conversation exchanges across all manifestations.
    public var totalExchanges: Int
    /// The practitioner's name, if they gave it. Trust — and a liability.
    public var nameGiven: String?
    /// The append-only record.
    public var moments: [RelationalMoment]

    public init(rootKey: UUID, displayName: String, firstSummonTick: Int) {
        self.rootKey = rootKey
        self.displayName = displayName
        self.timesSummoned = 0
        self.firstSummonTick = firstSummonTick
        self.lastSummonTick = firstSummonTick
        self.totalExchanges = 0
        self.nameGiven = nil
        self.moments = []
    }

    /// Sum of all moment valences — the relationship's net charge.
    public var netValence: Double {
        moments.reduce(0.0) { $0 + $1.valence }
    }

    /// The most recent parting, if any — the thing a spirit wakes remembering.
    public var lastParting: RelationalMoment? {
        moments.last { [.releasedWithLibation, .banished, .leftToFade].contains($0.kind) }
    }

    /// Where the relationship stands, given the spirit's personality.
    /// Deterministic: same record, same traits, same stage.
    public func stage(traits: [PersonalityTrait]) -> FamiliarityStage {
        let valence = netValence
        let soursFast = traits.contains(.spiteful) || traits.contains(.resentful)

        // Souring track
        if valence <= (soursFast ? -0.6 : -1.0) { return .hostile }
        if valence <= (soursFast ? -0.3 : -0.5) { return .cold }
        if valence < -0.05 { return .wary }

        // Warming track
        let bondsEasily = traits.contains(.loyal)
        let neverBonds = traits.contains(.resentful)
        if nameGiven != nil || timesSummoned >= 2 {
            let bondValence = bondsEasily ? 0.5 : 0.9
            if !neverBonds, timesSummoned >= 4 || nameGiven != nil,
               totalExchanges >= 8, valence >= bondValence {
                return .bonded
            }
            if timesSummoned >= 3 || totalExchanges >= 4 { return .acquainted }
            return .named
        }
        return .stranger
    }

    /// Coherence a call-by-name draws from this relationship.
    /// The relationship is the anchor: a bonded spirit answers a bare
    /// fragment; a hostile one gives the name no purchase.
    public func callCoherenceBonus(traits: [PersonalityTrait]) -> Double {
        switch stage(traits: traits) {
        case .bonded: return 0.4
        case .acquainted: return 0.25
        case .named: return 0.15
        case .stranger: return 0.05
        case .wary: return 0.1
        case .cold: return 0.05
        case .hostile: return 0.0
        }
    }
}

/// Every spirit relationship a practitioner carries.
public struct RelationshipLedger: Codable, Sendable {
    public private(set) var relationships: [UUID: SpiritRelationship]

    public init() {
        self.relationships = [:]
    }

    /// The stable relationship key for a spirit: root identity when known,
    /// so all epoch aspects share one memory.
    public static func key(for spirit: Spirit) -> UUID {
        spirit.rootIdentityID ?? spirit.id
    }

    public func relationship(for spirit: Spirit) -> SpiritRelationship? {
        relationships[Self.key(for: spirit)]
    }

    public func relationship(forKey key: UUID) -> SpiritRelationship? {
        relationships[key]
    }

    public var all: [SpiritRelationship] {
        relationships.values.sorted { $0.lastSummonTick > $1.lastSummonTick }
    }

    /// Record a summoning. Creates the relationship on first contact.
    public mutating func noteSummon(of spirit: Spirit, atTick tick: Int) {
        let key = Self.key(for: spirit)
        var rel = relationships[key] ?? SpiritRelationship(
            rootKey: key,
            displayName: spirit.epochName ?? spirit.template.rawValue,
            firstSummonTick: tick
        )
        rel.timesSummoned += 1
        rel.lastSummonTick = tick
        if let epochName = spirit.epochName {
            rel.displayName = epochName
        }
        rel.moments.append(RelationalMoment(kind: .anchored, tick: tick, detail: spirit.epochName))
        relationships[key] = rel
    }

    /// Record a conversational exchange.
    public mutating func noteExchange(withKey key: UUID) {
        relationships[key]?.totalExchanges += 1
    }

    /// Record a moment against a spirit's relationship.
    public mutating func record(_ kind: RelationalMoment.Kind, for spirit: Spirit, atTick tick: Int, detail: String? = nil) {
        record(kind, forKey: Self.key(for: spirit), atTick: tick, detail: detail)
    }

    /// Record a moment by relationship key — for consequences that land
    /// while the spirit is not manifested. The dead hear of things.
    public mutating func record(_ kind: RelationalMoment.Kind, forKey key: UUID, atTick tick: Int, detail: String? = nil) {
        guard relationships[key] != nil else { return }
        relationships[key]?.moments.append(RelationalMoment(kind: kind, tick: tick, detail: detail))
        if kind == .gaveTrueName {
            relationships[key]?.nameGiven = detail
        }
    }

    /// Record a departure by its manner.
    public mutating func recordDeparture(_ departure: SpiritDeparture) {
        let kind: RelationalMoment.Kind
        switch departure.manner {
        case .releasedWithLibation: kind = .releasedWithLibation
        case .banished: kind = .banished
        case .faded: kind = .leftToFade
        }
        record(kind, for: departure.spirit, atTick: departure.tick)
    }
}

/// Relational context for a call-by-name summoning: the practitioner is
/// calling someone they already know, through the relationship rather
/// than through fragments alone.
public struct RelationalInvocation: Sendable {
    /// The identity being called. Epoch resolution is confined to it.
    public let rootIdentityID: UUID
    /// Coherence the relationship contributes — the relationship is the anchor.
    public let coherenceBonus: Double
    /// Net relational valence — steers which aspect of the person answers.
    /// Banish the Captain often enough and the Butcher picks up instead.
    public let valence: Double

    public init(rootIdentityID: UUID, coherenceBonus: Double, valence: Double) {
        self.rootIdentityID = rootIdentityID
        self.coherenceBonus = coherenceBonus
        self.valence = valence
    }
}
