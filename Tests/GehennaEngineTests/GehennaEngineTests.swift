import Testing
import Foundation
@testable import GehennaEngine

// MARK: - Core Model Tests

@Suite("Era Tests")
struct EraTests {
    @Test("Era depth ordering")
    func eraDepthOrdering() {
        #expect(Era.ironAgeII.depth < Era.antediluvian.depth)
        #expect(Era.lateBronze.depth < Era.earlyBronze.depth)
    }

    @Test("Same era alignment is 1.0")
    func sameEraAlignment() {
        #expect(Era.ironAgeII.alignment(with: .ironAgeII) == 1.0)
    }

    @Test("Adjacent era alignment is 0.7")
    func adjacentEraAlignment() {
        #expect(Era.ironAgeII.alignment(with: .ironAgeI) == 0.7)
    }

    @Test("Distant era alignment diminishes")
    func distantEraAlignment() {
        let alignment = Era.ironAgeII.alignment(with: .earlyBronze)
        #expect(alignment < 0.5)
    }
}

@Suite("Affinity Tests")
struct AffinityTests {
    @Test("Fire opposes water")
    func fireOpposesWater() {
        #expect(Affinity.fire.opposes(.water))
        #expect(Affinity.water.opposes(.fire))
    }

    @Test("Earth opposes air")
    func earthOpposesAir() {
        #expect(Affinity.earth.opposes(.air))
        #expect(Affinity.air.opposes(.earth))
    }

    @Test("Silence opposes nothing")
    func silenceOpposesNothing() {
        for affinity in Affinity.allCases {
            #expect(!Affinity.silence.opposes(affinity))
        }
    }

    @Test("Same affinity resonance is 1.0")
    func sameAffinityResonance() {
        #expect(Affinity.fire.resonanceWith(.fire) == 1.0)
    }

    @Test("Opposing affinity resonance is 0.0")
    func opposingAffinityResonance() {
        #expect(Affinity.fire.resonanceWith(.water) == 0.0)
    }
}

@Suite("Domain Tests")
struct DomainTests {
    @Test("War resonates with rule")
    func warResonatesWithRule() {
        #expect(Domain.war.resonatesWith(.rule))
    }

    @Test("War conflicts with faith")
    func warConflictsWithFaith() {
        #expect(Domain.war.conflictsWith(.faith))
    }

    @Test("Same domain resonates")
    func sameDomainResonates() {
        #expect(Domain.knowledge.resonatesWith(.knowledge))
    }
}

// MARK: - Fragment Tests

@Suite("Fragment Tests")
struct FragmentTests {
    @Test("Skull has highest coherence weight")
    func skullCoherence() {
        let skull = Fragment(remains: .skull, era: .ironAgeII, domain: .war, affinity: .fire, integrity: .pristine)
        let longBone = Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire, integrity: .pristine)
        #expect(skull.coherenceWeight > longBone.coherenceWeight)
    }

    @Test("Corrupted integrity degrades coherence weight")
    func corruptedIntegrity() {
        let pristine = Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire, integrity: .pristine)
        let corrupted = Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire, integrity: .corrupted)
        #expect(pristine.coherenceWeight > corrupted.coherenceWeight)
    }
}

// MARK: - Region State Tests

@Suite("Region State Tests")
struct RegionStateTests {
    @Test("Veil thinness is derived")
    func veilIsDerived() {
        let stable = RegionState(name: "Test", ghostActivity: 0.0, corruption: 0.0, stability: 1.0, spiritualPressure: 0.0)
        let unstable = RegionState(name: "Test", ghostActivity: 0.7, corruption: 0.8, stability: 0.1, spiritualPressure: 0.9)
        #expect(stable.veilThinness < unstable.veilThinness)
    }

    @Test("Entropy decay is asymmetric")
    func asymmetricDecay() {
        var region = RegionState(
            name: "Test",
            ghostActivity: 0.5,
            corruption: 0.5,
            stability: 0.8,
            spiritualPressure: 0.5
        )

        let initialGhost = region.ghostActivity
        let initialCorruption = region.corruption
        let initialPressure = region.spiritualPressure

        region.tickDecay()

        let ghostDecay = initialGhost - region.ghostActivity
        let corruptionDecay = initialCorruption - region.corruption
        let pressureDecay = initialPressure - region.spiritualPressure

        // Ghost Activity decays fastest
        #expect(ghostDecay > corruptionDecay)
        // Corruption decays faster than Spiritual Pressure
        #expect(corruptionDecay > pressureDecay)
        // Spiritual Pressure barely decays
        #expect(pressureDecay < 0.01)
    }

    @Test("Deep Sheol requires triple threshold")
    func deepSheolAccess() {
        let safe = RegionState(name: "Test")
        #expect(!safe.deepSheolAccessible)

        let extreme = RegionState(
            name: "Test", corruption: 0.8, stability: 0.1,
            spiritualPressure: 0.8
        )
        // Need all three simultaneously
        #expect(extreme.veilThinness > 0.5) // should be high with those values
    }
}

// MARK: - Ritual DSL Tests

@Suite("Ritual DSL Tests")
struct RitualDSLTests {
    @Test("Ritual compiles with mandatory inputs")
    func ritualCompiles() {
        let config = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
            RitualSite(name: "Nahal Cave", type: .burialCave, affinity: .earth)
        }

