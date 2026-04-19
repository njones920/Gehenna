// MARK: - Resolution Pipeline
// The 13-stage deterministic pipeline that compiles a ritual into a spirit.
// The stages are precise because they have to be — any spirit can be traced
// back through its resolution and the trace will reproduce the same output
// from the same inputs.
//
// Same canon version, same pre-state, same intent, same entropy envelope
// must produce the same event.

import Foundation

/// The outcome class of a ritual — determined by the Coherence/Resonance/Conflict balance.
public enum OutcomeClass: String, Codable, Hashable, Sendable {
    case targeted       // high coherence — the specific spirit the practitioner was configuring for
    case guided         // moderate coherence — right neighborhood, some variance
    case wildDraw       // low coherence — a spirit from the tier/region pool
    case hostile        // high conflict — something came through that doesn't want to cooperate
    case mutation       // extreme conflict + regional entropy — the Mutation Protocol
    case failure        // authority rejected or critical configuration error
}

/// Intermediate computation state during pipeline resolution.
public struct ResolutionState: Sendable {
    public let configuration: RitualConfiguration
    public let regionState: RegionState
    public let profile: PractitionerProfile
    public let rootIdentities: [RootIdentity]
    public var entropySource: EntropySource

    // -- Computed during pipeline stages --
    public var coherence: Double = 0.0
    public var resonance: Double = 0.0
    public var conflict: Double = 0.0
    public var effectiveConflict: Double = 0.0  // after apotropaic reduction
    public var outcomeClass: OutcomeClass = .wildDraw
    public var resolvedTier: SpiritTier = .common
    public var authorityPassed: Bool = false
    public var isMutation: Bool = false

    // -- Epoch Resolution --
    public var resolvedEpoch: Epoch? = nil
    public var resolvedRootIdentity: RootIdentity? = nil

    // -- Diagnostics --
    public var autopsyFactors: [String] = []

    public init(
        configuration: RitualConfiguration,
        regionState: RegionState,
        profile: PractitionerProfile,
        rootIdentities: [RootIdentity] = [],
        entropySource: EntropySource
    ) {
        self.configuration = configuration
        self.regionState = regionState
        self.profile = profile
        self.rootIdentities = rootIdentities
        self.entropySource = entropySource
    }
}

/// Deterministic entropy source for reproducible resolution.
/// Uses a seeded PRNG so every ritual can be replayed identically.
public struct EntropySource: Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    /// Generate a deterministic random double in [0, 1).
    public mutating func next() -> Double {
        // xorshift64 — simple, fast, deterministic
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state) / Double(UInt64.max)
    }

    /// Generate a random double in [min, max].
    public mutating func next(in range: ClosedRange<Double>) -> Double {
        let raw = next()
        return range.lowerBound + raw * (range.upperBound - range.lowerBound)
    }
}

/// The result of a completed ritual resolution.
public struct RitualResult: Sendable {
    /// The spirit that manifested (nil if failure).
    public let spirit: Spirit?

    /// The outcome class.
    public let outcomeClass: OutcomeClass

    /// World-state effects to apply.
    public let worldEffects: WorldEffects

    /// Diagnostic text — the Ritual Autopsy.
    public let autopsy: [String]

    /// The entropy seed used — for replay verification.
    public let entropySeed: UInt64
}

/// World-state changes produced by a ritual.
public struct WorldEffects: Sendable {
    public var ghostActivityDelta: Double = 0.0
    public var corruptionDelta: Double = 0.0
    public var spiritualPressureDelta: Double = 0.0
    public var suspicionDelta: Double = 0.0
    public var siteScarring: Double = 0.0
    public var veilDamage: Double = 0.0
}

// MARK: - The Pipeline

/// The ritual resolution pipeline — the compiler.
public struct ResolutionPipeline: Sendable {

    public init() {}

