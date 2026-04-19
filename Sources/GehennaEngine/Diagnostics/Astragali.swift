// MARK: - Astragali Diagnostic System
// Four sheep knucklebones, cast before ritual execution.
// Divination in form, debugger in function.
//
// Each bone maps to one dimension: Coherence, Resonance, Conflict, Veil.
// Each shows favorable / warning / hostile based on the grammar's actual computation.
//
// Critically: the astragali degrade with Veil instability. The training wheels
// come off at the worst possible moment, by design, and the thing that takes
// them off is the practitioner's own behavior.

import Foundation

/// The reading of a single astragalus bone.
public enum AstragalusReading: String, Codable, Hashable, Sendable {
    case favorable  // good signal
    case warning    // caution
    case hostile    // danger
    case unreliable // bone has degraded — cannot be trusted
}

/// The four-bone diagnostic reading.
public struct AstragaliReading: Sendable {
    public let coherence: AstragalusReading
    public let resonance: AstragalusReading
    public let conflict: AstragalusReading
    public let veilState: AstragalusReading

    /// How many bones are reliable (not degraded by Veil instability).
    public var reliableCount: Int {
        [coherence, resonance, conflict, veilState]
            .filter { $0 != .unreliable }
            .count
    }
}

/// The Astragali diagnostic system.
public struct Astragali: Sendable {

    public init() {}

    /// Cast the bones for a ritual configuration.
    /// The readings reflect the grammar's actual evaluation — they are not random.
    /// Bones degrade with regional Veil instability.
    public func cast(
        configuration: RitualConfiguration,
        regionState: RegionState,
        profile: PractitionerProfile,
        seed: UInt64
    ) -> AstragaliReading {
        // Compute the three grammar dimensions via lightweight preview
        let coherenceScore = computeCoherencePreview(configuration, profile)
        let resonanceScore = computeResonancePreview(configuration)
        let conflictScore = computeConflictPreview(configuration)

        // Determine which bones have degraded
        let degradedBones = determineDegradation(regionState: regionState, seed: seed)

        // Map scores to readings
        let coherenceReading = degradedBones.contains(.coherence)
            ? .unreliable : scoreToReading(coherenceScore, inverted: false)

        let resonanceReading = degradedBones.contains(.resonance)
            ? .unreliable : scoreToReading(resonanceScore, inverted: false)

        let conflictReading = degradedBones.contains(.conflict)
            ? .unreliable : scoreToReading(conflictScore, inverted: true) // high conflict = hostile

        let veilReading = degradedBones.contains(.veil)
            ? .unreliable : scoreToReading(regionState.veilThinness, inverted: true) // high thinness = hostile

        return AstragaliReading(
            coherence: coherenceReading,
            resonance: resonanceReading,
            conflict: conflictReading,
            veilState: veilReading
        )
    }

    // MARK: - Preview Computations (lightweight, for diagnostics only)

    private func computeCoherencePreview(_ config: RitualConfiguration, _ profile: PractitionerProfile) -> Double {
        var coherence = config.remains.coherenceWeight * 0.4
        if let name = config.trueName { coherence += name.coherenceBonus }
        if let artifact = config.lifeArtifact {
            if artifact.domain == config.remains.domain { coherence += 0.2 }
        }
        coherence += profile.summonerSkill * 0.1
        return min(1.0, coherence)
    }

    private func computeResonancePreview(_ config: RitualConfiguration) -> Double {
        var resonance = config.site.siteResonance(with: config.remains.affinity) * 0.3
        if let libation = config.libation { resonance += libation.resonanceModifier }
        if let timing = config.timing { resonance += max(0.0, timing.resonanceBonus) }
        return min(1.0, resonance)
    }

    private func computeConflictPreview(_ config: RitualConfiguration) -> Double {
        var conflict = 0.0
        if config.remains.affinity.opposes(config.site.affinity) { conflict += 0.3 }
        if config.remains.integrity.isCorrupted { conflict += 0.2 }
        conflict += config.site.corruption * 0.15
        if let lib = config.libation, lib.type == .bloodOffering { conflict += 0.15 }
        return min(1.0, conflict)
    }

    /// Determine which bones have degraded based on Veil instability.
    /// In stable regions, all four read accurately. As the region destabilizes,
    /// bones become unreliable in exactly the regions where the practitioner
    /// has been most active.
    private func determineDegradation(regionState: RegionState, seed: UInt64) -> Set<BoneFace> {
        var degraded: Set<BoneFace> = []
        var entropy = EntropySource(seed: seed &+ 0xDEAD)

        let veil = regionState.veilThinness

        // Degradation thresholds — each bone fails at a different Veil level
        if veil > 0.7 {
            // First bone degrades: conflict (the one you need most)
            if entropy.next() < (veil - 0.7) * 3.0 {
                degraded.insert(.conflict)
            }
        }
        if veil > 0.5 {
            // Second bone degrades: veil state
            if entropy.next() < (veil - 0.5) * 2.5 {
                degraded.insert(.veil)
            }
        }
        if veil > 0.8 {
            // Third bone degrades: resonance
            if entropy.next() < (veil - 0.8) * 5.0 {
                degraded.insert(.resonance)
            }
        }
        if veil > 0.9 {
            // Fourth bone degrades: coherence (last to go)
            if entropy.next() < (veil - 0.9) * 10.0 {
                degraded.insert(.coherence)
            }
        }

        return degraded
    }

    private func scoreToReading(_ score: Double, inverted: Bool) -> AstragalusReading {
        let effective = inverted ? score : (1.0 - score)
        switch effective {
        case 0.0..<0.35: return .favorable
        case 0.35..<0.65: return .warning
        default: return .hostile
        }
    }

    private enum BoneFace: Hashable {
        case coherence, resonance, conflict, veil
    }
}
