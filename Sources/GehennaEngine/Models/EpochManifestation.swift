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

    /// Strict requirements the practitioner must meet to manifest this epoch.
    /// Overrides the template's baseline requirements.
    public let identityRequirements: IdentityRequirements?

    // MARK: Interiority — authored per epoch, same model as NPCs.
    // Optional so pre-0.4.29 canon files decode unchanged. The Expression
    // Layer renders these; they are never shown as raw facts.

    /// How this aspect narrates its own existence to itself.
    public let interiorVoice: String?

    /// Something true about this aspect the practitioner may never learn.
    public let privateTruth: String?

    /// What shaped this aspect before anyone called it back.
    public let wound: String?

    /// What this aspect wants that no ritual can supply.
    public let unsatisfiedWant: String?

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
        baselineDisposition: Disposition = .calm,
        identityRequirements: IdentityRequirements? = nil,
        interiorVoice: String? = nil,
        privateTruth: String? = nil,
        wound: String? = nil,
        unsatisfiedWant: String? = nil
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
        self.identityRequirements = identityRequirements
        self.interiorVoice = interiorVoice
        self.privateTruth = privateTruth
        self.wound = wound
        self.unsatisfiedWant = unsatisfiedWant
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
            self.id = UUID.deterministic(from: RootIdentity.identitySeed(
                trueName: trueName,
                coreTags: coreTags,
                epochs: epochs,
                nativeEra: nativeEra,
                culture: culture
            ))
        }
        self.trueName = trueName
        self.coreTags = coreTags
        self.epochs = epochs
        self.nativeEra = nativeEra
        self.culture = culture
    }

    private static func identitySeed(
        trueName: String?,
        coreTags: TagConstellation,
        epochs: [Epoch],
        nativeEra: Era,
        culture: String
    ) -> String {
        let normalizedName = (trueName ?? "unknown")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        let normalizedCulture = culture
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        let canonicalTags = coreTags.tags
            .map { "\($0.dimension.rawValue):\($0.value):\($0.weight)" }
            .sorted()
            .joined(separator: "|")

        let canonicalEpochEntries = epochs.map { epoch -> String in
            let epochName = epoch.name
            let template = epoch.template.rawValue
            let era = String(epoch.era.rawValue)
            let domain = epoch.domain?.rawValue ?? "none"
            let preferredSiteType = epoch.preferredSiteType?.rawValue ?? "none"
            let corruptionThreshold = epoch.corruptionThreshold.map { String($0) } ?? "none"
            let triggerTags = epoch.triggerTags.sorted().joined(separator: ",")

            return [
                epochName,
                template,
                era,
                domain,
                preferredSiteType,
                corruptionThreshold,
                triggerTags
            ].joined(separator: "~")
        }
        let canonicalEpochs = canonicalEpochEntries
            .sorted()
            .joined(separator: "|")

        return [
            "name=\(normalizedName)",
            "culture=\(normalizedCulture)",
            "nativeEra=\(nativeEra.rawValue)",
            "coreTags=\(canonicalTags)",
            "epochs=\(canonicalEpochs)"
        ].joined(separator: "||")
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
    /// `relationalValence` steers aspect selection on a call-by-name: a soured
    /// relationship favors the person's dark aspects; a warm one favors the
    /// aspect the practitioner has actually known. Epochs are moods of the
    /// relationship, not random forms.
    public func resolve(
        identity: RootIdentity,
        configuration: RitualConfiguration,
        regionState: RegionState,
        relationalValence: Double = 0.0
    ) -> Epoch? {
        guard !identity.epochs.isEmpty else { return nil }

        // Score each epoch against the current configuration
        let scored = identity.epochs.map { epoch in
            (epoch: epoch, score: scoreEpoch(
                epoch,
                configuration: configuration,
                regionState: regionState,
                relationalValence: relationalValence
            ))
        }

        // The highest-scoring epoch wins, with a minimum threshold
        let best = scored.max(by: { $0.score < $1.score })
        guard let winner = best, winner.score > 0.2 else {
            // No epoch scores high enough — fall back to the first (default) epoch
            return identity.epochs.first
        }

        return winner.epoch
    }

    /// Whether an epoch is a dark aspect — the shape a person takes when
    /// what was done to them outweighs who they were.
    private func isDarkAspect(_ epoch: Epoch) -> Bool {
        epoch.corruptionThreshold != nil
            || epoch.baselineDisposition == .hostile
            || epoch.template == .butcher
    }

    /// Score how well an epoch matches the current ritual context.
    private func scoreEpoch(
        _ epoch: Epoch,
        configuration: RitualConfiguration,
        regionState: RegionState,
        relationalValence: Double = 0.0
    ) -> Double {
        var score = 0.0

        // Relational steering — how the practitioner has treated this
        // person tilts which aspect picks up. Banish the Captain often
        // enough and the Butcher answers instead.
        if relationalValence < 0, isDarkAspect(epoch) {
            score += min(0.5, -relationalValence * 0.5)
        } else if relationalValence > 0, !isDarkAspect(epoch) {
            score += min(0.3, relationalValence * 0.25)
        }

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