    /// Resolve a ritual configuration into a spirit manifestation.
    /// This is the complete 13-stage pipeline from §3.5.
    public func resolve(
        configuration: RitualConfiguration,
        regionState: RegionState,
        profile: PractitionerProfile,
        seed: UInt64,
        rootIdentities: [RootIdentity] = []
    ) -> RitualResult {
        var state = ResolutionState(
            configuration: configuration,
            regionState: regionState,
            profile: profile,
            rootIdentities: rootIdentities,
            entropySource: EntropySource(seed: seed)
        )

        // Stage 1: Aggregation
        aggregation(&state)

        // Stage 2: Authority
        authority(&state)
        guard state.authorityPassed else {
            return RitualResult(
                spirit: nil,
                outcomeClass: .failure,
                worldEffects: WorldEffects(suspicionDelta: 0.05),
                autopsy: state.autopsyFactors + ["The site refused you. Your credentials did not hold."],
                entropySeed: seed
            )
        }

        // Stage 3: Coherence
        computeCoherence(&state)

        // Stage 4: Resonance
        computeResonance(&state)

        // Stage 5: Conflict
        computeConflict(&state)

        // Stage 6: Apotropaic Evaluation
        apotropaicEvaluation(&state)

        // Stage 7: Outcome Class
        determineOutcomeClass(&state)

        // Stage 8: Mutation Check
        mutationCheck(&state)

        // Stage 9: Tier Resolution
        resolveTier(&state)

        // Stage 10: Attribute Generation
        let attributes = generateAttributes(&state)

        // Stage 11: Template Selection (now epoch-aware)
        let template = selectTemplate(&state)

        // Stage 11.5: Epoch Resolution — if a root identity matches,
        // the epoch overrides template, personality, and disposition.
        resolveEpoch(&state)

        // Stage 12: Personality Binding
        let (traits, disposition) = bindPersonality(&state, template: template)

        // Stage 13: Manifestation
        return manifestation(&state, template: template, attributes: attributes,
                            traits: traits, disposition: disposition, seed: seed)
    }

    // MARK: - Pipeline Stages

    /// Stage 1: Collect all structured properties and narrative tags.
    private func aggregation(_ state: inout ResolutionState) {
        // Aggregation is implicit in the RitualConfiguration structure.
        // Tags are collected via configuration.aggregatedTags.
        // This stage exists to formalize the moment the pipeline begins.
        state.autopsyFactors.append("The fragments were gathered. The site was prepared.")
    }

    /// Stage 2: Verify the practitioner has standing to compile this ritual.
    private func authority(_ state: inout ResolutionState) {
        let tokens = state.profile.tokens

        // Basic authority check: effective purity must be above threshold
        let purityThreshold = 0.2  // very permissive — unauthorized rituals are dangerous, not impossible
        if tokens.effectivePurity < purityThreshold {
            state.autopsyFactors.append("Your hands were too unclean. The site turned you away.")
            state.authorityPassed = false
            return
        }

        // High-sanctity sites require better credentials
        if state.configuration.site.sanctity > 0.7 && tokens.effectivePurity < 0.5 {
            state.autopsyFactors.append("The sanctity of the place was too great for what you carry.")
            state.authorityPassed = false
            return
        }

        // Ritual fatigue check — too many rituals too fast
        if tokens.ritualFatigue > 0.9 {
            state.autopsyFactors.append("You were spent. The words would not come.")
            state.authorityPassed = false
            return
        }

        state.authorityPassed = true
    }