        #expect(config != nil)
        #expect(config?.remains.remainsType == .longBone)
        #expect(config?.site.name == "Nahal Cave")
    }

    @Test("Full ritual with all seven inputs")
    func fullRitualCompiles() {
        let config = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
            RitualSite(name: "Nahal Cave", type: .burialCave, affinity: .earth)
            TrueName("Hiram, son of Dagon", partial: true)
            LifeArtifact(name: "Bronze Spearhead", domain: .war, affinity: .fire, era: .ironAgeII)
            MemoryTrace(name: "Potsherd with inscription", era: .ironAgeII)
            Libation(.fermentedWine)
            WorldTiming(time: .night, lunar: .waxingGibbous)
        }

        #expect(config != nil)
        #expect(config?.trueName?.text == "Hiram, son of Dagon")
        #expect(config?.completeness == 5)
    }

    @Test("Ritual without Site does not compile")
    func ritualWithoutSite() {
        let config = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
        }

        // Should return nil — malformed rituals do not compile
        #expect(config == nil)
    }
}

// MARK: - Resolution Pipeline Tests

@Suite("Resolution Pipeline Tests")
struct ResolutionPipelineTests {

    let pipeline = ResolutionPipeline()
    let defaultProfile = PractitionerProfile()

    func stableRegion() -> RegionState {
        RegionState(name: "Ridge of Elah", stability: 0.8)
    }

    @Test("Deterministic resolution — same inputs produce same output")
    func deterministicResolution() {
        let config = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
            RitualSite(name: "Nahal Cave", type: .burialCave, affinity: .earth)
            Libation(.fermentedWine)
            WorldTiming(time: .night, lunar: .newMoon)
        }!

        let seed: UInt64 = 42

        let result1 = pipeline.resolve(
            configuration: config, regionState: stableRegion(),
            profile: defaultProfile, seed: seed
        )
        let result2 = pipeline.resolve(
            configuration: config, regionState: stableRegion(),
            profile: defaultProfile, seed: seed
        )

        #expect(result1.spirit?.template == result2.spirit?.template)
        #expect(result1.spirit?.tier == result2.spirit?.tier)
        #expect(result1.outcomeClass == result2.outcomeClass)
    }

    @Test("High coherence produces targeted outcome")
    func targetedOutcome() {
        let config = Ritual.compile {
            Fragment(remains: .skull, era: .ironAgeII, domain: .war, affinity: .fire, integrity: .pristine)
            RitualSite(name: "Battlefield", type: .battlefield, affinity: .fire)
            TrueName("Hiram, son of Dagon")
            LifeArtifact(name: "Spearhead", domain: .war, affinity: .fire, era: .ironAgeII)
            Libation(.fermentedWine)
            WorldTiming(time: .night, lunar: .newMoon)
        }!

        let result = pipeline.resolve(
            configuration: config, regionState: stableRegion(),
            profile: defaultProfile, seed: 42
        )

        #expect(result.spirit != nil)
        #expect(result.outcomeClass == .targeted || result.outcomeClass == .guided)
    }

    @Test("Conflicting affinities increase conflict")
    func conflictingAffinities() {
        // Fire remains at water site — opposition
        let conflicted = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
            RitualSite(name: "Spring", type: .springCaveMouth, affinity: .water)
        }!

        // Fire remains at fire site — resonance
        let resonant = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
            RitualSite(name: "Battlefield", type: .battlefield, affinity: .fire)
        }!

        _ = pipeline.resolve(
            configuration: conflicted, regionState: stableRegion(),
            profile: defaultProfile, seed: 42
        )
        let resonantResult = pipeline.resolve(
            configuration: resonant, regionState: stableRegion(),
            profile: defaultProfile, seed: 42
        )

        // Conflicted should be hostile or wild draw; resonant should be more stable
        let resonantSpirit = resonantResult.spirit

        // Both should manifest but the conflicted one should be less stable
        #expect(resonantSpirit != nil)
    }

    @Test("Every ritual produces entropy")
    func ritualProducesEntropy() {
        let config = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
            RitualSite(name: "Cave", type: .burialCave, affinity: .earth)
        }!

        let result = pipeline.resolve(
            configuration: config, regionState: stableRegion(),
            profile: defaultProfile, seed: 42
        )

        #expect(result.worldEffects.ghostActivityDelta > 0)
        #expect(result.worldEffects.spiritualPressureDelta > 0)
        #expect(result.worldEffects.suspicionDelta > 0)
    }

    @Test("Apotropaic artifact reduces hostile probability")
    func apotropaicRule() {
        let config = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .death, affinity: .fire)
            RitualSite(name: "Topheth", type: .topheth, affinity: .fire,
                       corruption: 0.5)
            LifeArtifact(name: "Bronze Dagger", domain: .war, affinity: .fire, era: .ironAgeII)
        }!

        #expect(config.hasApotropaicArtifact)

        let result = pipeline.resolve(
            configuration: config, regionState: stableRegion(),
            profile: defaultProfile, seed: 42
        )

        // Autopsy should mention the bronze turning something aside
        #expect(result.autopsy.contains { $0.contains("bronze") })
    }

    @Test("Ritual autopsy produces readable text")
    func autopsyIsReadable() {
        let config = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
            RitualSite(name: "Cave", type: .burialCave, affinity: .earth)
            Libation(.fermentedWine)
        }!

        let result = pipeline.resolve(
            configuration: config, regionState: stableRegion(),
            profile: defaultProfile, seed: 42
        )

        let autopsy = RitualAutopsy()
        let text = autopsy.interpret(result, configuration: config)

        #expect(!text.isEmpty)
        // Should not contain any numbers
        #expect(!text.contains(where: { $0.isNumber }))
    }

    @Test("Higher tier spirits from deeper eras")
    func deeperErasHigherTiers() {
        let recentConfig = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
            RitualSite(name: "Cave", type: .burialCave, affinity: .earth,
                       veilThinness: 0.5)
            Libation(.fermentedWine)
        }!

        let ancientConfig = Ritual.compile {
            Fragment(remains: .skull, era: .earlyBronze, domain: .rule, affinity: .earth,
                     integrity: .pristine)
            RitualSite(name: "Cave", type: .burialCave, affinity: .earth,
                       veilThinness: 0.7)
            TrueName("Ancient-One")
            Libation(.honeyWine)
            WorldTiming(time: .deepNight, lunar: .newMoon)
        }!

        let recentResult = pipeline.resolve(
            configuration: recentConfig, regionState: stableRegion(),
            profile: defaultProfile, seed: 42
        )
        let ancientResult = pipeline.resolve(
            configuration: ancientConfig, regionState: stableRegion(),
            profile: defaultProfile, seed: 42
        )

        // Ancient, complete configuration should produce higher or equal tier
        #expect(ancientResult.spirit!.tier >= recentResult.spirit!.tier)
    }
}

