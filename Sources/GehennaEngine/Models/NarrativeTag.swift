// MARK: - Narrative Tags
// The tag dictionary is the most important content artifact in the game.
// Tags are the specificity layer — they determine WHO manifests from the
// combinatorial space, not just WHAT class of thing. A thin dictionary
// produces generic ghosts. A deep dictionary produces specific people.

import Foundation

/// A single narrative tag with its dimension and value.
public struct NarrativeTag: Codable, Hashable, Sendable {

    /// The dimension this tag belongs to.
    public let dimension: Dimension

    /// The specific value within that dimension.
    public let value: String

    /// Optional weight — how strongly this tag defines the identity. Default 1.0.
    public let weight: Double

    public init(_ dimension: Dimension, _ value: String, weight: Double = 1.0) {
        self.dimension = dimension
        self.value = value
        self.weight = weight
    }

    /// Tag dimensions — the axes along which identity is described.
    public enum Dimension: String, Codable, Hashable, CaseIterable, Sendable {
        case identity       // occupation, culture, age, status, gender, physical traits
        case deathContext   // how they died — battle, plague, sacrifice, murder, old age
        case relational     // who they served, loved, betrayed, raised, buried
        case cultural       // which deity, sanctuary, trade tradition, language, kinship
        case era            // specific historical events they lived through
        case disposition    // what they carried in life — grief, rage, duty, pride
        case taboo          // what they will not say, do, answer, or accept
    }
}

/// A constellation of tags that points at a specific person.
/// The intersection of tags across dimensions narrows the identity space
/// from "any dead person" to "this specific dead person."
public struct TagConstellation: Codable, Hashable, Sendable {
    public var tags: [NarrativeTag]

    public init(_ tags: [NarrativeTag] = []) {
        self.tags = tags
    }

    /// All tags in a specific dimension.
    public func tags(in dimension: NarrativeTag.Dimension) -> [NarrativeTag] {
        tags.filter { $0.dimension == dimension }
    }

    /// Whether this constellation contains a tag with the given value.
    public func contains(value: String) -> Bool {
        tags.contains { $0.value == value }
    }

    /// Merge two constellations, combining their tags.
    public func merged(with other: TagConstellation) -> TagConstellation {
        TagConstellation(tags + other.tags)
    }

    /// Similarity score between two constellations.
    /// Higher = more tags in common = more likely the same person.
    public func similarity(to other: TagConstellation) -> Double {
        guard !tags.isEmpty && !other.tags.isEmpty else { return 0.0 }
        let myValues = Set(tags.map { $0.value })
        let theirValues = Set(other.tags.map { $0.value })
        let shared = myValues.intersection(theirValues).count
        let total = myValues.union(theirValues).count
        return Double(shared) / Double(total)
    }
}