    /// Stage 3: Compute Coherence — do the fragments point to the same person?
    private func computeCoherence(_ state: inout ResolutionState) {
        var coherence = 0.0

        // Remains coherence weight (skull > long bone > ... > cremated bone)
        coherence += state.configuration.remains.coherenceWeight * 0.4

        // True Name is the biggest coherence contributor
        if let name = state.configuration.trueName {
            coherence += name.coherenceBonus
            if !name.isPartial {
                state.autopsyFactors.append("The name carried farther than the bone.")
            }
        }

        // Life Artifact matching adds coherence if domains match remains
        if let artifact = state.configuration.lifeArtifact {
            if artifact.domain == state.configuration.remains.domain {
                coherence += 0.2
            }
            if artifact.era == state.configuration.remains.era {
                coherence += 0.1
            }
        }

        // Memory Trace adds coherence through tag overlap
        if let trace = state.configuration.memoryTrace {
            let similarity = trace.tags.similarity(to: state.configuration.remains.tags)
            coherence += similarity * 0.15
        }

        // Summoner skill reduces noise
        coherence += state.profile.summonerSkill * 0.1

        state.coherence = min(1.0, max(0.0, coherence))
    }

    /// Stage 4: Compute Resonance — do the input properties amplify each other?
    private func computeResonance(_ state: inout ResolutionState) {
        var resonance = 0.0
        let config = state.configuration

        // Affinity resonance: remains ↔ site
        resonance += config.site.siteResonance(with: config.remains.affinity) * 0.3

        // Affinity resonance: remains ↔ artifact
        if let artifact = config.lifeArtifact {
            resonance += config.remains.affinity.resonanceWith(artifact.affinity) * 0.2
        }

        // Domain resonance: remains ↔ artifact
        if let artifact = config.lifeArtifact {
            if config.remains.domain.resonatesWith(artifact.domain) {
                resonance += 0.15
            }
        }

        // Era alignment across inputs
        let eras = config.eras
        if eras.count > 1 {
            let alignments = zip(eras, eras.dropFirst()).map { $0.alignment(with: $1) }
            let avgAlignment = alignments.reduce(0.0, +) / Double(alignments.count)
            resonance += avgAlignment * 0.15
        }

        // Libation bonus
        if let libation = config.libation {
            resonance += libation.resonanceModifier

            // Domain match between libation and remains
            if let libDomain = libation.domain, libDomain.resonatesWith(config.remains.domain) {
                resonance += 0.1
            }
        }

        // Timing bonus
        if let timing = config.timing {
            resonance += max(0.0, timing.resonanceBonus)
        }

        // Site death saturation amplifies everything
        resonance *= (1.0 + config.site.deathSaturation * 0.2)

        state.resonance = min(1.0, max(0.0, resonance))

        if state.resonance > 0.6 {
            state.autopsyFactors.append("The fragments sang together. The resonance was strong.")
        }
    }

    /// Stage 5: Compute Conflict — do the input properties oppose each other?
    private func computeConflict(_ state: inout ResolutionState) {
        var conflict = 0.0
        let config = state.configuration

        // Affinity opposition: remains ↔ site
        if config.remains.affinity.opposes(config.site.affinity) {
            conflict += 0.3
            state.autopsyFactors.append("The site overpowered your offering.")
        }

        // Affinity opposition: remains ↔ artifact
        if let artifact = config.lifeArtifact {
            if config.remains.affinity.opposes(artifact.affinity) {
                conflict += 0.2
            }
        }

        // Domain conflict
        if let artifact = config.lifeArtifact {
            if config.remains.domain.conflictsWith(artifact.domain) {
                conflict += 0.15
            }
        }

        // Low integrity increases conflict — corrupted fragments are unstable
        if config.remains.integrity.isCorrupted {
            conflict += 0.2
        } else if config.remains.integrity.isDegraded {
            conflict += 0.1
        }

        // Site corruption amplifies conflict
        conflict += config.site.corruption * 0.15

        // Blood offering adds conflict
        if let libation = config.libation {
            if libation.type == .bloodOffering {
                conflict += 0.15
                state.autopsyFactors.append("The blood drew something that was already listening.")
            } else if libation.type == .opiumTincture {
                conflict += 0.1
            }
        }

        // Bad timing amplifies conflict
        if let timing = config.timing, timing.resonanceBonus < 0 {
            conflict += abs(timing.resonanceBonus) * 0.5
            state.autopsyFactors.append("The hour was wrong. You felt it as you spoke.")
        }

        state.conflict = min(1.0, max(0.0, conflict))
    }