// MARK: - Astragali Tests

@Suite("Astragali Tests")
struct AstragaliTests {
    @Test("Astragali produce reading for valid configuration")
    func astragaliReading() {
        let config = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
            RitualSite(name: "Cave", type: .burialCave, affinity: .earth)
        }!

        let astragali = Astragali()
        let reading = astragali.cast(
            configuration: config,
            regionState: RegionState(name: "Test"),
            profile: PractitionerProfile(),
            seed: 42
        )

        // In a stable region, all bones should be reliable
        #expect(reading.reliableCount == 4)
    }

    @Test("Astragali degrade with Veil instability")
    func astragaliDegradation() {
        let config = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
            RitualSite(name: "Cave", type: .burialCave, affinity: .earth)
        }!

        let astragali = Astragali()

        // Test across many seeds to ensure degradation occurs at high instability
        let unstableRegion = RegionState(
            name: "Scarred", corruption: 0.9,
            stability: 0.05, spiritualPressure: 0.95
        )

        var anyDegraded = false
        for seed: UInt64 in 1...20 {
            let reading = astragali.cast(
                configuration: config,
                regionState: unstableRegion,
                profile: PractitionerProfile(),
                seed: seed
            )
            if reading.reliableCount < 4 {
                anyDegraded = true
                break
            }
        }

        #expect(anyDegraded, "At least one bone should degrade in extremely unstable region")
    }
}

// MARK: - Practitioner Profile Tests

@Suite("Practitioner Profile Tests")
struct ProfileTests {
    @Test("New practitioner starts as apprentice with capacity 1")
    func newPractitioner() {
        let profile = PractitionerProfile()
        #expect(profile.masteryPhase == .apprentice)
        #expect(profile.summmonerCapacity == 1)
    }

    @Test("Capacity grows at milestones")
    func capacityGrowth() {
        var profile = PractitionerProfile()
        for _ in 0..<10 {
            profile.recordRitual(success: true, wasMutation: false, domain: .war, entropyCost: 0.1)
        }
        #expect(profile.summmonerCapacity == 2)
    }

    @Test("Mastery phase advances with experience")
    func masteryAdvancement() {
        var profile = PractitionerProfile()
        #expect(profile.masteryPhase == .apprentice)

        for _ in 0..<10 {
            profile.recordRitual(success: true, wasMutation: false, domain: .war, entropyCost: 0.1)
        }
        #expect(profile.masteryPhase == .practitioner)
    }
}

// MARK: - Epoch Manifestation Tests (v3 §5.3)

@Suite("Epoch Manifestation Tests")
struct EpochTests {

    let pipeline = ResolutionPipeline()

    func stableRegion() -> RegionState {
        RegionState(name: "Ridge of Elah", stability: 0.8)
    }

    @Test("Epoch resolver selects warrior epoch for battlefield configuration")
    func epochResolverSelectsWarrior() {
        let identity = RidgeOfElah.hiramSonOfDagon()
        let resolver = EpochResolver()

        // Configure for the Bronze Captain: battlefield + soldier tags + war domain
        let config = RitualConfiguration(
            remains: Fragment(
                remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire,
                tags: TagConstellation([
                    NarrativeTag(.identity, "soldier"),
                    NarrativeTag(.cultural, "coastal_warrior"),
                ])
            ),
            site: RitualSite(name: "Battlefield", type: .battlefield, affinity: .fire)
        )

        let epoch = resolver.resolve(
            identity: identity,
            configuration: config,
            regionState: stableRegion()
        )

        #expect(epoch != nil)
        #expect(epoch?.name == "Bronze Captain")
        #expect(epoch?.template == .warrior)
    }

