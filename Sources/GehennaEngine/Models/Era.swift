// MARK: - Era
// Historical periods the dead inhabited. Deeper eras produce more powerful,
// more dangerous spirits — they have been in Sheol longer and carry older knowledge.

/// The historical epoch a fragment or spirit belongs to.
/// Ordered from most recent to most ancient. Depth increases power and risk.
public enum Era: Int, Codable, Hashable, CaseIterable, Comparable, Sendable {
    case ironAgeII    = 1  // ~1000–700 BCE — the present of the reference canon
    case ironAgeI     = 2  // ~1200–1000 BCE — the Sea Peoples, the collapse
    case lateBronze   = 3  // ~1550–1200 BCE — Ugarit, the great kingdoms
    case middleBronze = 4  // ~2000–1550 BCE — the patriarchal age, Hyksos
    case earlyBronze  = 5  // ~3300–2000 BCE — the first cities, the first temples
    case antediluvian = 6  // before record — the Rephaim, the deep past

    /// Higher depth = older era = more powerful spirits.
    public var depth: Int { rawValue }

    /// How well two eras align. Same era = 1.0, adjacent = 0.7, distant = diminishing.
    public func alignment(with other: Era) -> Double {
        let distance = abs(self.rawValue - other.rawValue)
        switch distance {
        case 0: return 1.0
        case 1: return 0.7
        case 2: return 0.4
        case 3: return 0.2
        default: return 0.1
        }
    }

    public static func < (lhs: Era, rhs: Era) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
