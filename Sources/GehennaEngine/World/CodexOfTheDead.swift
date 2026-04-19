// MARK: - Codex of the Dead
// The practitioner's archive. Also the progression system.
// No level number. No power rating. Just the Codex, and the Codex
// tells the practitioner exactly how far they have come.
//
// An entry is not a database row. It is a practitioner's notes.
// Incomplete entries have visible gaps that invite filling.

import Foundation

/// Completeness level of a Codex entry.
public enum EntryCompleteness: String, Codable, Hashable, Sendable, Comparable {
    case fragmentary  // just a template and tier — almost nothing known
    case partial      // some tags, some attributes inferred
    case substantial  // multiple encounters, personality patterns recognized
    case complete     // full identity reconstructed, all aspects documented

    private var order: Int {
        switch self {
        case .fragmentary: return 0
        case .partial:     return 1
        case .substantial: return 2
        case .complete:    return 3
        }
    }

    public static func < (lhs: EntryCompleteness, rhs: EntryCompleteness) -> Bool {
        lhs.order < rhs.order
    }
}

/// A single entry in the Codex of the Dead.
public struct CodexEntry: Codable, Sendable, Identifiable {
    public let id: UUID

    /// The spirit template observed.
    public let template: SpiritTemplate

    /// The spirit tier observed.
    public let tier: SpiritTier

    /// The dominant era of the spirit.
    public let era: Era

    /// Tags accumulated across encounters.
    public var knownTags: TagConstellation

    /// Personality traits observed.
    public var observedTraits: [PersonalityTrait]

    /// Dispositions seen across encounters.
    public var observedDispositions: [Disposition]

    /// How many times this spirit (or one matching its identity) has been encountered.
    public var encounterCount: Int

    /// Practitioner's notes — the autopsy fragments and observations.
    public var notes: [String]

    /// Completeness level.
    public var completeness: EntryCompleteness

    /// Ritual IDs that produced encounters with this spirit.
    public var ritualHistory: [UUID]

    /// True Name, if discovered.
    public var knownName: String?

    /// Cross-references to other entries (epoch manifestation linking).
    public var linkedEntries: [UUID]

    /// When this entry was first created.
    public let firstEncounterTick: Int

    /// When this entry was last updated.
    public var lastEncounterTick: Int

    /// The epoch name (aspect) of the root identity, if resolved. (v3 §5.3)
    /// e.g. "Bronze Captain", "Ashkelon Butcher"
    public var epochName: String?

    /// The root identity this entry belongs to, if known. (v3 §5.3)
    /// When two entries share a root identity, they are aspects of the same person.
    public var rootIdentityID: UUID?

    public init(
        spirit: Spirit,
        autopsy: [String],
        ritualID: UUID,
        tick: Int
    ) {
        self.id = UUID()
        self.template = spirit.template
        self.tier = spirit.tier
        self.era = spirit.era
        self.knownTags = spirit.tags
        self.observedTraits = spirit.personalityTraits
        self.observedDispositions = [spirit.disposition]
        self.encounterCount = 1
        self.notes = autopsy
        self.completeness = .fragmentary
        self.ritualHistory = [ritualID]
        self.knownName = nil
        self.linkedEntries = []
        self.firstEncounterTick = tick
        self.lastEncounterTick = tick
        self.epochName = spirit.epochName
        self.rootIdentityID = spirit.rootIdentityID
    }

    /// Update this entry with a new encounter of the same or similar spirit.
    public mutating func addEncounter(
        spirit: Spirit,
        autopsy: [String],
        ritualID: UUID,
        tick: Int
    ) {
        encounterCount += 1
        lastEncounterTick = tick
        ritualHistory.append(ritualID)
        knownTags = knownTags.merged(with: spirit.tags)
        notes.append(contentsOf: autopsy)

        // Record new traits and dispositions
        for trait in spirit.personalityTraits where !observedTraits.contains(trait) {
            observedTraits.append(trait)
        }
        if !observedDispositions.contains(spirit.disposition) {
            observedDispositions.append(spirit.disposition)
        }

        // Update completeness
        updateCompleteness()
    }

    /// Recalculate completeness based on accumulated knowledge.
    private mutating func updateCompleteness() {
        let tagCount = knownTags.tags.count
        let traitCount = observedTraits.count
        let dispCount = observedDispositions.count
        let hasLinks = !linkedEntries.isEmpty

        if tagCount >= 8 && traitCount >= 2 && encounterCount >= 5 && knownName != nil {
            completeness = .complete
        } else if (tagCount >= 5 && traitCount >= 2 && encounterCount >= 3) || (hasLinks && tagCount >= 4) {
            completeness = .substantial
        } else if tagCount >= 2 || encounterCount >= 2 || dispCount >= 2 {
            completeness = .partial
        }
    }