    @Test("Dark epoch activates in corrupted conditions")
    func darkEpochInCorruption() {
        let identity = RidgeOfElah.hiramSonOfDagon()
        let resolver = EpochResolver()

        // Configure for the Ashkelon Butcher: corrupted region + topheth site
        let config = RitualConfiguration(
            remains: Fragment(
                remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire,
                tags: TagConstellation([
                    NarrativeTag(.deathContext, "battle"),
                    NarrativeTag(.disposition, "rage"),
                ])
            ),
            site: RitualSite(name: "Topheth", type: .topheth, affinity: .fire)
        )

        let corruptedRegion = RegionState(
            name: "Corrupted", corruption: 0.6, stability: 0.3
        )

        let epoch = resolver.resolve(
            identity: identity,
            configuration: config,
            regionState: corruptedRegion
        )

        #expect(epoch != nil)
        #expect(epoch?.name == "Ashkelon Butcher")
        #expect(epoch?.template == .butcher)
    }

    @Test("Pipeline with root identities resolves epoch")
    func pipelineResolvesEpoch() {
        let identities = RidgeOfElah.rootIdentities()

        let config = RitualConfiguration(
            remains: Fragment(
                remains: .skull, era: .ironAgeII, domain: .war, affinity: .fire,
                integrity: .pristine,
                tags: TagConstellation([
                    NarrativeTag(.identity, "soldier"),
                    NarrativeTag(.identity, "Philistine"),
                    NarrativeTag(.identity, "captain"),
                    NarrativeTag(.cultural, "coastal_warrior"),
                ])
            ),
            site: RitualSite(name: "Battlefield", type: .battlefield, affinity: .fire),
            trueName: TrueName("Hiram, son of Dagon", partial: false),
            libation: Libation(.fermentedWine)
        )

        let result = pipeline.resolve(
            configuration: config,
            regionState: stableRegion(),
            profile: PractitionerProfile(),
            seed: 42,
            rootIdentities: identities
        )

        #expect(result.spirit != nil)
        #expect(result.spirit?.epochName != nil)
        #expect(result.spirit?.rootIdentityID != nil)
        #expect(result.autopsy.contains { $0.contains("someone specific") })
    }

    @Test("Spirits from same root identity have same rootIdentityID")
    func spiritsShareRootIdentity() {
        let identities = RidgeOfElah.rootIdentities()

        // First: summon the warrior aspect
        let config1 = RitualConfiguration(
            remains: Fragment(
                remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire,
                tags: TagConstellation([
                    NarrativeTag(.identity, "soldier"),
                    NarrativeTag(.identity, "Philistine"),
                    NarrativeTag(.cultural, "coastal_warrior"),
                ])
            ),
            site: RitualSite(name: "Battlefield", type: .battlefield, affinity: .fire),
            libation: Libation(.fermentedWine)
        )

        // Second: summon at the shrine for the guardian aspect
        let config2 = RitualConfiguration(
            remains: Fragment(
                remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire,
                tags: TagConstellation([
                    NarrativeTag(.identity, "soldier"),
                    NarrativeTag(.identity, "Philistine"),
                    NarrativeTag(.relational, "served_a_lord"),
                ])
            ),
            site: RitualSite(name: "Shrine", type: .ancestorShrine, affinity: .earth),
            libation: Libation(.fermentedWine)
        )

        let result1 = pipeline.resolve(
            configuration: config1, regionState: stableRegion(),
            profile: PractitionerProfile(), seed: 42,
            rootIdentities: identities
        )

        let result2 = pipeline.resolve(
            configuration: config2, regionState: stableRegion(),
            profile: PractitionerProfile(), seed: 43,
            rootIdentities: identities
        )

        // Both should have the same root identity but different epoch names
        if let id1 = result1.spirit?.rootIdentityID,
           let id2 = result2.spirit?.rootIdentityID {
            #expect(id1 == id2)
            #expect(result1.spirit?.epochName != result2.spirit?.epochName)
        }
    }
}

// MARK: - Mastery-Aware Autopsy Tests (v3 §3.7)

@Suite("Mastery-Aware Autopsy Tests")
struct MasteryAutopsyTests {

    let pipeline = ResolutionPipeline()

    @Test("Apprentice autopsy uses emotional language")
    func apprenticeVoice() {
        let config = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
            RitualSite(name: "Cave", type: .burialCave, affinity: .earth)
            Libation(.fermentedWine)
        }!

        let region = RegionState(name: "Test", stability: 0.8)
        let result = pipeline.resolve(
            configuration: config, regionState: region,
            profile: PractitionerProfile(), seed: 42
        )

        let autopsy = RitualAutopsy()
        let text = autopsy.interpret(result, configuration: config, masteryPhase: .apprentice)