    /// Stage 6: Apotropaic Evaluation.
    /// War-domain Life Artifact reduces effective Conflict for Hostile Manifestation probability.
    /// Grounded in Te'omim Cave: bronze weapons placed as protective talismans.
    private func apotropaicEvaluation(_ state: inout ResolutionState) {
        state.effectiveConflict = state.conflict

        if state.configuration.hasApotropaicArtifact {
            // Reduce by one "band" — approximately 0.15 reduction
            state.effectiveConflict = max(0.0, state.effectiveConflict - 0.15)
            state.autopsyFactors.append("The bronze turned something aside. You would not know what.")
        }
    }

    /// Stage 7: Determine Outcome Class from Coherence/Resonance/Conflict balance.
    private func determineOutcomeClass(_ state: inout ResolutionState) {
        let c = state.coherence
        let r = state.resonance
        let ec = state.effectiveConflict

        if ec > 0.7 && c < 0.3 {
            state.outcomeClass = .hostile
        } else if c > 0.6 && r > 0.4 {
            state.outcomeClass = .targeted
        } else if c > 0.3 {
            state.outcomeClass = .guided
        } else if ec > c {
            state.outcomeClass = .hostile
        } else {
            state.outcomeClass = .wildDraw
        }
    }

    /// Stage 8: Mutation Check.
    /// If Conflict radically exceeds Coherence AND regional entropy is sufficient,
    /// divert to the Mutation Protocol.
    private func mutationCheck(_ state: inout ResolutionState) {
        let conflictRatio = state.conflict / max(0.01, state.coherence)
        let region = state.regionState

        // Mutation requires: high conflict/coherence ratio + regional entropy
        if conflictRatio > 3.0 &&
           region.spiritualPressure > 0.5 &&
           region.veilThinness > 0.4 {
            // Probabilistic trigger — cannot be reliably farmed
            let mutationChance = min(0.6, (conflictRatio - 3.0) * 0.15 +
                                           region.spiritualPressure * 0.3)
            let roll = state.entropySource.next()
            if roll < mutationChance {
                state.outcomeClass = .mutation
                state.isMutation = true
                state.autopsyFactors.append("Something broke in the grammar. The fragments did not agree, and the Veil filled the gaps with what it had.")
            }
        }
    }

    /// Stage 9: Tier Resolution.
    /// Determined by era depth, fragment completeness, site Veil Thinness, libation gating.
    private func resolveTier(_ state: inout ResolutionState) {
        let config = state.configuration
        var tierScore = 0.0

        // Era depth contributes
        tierScore += Double(config.remains.era.depth) * 0.15

        // Fragment completeness
        tierScore += Double(config.completeness) * 0.1

        // Site Veil Thinness — thinner veil allows deeper pulls
        tierScore += config.site.veilThinness * 0.2

        // Region Veil Thinness
        tierScore += state.regionState.veilThinness * 0.15

        // Coherence bonus
        tierScore += state.coherence * 0.2

        // Determine tier from score
        let maxAllowedByLibation: SpiritTier = config.libation?.tiersUnlocked.max() ?? .common

        let resolvedFromScore: SpiritTier
        switch tierScore {
        case 0.0..<0.3:  resolvedFromScore = .common
        case 0.3..<0.5:  resolvedFromScore = .uncommon
        case 0.5..<0.7:  resolvedFromScore = .rare
        case 0.7..<0.9:  resolvedFromScore = .legendary
        default:         resolvedFromScore = .mythic
        }

        // Tier cannot exceed libation gating
        state.resolvedTier = min(resolvedFromScore, maxAllowedByLibation)

        // Mutations can exceed normal tier by one
        if state.isMutation && state.resolvedTier < .mythic {
            let roll = state.entropySource.next()
            if roll < 0.3 {
                state.resolvedTier = SpiritTier(rawValue: state.resolvedTier.rawValue + 1)!
            }
        }
    }

