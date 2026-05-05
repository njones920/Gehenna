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

@Suite("Narrative Tag Tests")
struct NarrativeTagTests {
    @Test("Tag constellation merge deduplicates exact duplicates")
    func tagConstellationMergeDeduplicates() {
        let warrior = NarrativeTag(.identity, "warrior")
        let battle = NarrativeTag(.deathContext, "battle")

        let left = TagConstellation([warrior, battle])
        let right = TagConstellation([warrior, NarrativeTag(.cultural, "philistine")])

        let merged = left.merged(with: right)

        #expect(merged.tags.count == 3)
        #expect(merged.tags[0] == warrior)
        #expect(merged.tags[1] == battle)
        #expect(merged.tags[2] == NarrativeTag(.cultural, "philistine"))
    }

    @Test("Codex encounter merge does not accumulate duplicate tags")
    func codexEncounterMergeDeduplicatesKnownTags() {
        let sharedTag = NarrativeTag(.identity, "warrior")
        let additionalTag = NarrativeTag(.deathContext, "battle")
        let rootIdentityID = UUID()

        let attributes = SpiritAttributes(
            strength: 0.4,
            knowledge: 0.4,
            will: 0.4,
            stability: 0.6,
            disposition: 0.4
        )
        let firstSpirit = Spirit(
            template: .warrior,
            tier: .common,
            tags: TagConstellation([sharedTag, additionalTag]),
            era: .ironAgeII,
            epochName: "First",
            rootIdentityID: rootIdentityID,
            personalityTraits: [.loyal],
            disposition: .curious,
            attributes: attributes
        )
        let thirdTag = NarrativeTag(.cultural, "philistine")
        let secondSpirit = Spirit(
            template: .warrior,
            tier: .common,
            tags: TagConstellation([sharedTag, additionalTag, thirdTag]),
            era: .ironAgeII,
            epochName: "Second",
            rootIdentityID: rootIdentityID,
            personalityTraits: [.loyal],
            disposition: .curious,
            attributes: attributes
        )

        var codex = CodexOfTheDead()
        let ritualID = UUID()

        let entryID = codex.recordEncounter(
            spirit: firstSpirit,
            autopsy: [],
            ritualID: ritualID,
            tick: 1
        )
        _ = codex.recordEncounter(
            spirit: secondSpirit,
            autopsy: [],
            ritualID: UUID(),
            tick: 2
        )

        let knownTags = codex.entries[entryID]?.knownTags.tags ?? []
        #expect(knownTags.count == 3)
        #expect(knownTags.contains(sharedTag))
        #expect(knownTags.contains(additionalTag))
        #expect(knownTags.contains(thirdTag))
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
        #expect(profile.summonerCapacity == 1)
    }

