// MARK: - Fragment
// The dual-layer fragment model. Every input to a ritual carries data on two layers:
// structured properties for mechanical resolution, and narrative tags for expressive rendering.
// The structured properties determine WHAT class of thing manifests.
// The narrative tags determine WHICH specific person within that class.

import Foundation

/// The physical integrity of a fragment — how well-preserved it is.
/// Affects Coherence and limits what can be summoned.
public struct Integrity: Codable, Hashable, Sendable {
    /// 0.0 = completely corrupted/destroyed, 1.0 = pristine.
    public let value: Double

    public init(_ value: Double) {
        self.value = min(1.0, max(0.0, value))
    }

    public var isPristine: Bool { value > 0.9 }
    public var isDegraded: Bool { value < 0.5 }
    public var isCorrupted: Bool { value < 0.2 }

    public static let pristine  = Integrity(1.0)
    public static let worn      = Integrity(0.7)
    public static let degraded  = Integrity(0.4)
    public static let corrupted = Integrity(0.15)
    public static let ruined    = Integrity(0.05)
}

/// The type of physical remains used as an anchor.
public enum RemainsType: String, Codable, Hashable, Sendable {
    case skull          // most coherent anchor — the seat of identity
    case longBone       // femur, humerus — strong anchor, common find
    case ribFragment    // partial, moderate coherence
    case handBones      // knucklebones, phalanges — craft-associated
    case ossuaryChip    // secondary burial fragment — reduced coherence
    case crematedBone   // Tophet context — carries Fire affinity, low coherence
    case toothFragment  // small but personal — surprisingly high identity signal
}

/// A fragment of the dead — the primary input to a ritual.
/// Remains are mandatory. Everything else enriches the summoning.
public struct Fragment: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID

    // -- Structured properties (mechanical layer) --
    public let remainsType: RemainsType
    public let era: Era
    public let domain: Domain
    public let affinity: Affinity
    public let integrity: Integrity

    // -- Narrative layer --
    public let tags: TagConstellation

    /// Optional partial name inscribed or associated with this fragment.
    public let inscribedName: String?

    public init(
        id: UUID = UUID(),
        remains: RemainsType,
        era: Era,
        domain: Domain,
        affinity: Affinity,
        integrity: Integrity = .worn,
        tags: TagConstellation = TagConstellation(),
        inscribedName: String? = nil
    ) {
        self.id = id
        self.remainsType = remains
        self.era = era
        self.domain = domain
        self.affinity = affinity
        self.integrity = integrity
        self.tags = tags
        self.inscribedName = inscribedName
    }

    /// Coherence contribution — how clearly this fragment points at one person.
    /// Skulls are most coherent. Cremated bone least. Integrity degrades all.
    public var coherenceWeight: Double {
        let baseWeight: Double = switch remainsType {
        case .skull:         1.0
        case .longBone:      0.75
        case .toothFragment: 0.65
        case .handBones:     0.55
        case .ribFragment:   0.45
        case .ossuaryChip:   0.3
        case .crematedBone:  0.2
        }
        return baseWeight * integrity.value
    }
}
