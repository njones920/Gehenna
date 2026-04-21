// MARK: - Epoch Manifestation System
// The same person can manifest differently depending on how the ritual interrogates them.
//
// This is one of the deepest mechanics in the game and it reshapes what collection means.
// In Pokémon, the thing you caught is definitely the thing. Charizard is Charizard.
// In GEHENNA, the thing you summoned is one *aspect* of someone, and another aspect
// might exist that you have not yet encountered.
//
// Hiram son of Dagon, captain of Ashkelon, dies in battle. His bones go to Sheol.
// Centuries later, fragments of him survive in different contexts.
// - Invoked with military artifacts at a battlefield → Bronze Captain
// - Invoked with corrupted fragments at a desecrated site → Ashkelon Butcher
// - Invoked with familial memory traces at an ancestor shrine → Nameless Shield-Bearer
//
// All three are Hiram. None of them is the whole Hiram.

import Foundation

/// An epoch is a specific aspect of a root identity — who the person was
/// when viewed through a particular lens of fragments, eras, and world-state.
public struct Epoch: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID

    /// The epoch name — what the Codex calls this aspect.
    /// e.g. "Bronze Captain", "Ashkelon Butcher", "Nameless Shield-Bearer"
    public let name: String

    /// The template this epoch manifests as.
    public let template: SpiritTemplate

    /// The dominant era that activates this epoch.
    public let era: Era

    /// The dominant domain that activates this epoch.
    public let domain: Domain?

    /// Tag triggers — narrative tag values that, when present in the ritual configuration,
    /// bias template selection toward this epoch.
    public let triggerTags: Set<String>

    /// Tags that are intrinsic to this epoch — added to the manifestation's constellation.
    public let epochTags: TagConstellation

    /// Site type affinity — if the ritual is performed at this site type,
    /// this epoch is more likely to activate.
    public let preferredSiteType: SiteType?

    /// Corruption threshold — if regional corruption exceeds this, the epoch may activate.
    /// Used for "dark aspect" epochs like the Ashkelon Butcher.
    public let corruptionThreshold: Double?

    /// Personality traits specific to this epoch. Overrides the default template traits.
    public let personalityTraits: [PersonalityTrait]

    /// The baseline disposition when manifesting as this epoch.
    public let baselineDisposition: Disposition

    public init(
        id: UUID = UUID(),
        name: String,
        template: SpiritTemplate,
        era: Era,
        domain: Domain? = nil,
        triggerTags: Set<String> = [],
        epochTags: TagConstellation = TagConstellation(),
        preferredSiteType: SiteType? = nil,
        corruptionThreshold: Double? = nil,
        personalityTraits: [PersonalityTrait] = [],
        baselineDisposition: Disposition = .calm
    ) {
        self.id = id
        self.name = name
        self.template = template
        self.era = era
        self.domain = domain
        self.triggerTags = triggerTags
        self.epochTags = epochTags
        self.preferredSiteType = preferredSiteType
        self.corruptionThreshold = corruptionThreshold
        self.personalityTraits = personalityTraits
        self.baselineDisposition = baselineDisposition
    }
}

/// A root identity — the actual person beneath all their epoch manifestations.
/// The Codex builds toward discovering root identities by cross-referencing
/// epoch manifestations that share enough tags.
public struct RootIdentity: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID

    /// The person's full name, if known.
    public let trueName: String?

    /// Core tags that are common across all epochs — the identity bedrock.
    public let coreTags: TagConstellation

    /// All known epochs — the different aspects this person can manifest as.
    public var epochs: [Epoch]

    /// The era this person actually lived in.
    public let nativeEra: Era

    /// The cultural group this person belonged to.
    public let culture: String

    public init(
        id: UUID? = nil,
        trueName: String? = nil,
        coreTags: TagConstellation,
        epochs: [Epoch],
        nativeEra: Era,
        culture: String
    ) {
        if let id = id {
            self.id = id
        } else {
            let namePart = trueName ?? "unknown"
            let seedString = "\(namePart)|\(culture)|\(nativeEra.rawValue)"
            self.id = UUID.deterministic(from: seedString)
        }
        self.trueName = trueName
        self.coreTags = coreTags
        self.epochs = epochs
        self.nativeEra = nativeEra
        self.culture = culture
    }
}