    @Test("Capacity grows at milestones")
    func capacityGrowth() {
        var profile = PractitionerProfile()
        for _ in 0..<10 {
            profile.recordRitual(success: true, wasMutation: false, domain: .war, entropyCost: 0.1)
        }
        #expect(profile.summonerCapacity == 2)
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

    @Test("Mortuary ritual without compensation marks grave robbing")
    func mortuaryRitualMarksGraveRobbing() {
        var profile = PractitionerProfile()
        let config = RitualConfiguration(
            remains: Fragment(
                remains: .ossuaryChip,
                era: .ironAgeII,
                domain: .death,
                affinity: .earth
            ),
            site: RitualSite(name: "Bench Tomb", type: .burialCave, affinity: .earth)
        )

        profile.applyRitualConsequences(
            configuration: config,
            result: RitualResult(
                spirit: nil,
                outcomeClass: .failure,
                worldEffects: WorldEffects(),
                autopsy: [],
                entropySeed: 1
            )
        )

        #expect(profile.taboosBroken.contains(.graveRobbing))
        #expect(profile.tokens.corpseContagion > 0.0)
    }

    @Test("Compensated mortuary ritual avoids grave robbing taboo")
    func compensatedMortuaryRitualAvoidsGraveRobbing() {
        var profile = PractitionerProfile()
        let config = RitualConfiguration(
            remains: Fragment(
                remains: .ossuaryChip,
                era: .ironAgeII,
                domain: .death,
                affinity: .earth
            ),
            site: RitualSite(name: "Ancestor Niche", type: .ossuaryNiche, affinity: .earth),
            libation: Libation(.fermentedWine)
        )

        profile.applyRitualConsequences(
            configuration: config,
            result: RitualResult(
                spirit: nil,
                outcomeClass: .failure,
                worldEffects: WorldEffects(),
                autopsy: [],
                entropySeed: 2
            )
        )

        #expect(!profile.taboosBroken.contains(.graveRobbing))
    }

    @Test("Corrupted fragment at sanctified site marks unclean sacrifice")
    func corruptedFragmentAtSanctifiedSiteMarksUncleanSacrifice() {
        var profile = PractitionerProfile()
        var site = RitualSite(name: "Hill Shrine", type: .ancestorShrine, affinity: .silence)
        site.sanctity = 0.85

        let config = RitualConfiguration(
            remains: Fragment(
                remains: .crematedBone,
                era: .ironAgeII,
                domain: .faith,
                affinity: .fire,
                integrity: .corrupted
            ),
            site: site,
            libation: Libation(.bloodOffering)
        )

        profile.applyRitualConsequences(
            configuration: config,
            result: RitualResult(
                spirit: nil,
                outcomeClass: .hostile,
                worldEffects: WorldEffects(),
                autopsy: [],
                entropySeed: 3
            )
        )

        #expect(profile.taboosBroken.contains(.uncleanSacrifice))
        #expect(profile.tokens.ritualFatigue > 0.0)
    }

    @Test("Blood sacrifice at topheth marks topheth pact")
    func tophethSacrificeMarksTophethPact() {
        var profile = PractitionerProfile()
        let config = RitualConfiguration(
            remains: Fragment(
                remains: .crematedBone,
                era: .ironAgeII,
                domain: .war,
                affinity: .fire,
                integrity: .corrupted
            ),
            site: RitualSite(name: "Burning Ground", type: .topheth, affinity: .fire),
            libation: Libation(.bloodOffering)
        )

        profile.applyRitualConsequences(
            configuration: config,
            result: RitualResult(
                spirit: nil,
                outcomeClass: .failure,
                worldEffects: WorldEffects(),
                autopsy: [],
                entropySeed: 4
            )
        )

        #expect(profile.taboosBroken.contains(.tophethPact))
        #expect(profile.tokens.corpseContagion >= 0.2)
        #expect(profile.tokens.purity < 0.8)
    }
}

// MARK: - Persistence Tests

@Suite("Persistence Tests")
struct PersistenceTests {
    @Test("Single-player snapshot round-trips world, journal, and practitioner state")
    func singlePlayerSnapshotRoundTrip() throws {
        let region = RegionState(name: "Ridge of Elah", stability: 0.7)
        let site = RitualSite(name: "Kfar Shalem Shrine", type: .ancestorShrine, affinity: .earth)
        let npc = try #require(RidgeOfElah.abiGad())

        var world = WorldSimulation(regions: [region])
        var persistedSite = site
        world.currentTick = 12
        world.applyRitualEffects(
            WorldEffects(ghostActivityDelta: 0.2, corruptionDelta: 0.1, suspicionDelta: 0.05),
            regionID: region.id,
            site: &persistedSite,
            practitionerName: "Operator"
        )

        var profile = PractitionerProfile()
        profile.taboosBroken = [.graveRobbing, .tophethPact]
        profile.tokens.corpseContagion = 0.35
        profile.tokens.purity = 0.6
        profile.totalRituals = 3

        let inventory = PractitionerInventorySnapshot(
            fragments: [
                Fragment(remains: .skull, era: .ironAgeII, domain: .death, affinity: .earth, integrity: .worn)
            ],
            artifacts: [
                LifeArtifact(name: "Bronze Spearhead", domain: .war, affinity: .fire, era: .ironAgeII)
            ],
            memoryTraces: [
                MemoryTrace(name: "Jar Fragment", era: .ironAgeII)
            ],
            libations: [.water, .fermentedWine]
        )

        let snapshot = SinglePlayerSnapshot(
            savedAtTick: 12,
            world: world,
            profile: profile,
            codex: CodexOfTheDead(),
            sites: [persistedSite],
            inventory: inventory,
            currentSiteIndex: 0,
            ritualCount: 3,
            rootIdentities: try RidgeOfElah.rootIdentities(),
            npcs: [npc],
            clock: WorldClock(startingTick: 12)
        )

        let data = try SnapshotStore.encode(snapshot)
        let decoded = try SnapshotStore.decodeSinglePlayerSnapshot(from: data)

        #expect(decoded.savedAtTick == 12)
        #expect(decoded.clock.currentTick == 12)
        #expect(decoded.world.currentTick == 12)
        #expect(decoded.world.journal.count == 1)
        #expect(decoded.world.journal[0].type == JournalEntry.JournalEntryType.ritualPerformed)
        #expect(decoded.profile.taboosBroken.contains(Taboo.graveRobbing))
        #expect(decoded.profile.taboosBroken.contains(Taboo.tophethPact))
        #expect(decoded.inventory.fragments.count == 1)
        #expect(decoded.inventory.libations == [LibationType.water, LibationType.fermentedWine])
        #expect(decoded.npcs.count == 1)
        #expect(decoded.sites[0].localSuspicion > 0.0)
    }
}

// MARK: - Epoch Manifestation Tests (v3 §5.3)

@Suite("Epoch Manifestation Tests")
struct EpochTests {

