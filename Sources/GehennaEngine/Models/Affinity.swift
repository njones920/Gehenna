// MARK: - Affinity
// The five elemental affinities — not elements in the fantasy sense,
// but cosmological resonance categories drawn from ancient Near Eastern thought.
// Opposition is the primary Conflict driver.

/// Elemental affinity of a fragment, spirit, or site.
public enum Affinity: String, Codable, Hashable, CaseIterable, Sendable {
    case fire
    case water
    case earth
    case silence
    case air

    /// The affinity that opposes this one. Opposition accumulates Conflict.
    public var opposition: Affinity {
        switch self {
        case .fire:    return .water
        case .water:   return .fire
        case .earth:   return .air
        case .air:     return .earth
        case .silence: return .silence  // silence opposes nothing — it is the absence
        }
    }

    /// Whether this affinity opposes another.
    public func opposes(_ other: Affinity) -> Bool {
        self != .silence && other != .silence && self.opposition == other
    }

    /// Resonance bonus when two affinities match.
    public func resonanceWith(_ other: Affinity) -> Double {
        if self == other { return 1.0 }
        if self == .silence || other == .silence { return 0.3 }  // silence is neutral, mild resonance
        if self.opposes(other) { return 0.0 }  // opposition produces no resonance
        return 0.5  // non-opposing, non-matching: mild affinity
    }
}