extension UUID {
    /// Generates a deterministic UUID based on a stable string.
    /// This uses a stable custom hash to avoid the random seeding of Swift's `String.hashValue`.
    public static func deterministic(from string: String) -> UUID {
        let bytes = Array(string.utf8)
        
        // FNV-1a 64-bit hash function
        func fnv1a(_ data: [UInt8], seed: UInt64) -> UInt64 {
            var hash = seed
            for byte in data {
                hash ^= UInt64(byte)
                hash = hash &* 0x100000001B3
            }
            return hash
        }
        
        // Generate two 64-bit hashes using different seeds to fill 128 bits
        let h1 = fnv1a(bytes, seed: 0xCBF29CE484222325)
        let h2 = fnv1a(bytes, seed: 0x0123456789ABCDEF)
        
        var uuidBytes: [UInt8] = [
            UInt8((h1 >> 56) & 0xFF), UInt8((h1 >> 48) & 0xFF), UInt8((h1 >> 40) & 0xFF), UInt8((h1 >> 32) & 0xFF),
            UInt8((h1 >> 24) & 0xFF), UInt8((h1 >> 16) & 0xFF), UInt8((h1 >> 8) & 0xFF), UInt8(h1 & 0xFF),
            UInt8((h2 >> 56) & 0xFF), UInt8((h2 >> 48) & 0xFF), UInt8((h2 >> 40) & 0xFF), UInt8((h2 >> 32) & 0xFF),
            UInt8((h2 >> 24) & 0xFF), UInt8((h2 >> 16) & 0xFF), UInt8((h2 >> 8) & 0xFF), UInt8(h2 & 0xFF)
        ]
        
        // Set UUID version to 8 (Custom) and variant to RFC4122
        uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x80
        uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80
        
        return UUID(uuid: (
            uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
            uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
            uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
            uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
        ))
    }
}

/// The epoch resolver — determines which epoch of a root identity to manifest
/// based on the ritual configuration and world state.
public struct EpochResolver: Sendable {

    public init() {}

    /// Given a root identity and a ritual context, determine which epoch manifests.
    /// Returns nil if no epoch matches — the default template selection takes over.
    public func resolve(
        identity: RootIdentity,
        configuration: RitualConfiguration,
        regionState: RegionState
    ) -> Epoch? {
        guard !identity.epochs.isEmpty else { return nil }

        // Score each epoch against the current configuration
        let scored = identity.epochs.map { epoch in
            (epoch: epoch, score: scoreEpoch(epoch, configuration: configuration, regionState: regionState))
        }

        // The highest-scoring epoch wins, with a minimum threshold
        let best = scored.max(by: { $0.score < $1.score })
        guard let winner = best, winner.score > 0.2 else {
            // No epoch scores high enough — fall back to the first (default) epoch
            return identity.epochs.first
        }

        return winner.epoch
    }

    /// Score how well an epoch matches the current ritual context.
    private func scoreEpoch(
        _ epoch: Epoch,
        configuration: RitualConfiguration,
        regionState: RegionState
    ) -> Double {
        var score = 0.0

        // Era alignment — the dominant era of the ritual vs the epoch's era
        let eraAlignment = configuration.dominantEra.alignment(with: epoch.era)
        score += eraAlignment * 0.3

        // Domain alignment — if the epoch has a domain preference
        if let epochDomain = epoch.domain {
            if configuration.remains.domain == epochDomain {
                score += 0.25
            }
            if configuration.lifeArtifact?.domain == epochDomain {
                score += 0.15
            }
        }

        // Tag trigger matching — how many trigger tags appear in the configuration
        let configTagValues = Set(configuration.aggregatedTags.tags.map(\.value))
        let triggerMatches = epoch.triggerTags.intersection(configTagValues).count
        if !epoch.triggerTags.isEmpty {
            score += Double(triggerMatches) / Double(epoch.triggerTags.count) * 0.25
        }

        // Site type preference
        if let preferred = epoch.preferredSiteType, preferred == configuration.site.type {
            score += 0.15
        }

        // Corruption threshold — dark aspects activate in corrupted conditions
        if let threshold = epoch.corruptionThreshold {
            if regionState.corruption >= threshold {
                score += 0.2
            } else {
                score -= 0.1  // penalize dark epochs in clean conditions
            }
        }

        // Libation influence — blood offerings bias toward violent epochs
        if let libation = configuration.libation {
            switch libation.type {
            case .bloodOffering:
                if epoch.baselineDisposition == .hostile || epoch.baselineDisposition == .hungry {
                    score += 0.1
                }
            case .honeyWine:
                if epoch.baselineDisposition == .honored || epoch.baselineDisposition == .calm {
                    score += 0.1
                }
            case .fermentedWine:
                if epoch.baselineDisposition == .curious || epoch.baselineDisposition == .calm {
                    score += 0.05
                }
            default:
                break
            }
        }

        return max(0.0, score)
    }
}