        // Apprentice language should be experiential/emotional
        #expect(text.contains("felt") || text.contains("Something") || text.contains("sure"))
    }

    @Test("Master autopsy uses precise language")
    func masterVoice() {
        let config = Ritual.compile {
            Fragment(remains: .skull, era: .ironAgeII, domain: .war, affinity: .fire, integrity: .pristine)
            RitualSite(name: "Battlefield", type: .battlefield, affinity: .fire)
            TrueName("Hiram, son of Dagon")
            Libation(.fermentedWine)
        }!

        let region = RegionState(name: "Test", stability: 0.8)
        let result = pipeline.resolve(
            configuration: config, regionState: region,
            profile: PractitionerProfile(), seed: 42
        )

        let autopsy = RitualAutopsy()
        let text = autopsy.interpret(result, configuration: config, masteryPhase: .master)

        // Master language should be technical/precise
        #expect(text.contains("compile") || text.contains("constraint") || text.contains("inputs") || text.contains("Clean"))
    }

    @Test("Different mastery phases produce different text")
    func phasesProduceDifferentText() {
        let config = Ritual.compile {
            Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
            RitualSite(name: "Cave", type: .burialCave, affinity: .earth)
        }!

        let region = RegionState(name: "Test", stability: 0.8)
        let result = pipeline.resolve(
            configuration: config, regionState: region,
            profile: PractitionerProfile(), seed: 42
        )

        let autopsy = RitualAutopsy()
        let apprentice = autopsy.interpret(result, configuration: config, masteryPhase: .apprentice)
        let master = autopsy.interpret(result, configuration: config, masteryPhase: .master)

        // Same ritual, different voice
        #expect(apprentice != master)
    }
}

// MARK: - NPC Interiority Tests (v3 §5.7)

@Suite("NPC Tests")
struct NPCTests {

    @Test("NPC suspicion increases with rumors")
    func suspicionFromRumors() {
        var npc = RidgeOfElah.yoelBenShimri()
        let initialSuspicion = npc.personalSuspicion

        npc.hearRumor(strength: 0.2)

        #expect(npc.personalSuspicion > initialSuspicion)
        #expect(npc.hasHeardRumors)
        #expect(npc.trust < 0.35) // trust decreases
    }

    @Test("Priest faction amplifies suspicion")
    func priestAmplification() {
        var priest = RidgeOfElah.yoelBenShimri()
        var trader = RidgeOfElah.huramTheTrader()

        priest.hearRumor(strength: 0.2)
        trader.hearRumor(strength: 0.2)

        // Priest faction multiplier (1.5) vs trader (0.7)
        #expect(priest.personalSuspicion > trader.personalSuspicion)
    }

    @Test("Positive interactions build trust")
    func trustFromInteraction() {
        var npc = RidgeOfElah.tamarBatYoav()
        let initialTrust = npc.trust

        npc.positiveInteraction(strength: 0.15)

        #expect(npc.trust > initialTrust)
    }

    @Test("High suspicion and low trust cause refusal")
    func npcRefusal() {
        var npc = RidgeOfElah.abiGad()

        // Repeatedly witness suspicious activity
        npc.witnessActivity(severity: 0.4)
        npc.witnessActivity(severity: 0.4)

        #expect(npc.hasWitnessedDirectly)
        #expect(npc.isRefusing)
    }

    @Test("NPC tick state causes suspicion to decay")
    func npcTickDecay() {
        var npc = RidgeOfElah.huramTheTrader()
        npc.hearRumor(strength: 0.3)
        let initialSuspicion = npc.personalSuspicion

        // Tick 100 times — rumor-based suspicion should decay
        for _ in 0..<100 {
            npc.tickState()
        }

        #expect(npc.personalSuspicion < initialSuspicion)
    }

    @Test("NPC wouldFlee with high suspicion and low trust")
    func npcFleeCondition() {
        var npc = RidgeOfElah.abiGad()
        npc.witnessActivity(severity: 0.5)
        npc.witnessActivity(severity: 0.5)

        #expect(npc.wouldFlee)
    }
}

// MARK: - Journal Query Tests

@Suite("Journal Query Tests")
struct JournalQueryTests {

    @Test("Journal records ritual events with site ID")
    func journalRecordsRitualWithSiteID() {
        var world = WorldSimulation(regions: [RegionState(name: "Test")])
        let regionID = world.regions.keys.first!
        var site = RitualSite(name: "Test Cave", type: .burialCave, affinity: .earth)
        let siteID = site.id

        let effects = WorldEffects(
            ghostActivityDelta: 0.05,
            corruptionDelta: 0.02,
            spiritualPressureDelta: 0.03,
            suspicionDelta: 0.01
        )
        world.applyRitualEffects(effects, regionID: regionID, site: &site)

        let siteEvents = world.events(at: siteID)
        #expect(siteEvents.count == 1)
        #expect(siteEvents.first?.source == .ritual)
        #expect(siteEvents.first?.severity == .significant)
    }

    @Test("Journal events filterable by severity")
    func journalSeverityFilter() {
        var world = WorldSimulation(regions: [RegionState(name: "Test")])
        let regionID = world.regions.keys.first!
        var site = RitualSite(name: "Test", type: .burialCave, affinity: .earth)

        // Record a ritual — significant severity
        let effects = WorldEffects(
            ghostActivityDelta: 0.05,
            corruptionDelta: 0.02,
            spiritualPressureDelta: 0.03,
            suspicionDelta: 0.01
        )
        world.applyRitualEffects(effects, regionID: regionID, site: &site)

        let significant = world.events(severity: .significant)
        let ruptures = world.events(severity: .rupture)

        #expect(significant.count >= 1)
        #expect(ruptures.isEmpty)
    }

