// MARK: - Life Artifact & Memory Trace
// Optional modifier inputs that increase specificity, power, and control.

import Foundation

/// A life artifact — an object from the spirit's living days.
/// Amplifies Resonance when its Domain matches the target identity.
public struct LifeArtifact: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let domain: Domain
    public let affinity: Affinity
    public let era: Era
    public let tags: TagConstellation

    public init(
        id: UUID = UUID(),
        name: String,
        domain: Domain,
        affinity: Affinity,
        era: Era,
        tags: TagConstellation = TagConstellation()
    ) {
        self.id = id
        self.name = name
        self.domain = domain
        self.affinity = affinity
        self.era = era
        self.tags = tags
    }

    /// Whether this artifact is a war-domain item (triggers Apotropaic Rule).
    /// Grounded in Te'omim Cave evidence: bronze weapons placed as protective talismans.
    public var isApotropaic: Bool {
        domain == .war
    }
}

/// A memory trace — evidence of a life lived rather than a specific identity.
/// Domestic pottery, loom weights, grain jars with ownership marks.
/// Enriches the manifestation — the more about who the person was, the more complete the spirit.
public struct MemoryTrace: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let tags: TagConstellation
    public let era: Era

    public init(
        id: UUID = UUID(),
        name: String,
        tags: TagConstellation = TagConstellation(),
        era: Era
    ) {
        self.id = id
        self.name = name
        self.tags = tags
        self.era = era
    }
}

/// A true name — spoken identification of the spirit.
/// Increases Coherence dramatically. Partial names produce partial bonuses.
public struct TrueName: Codable, Hashable, Sendable {
    /// The name as known. May be partial.
    public let text: String

    /// Whether the name is complete (personal name + patronymic) or partial.
    public let isPartial: Bool

    public init(_ text: String, partial: Bool = false) {
        self.text = text
        self.isPartial = partial
    }

    /// Coherence bonus from naming. Full names are dramatically stronger.
    public var coherenceBonus: Double {
        isPartial ? 0.3 : 0.7
    }
}