// MARK: - Ridge of Elah Root Identities

extension RidgeOfElah {

    /// Hiram son of Dagon — the example from the Codex.
    /// Captain of Ashkelon. Philistine warrior. Died in battle on the ridge.
    /// Three epochs: the soldier at his best, the violence of his death, the protector.
    public static func hiramSonOfDagon() -> RootIdentity {
        RootIdentity(
            trueName: "Hiram, son of Dagon",
            coreTags: TagConstellation([
                NarrativeTag(.identity, "soldier"),
                NarrativeTag(.identity, "Philistine"),
                NarrativeTag(.identity, "captain"),
                NarrativeTag(.cultural, "coastal_warrior"),
                NarrativeTag(.cultural, "Ashkelon"),
                NarrativeTag(.deathContext, "battle"),
                NarrativeTag(.relational, "served_a_lord"),
            ]),
            epochs: [
                // Epoch 1: Bronze Captain — the soldier at his best
                Epoch(
                    name: "Bronze Captain",
                    template: .warrior,
                    era: .ironAgeII,
                    domain: .war,
                    triggerTags: ["soldier", "captain", "coastal_warrior", "Ashkelon"],
                    epochTags: TagConstellation([
                        NarrativeTag(.disposition, "duty"),
                        NarrativeTag(.disposition, "pride"),
                        NarrativeTag(.relational, "commanded_infantry"),
                    ]),
                    preferredSiteType: .battlefield,
                    personalityTraits: [.prideful, .loyal],
                    baselineDisposition: .honored
                ),
                // Epoch 2: Ashkelon Butcher — the violence overtaking the person
                Epoch(
                    name: "Ashkelon Butcher",
                    template: .butcher,
                    era: .ironAgeII,
                    domain: .war,
                    triggerTags: ["battle", "rage", "burning"],
                    epochTags: TagConstellation([
                        NarrativeTag(.disposition, "rage"),
                        NarrativeTag(.deathContext, "violent_end"),
                    ]),
                    preferredSiteType: .topheth,
                    corruptionThreshold: 0.4,
                    personalityTraits: [.spiteful, .territorial],
                    baselineDisposition: .hostile
                ),
                // Epoch 3: Nameless Shield-Bearer — the protector, the tender version
                Epoch(
                    name: "Nameless Shield-Bearer",
                    template: .guardian,
                    era: .ironAgeII,
                    domain: .war,
                    triggerTags: ["household", "son_of", "served_a_lord"],
                    epochTags: TagConstellation([
                        NarrativeTag(.disposition, "devotion"),
                        NarrativeTag(.relational, "protected_someone"),
                    ]),
                    preferredSiteType: .ancestorShrine,
                    personalityTraits: [.protective, .loyal],
                    baselineDisposition: .calm
                ),
            ],
            nativeEra: .ironAgeII,
            culture: "Philistine"
        )
    }