    /// Stage 10: Generate Strength, Knowledge, Will, Stability, Disposition attributes.
    private func generateAttributes(_ state: inout ResolutionState) -> SpiritAttributes {
        let tier = state.resolvedTier
        let tierMultiplier = Double(tier.rawValue) * 0.2
        let variance = state.configuration.libation?.varianceMultiplier ?? 1.0

        // Base attributes scale with tier
        let baseStrength = (0.3 + tierMultiplier) * (state.configuration.remains.domain == .war ? 1.3 : 1.0)
        let baseKnowledge = (0.3 + tierMultiplier) * (state.configuration.remains.domain == .knowledge ? 1.3 : 1.0)
        let baseWill = 0.3 + tierMultiplier
        let baseStability = 0.5 + state.resonance * 0.3 - state.conflict * 0.2

        // Apply variance and entropy
        let strength = max(0.1, min(1.0, baseStrength + state.entropySource.next(in: -0.15...0.15) * variance))
        let knowledge = max(0.1, min(1.0, baseKnowledge + state.entropySource.next(in: -0.15...0.15) * variance))
        let will = max(0.1, min(1.0, baseWill + state.entropySource.next(in: -0.1...0.1) * variance))
        let stability = max(0.1, min(1.0, baseStability + state.entropySource.next(in: -0.1...0.1) * variance))

        // Disposition score — influences starting Disposition enum
        let dispositionScore = 0.5 + state.resonance * 0.3 - state.effectiveConflict * 0.3
            + state.entropySource.next(in: -0.1...0.1) * variance

        // Mutations have massive variance
        if state.isMutation {
            return SpiritAttributes(
                strength: max(0.1, min(1.2, strength + state.entropySource.next(in: -0.3...0.3))),
                knowledge: max(0.1, min(1.2, knowledge + state.entropySource.next(in: -0.3...0.3))),
                will: max(0.1, min(1.2, will + state.entropySource.next(in: -0.3...0.3))),
                stability: max(0.1, min(0.8, stability - 0.2)),  // mutations are inherently unstable
                disposition: dispositionScore
            )
        }

        return SpiritAttributes(
            strength: strength,
            knowledge: knowledge,
            will: will,
            stability: stability,
            disposition: dispositionScore
        )
    }

    /// Stage 11: Template Selection — match narrative tags against available templates.
    private func selectTemplate(_ state: inout ResolutionState) -> SpiritTemplate {
        let config = state.configuration
        let domain = config.remains.domain

        // Mutations use a forced template
        if state.isMutation {
            // Schismatic — oscillates. Pick from conflict-adjacent templates.
            let conflictTemplates: [SpiritTemplate] = [.butcher, .warden, .shade]
            let idx = Int(state.entropySource.next() * Double(conflictTemplates.count))
            return conflictTemplates[min(idx, conflictTemplates.count - 1)]
        }

        // Domain-primary template selection
        let domainTemplates: [Domain: [SpiritTemplate]] = [
            .war:       [.warrior, .scout, .guardian, .butcher],
            .knowledge: [.prophet, .witness, .artisan],
            .faith:     [.prophet, .mourner, .guardian],
            .rule:      [.sovereign, .warden, .merchant],
            .death:     [.shade, .mourner, .warden],
        ]

        let candidates = domainTemplates[domain] ?? [.shade]

        // Tag-based refinement
        let tags = config.aggregatedTags
        if tags.contains(value: "soldier") || tags.contains(value: "warrior") { return .warrior }
        if tags.contains(value: "king") || tags.contains(value: "ruler") { return .sovereign }
        if tags.contains(value: "priest") || tags.contains(value: "seer") { return .prophet }
        if tags.contains(value: "smith") || tags.contains(value: "builder") { return .artisan }
        if tags.contains(value: "trader") || tags.contains(value: "merchant") { return .merchant }
        if tags.contains(value: "protector") || tags.contains(value: "guardian") { return .guardian }

        // Default: pick from domain candidates weighted by tier
        if state.resolvedTier >= .legendary && candidates.contains(.sovereign) {
            return .sovereign
        }

        let idx = Int(state.entropySource.next() * Double(candidates.count))
        return candidates[min(idx, candidates.count - 1)]
    }