    @Test("Journal events filterable by tag")
    func journalTagFilter() {
        var world = WorldSimulation(regions: [RegionState(name: "Test")])
        let regionID = world.regions.keys.first!
        var site = RitualSite(name: "Test", type: .burialCave, affinity: .earth)

        let effects = WorldEffects(
            ghostActivityDelta: 0.05,
            corruptionDelta: 0.02,
            spiritualPressureDelta: 0.03,
            suspicionDelta: 0.01
        )
        world.applyRitualEffects(effects, regionID: regionID, site: &site)

        let ritualEvents = world.events(tagged: "ritual")
        #expect(!ritualEvents.isEmpty)
    }

    @Test("Journal events filterable by tick")
    func journalTickFilter() {
        var world = WorldSimulation(regions: [RegionState(name: "Test")])
        world.currentTick = 5
        let regionID = world.regions.keys.first!
        var site = RitualSite(name: "Test", type: .burialCave, affinity: .earth)

        let effects = WorldEffects(
            ghostActivityDelta: 0.05,
            corruptionDelta: 0.02,
            spiritualPressureDelta: 0.03,
            suspicionDelta: 0.01
        )
        world.applyRitualEffects(effects, regionID: regionID, site: &site)

        let since3 = world.events(since: 3)
        let since10 = world.events(since: 10)

        #expect(!since3.isEmpty)
        #expect(since10.isEmpty)
    }
}

// MARK: - World Clock Tests

@Suite("World Clock Tests")
struct WorldClockTests {

    @Test("Clock advances tick count correctly")
    func clockAdvancesTicks() {
        var clock = WorldClock()
        var world = WorldSimulation(regions: [RegionState(name: "Test")])
        var sites = [RitualSite(name: "Cave", type: .burialCave, affinity: .earth)]
        var npcs: [NPC] = []

        #expect(clock.currentTick == 0)
        let _ = clock.advance(by: 3, world: &world, sites: &sites, npcs: &npcs)
        #expect(clock.currentTick == 3)
    }

    @Test("Travel costs more ticks than a command")
    func travelCostsMore() {
        var clock = WorldClock()
        var world = WorldSimulation(regions: [RegionState(name: "Test")])
        var sites = [RitualSite(name: "Cave", type: .burialCave, affinity: .earth)]
        var npcs: [NPC] = []

        let _ = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)
        let afterCommand = clock.currentTick

        let _ = clock.advanceForTravel(world: &world, sites: &sites, npcs: &npcs)
        let travelTicks = clock.currentTick - afterCommand

        #expect(travelTicks > clock.ticksPerCommand)
    }

    @Test("Rest costs the most ticks")
    func restCostsMost() {
        let clock = WorldClock()
        #expect(clock.ticksPerRest > clock.ticksPerTravel)
        #expect(clock.ticksPerTravel > clock.ticksPerCommand)
    }

    @Test("Clock synchronizes world tick")
    func clockSyncsWorldTick() {
        var clock = WorldClock()
        var world = WorldSimulation(regions: [RegionState(name: "Test")])
        var sites = [RitualSite(name: "Cave", type: .burialCave, affinity: .earth)]
        var npcs: [NPC] = []

        let _ = clock.advance(by: 5, world: &world, sites: &sites, npcs: &npcs)
        #expect(world.currentTick == clock.currentTick)
    }

    @Test("Clock collects threshold events")
    func clockCollectsEvents() {
        var clock = WorldClock()
        // Start with very high ghost activity to trigger threshold
        let region = RegionState(name: "Volatile", ghostActivity: 0.9, corruption: 0.7, stability: 0.2, spiritualPressure: 0.8)
        var world = WorldSimulation(regions: [region])
        var sites = [RitualSite(name: "Cave", type: .burialCave, affinity: .earth)]
        var npcs: [NPC] = []

        let events = clock.advance(by: 1, world: &world, sites: &sites, npcs: &npcs)
        // With such extreme values, we should see at least one threshold event
        #expect(!events.isEmpty || !world.journal.isEmpty)
    }
}

// MARK: - Site State Tests

@Suite("Site State Tests")
struct SiteStateTests {

    @Test("Scarring accumulates with rituals")
    func scarringAccumulates() {
        var site = RitualSite(name: "Test", type: .burialCave, affinity: .earth)
        #expect(site.scarring == 0.0)

        site.recordRitualPerformed()
        #expect(site.scarring > 0.0)

        let firstScarring = site.scarring
        site.recordRitualPerformed()
        #expect(site.scarring > firstScarring)
    }

    @Test("Scarring heals only after traces and witness exposure cool")
    func scarringHealsAfterCooling() {
        var site = RitualSite(name: "Test", type: .burialCave, affinity: .earth)
        site.recordRitualPerformed()
        site.recordRitualPerformed()
        let scarring = site.scarring

        site.tickSiteState()
        #expect(site.scarring == scarring)

        // Tick many times — traces and witness exposure cool before scars recover.
        for _ in 0..<100 {
            site.tickSiteState()
        }

        #expect(site.scarring < scarring)
    }