    /// The Scribe of Baal — the temple-trained knowledge keeper of Tel Keshet.
    /// Two epochs: the scholar and the heretic.
    public static func scribeOfBaal() -> RootIdentity {
        RootIdentity(
            trueName: nil,    // only the partial "...ram, son of" is known
            coreTags: TagConstellation([
                NarrativeTag(.identity, "scribe"),
                NarrativeTag(.identity, "Canaanite"),
                NarrativeTag(.identity, "elder"),
                NarrativeTag(.cultural, "temple_trained"),
                NarrativeTag(.cultural, "devoted_to_baal"),
                NarrativeTag(.deathContext, "old_age"),
            ]),
            epochs: [
                // Epoch 1: Temple Scribe — the keeper of knowledge
                Epoch(
                    name: "Temple Scribe",
                    template: .witness,
                    era: .lateBronze,
                    domain: .knowledge,
                    triggerTags: ["scribe", "temple_trained", "elder"],
                    epochTags: TagConstellation([
                        NarrativeTag(.disposition, "pride"),
                        NarrativeTag(.relational, "raised_apprentices"),
                    ]),
                    preferredSiteType: .collapsingTemple,
                    personalityTraits: [.prideful, .curious],
                    baselineDisposition: .curious
                ),
                // Epoch 2: Voice of Baal — the devoted, refusing the new gods
                Epoch(
                    name: "Voice of Baal",
                    template: .prophet,
                    era: .lateBronze,
                    domain: .faith,
                    triggerTags: ["devoted_to_baal", "priest", "will_not_speak_yhwh"],
                    epochTags: TagConstellation([
                        NarrativeTag(.disposition, "devotion"),
                        NarrativeTag(.taboo, "will_not_speak_yhwh"),
                    ]),
                    preferredSiteType: .collapsingTemple,
                    personalityTraits: [.territorial, .prideful],
                    baselineDisposition: .honored
                ),
            ],
            nativeEra: .lateBronze,
            culture: "Canaanite"
        )
    }

    /// Abdi-Resheph — the Early Bronze Age ruler from the deep shaft of Nahal Caves.
    /// The Rephaim gate guardian. Three epochs.
    public static func abdiResheph() -> RootIdentity {
        RootIdentity(
            trueName: "Abdi-Resheph",
            coreTags: TagConstellation([
                NarrativeTag(.identity, "ruler"),
                NarrativeTag(.identity, "elder"),
                NarrativeTag(.era, "early_bronze_age"),
                NarrativeTag(.cultural, "first_settlements"),
                NarrativeTag(.deathContext, "old_age"),
                NarrativeTag(.relational, "founded_a_lineage"),
                NarrativeTag(.taboo, "will_not_serve"),
            ]),
            epochs: [
                // Epoch 1: Founder — the builder of the lineage
                Epoch(
                    name: "The Founder",
                    template: .sovereign,
                    era: .earlyBronze,
                    domain: .rule,
                    triggerTags: ["ruler", "founded_a_lineage", "first_settlements"],
                    epochTags: TagConstellation([
                        NarrativeTag(.disposition, "authority"),
                        NarrativeTag(.relational, "established_order"),
                    ]),
                    preferredSiteType: .burialCave,
                    personalityTraits: [.prideful, .territorial],
                    baselineDisposition: .honored
                ),
                // Epoch 2: The Warden — guarding the deep shaft
                Epoch(
                    name: "Warden of the Deep",
                    template: .warden,
                    era: .earlyBronze,
                    domain: .death,
                    triggerTags: ["elder", "ancestor_veneration", "will_not_serve"],
                    epochTags: TagConstellation([
                        NarrativeTag(.disposition, "authority"),
                        NarrativeTag(.taboo, "will_not_serve"),
                    ]),
                    preferredSiteType: .burialCave,
                    personalityTraits: [.territorial, .resentful],
                    baselineDisposition: .hostile
                ),
                // Epoch 3: The Ancestor — invoked for guidance at the shrine
                Epoch(
                    name: "First Ancestor",
                    template: .guardian,
                    era: .earlyBronze,
                    domain: .rule,
                    triggerTags: ["ancestor_veneration", "household", "peace"],
                    epochTags: TagConstellation([
                        NarrativeTag(.disposition, "peace"),
                    ]),
                    preferredSiteType: .ancestorShrine,
                    personalityTraits: [.protective, .amusedByBoldness],
                    baselineDisposition: .calm
                ),
            ],
            nativeEra: .earlyBronze,
            culture: "Canaanite/Early Bronze"
        )
    }

    /// All root identities for the Ridge of Elah vertical slice.
    public static func rootIdentities() -> [RootIdentity] {
        [hiramSonOfDagon(), scribeOfBaal(), abdiResheph()]
    }
}