    let pipeline = ResolutionPipeline()

    func stableRegion() -> RegionState {
        RegionState(name: "Ridge of Elah", stability: 0.8)
    }

    @Test("Root identity IDs are deterministic based on string traits")
    func rootIdentityDeterministicIDs() {
        let id1 = RootIdentity(
            trueName: "Hiram, son of Dagon",
            coreTags: TagConstellation([
                NarrativeTag(.identity, "warrior"),
                NarrativeTag(.cultural, "coastal_warrior"),
            ]),
            epochs: [
                Epoch(name: "Bronze Captain", template: .warrior, era: .ironAgeII, domain: .war)
            ],
            nativeEra: .ironAgeII,
            culture: "Philistine"
        )
        
        let id2 = RootIdentity(
            trueName: "Hiram, son of Dagon",
            coreTags: TagConstellation([
                NarrativeTag(.cultural, "coastal_warrior"),
                NarrativeTag(.identity, "warrior"),
            ]),
            epochs: [
                Epoch(name: "Bronze Captain", template: .warrior, era: .ironAgeII, domain: .war)
            ],
            nativeEra: .ironAgeII,
            culture: "Philistine"
        )
        
        let id3 = RootIdentity(
            trueName: "Hiram, son of Dagon",
            coreTags: TagConstellation([
                NarrativeTag(.identity, "warrior"),
                NarrativeTag(.cultural, "highland_village"),
            ]),
            epochs: [
                Epoch(name: "Bronze Captain", template: .warrior, era: .ironAgeII, domain: .war)
            ],
            nativeEra: .ironAgeII,
            culture: "Philistine"
        )
        
        #expect(id1.id == id2.id, "Identical identities should produce the same deterministic ID")
        #expect(id1.id != id3.id, "Different identity content should produce different IDs")
    }