    /// Stage 11.5: Epoch Resolution.
    /// Determines which aspect of a root identity manifests based on the ritual context.
    /// If a root identity matches, the epoch overrides the default template selection.
    private func resolveEpoch(_ state: inout ResolutionState) {
        guard !state.isMutation else { return }  // mutations bypass epoch resolution
        guard !state.rootIdentities.isEmpty else { return }

        let config = state.configuration
        let configTags = Set(config.aggregatedTags.tags.map(\.value))

        // Score each root identity by tag overlap with the configuration
        var bestMatch: (identity: RootIdentity, score: Double)? = nil
        for identity in state.rootIdentities {
            let coreTags = Set(identity.coreTags.tags.map(\.value))
            let overlap = configTags.intersection(coreTags).count
            let score = Double(overlap) / max(1.0, Double(coreTags.count))

            // True name match is a massive coherence bonus
            var nameBonus = 0.0
            if let trueName = config.trueName,
               let rootName = identity.trueName,
               trueName.text.localizedCaseInsensitiveContains(rootName) {
                nameBonus = 0.5
            }

            let totalScore = score + nameBonus
            if totalScore > 0.3, totalScore > (bestMatch?.score ?? 0.0) {
                bestMatch = (identity, totalScore)
            }
        }

        guard let match = bestMatch else { return }

        // Found a root identity — now resolve which epoch
        let resolver = EpochResolver()
        if let epoch = resolver.resolve(
            identity: match.identity,
            configuration: config,
            regionState: state.regionState
        ) {
            state.resolvedEpoch = epoch
            state.resolvedRootIdentity = match.identity

            state.autopsyFactors.append(
                "The fragments pointed to someone specific. The \(epoch.name) answered."
            )
        }
    }

    /// Stage 12: Personality Binding.
    /// Bind intrinsic Personality Traits from the template. Apply regional reputation memory.
    /// If an epoch was resolved, the epoch's traits and baseline disposition override defaults.
    private func bindPersonality(_ state: inout ResolutionState, template: SpiritTemplate) -> ([PersonalityTrait], Disposition) {

        // If an epoch was resolved, use its personality and disposition
        if let epoch = state.resolvedEpoch {
            let traits = epoch.personalityTraits.isEmpty
                ? defaultTraits(for: epoch.template) : epoch.personalityTraits

            // Start with the epoch's baseline disposition, modulate by resonance/conflict
            var disposition = epoch.baselineDisposition

            // Libation can shift disposition
            if let libation = state.configuration.libation {
                switch libation.type {
                case .fermentedWine:
                    state.autopsyFactors.append("The wine softened the sharp edges.")
                case .bloodOffering:
                    if disposition == .calm || disposition == .curious {
                        disposition = .hungry
                        state.autopsyFactors.append("The blood changed something. It came sharper.")
                    }
                default: break
                }
            }

            return (traits, disposition)
        }

        // Default: template-intrinsic traits
        let traits = defaultTraits(for: template)

        // Disposition from attributes
        let dispScore = state.entropySource.next()  // additional variance
        let baseDisp = (state.resonance - state.effectiveConflict + 0.5) * 0.5 + dispScore * 0.5

        let disposition: Disposition
        switch baseDisp {
        case 0.0..<0.2:  disposition = .hostile
        case 0.2..<0.35: disposition = .hungry
        case 0.35..<0.5: disposition = .sorrowful
        case 0.5..<0.65: disposition = .calm
        case 0.65..<0.8: disposition = .curious
        default:         disposition = .honored
        }

        // Libation influence on disposition
        if let libation = state.configuration.libation {
            switch libation.type {
            case .fermentedWine:
                state.autopsyFactors.append("The wine softened the sharp edges.")
            case .bloodOffering where disposition != .hostile:
                state.autopsyFactors.append("The blood did not trouble it. Not this time.")
            default: break
            }
        }

        if disposition == .hostile {
            state.autopsyFactors.append("The spirit did not come willingly.")
        } else if disposition == .honored {
            state.autopsyFactors.append("The spirit did not come hungry.")
        }

        return (traits, disposition)
    }