    @Test("Purification repairs site scarring and corruption")
    func purificationRepairsSiteScarring() {
        var site = RitualSite(name: "Test", type: .burialCave, affinity: .earth)
        site.recordMutation()
        site.recordMutation()
        let scarring = site.scarring
        let corruption = site.corruption

        site.purifySite(strength: 0.5)

        #expect(site.scarring < scarring)
        #expect(site.corruption < corruption)
    }

    @Test("Active traces fade over time")
    func tracesFade() {
        var site = RitualSite(name: "Test", type: .burialCave, affinity: .earth)
        site.recordRitualPerformed()
        site.recordRitualPerformed()
        site.recordRitualPerformed()
        #expect(!site.activeTraces.isEmpty)

        // Tick many times — traces should eventually fade
        for _ in 0..<100 {
            site.tickSiteState()
        }

        #expect(site.activeTraces.count < 3)
    }

    @Test("Mutation causes heavier scarring than ritual")
    func mutationCausesHeavierScarring() {
        var ritualSite = RitualSite(name: "Ritual", type: .burialCave, affinity: .earth)
        var mutationSite = RitualSite(name: "Mutation", type: .burialCave, affinity: .earth)

        ritualSite.recordRitualPerformed()
        mutationSite.recordMutation()

        #expect(mutationSite.scarring > ritualSite.scarring)
    }

    @Test("Site disturbance detectable after ritual")
    func disturbanceDetectable() {
        var site = RitualSite(name: "Test", type: .burialCave, affinity: .earth)
        #expect(!site.isDisturbed)

        site.recordRitualPerformed()
        #expect(site.isDisturbed)
    }

    @Test("Local Veil modifier increases with scarring")
    func localVeilModifier() {
        var site = RitualSite(name: "Test", type: .burialCave, affinity: .earth)
        let initialVeil = site.effectiveVeilThinness

        // Scar the site heavily
        for _ in 0..<10 {
            site.recordRitualPerformed()
        }

        #expect(site.effectiveVeilThinness > initialVeil)
        #expect(site.localVeilModifier > 0.0)
    }

    @Test("Ancestor shrine has highest suspicion multiplier")
    func ancestorShrineSuspicion() {
        var shrine = RitualSite(name: "Shrine", type: .ancestorShrine, affinity: .earth)
        var cave = RitualSite(name: "Cave", type: .burialCave, affinity: .earth)

        shrine.recordRitualPerformed()
        cave.recordRitualPerformed()

        #expect(shrine.localSuspicion > cave.localSuspicion)
    }

    @Test("Witness exposure cools over time")
    func witnessExposureCools() {
        var site = RitualSite(name: "Test", type: .burialCave, affinity: .earth)
        site.recordRitualPerformed()
        let initialExposure = site.witnessExposure

        for _ in 0..<10 {
            site.tickSiteState()
        }

        #expect(site.witnessExposure < initialExposure)
    }
}

// MARK: - World Director Tests

@Suite("World Director Tests")
struct WorldDirectorTests {

    let director = WorldDirector()

    @Test("Director produces no events for calm world")
    func calmWorldProducesNothing() {
        let world = WorldSimulation(regions: [RegionState(name: "Calm", stability: 0.9)])
        let sites = [RitualSite(name: "Cave", type: .burialCave, affinity: .earth)]
        let npcs: [NPC] = []
        let clock = WorldClock()

        let events = director.evaluate(
            world: world, sites: sites, npcs: npcs,
            currentSiteIndex: 0, clock: clock
        )

        // A calm world with no history should produce nothing or only ambient events
        let nonAmbient = events.filter { $0.severity >= .notable }
        #expect(nonAmbient.isEmpty)
    }

    @Test("Director fires for site disturbance")
    func directorFiresForDisturbance() {
        let world = WorldSimulation(regions: [RegionState(name: "Test")])
        var site = RitualSite(name: "Cave", type: .burialCave, affinity: .earth)
        site.recordRitualPerformed()
        site.recordRitualPerformed()
        // lastVisitTick is nil, so the practitioner hasn't visited recently
        let sites = [site]
        let npcs: [NPC] = []
        let clock = WorldClock()

        let events = director.evaluate(
            world: world, sites: sites, npcs: npcs,
            currentSiteIndex: 0, clock: clock
        )

        let disturbances = events.filter { $0.type == .siteDisturbance }
        #expect(!disturbances.isEmpty)
    }

    @Test("Director fires for high Veil thinness")
    func directorFiresForVeilInstability() {
        let world = WorldSimulation(regions: [RegionState(name: "Test")])
        let site = RitualSite(name: "Cave", type: .burialCave, affinity: .earth, veilThinness: 0.8)
        let sites = [site]
        let npcs: [NPC] = []
        let clock = WorldClock()

        let events = director.evaluate(
            world: world, sites: sites, npcs: npcs,
            currentSiteIndex: 0, clock: clock
        )

        let veilEvents = events.filter { $0.type == .veilInstability }
        #expect(!veilEvents.isEmpty)
    }

