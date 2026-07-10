// MARK: - Retinue
// The practitioner's bound spirits. An anchored spirit stays manifested
// until its Stability runs out or the practitioner dismisses it. Spirits
// are relationships, not possessions: the retinue holds who walks with
// you now; the Codex holds who you know.
//
// How a spirit leaves is part of the relationship. Release with libation,
// banishment, and being left to fade are different partings, and the
// world records them differently.

import Foundation

/// How a spirit leaves the practitioner's service.
public enum DismissalManner: String, Codable, Sendable {
    case releasedWithLibation   // respectful parting — costs a libation
    case banished               // abrupt, free, a slight
    case faded                  // stability ran out — left to dissolve
}

/// A spirit currently anchored to the practitioner.
public struct BoundSpirit: Codable, Sendable, Identifiable {
    public var spirit: Spirit

    /// Tick at which the spirit was anchored into the retinue.
    public let anchoredAtTick: Int

    /// Site where the manifestation occurred, if known.
    public let originSiteID: UUID?

    /// Conversation exchanges during this manifestation (the door held open).
    public var exchangeCount: Int

    public var id: UUID { spirit.id }

    public init(
        spirit: Spirit,
        anchoredAtTick: Int,
        originSiteID: UUID? = nil,
        exchangeCount: Int = 0
    ) {
        self.spirit = spirit
        self.anchoredAtTick = anchoredAtTick
        self.originSiteID = originSiteID
        self.exchangeCount = exchangeCount
    }
}

/// A spirit's departure from the retinue, with how it happened.
/// The manner is relational truth — the ledger (0.4.30) will read it.
public struct SpiritDeparture: Sendable {
    public let spirit: Spirit
    public let manner: DismissalManner
    public let tick: Int

    public init(spirit: Spirit, manner: DismissalManner, tick: Int) {
        self.spirit = spirit
        self.manner = manner
        self.tick = tick
    }
}

/// The set of spirits currently walking with the practitioner.
/// Capacity is enforced at anchor time against the profile's
/// `summonerCapacity`; the retinue itself has no intrinsic cap.
public struct Retinue: Codable, Sendable {
    public private(set) var bound: [BoundSpirit]

    // MARK: Decay tuning — canon constants (Codex 5.6, co-presence)

    /// Stability lost per tick under calm conditions.
    public static let baseDecayPerTick: Double = 0.02
    /// Additional decay per tick scaled by regional Corruption.
    public static let corruptionDecayWeight: Double = 0.03
    /// Strain each additional co-present spirit adds for everyone.
    public static let coPresenceStrainPerSpirit: Double = 0.01
    /// Extra strain when two or more Prideful spirits share the retinue.
    public static let pridefulRivalryStrain: Double = 0.015
    /// Stability cost of one conversational exchange — holding the door open.
    public static let strainPerExchange: Double = 0.015

    public init(bound: [BoundSpirit] = []) {
        self.bound = bound
    }

    public var count: Int { bound.count }
    public var isEmpty: Bool { bound.isEmpty }

    public func boundSpirit(withID id: UUID) -> BoundSpirit? {
        bound.first { $0.spirit.id == id }
    }

    /// Anchor a manifested spirit. Fails (returns false) when the
    /// practitioner's capacity is already fully held.
    @discardableResult
    public mutating func anchor(
        _ spirit: Spirit,
        atTick tick: Int,
        originSiteID: UUID? = nil,
        capacity: Int
    ) -> Bool {
        guard bound.count < capacity else { return false }
        bound.append(BoundSpirit(spirit: spirit, anchoredAtTick: tick, originSiteID: originSiteID))
        return true
    }

    /// Dismiss a bound spirit by choice. Returns the departure, or nil
    /// if no such spirit is bound. `.faded` is not a valid chosen manner;
    /// fading happens only through decay in `advance`.
    public mutating func dismiss(
        id: UUID,
        manner: DismissalManner,
        atTick tick: Int
    ) -> SpiritDeparture? {
        guard manner != .faded,
              let index = bound.firstIndex(where: { $0.spirit.id == id }) else { return nil }
        let departed = bound.remove(at: index)
        return SpiritDeparture(spirit: departed.spirit, manner: manner, tick: tick)
    }

    /// Record a conversational exchange with a bound spirit. Speaking with
    /// the dead holds the door open: each exchange strains the spirit's
    /// stability. If the strain spends it, the spirit fades mid-word and
    /// the departure is returned.
    public mutating func recordExchange(with id: UUID, atTick tick: Int) -> SpiritDeparture? {
        guard let index = bound.firstIndex(where: { $0.spirit.id == id }) else { return nil }
        bound[index].exchangeCount += 1
        bound[index].spirit.decayStability(by: Self.strainPerExchange)
        if !bound[index].spirit.isManifested {
            let departed = bound.remove(at: index)
            return SpiritDeparture(spirit: departed.spirit, manner: .faded, tick: tick)
        }
        return nil
    }

    /// Apply direct strain to one bound spirit — doubt, contest, shock.
    /// If the strain spends it, the spirit returns to Sheol and the
    /// departure is returned.
    public mutating func strain(id: UUID, by amount: Double, atTick tick: Int) -> SpiritDeparture? {
        guard let index = bound.firstIndex(where: { $0.spirit.id == id }) else { return nil }
        bound[index].spirit.decayStability(by: amount)
        if !bound[index].spirit.isManifested {
            let departed = bound.remove(at: index)
            return SpiritDeparture(spirit: departed.spirit, manner: .faded, tick: tick)
        }
        return nil
    }

    /// The stability every bound spirit loses this tick, given current
    /// conditions. Recomputed per tick because strain lessens as the
    /// retinue thins.
    public func decayPerTick(regionCorruption: Double) -> Double {
        var decay = Self.baseDecayPerTick + max(0.0, regionCorruption) * Self.corruptionDecayWeight
        if bound.count > 1 {
            decay += Double(bound.count - 1) * Self.coPresenceStrainPerSpirit
            let pridefulCount = bound.filter { $0.spirit.personalityTraits.contains(.prideful) }.count
            if pridefulCount > 1 {
                decay += Self.pridefulRivalryStrain
            }
        }
        return decay
    }

    /// Advance the retinue through elapsed ticks. Spirits whose stability
    /// reaches zero return to Sheol and are reported as `.faded` departures,
    /// in the order they fell.
    public mutating func advance(
        ticks: Int,
        regionCorruption: Double,
        endingAtTick currentTick: Int
    ) -> [SpiritDeparture] {
        guard ticks > 0, !bound.isEmpty else { return [] }
        var departures: [SpiritDeparture] = []
        let firstTick = currentTick - ticks + 1

        for tick in firstTick...currentTick {
            guard !bound.isEmpty else { break }
            let decay = decayPerTick(regionCorruption: regionCorruption)
            for index in bound.indices {
                bound[index].spirit.decayStability(by: decay)
            }
            let fallen = bound.filter { !$0.spirit.isManifested }
            if !fallen.isEmpty {
                bound.removeAll { !$0.spirit.isManifested }
                departures.append(contentsOf: fallen.map {
                    SpiritDeparture(spirit: $0.spirit, manner: .faded, tick: tick)
                })
            }
        }
        return departures
    }
}