    /// Default personality traits per template.
    private func defaultTraits(for template: SpiritTemplate) -> [PersonalityTrait] {
        switch template {
        case .warrior:   return [.prideful, .loyal]
        case .scout:     return [.curious, .opportunistic]
        case .guardian:  return [.protective, .territorial]
        case .prophet:   return [.curious, .resentful]
        case .witness:   return [.loyal, .curious]
        case .warden:    return [.territorial, .prideful]
        case .sovereign: return [.prideful, .amusedByBoldness]
        case .shade:     return [.resentful]
        case .butcher:   return [.spiteful, .capricious]
        case .mourner:   return [.protective, .resentful]
        case .artisan:   return [.curious, .prideful]
        case .merchant:  return [.opportunistic, .amusedByBoldness]
        }
    }

    /// Stage 13: Manifestation.
    /// Instantiate the spirit. Apply world-state effects. Begin entropy output.
    /// If an epoch was resolved, the spirit carries the epoch's template, tags, and identity references.
    private func manifestation(
        _ state: inout ResolutionState,
        template: SpiritTemplate,
        attributes: SpiritAttributes,
        traits: [PersonalityTrait],
        disposition: Disposition,
        seed: UInt64
    ) -> RitualResult {
        let config = state.configuration

        // Determine final template and tags — epoch overrides default if resolved
        let finalTemplate: SpiritTemplate
        let finalTags: TagConstellation
        let epochName: String?
        let rootIdentityID: UUID?

        if let epoch = state.resolvedEpoch, let rootID = state.resolvedRootIdentity {
            finalTemplate = epoch.template
            // Merge epoch-specific tags with configuration tags
            finalTags = config.aggregatedTags.merged(with: epoch.epochTags)
            epochName = epoch.name
            rootIdentityID = rootID.id
        } else {
            finalTemplate = template
            finalTags = config.aggregatedTags
            epochName = nil
            rootIdentityID = nil
        }

        // Build the spirit
        let spirit = Spirit(
            template: finalTemplate,
            tier: state.resolvedTier,
            tags: finalTags,
            era: config.dominantEra,
            epochName: epochName,
            rootIdentityID: rootIdentityID,
            personalityTraits: traits,
            disposition: disposition,
            attributes: attributes,
            isMutation: state.isMutation,
            originRitualID: config.id
        )

        // Calculate world effects — every ritual is entropy
        var effects = WorldEffects()
        effects.ghostActivityDelta = 0.05 + Double(state.resolvedTier.rawValue) * 0.02
        effects.corruptionDelta = (config.libation?.corruptionCost ?? 0.01) + (state.isMutation ? 0.1 : 0.0)
        effects.spiritualPressureDelta = 0.03 + Double(state.resolvedTier.rawValue) * 0.015
        effects.suspicionDelta = 0.02
        effects.siteScarring = 0.02 + (state.isMutation ? 0.1 : 0.0)

        // Mutations tear the Veil — permanent cosmological scarring
        if state.isMutation {
            effects.veilDamage = 0.15
            state.autopsyFactors.append("The site will remember this. The stone remembers.")
        }

        return RitualResult(
            spirit: spirit,
            outcomeClass: state.outcomeClass,
            worldEffects: effects,
            autopsy: state.autopsyFactors,
            entropySeed: seed
        )
    }
}