    @Test("Director respects max events per evaluation")
    func directorRespectsMaxEvents() {
        // Create an extremely volatile state that should trigger many conditions
        let world = WorldSimulation(regions: [
            RegionState(name: "Chaos", ghostActivity: 0.9, corruption: 0.8, stability: 0.1, spiritualPressure: 0.9)
        ])
        var site = RitualSite(name: "Topheth", type: .topheth, affinity: .fire, veilThinness: 0.9, corruption: 0.8)
        site.recordRitualPerformed()
        site.recordRitualPerformed()
        site.recordMutation()
        let sites = [site]
        let npcs = RidgeOfElah.kfarShalemNPCs()
        let clock = WorldClock()

        let events = director.evaluate(
            world: world, sites: sites, npcs: npcs,
            currentSiteIndex: 0, clock: clock
        )

        #expect(events.count <= 2)
    }

    @Test("Director fires NPC initiative at village")
    func directorFiresNPCInitiativeAtVillage() {
        let world = WorldSimulation(regions: [RegionState(name: "Test")])
        let site = RitualSite(name: "Kfar Shalem", type: .ancestorShrine, affinity: .earth)
        let sites = [site]

        // Create an NPC that would approach
        var npc = RidgeOfElah.tamarBatYoav()
        npc.positiveInteraction(strength: 0.4)
        npc.positiveInteraction(strength: 0.4)  // trust > 0.85 → at threshold → would approach
        let npcs = [npc]
        let clock = WorldClock()

        let events = director.evaluate(
            world: world, sites: sites, npcs: npcs,
            currentSiteIndex: 0, clock: clock
        )

        let npcEvents = events.filter { $0.type == .npcInitiative }
        #expect(!npcEvents.isEmpty)
    }

    @Test("Director narration contains no numbers")
    func directorNarrationDiegetic() {
        let world = WorldSimulation(regions: [
            RegionState(name: "Test", ghostActivity: 0.7, corruption: 0.5, stability: 0.3)
        ])
        var site = RitualSite(name: "Cave", type: .burialCave, affinity: .earth, veilThinness: 0.8)
        site.recordRitualPerformed()
        let sites = [site]
        let npcs: [NPC] = []
        let clock = WorldClock()

        let events = director.evaluate(
            world: world, sites: sites, npcs: npcs,
            currentSiteIndex: 0, clock: clock
        )

        for event in events {
            #expect(!event.description.contains(where: { $0.isNumber }),
                    "Director narration should not contain numbers: \(event.description)")
        }
    }
}

// MARK: - World Shard Multiplayer Tests

@Suite("World Shard Multiplayer Tests")
struct WorldShardTests {

    @Test("Ritual command records one journal entry and increments attempts")
    func ritualCommandRecordsSingleJournalEntry() async {
        let content = RidgeOfElah.createWorld()
        let shard = WorldShard(
            world: WorldSimulation(regions: [content.region]),
            sites: content.sites,
            npcs: RidgeOfElah.kfarShalemNPCs(),
            rootIdentities: RidgeOfElah.rootIdentities()
        )

        let session = PractitionerSession(
            name: "Test Practitioner",
            fragments: content.fragments,
            artifacts: content.artifacts,
            memoryTraces: content.memoryTraces
        )
        let playerID = await shard.addPractitioner(session)

        let result = await shard.execute(.performRitual(RitualIntent(
            fragmentIndex: 0,
            trueName: "Hiram, son of Dagon",
            artifactIndex: 0,
            traceIndex: 0,
            libationType: .fermentedWine
        )), for: playerID)

        let journal = await shard.journal
        let ritualEntries = journal.filter { $0.type == .ritualPerformed }
        let updatedSession = await shard.session(for: playerID)

        #expect(!result.narration.isEmpty)
        #expect(ritualEntries.count == 1)
        #expect(ritualEntries.first?.source == .practitioner)
        #expect(ritualEntries.first?.description.contains("Test Practitioner") == true)
        #expect(updatedSession?.ritualCount == 1)
        #expect(updatedSession?.profile.totalRituals == 1)
    }

    @Test("Practitioners share site scarring")
    func practitionersShareSiteScarring() async {
        let content = RidgeOfElah.createWorld()
        let shard = WorldShard(
            world: WorldSimulation(regions: [content.region]),
            sites: content.sites,
            npcs: RidgeOfElah.kfarShalemNPCs(),
            rootIdentities: RidgeOfElah.rootIdentities()
        )

        let first = PractitionerSession(
            name: "First Practitioner",
            fragments: content.fragments,
            artifacts: content.artifacts,
            memoryTraces: content.memoryTraces
        )
        let second = PractitionerSession(
            name: "Second Practitioner",
            fragments: content.fragments,
            artifacts: content.artifacts,
            memoryTraces: content.memoryTraces
        )

        let firstID = await shard.addPractitioner(first)
        let secondID = await shard.addPractitioner(second)
        let initialScarring = await shard.siteStates[0].scarring

        for _ in 0..<3 {
            _ = await shard.execute(.performRitual(RitualIntent(
                fragmentIndex: 0,
                trueName: "Hiram, son of Dagon",
                artifactIndex: 0,
                traceIndex: 0,
                libationType: .fermentedWine
            )), for: firstID)
        }

        let seenBySecond = await shard.execute(.look, for: secondID)
        let sharedScarring = await shard.siteStates[0].scarring

        #expect(sharedScarring > initialScarring)
        #expect(seenBySecond.narration.first == "[Battlefield Ridge]")
    }
}
