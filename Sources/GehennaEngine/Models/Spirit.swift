// MARK: - Spirit
// A spirit is a manifestation — a specific person pulled from Sheol
// through the ritual grammar. Spirits carry templates (behavioral class),
// attributes (hidden capabilities), personality (fixed behavioral modifiers),
// and disposition (emotional state that drifts during deployment).

import Foundation

/// Spirit tier — determined by era depth, fragment completeness, site conditions, and libation gating.
public enum SpiritTier: Int, Codable, Hashable, CaseIterable, Comparable, Sendable {
    case common    = 1
    case uncommon  = 2
    case rare      = 3
    case legendary = 4
    case mythic    = 5

    public static func < (lhs: SpiritTier, rhs: SpiritTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Behavioral archetype — the class of entity that manifests.
/// Templates are authored. The tag space selects which template fits.
public enum SpiritTemplate: String, Codable, Hashable, CaseIterable, Sendable {
    case warrior    // the fighter, the soldier, the defender
    case scout      // the watcher, the spy, the ranger
    case guardian   // the protector, the shieldbearer, the ancestor
    case prophet    // the seer, the oracle, the one who speaks
    case witness    // the one who saw, the survivor, the recorder
    case warden     // the keeper, the tomb guard, the gatekeeper
    case sovereign  // the king, the queen, the one who ruled — Rephaim class
    case shade      // the diminished, the forgotten, the common dead
    case butcher    // the wrathful aspect — violence overtaking personhood
    case mourner    // the grieving, the one who carries loss
    case artisan    // the maker, the smith, the builder
    case merchant   // the trader, the traveler, the one who connected
}

/// Intrinsic personality traits — fixed at template binding, not alterable by the practitioner.
/// These are the Unsolvability Principle made mechanical.
public enum PersonalityTrait: String, Codable, Hashable, CaseIterable, Sendable {
    case prideful            // rejects commands it considers beneath it
    case protective          // defends the practitioner without being asked
    case opportunistic       // takes advantage of openings, sometimes unwanted
    case capricious          // obeys unpredictably
    case curious             // asks questions, investigates, may wander
    case spiteful            // holds grudges, retaliates for perceived slights
    case amusedByBoldness    // responds positively to risky or audacious commands
    case resentful           // carries bitterness about being summoned
    case loyal               // cooperates reliably once trust is earned
    case territorial         // protective of its site, hostile to intruders at its home
}

/// Emotional baseline at manifestation — shaped by fragments, libation, and regional reputation.
/// Disposition drifts during deployment based on treatment.
public enum Disposition: String, Codable, Hashable, CaseIterable, Sendable {
    case calm       // neutral, waiting
    case hostile    // aggressive, dangerous
    case curious    // interested, open
    case sorrowful  // grieving, withdrawn
    case hungry     // wants something — attention, offerings, justice
    case honored    // pleased to have been called properly
}

/// The five hidden attributes of a manifested spirit.
public struct SpiritAttributes: Codable, Hashable, Sendable {
    public let strength: Double    // combat effectiveness, physical force
    public let knowledge: Double   // information held, lore access, divination quality
    public let will: Double        // resistance to control, dominance in co-presence
    public let stability: Double   // how long before the spirit returns to Sheol
    public let disposition: Double // numerical backing for the Disposition enum (maps to thresholds)

    public init(
        strength: Double,
        knowledge: Double,
        will: Double,
        stability: Double,
        disposition: Double
    ) {
        self.strength = strength
        self.knowledge = knowledge
        self.will = will
        self.stability = stability
        self.disposition = disposition
    }
}

/// A manifested spirit — the output of a successful ritual.
public struct Spirit: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID

    // -- Identity --
    public let template: SpiritTemplate
    public let tier: SpiritTier
    public let tags: TagConstellation
    public let era: Era

    // -- Epoch Identity --
    /// The epoch this spirit manifested as — which aspect of the root identity.
    /// e.g., "Bronze Captain" vs "Ashkelon Butcher" — same person, different aspect.
    public let epochName: String?

    /// The root identity ID, if this spirit was resolved from a known root identity.
    /// Enables Codex cross-referencing across epoch manifestations.
    public let rootIdentityID: UUID?

    // -- Behavior --
    public let personalityTraits: [PersonalityTrait]
    public var disposition: Disposition
    public let attributes: SpiritAttributes

    // -- State --
    /// Current stability — decays under stress, combat, co-presence, corruption, time.
    /// When this reaches zero, the spirit returns to Sheol.
    public var currentStability: Double

    /// Whether this spirit was produced by the Mutation Protocol.
    public let isMutation: Bool

    /// The ritual that produced this spirit — for Codex genealogy.
    public let originRitualID: UUID?

    public init(
        id: UUID = UUID(),
        template: SpiritTemplate,
        tier: SpiritTier,
        tags: TagConstellation,
        era: Era,
        epochName: String? = nil,
        rootIdentityID: UUID? = nil,
        personalityTraits: [PersonalityTrait],
        disposition: Disposition,
        attributes: SpiritAttributes,
        isMutation: Bool = false,
        originRitualID: UUID? = nil
    ) {
        self.id = id
        self.template = template
        self.tier = tier
        self.tags = tags
        self.era = era
        self.epochName = epochName
        self.rootIdentityID = rootIdentityID
        self.personalityTraits = personalityTraits
        self.disposition = disposition
        self.attributes = attributes
        self.currentStability = attributes.stability
        self.isMutation = isMutation
        self.originRitualID = originRitualID
    }

    /// Whether the spirit is still manifested.
    public var isManifested: Bool { currentStability > 0 }

    /// Apply stability decay from one tick.
    public mutating func decayStability(by amount: Double) {
        currentStability = max(0.0, currentStability - amount)
    }
}
