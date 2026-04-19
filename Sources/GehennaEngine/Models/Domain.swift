// MARK: - Domain
// The five domains of existence that fragments and spirits belong to.
// Domains are the functional categories of the dead — what they did, what they knew,
// what shaped them. Domain alignment between fragments drives Resonance.

/// The functional domain of a fragment, spirit, or site.
public enum Domain: String, Codable, Hashable, CaseIterable, Sendable {
    case war       // soldiers, weapons, battlefields, conquest
    case knowledge // scribes, priests, scholars, temple libraries
    case faith     // devotees, sanctuaries, ritual objects, divine service
    case rule      // kings, governors, administrators, seals of office
    case death     // burial workers, mourners, Tophet attendants, Sheol-adjacent

    /// Whether two domains have natural affinity (amplify each other).
    public func resonatesWith(_ other: Domain) -> Bool {
        switch (self, other) {
        case (.war, .rule), (.rule, .war):           return true  // commanders and kings
        case (.knowledge, .faith), (.faith, .knowledge): return true  // scribes and priests
        case (.faith, .death), (.death, .faith):     return true  // funerary religion
        default: return self == other  // same domain always resonates
        }
    }

    /// Whether two domains are in tension (produce Conflict).
    public func conflictsWith(_ other: Domain) -> Bool {
        switch (self, other) {
        case (.war, .faith), (.faith, .war):         return true  // violence vs devotion
        case (.rule, .death), (.death, .rule):       return true  // sovereignty vs mortality
        case (.knowledge, .war), (.war, .knowledge): return true  // understanding vs destruction
        default: return false
        }
    }
}
