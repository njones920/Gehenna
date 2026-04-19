// MARK: - Region State
// The seven regional variables that model the Surface World.
// Each variable interacts with the others through threshold events and cascades.
// The Veil is never directly manipulable — it is always derived.

import Foundation

/// The state of a region in the simulation.
public struct RegionState: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let name: String

    // -- The Seven Regional Variables --
    /// Total inhabitants. Drops from famine, war, spirit-driven flight.
    public var population: Double

    /// Current conflict level. Driven by faction tensions, cascades, player actions.
    public var warIntensity: Double

    /// Ambient presence of restless dead. Decays relatively quickly.
    public var ghostActivity: Double

    /// Spiritual contamination. Decays slowly.
    public var corruption: Double

    /// Civilizational resilience. Collapses trigger Settlement Failure.
    public var stability: Double

    /// How much the living population suspects necromantic activity. Per-region.
    public var suspicion: Double

    /// Long memory of the cosmology. Barely decays at all.
    public var spiritualPressure: Double

    public init(
        id: UUID = UUID(),
        name: String,
        population: Double = 0.8,
        warIntensity: Double = 0.1,
        ghostActivity: Double = 0.1,
        corruption: Double = 0.05,
        stability: Double = 0.8,
        suspicion: Double = 0.05,
        spiritualPressure: Double = 0.1
    ) {
        self.id = id
        self.name = name
        self.population = population
        self.warIntensity = warIntensity
        self.ghostActivity = ghostActivity
        self.corruption = corruption
        self.stability = stability
        self.suspicion = suspicion
        self.spiritualPressure = spiritualPressure
    }

    // MARK: - Derived Values

    /// The Veil — boundary between living and dead.
    /// Not binary. A continuous variable derived from other state.
    /// Higher = thinner = easier passage for spirits.
    /// The Veil is never directly manipulable. You cannot repair the Veil —
    /// you can only repair the world, and the Veil follows.
    public var veilThinness: Double {
        let base = (corruption * 0.35) + (ghostActivity * 0.25) +
                   (spiritualPressure * 0.3) + ((1.0 - stability) * 0.1)
        return min(1.0, max(0.0, base))
    }

    // MARK: - Threshold Checks

    /// Whether Ghost Activity has crossed the hostile encounter threshold.
    public var ghostsHostile: Bool { ghostActivity > 0.6 }

    /// Whether Corruption is degrading fragment Integrity across the region.
    public var corruptionDegrading: Bool { corruption > 0.5 }

    /// Whether Stability has collapsed — triggers Settlement Failure and Survival Override.
    public var settlementFailing: Bool { stability < 0.2 }

    /// Whether Suspicion has triggered organized inquisition.
    public var inquisitionActive: Bool { suspicion > 0.8 }

    /// Whether Veil Thinness is producing Cosmological Scarring.
    public var cosmologicallyScarred: Bool { veilThinness > 0.85 }

    /// Whether conditions support Deep Sheol access.
    public var deepSheolAccessible: Bool {
        veilThinness > 0.75 && corruption > 0.7 && spiritualPressure > 0.7
    }

    // MARK: - Entropy Processing

    /// Apply one tick of entropy decay. Decay rates are asymmetric by design.
    /// Ghost Activity decays fast. Corruption decays slow. Spiritual Pressure barely moves.
    public mutating func tickDecay() {
        // Decay rates scaled by stability — stable regions recover faster
        let stabilityFactor = max(0.1, stability)

        ghostActivity = max(0.0, ghostActivity - (0.03 * stabilityFactor))
        corruption = max(0.0, corruption - (0.005 * stabilityFactor))
        spiritualPressure = max(0.0, spiritualPressure - (0.001 * stabilityFactor))
        suspicion = max(0.0, suspicion - (0.01 * stabilityFactor))
        warIntensity = max(0.0, warIntensity - (0.008 * stabilityFactor))

        // Stability recovers when entropy is low
        if ghostActivity < 0.3 && corruption < 0.3 {
            stability = min(1.0, stability + (0.005 * (1.0 - corruption)))
        }
    }

    /// Apply entropy from a completed ritual.
    public mutating func applyRitualEntropy(
        ghostActivityDelta: Double = 0.08,
        corruptionDelta: Double = 0.03,
        spiritualPressureDelta: Double = 0.05,
        suspicionDelta: Double = 0.02
    ) {
        ghostActivity = min(1.0, ghostActivity + ghostActivityDelta)
        corruption = min(1.0, corruption + corruptionDelta)
        spiritualPressure = min(1.0, spiritualPressure + spiritualPressureDelta)
        suspicion = min(1.0, suspicion + suspicionDelta)

        // Ghost activity erodes stability
        if ghostActivity > 0.4 {
            stability = max(0.0, stability - 0.01)
        }
    }
}