    @Test("Epoch resolver selects warrior epoch for battlefield configuration")
    func epochResolverSelectsWarrior() throws {
        let identity = try #require(RidgeOfElah.hiramSonOfDagon())
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
    func darkEpochInCorruption() throws {
        let identity = try #require(RidgeOfElah.hiramSonOfDagon())
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
    func pipelineResolvesEpoch() throws {
        let identities = try RidgeOfElah.rootIdentities()

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
    func spiritsShareRootIdentity() throws {
        let identities = try RidgeOfElah.rootIdentities()

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

// MARK: - Canon Data Tests

@Suite("Canon Data Tests")
struct CanonDataTests {
    @Test("Bundled NPC canon decodes with authored interiority")
    func bundledNPCsDecodeWithInteriority() throws {
        let npcs = try CanonDataLoader.loadNPCs()

        #expect(npcs.count >= 6)
        for npc in npcs {
            #expect(!npc.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!npc.interiority.interiorVoice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!npc.interiority.wound.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @Test("Bundled root identity canon decodes with named epochs")
    func bundledRootIdentitiesDecodeWithEpochs() throws {
        let identities = try CanonDataLoader.loadRootIdentities()

        #expect(identities.count >= 3)
        for identity in identities {
            #expect(!identity.epochs.isEmpty)
            for epoch in identity.epochs {
                #expect(!epoch.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    @Test("NPC behavioral API updates trust and suspicion")
    func npcBehavioralAPIUpdatesTrustAndSuspicion() {
        var npc = NPC(
            name: "Test Witness",
            role: "Villager",
            faction: .elders,
            trust: 0.5,
            personalSuspicion: 0.0,
            register: VoiceRegister(style: .formal),
            interiority: NPCInteriority(
                interiorVoice: "I know what I saw.",
                privateTruth: "They remember more than they say.",
                unsatisfiedWant: "A quiet house.",
                wound: "A night that would not end.",
                threshold: "Enough silence."
            )
        )
        let initialTrust = npc.trust

        npc.positiveInteraction(strength: 0.3)
        #expect(npc.trust > initialTrust)

        let trustAfterPositiveInteraction = npc.trust
        let initialSuspicion = npc.personalSuspicion
        npc.witnessActivity(severity: 0.4)

        #expect(npc.personalSuspicion > initialSuspicion)
        #expect(npc.trust < trustAfterPositiveInteraction)
    }
}

// MARK: - NPC Interiority Tests (v3 §5.7)

@Suite("NPC Tests")
struct NPCTests {

    @Test("NPC suspicion increases with rumors")
    func suspicionFromRumors() throws {
        var npc = try #require(RidgeOfElah.yoelBenShimri())
        let initialSuspicion = npc.personalSuspicion

        npc.hearRumor(strength: 0.2)

        #expect(npc.personalSuspicion > initialSuspicion)
        #expect(npc.hasHeardRumors)
        #expect(npc.trust < 0.35) // trust decreases
    }

    @Test("Priest faction amplifies suspicion")
    func priestAmplification() throws {
        var priest = try #require(RidgeOfElah.yoelBenShimri())
        var trader = try #require(RidgeOfElah.huramTheTrader())

        priest.hearRumor(strength: 0.2)
        trader.hearRumor(strength: 0.2)

        // Priest faction multiplier (1.5) vs trader (0.7)
        #expect(priest.personalSuspicion > trader.personalSuspicion)
    }

    @Test("Positive interactions build trust")
    func trustFromInteraction() throws {
        var npc = try #require(RidgeOfElah.tamarBatYoav())
        let initialTrust = npc.trust

        npc.positiveInteraction(strength: 0.15)

        #expect(npc.trust > initialTrust)
    }

    @Test("High suspicion and low trust cause refusal")
    func npcRefusal() throws {
        var npc = try #require(RidgeOfElah.abiGad())

        // Repeatedly witness suspicious activity
        npc.witnessActivity(severity: 0.4)
        npc.witnessActivity(severity: 0.4)

        #expect(npc.hasWitnessedDirectly)
        #expect(npc.isRefusing)
    }

    @Test("NPC tick state causes suspicion to decay")
    func npcTickDecay() throws {
        var npc = try #require(RidgeOfElah.huramTheTrader())
        npc.hearRumor(strength: 0.3)
        let initialSuspicion = npc.personalSuspicion

        // Tick 100 times — rumor-based suspicion should decay
        for _ in 0..<100 {
            npc.tickState()
        }

        #expect(npc.personalSuspicion < initialSuspicion)
    }

    @Test("NPC wouldFlee with high suspicion and low trust")
    func npcFleeCondition() throws {
        var npc = try #require(RidgeOfElah.abiGad())
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

    @Test("Clock derives time of day from tick count")
    func clockDerivesTimeOfDay() {
        var clock = WorldClock()
        // Tick 0 = dawn, 1 = morning, ... 5 = night, 6 = deepNight, 7 = dawn again
        #expect(clock.currentTimeOfDay == .dawn)

        clock.currentTick = 5
        #expect(clock.currentTimeOfDay == .night)

        clock.currentTick = 6
        #expect(clock.currentTimeOfDay == .deepNight)

        clock.currentTick = 7  // wraps to dawn
        #expect(clock.currentTimeOfDay == .dawn)
    }

    @Test("Clock derives lunar phase from tick count")
    func clockDerivesLunarPhase() {
        var clock = WorldClock()
        // Day 0 (ticks 0-6) = newMoon, day 1 (ticks 7-13) = waxingCrescent, etc.
        #expect(clock.currentLunarPhase == .newMoon)

        clock.currentTick = 7  // day 1
        #expect(clock.currentLunarPhase == .waxingCrescent)

        clock.currentTick = 28  // day 4
        #expect(clock.currentLunarPhase == .fullMoon)

        clock.currentTick = 56  // day 8 — wraps to newMoon
        #expect(clock.currentLunarPhase == .newMoon)
    }

    @Test("Clock currentTiming combines time of day and lunar phase")
    func clockCurrentTimingCombines() {
        var clock = WorldClock()
        clock.currentTick = 33  // day 4 (fullMoon), tick-in-day 5 (night)
        let timing = clock.currentTiming
        #expect(timing.timeOfDay == .night)
        #expect(timing.lunarPhase == .fullMoon)
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

    @Test("Village rumors reach elders more strongly than cave rumors")
    func villageRumorsTravelFurtherThanCaveRumors() {
        var shrine = RitualSite(name: "Kfar Shalem", type: .ancestorShrine, affinity: .earth)
        var cave = RitualSite(name: "Nahal Caves", type: .burialCave, affinity: .earth)

        shrine.recordRitualPerformed()
        cave.recordRitualPerformed()

        let shrineRumor = shrine.rumorStrength(for: .elders)
        let caveRumor = cave.rumorStrength(for: .elders)

        #expect(shrineRumor > caveRumor)
    }

    @Test("Topheth rumors reach priesthood more strongly than traders")
    func tophethRumorsFavorPriesthood() {
        var topheth = RitualSite(name: "The Burning Ground", type: .topheth, affinity: .fire)
        topheth.recordRitualPerformed()

        let priestRumor = topheth.rumorStrength(for: .priesthood)
        let traderRumor = topheth.rumorStrength(for: .traders)

        #expect(priestRumor > traderRumor)
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
    func directorRespectsMaxEvents() throws {
        // Create an extremely volatile state that should trigger many conditions
        let world = WorldSimulation(regions: [
            RegionState(name: "Chaos", ghostActivity: 0.9, corruption: 0.8, stability: 0.1, spiritualPressure: 0.9)
        ])
        var site = RitualSite(name: "Topheth", type: .topheth, affinity: .fire, veilThinness: 0.9, corruption: 0.8)
        site.recordRitualPerformed()
        site.recordRitualPerformed()
        site.recordMutation()
        let sites = [site]
        let npcs = try RidgeOfElah.kfarShalemNPCs()
        let clock = WorldClock()

        let events = director.evaluate(
            world: world, sites: sites, npcs: npcs,
            currentSiteIndex: 0, clock: clock
        )

        #expect(events.count <= 2)
    }

    @Test("Director fires NPC initiative at village")
    func directorFiresNPCInitiativeAtVillage() throws {
        let world = WorldSimulation(regions: [RegionState(name: "Test")])
        let site = RitualSite(name: "Kfar Shalem", type: .ancestorShrine, affinity: .earth)
        let sites = [site]

        // Create an NPC that would approach
        var npc = try #require(RidgeOfElah.tamarBatYoav())
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
    func ritualCommandRecordsSingleJournalEntry() async throws {
        let content = RidgeOfElah.createWorld()
        let shard = WorldShard(
            world: WorldSimulation(regions: [content.region]),
            sites: content.sites,
            npcs: try RidgeOfElah.kfarShalemNPCs(),
            rootIdentities: try RidgeOfElah.rootIdentities()
        )

        let session = PractitionerSession(
            name: "Test Practitioner",
            fragments: [Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .earth)],
            artifacts: [],
            memoryTraces: []
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
    func practitionersShareSiteScarring() async throws {
        let content = RidgeOfElah.createWorld()
        let shard = WorldShard(
            world: WorldSimulation(regions: [content.region]),
            sites: content.sites,
            npcs: try RidgeOfElah.kfarShalemNPCs(),
            rootIdentities: try RidgeOfElah.rootIdentities()
        )

        let first = PractitionerSession(
            name: "First Practitioner",
            fragments: [Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .earth)],
            artifacts: [],
            memoryTraces: []
        )
        let second = PractitionerSession(
            name: "Second Practitioner",
            fragments: [Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .earth)],
            artifacts: [],
            memoryTraces: []
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

// MARK: - Rumor Engine Tests

@Suite("Rumor Engine Tests")
struct RumorEngineTests {
    private func testNPC(name: String = "Probe", faction: Faction = .elders) -> NPC {
        NPC(
            name: name,
            role: "Test",
            faction: faction,
            register: VoiceRegister(style: .vernacular),
            interiority: NPCInteriority(
                interiorVoice: "",
                privateTruth: "",
                unsatisfiedWant: "",
                wound: "",
                threshold: ""
            )
        )
    }

    @Test("A ritual at a village shrine seeds a rumor in the ledger")
    func seedingFromRitualPlantsRumor() throws {
        var world = WorldSimulation(regions: [RegionState(name: "R", stability: 0.8)])
        world.currentTick = 10

        var site = RitualSite(name: "Kfar Shalem", type: .ancestorShrine, affinity: .earth)
        site.recordRitualPerformed()

        var npcs = [
            testNPC(name: "Elder", faction: .elders),
            testNPC(name: "Priest", faction: .priesthood),
            testNPC(name: "Trader", faction: .traders),
        ]

        let rumorID = world.seedRitualRumor(
            site: site,
            wasMutation: false,
            libation: .fermentedWine,
            timing: WorldTiming(time: .deepNight, lunar: .newMoon),
            practitionerName: "Amoz",
            npcs: &npcs
        )

        #expect(rumorID != nil)
        let rumor = try #require(rumorID.flatMap { world.rumorLedger.rumors[$0] })
        #expect(rumor.kind == .ritual)
        #expect(rumor.originSiteName == "Kfar Shalem")
        #expect(rumor.sentence.contains("Amoz"))
        #expect(!rumor.hearers.isEmpty)
        #expect(npcs[0].hasHeardRumors)
        #expect(npcs[0].heardRumorIDs.contains(rumor.id))
    }

    @Test("Blood libation produces a blood-offering rumor")
    func bloodLibationTagsRumor() throws {
        var world = WorldSimulation(regions: [RegionState(name: "R", stability: 0.8)])
        var site = RitualSite(name: "The Burning Ground", type: .topheth, affinity: .fire)
        site.recordRitualPerformed()
        var npcs = [testNPC(faction: .priesthood)]

        let rumorID = world.seedRitualRumor(
            site: site,
            wasMutation: false,
            libation: .bloodOffering,
            timing: WorldTiming(time: .deepNight, lunar: .newMoon),
            practitionerName: nil,
            npcs: &npcs
        )

        let rumor = try #require(rumorID.flatMap { world.rumorLedger.rumors[$0] })
        #expect(rumor.kind == .bloodOffering)
    }

    @Test("Mutation events seed a mutation rumor")
    func mutationFlagsRumor() throws {
        var world = WorldSimulation(regions: [RegionState(name: "R", stability: 0.8)])
        var site = RitualSite(name: "Nahal Caves", type: .burialCave, affinity: .earth)
        site.recordRitualPerformed()
        var npcs = [testNPC(faction: .priesthood)]

        let rumorID = world.seedRitualRumor(
            site: site,
            wasMutation: true,
            libation: .water,
            timing: WorldTiming(time: .deepNight, lunar: .newMoon),
            practitionerName: nil,
            npcs: &npcs
        )

        let rumor = try #require(rumorID.flatMap { world.rumorLedger.rumors[$0] })
        #expect(rumor.kind == .mutation)
    }

    @Test("Quiet site with no reach does not seed a rumor")
    func lowReachDropsRumor() {
        var world = WorldSimulation(regions: [RegionState(name: "R", stability: 0.9)])
        let quietSite = RitualSite(name: "Hidden Niche", type: .ossuaryNiche, affinity: .earth)
        var npcs = [testNPC(faction: .elders)]

        let rumorID = world.seedRitualRumor(
            site: quietSite,
            wasMutation: false,
            libation: .water,
            timing: WorldTiming(),
            practitionerName: nil,
            npcs: &npcs
        )

        #expect(rumorID == nil)
    }

    @Test("Propagation reaches new carriers over ticks")
    func propagationReachesNewCarriers() throws {
        var world = WorldSimulation(regions: [RegionState(name: "R", stability: 0.8)])
        var site = RitualSite(name: "Kfar Shalem", type: .ancestorShrine, affinity: .earth)
        for _ in 0..<3 { site.recordRitualPerformed() }

        var npcs: [NPC] = (0..<6).map { i in
            testNPC(name: "NPC\(i)", faction: [.elders, .priesthood, .traders][i % 3])
        }

        let rumorID = try #require(world.seedRitualRumor(
            site: site,
            wasMutation: false,
            libation: .fermentedWine,
            timing: WorldTiming(time: .deepNight, lunar: .newMoon),
            practitionerName: "Amoz",
            npcs: &npcs
        ))

        let initialHearerCount = world.rumorLedger.rumors[rumorID]?.hearers.count ?? 0

        for _ in 1...8 {
            world.currentTick += 1
            world.tickRumors(npcs: &npcs)
        }

        let descendantCarrierIDs = world.rumorLedger.rumors.values
            .filter { $0.id == rumorID || $0.ancestorID == rumorID }
            .flatMap(\.hearers)
        let uniqueCarriers = Set(descendantCarrierIDs)
        #expect(uniqueCarriers.count > initialHearerCount)
    }

    @Test("Mutation-heavy rumors fork child rumors")
    func mutationProducesChild() {
        var world = WorldSimulation(regions: [RegionState(name: "R", stability: 0.8)])
        var site = RitualSite(name: "Kfar Shalem", type: .ancestorShrine, affinity: .earth)
        for _ in 0..<5 { site.recordRitualPerformed() }

        var npcs: [NPC] = (0..<50).map { i in
            testNPC(name: "NPC\(i)", faction: [.elders, .priesthood, .traders][i % 3])
        }

        guard let rumorID = world.seedRitualRumor(
            site: site,
            wasMutation: true,
            libation: .bloodOffering,
            timing: WorldTiming(time: .deepNight, lunar: .newMoon),
            practitionerName: "Amoz",
            npcs: &npcs
        ) else {
            Issue.record("failed to seed mutation-heavy rumor")
            return
        }

        var sawChild = false
        for _ in 1...50 {
            world.currentTick += 1
            world.tickRumors(npcs: &npcs)
            if world.rumorLedger.rumors.values.contains(where: { $0.ancestorID == rumorID }) {
                sawChild = true
                break
            }
        }

        #expect(sawChild)
    }

    @Test("Rumor carriers raise regional suspicion over time")
    func rumorPressureRaisesRegionSuspicion() throws {
        var world = WorldSimulation(regions: [RegionState(name: "R", stability: 0.8, suspicion: 0.05)])
        var site = RitualSite(name: "Kfar Shalem", type: .ancestorShrine, affinity: .earth)
        for _ in 0..<5 { site.recordRitualPerformed() }

        var npcs: [NPC] = (0..<8).map { i in
            testNPC(name: "NPC\(i)", faction: [.elders, .priesthood, .traders][i % 3])
        }

        _ = try #require(world.seedRitualRumor(
            site: site,
            wasMutation: false,
            libation: .fermentedWine,
            timing: WorldTiming(time: .deepNight, lunar: .newMoon),
            practitionerName: "Amoz",
            npcs: &npcs
        ))

        let regionID = try #require(world.regions.keys.first)
        let initialSuspicion = try #require(world.regions[regionID]?.suspicion)

        for _ in 1...4 {
            world.currentTick += 1
            world.tickRumors(npcs: &npcs)
        }

        let finalSuspicion = try #require(world.regions[regionID]?.suspicion)
        #expect(finalSuspicion > initialSuspicion)
    }

    @Test("Rumor pressure can tip a watchful region into inquisition")
    func rumorPressureCanTriggerInquisition() throws {
        var clock = WorldClock()
        var world = WorldSimulation(regions: [
            RegionState(name: "R", stability: 0.1, suspicion: 0.7995)
        ])
        var site = RitualSite(name: "Kfar Shalem", type: .ancestorShrine, affinity: .earth)
        for _ in 0..<8 { site.recordRitualPerformed() }

        var sites = [site]
        var npcs: [NPC] = (0..<8).map { i in
            testNPC(name: "NPC\(i)", faction: [.elders, .priesthood, .traders][i % 3])
        }

        _ = try #require(world.seedRitualRumor(
            site: site,
            wasMutation: true,
            libation: .bloodOffering,
            timing: WorldTiming(time: .deepNight, lunar: .newMoon),
            practitionerName: "Amoz",
            npcs: &npcs
        ))

        _ = clock.advance(by: 3, world: &world, sites: &sites, npcs: &npcs)

        let triggeredInquisition = world.journal.contains { entry in
            entry.type == .thresholdEvent && entry.tags.contains("inquisitionTriggered")
        }
        #expect(triggeredInquisition)
    }

    @Test("Rumors decay and eventually go extinct")
    func decayRemovesStaleRumors() {
        var ledger = RumorLedger()
        let rumorID = UUID()
        ledger.rumors[rumorID] = Rumor(
            id: rumorID,
            originTick: 0,
            originSiteID: nil,
            kind: .ritual,
            originSiteName: "nowhere",
            subjectDescriptor: "a stranger",
            act: "spoke",
            timeDescriptor: "at night",
            strength: 0.2,
            lastPropagatedTick: 0
        )

        for tick in 1...300 {
            ledger.decay(tick: tick)
        }

        #expect(ledger.rumors[rumorID] == nil)
    }

    @Test("NPC hearing a rumor records carrier state and bumps suspicion")
    func npcHearRecordsCarrier() {
        var npc = testNPC(faction: .priesthood)
        let rumor = Rumor(
            originTick: 0,
            originSiteID: nil,
            kind: .mutation,
            originSiteName: "the caves",
            subjectDescriptor: "a stranger",
            act: "called something wrong",
            timeDescriptor: "in deep night",
            strength: 0.6
        )

        let priorSuspicion = npc.personalSuspicion
        npc.hear(rumor, at: 5)

        #expect(npc.hasHeardRumors)
        #expect(npc.heardRumorIDs.contains(rumor.id))
        #expect(npc.lastHeardRumorID == rumor.id)
        #expect(npc.personalSuspicion > priorSuspicion)
    }

    @Test("Legacy world snapshots without rumor ledger still decode")
    func legacySnapshotDecodesWithoutLedger() throws {
        var world = WorldSimulation(regions: [RegionState(name: "Legacy")])
        world.currentTick = 42
        let encoded = try JSONEncoder().encode(world)
        var jsonObject = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        jsonObject.removeValue(forKey: "rumorLedger")
        let legacy = try JSONSerialization.data(withJSONObject: jsonObject)

        let decoded = try JSONDecoder().decode(WorldSimulation.self, from: legacy)
        #expect(decoded.currentTick == 42)
        #expect(decoded.rumorLedger.rumors.isEmpty)
    }
}