    /// Link this entry to another as an epoch manifestation of the same root identity.
    public mutating func linkTo(_ otherEntryID: UUID) {
        if !linkedEntries.contains(otherEntryID) {
            linkedEntries.append(otherEntryID)
        }
    }
}

/// The practitioner's complete Codex — their archive of the dead.
public struct CodexOfTheDead: Codable, Sendable {
    /// All entries, keyed by entry ID.
    public var entries: [UUID: CodexEntry]

    public init() {
        self.entries = [:]
    }

    /// Record a spirit encounter. Either creates a new entry or updates an existing one
    /// if a similar spirit has been encountered before.
    public mutating func recordEncounter(
        spirit: Spirit,
        autopsy: [String],
        ritualID: UUID,
        tick: Int
    ) -> UUID {
        // Check if we've seen a similar spirit before (by tag similarity)
        if let existingID = findSimilarEntry(for: spirit) {
            entries[existingID]?.addEncounter(
                spirit: spirit, autopsy: autopsy,
                ritualID: ritualID, tick: tick
            )
            return existingID
        } else {
            let entry = CodexEntry(
                spirit: spirit, autopsy: autopsy,
                ritualID: ritualID, tick: tick
            )
            entries[entry.id] = entry
            return entry.id
        }
    }

    /// Find an existing entry that likely represents the same spirit.
    private func findSimilarEntry(for spirit: Spirit) -> UUID? {
        // First check: if the spirit has a root identity and epoch, match by root + epoch
        if let rootID = spirit.rootIdentityID, let epochName = spirit.epochName {
            for (id, entry) in entries {
                if entry.rootIdentityID == rootID && entry.epochName == epochName {
                    return id
                }
            }
        }

        // Fallback: same template + high tag similarity = likely the same person
        for (id, entry) in entries {
            if entry.template == spirit.template &&
               entry.era == spirit.era &&
               entry.knownTags.similarity(to: spirit.tags) > 0.5 {
                return id
            }
        }
        return nil
    }

    /// Auto-cross-link entries that share a root identity but represent different epochs.
    /// This is the archaeology mechanic: the practitioner discovers that two entries
    /// are aspects of the same person. (v3 §5.3)
    public mutating func crossLinkEpochs() {
        // Group entries by root identity ID
        var byRoot: [UUID: [UUID]] = [:]
        for (entryID, entry) in entries {
            if let rootID = entry.rootIdentityID {
                byRoot[rootID, default: []].append(entryID)
            }
        }

        // For each root identity with multiple entries, cross-link them
        for (_, entryIDs) in byRoot where entryIDs.count > 1 {
            for entryID in entryIDs {
                for otherID in entryIDs where otherID != entryID {
                    entries[entryID]?.linkTo(otherID)
                }
            }
        }
    }

    /// Root identities that have been partially discovered — entries exist for
    /// multiple epochs of the same person.
    public var discoveredRootIdentities: [UUID: [CodexEntry]] {
        var byRoot: [UUID: [CodexEntry]] = [:]
        for entry in entries.values {
            if let rootID = entry.rootIdentityID {
                byRoot[rootID, default: []].append(entry)
            }
        }
        return byRoot.filter { $0.value.count > 1 }
    }

    /// All entries sorted by most recent encounter.
    public var recentEntries: [CodexEntry] {
        entries.values.sorted { $0.lastEncounterTick > $1.lastEncounterTick }
    }

    /// Entries by completeness.
    public var entriesByCompleteness: [EntryCompleteness: [CodexEntry]] {
        Dictionary(grouping: entries.values, by: \.completeness)
    }

    /// Total unique spirits encountered.
    public var totalEncountered: Int { entries.count }

    /// Total entries at each completeness level.
    public var progressSummary: String {
        let complete = entries.values.filter { $0.completeness == .complete }.count
        let substantial = entries.values.filter { $0.completeness == .substantial }.count
        let partial = entries.values.filter { $0.completeness == .partial }.count
        let fragmentary = entries.values.filter { $0.completeness == .fragmentary }.count
        return "\(complete) complete, \(substantial) substantial, \(partial) partial, \(fragmentary) fragmentary"
    }
}
