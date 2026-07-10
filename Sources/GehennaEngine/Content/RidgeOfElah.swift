// MARK: - Ridge of Elah
// The reference vertical slice region. A contested borderland in the Shephelah
// between highland tribal territory and coastal warrior city-states.
// Five locations. Enough content to exercise every system.
//
// Each location exercises distinct systems. Each is individually comprehensible.
// Together they form an interconnected region where practitioner choices at one
// location propagate consequences across the others.

import Foundation

/// Factory for the Ridge of Elah vertical slice content.
public enum RidgeOfElah {

    // MARK: - Region

    /// The Ridge of Elah region state — the contested borderland.
    public static func createRegion() -> RegionState {
        RegionState(
            name: "Ridge of Elah",
            population: 0.7,
            warIntensity: 0.3,      // active low-level conflict
            ghostActivity: 0.15,    // some restless dead from recent battles
            corruption: 0.1,
            stability: 0.7,
            suspicion: 0.1,
            spiritualPressure: 0.15
        )
    }

    // MARK: - Sites

    /// Battlefield Ridge — Active warfare. Recent dead. Fire affinity.
    /// Low initial Veil Thinness. War-domain fragments.
    public static func battlefieldRidge() -> RitualSite {
        RitualSite(
            name: "Battlefield Ridge",
            type: .battlefield,
            affinity: .fire,
            deathSaturation: 0.35,  // recent dead are plentiful
            veilThinness: 0.2,      // low — the dead here are fresh, not ancient
            sanctity: 0.1,          // no holiness on a killing field
            corruption: 0.15,
            tags: TagConstellation([
                NarrativeTag(.era, "iron_age_ii"),
                NarrativeTag(.deathContext, "battle"),
                NarrativeTag(.identity, "soldier"),
                NarrativeTag(.cultural, "contested_borderland"),
            ]),
            fragments: battlefieldFragments()
        )
    }

    /// Tel Keshet — Collapsed Bronze Age temple-fortress.
    /// Silence affinity. Ancient high-Sanctity fragments. Knowledge and Faith domains.
    public static func telKeshet() -> RitualSite {
        RitualSite(
            name: "Tel Keshet",
            type: .collapsingTemple,
            affinity: .silence,
            deathSaturation: 0.5,   // centuries of the dead
            veilThinness: 0.45,     // ancient site, well-worn boundary
            sanctity: 0.7,          // still carries residual holiness
            corruption: 0.05,       // relatively pure
            tags: TagConstellation([
                NarrativeTag(.era, "late_bronze_age"),
                NarrativeTag(.cultural, "temple_compound"),
                NarrativeTag(.identity, "priest"),
                NarrativeTag(.identity, "scribe"),
                NarrativeTag(.cultural, "devoted_to_baal"),
            ]),
            fragments: telKeshetFragments(),
            artifacts: starterArtifacts()
        )
    }

    /// Nahal Caves — Limestone network with underground spring.
    /// Mixed-era burials. Earth affinity. Moderate Veil Thinness.
    /// Deep shaft contains Early Bronze Age content gated by a Tomb Guardian.
    public static func nahalCaves() -> RitualSite {
        RitualSite(
            name: "Nahal Caves",
            type: .burialCave,
            affinity: .earth,
            deathSaturation: 0.6,   // centuries of burials layered deep
            veilThinness: 0.5,      // the spring thins the boundary
            sanctity: 0.4,          // mixed — both sacred and profane burials
            corruption: 0.1,
            tags: TagConstellation([
                NarrativeTag(.era, "mixed_era"),
                NarrativeTag(.deathContext, "burial"),
                NarrativeTag(.cultural, "ancestor_veneration"),
                NarrativeTag(.identity, "elder"),
            ]),
            fragments: nahalCavesFragments(),
            memoryTraces: starterMemoryTraces()
        )
    }

    /// Kfar Shalem — Living highland village. Social zone.
    /// Not a ritual site in the traditional sense — attempting rituals here
    /// generates massive Suspicion.
    public static func kfarShalem() -> RitualSite {
        RitualSite(
            name: "Kfar Shalem",
            type: .ancestorShrine,
            affinity: .earth,
            deathSaturation: 0.1,   // a living place, not a dead one
            veilThinness: 0.1,      // the boundary is thick where life is loud
            sanctity: 0.5,          // ancestor shrine within the village
            corruption: 0.0,
            tags: TagConstellation([
                NarrativeTag(.era, "iron_age_ii"),
                NarrativeTag(.cultural, "highland_village"),
                NarrativeTag(.identity, "villager"),
            ])
        )
    }

    /// The Burning Ground — Defiled ritual site in the wadi.
    /// Early Iron Age. Fire affinity. High Corruption.
    /// All fragments here carry Corrupted Integrity.
    /// The Tophet-style site. The place where the game's name becomes
    /// a place the practitioner can stand.
    public static func burningGround() -> RitualSite {
        RitualSite(
            name: "The Burning Ground",
            type: .topheth,
            affinity: .fire,
            deathSaturation: 0.8,   // saturated with death
            veilThinness: 0.65,     // the boundary is thin from old atrocity
            sanctity: 0.0,          // no holiness remains
            corruption: 0.6,        // deeply corrupted
            tags: TagConstellation([
                NarrativeTag(.era, "iron_age_i"),
                NarrativeTag(.deathContext, "sacrifice"),
                NarrativeTag(.deathContext, "burning"),
                NarrativeTag(.cultural, "tophet"),
                NarrativeTag(.disposition, "grief"),
                NarrativeTag(.disposition, "rage"),
                NarrativeTag(.taboo, "will_not_speak_of_offering"),
            ]),
            fragments: burningGroundFragments()
        )
    }

    /// All five sites.
    public static func allSites() -> [RitualSite] {
        [battlefieldRidge(), telKeshet(), nahalCaves(), kfarShalem(), burningGround()]
    }

    // MARK: - Starter Fragments

    /// Fragments the practitioner discovers at Battlefield Ridge.
    public static func battlefieldFragments() -> [Fragment] {
        [
            Fragment(
                remains: .longBone,
                era: .ironAgeII,
                domain: .war,
                affinity: .fire,
                integrity: .worn,
                tags: TagConstellation([
                    NarrativeTag(.identity, "soldier"),
                    NarrativeTag(.identity, "Philistine"),
                    NarrativeTag(.deathContext, "battle"),
                    NarrativeTag(.relational, "served_a_lord"),
                    NarrativeTag(.disposition, "duty"),
                ]),
                inscribedName: nil
            ),
            Fragment(
                remains: .ribFragment,
                era: .ironAgeII,
                domain: .war,
                affinity: .fire,
                integrity: .degraded,
                tags: TagConstellation([
                    NarrativeTag(.identity, "soldier"),
                    NarrativeTag(.identity, "young"),
                    NarrativeTag(.deathContext, "battle"),
                    NarrativeTag(.disposition, "rage"),
                ])
            ),
        ]
    }

    /// Fragments discoverable at Tel Keshet.
    public static func telKeshetFragments() -> [Fragment] {
        [
            Fragment(
                remains: .skull,
                era: .lateBronze,
                domain: .knowledge,
                affinity: .silence,
                integrity: .worn,
                tags: TagConstellation([
                    NarrativeTag(.identity, "scribe"),
                    NarrativeTag(.identity, "Canaanite"),
                    NarrativeTag(.identity, "elder"),
                    NarrativeTag(.cultural, "temple_trained"),
                    NarrativeTag(.cultural, "devoted_to_baal"),
                    NarrativeTag(.deathContext, "old_age"),
                    NarrativeTag(.disposition, "pride"),
                    NarrativeTag(.relational, "raised_apprentices"),
                ]),
                inscribedName: "...ram, son of"
            ),
            Fragment(
                remains: .handBones,
                era: .lateBronze,
                domain: .faith,
                affinity: .silence,
                integrity: .pristine,
                tags: TagConstellation([
                    NarrativeTag(.identity, "priest"),
                    NarrativeTag(.identity, "Canaanite"),
                    NarrativeTag(.cultural, "devoted_to_baal"),
                    NarrativeTag(.deathContext, "old_age"),
                    NarrativeTag(.disposition, "devotion"),
                    NarrativeTag(.taboo, "will_not_speak_yhwh"),
                ])
            ),
        ]
    }

    /// Fragments discoverable in the Nahal Caves.
    public static func nahalCavesFragments() -> [Fragment] {
        [
            Fragment(
                remains: .longBone,
                era: .middleBronze,
                domain: .war,
                affinity: .earth,
                integrity: .worn,
                tags: TagConstellation([
                    NarrativeTag(.identity, "warrior"),
                    NarrativeTag(.identity, "Amorite"),
                    NarrativeTag(.deathContext, "battle"),
                    NarrativeTag(.disposition, "pride"),
                    NarrativeTag(.relational, "defended_a_pass"),
                ])
            ),
            // Maacah. Buried above the spring, without a name, without
            // the rites. The Devorah thread points here.
            Fragment(
                remains: .longBone,
                era: .ironAgeII,
                domain: .faith,
                affinity: .earth,
                integrity: .worn,
                tags: TagConstellation([
                    NarrativeTag(.identity, "adult_woman"),
                    NarrativeTag(.identity, "Israelite"),
                    NarrativeTag(.cultural, "highland_clan"),
                    NarrativeTag(.cultural, "keeps_asherah_figurine"),
                    NarrativeTag(.cultural, "devoted_to_asherah"),
                    NarrativeTag(.deathContext, "childbirth"),
                    NarrativeTag(.relational, "lost_a_child"),
                    NarrativeTag(.disposition, "grief"),
                ])
            ),
            Fragment(
                remains: .ossuaryChip,
                era: .ironAgeI,
                domain: .death,
                affinity: .earth,
                integrity: .degraded,
                tags: TagConstellation([
                    NarrativeTag(.identity, "elder"),
                    NarrativeTag(.identity, "Israelite"),
                    NarrativeTag(.deathContext, "old_age"),
                    NarrativeTag(.cultural, "ancestor_veneration"),
                    NarrativeTag(.relational, "buried_by_children"),
                    NarrativeTag(.disposition, "peace"),
                ])
            ),
            // Deep shaft fragment — gated by the Tomb Guardian
            Fragment(
                remains: .skull,
                era: .earlyBronze,
                domain: .rule,
                affinity: .earth,
                integrity: .worn,
                tags: TagConstellation([
                    NarrativeTag(.identity, "ruler"),
                    NarrativeTag(.identity, "elder"),
                    NarrativeTag(.era, "early_bronze_age"),
                    NarrativeTag(.deathContext, "old_age"),
                    NarrativeTag(.cultural, "first_settlements"),
                    NarrativeTag(.disposition, "authority"),
                    NarrativeTag(.relational, "founded_a_lineage"),
                    NarrativeTag(.taboo, "will_not_serve"),
                ]),
                inscribedName: "Abdi-Resheph"
            ),
        ]
    }

    /// Fragments from The Burning Ground — all carry corrupted integrity.
    public static func burningGroundFragments() -> [Fragment] {
        [
            Fragment(
                remains: .crematedBone,
                era: .ironAgeI,
                domain: .death,
                affinity: .fire,
                integrity: .corrupted, // all Burning Ground fragments are corrupted
                tags: TagConstellation([
                    NarrativeTag(.deathContext, "sacrifice"),
                    NarrativeTag(.deathContext, "burning"),
                    NarrativeTag(.identity, "young"),
                    NarrativeTag(.cultural, "tophet"),
                    NarrativeTag(.disposition, "grief"),
                    NarrativeTag(.taboo, "will_not_speak_of_offering"),
                ])
            ),
            Fragment(
                remains: .toothFragment,
                era: .ironAgeI,
                domain: .faith,
                affinity: .fire,
                integrity: .corrupted,
                tags: TagConstellation([
                    NarrativeTag(.identity, "child"),
                    NarrativeTag(.deathContext, "sacrifice"),
                    NarrativeTag(.cultural, "tophet"),
                    NarrativeTag(.disposition, "silence"),
                    NarrativeTag(.taboo, "will_not_speak_of_parents"),
                ])
            ),
        ]
    }

    // MARK: - Life Artifacts

    /// Discoverable life artifacts in the Ridge of Elah.
    public static func starterArtifacts() -> [LifeArtifact] {
        [
            LifeArtifact(
                name: "Bronze Spearhead",
                domain: .war,
                affinity: .fire,
                era: .ironAgeII,
                tags: TagConstellation([
                    NarrativeTag(.identity, "soldier"),
                    NarrativeTag(.identity, "Philistine"),
                    NarrativeTag(.cultural, "coastal_warrior"),
                ])
            ),
            LifeArtifact(
                name: "Clay Seal Impression",
                domain: .rule,
                affinity: .earth,
                era: .lateBronze,
                tags: TagConstellation([
                    NarrativeTag(.identity, "official"),
                    NarrativeTag(.cultural, "temple_administration"),
                ])
            ),
            LifeArtifact(
                name: "Bronze Ritual Dagger",
                domain: .war,
                affinity: .fire,
                era: .lateBronze,
                tags: TagConstellation([
                    NarrativeTag(.cultural, "apotropaic"),
                    NarrativeTag(.identity, "priest"),
                    NarrativeTag(.cultural, "te_omim_cave_tradition"),
                ])
            ),
            LifeArtifact(
                name: "Loom Weight",
                domain: .knowledge,
                affinity: .earth,
                era: .ironAgeII,
                tags: TagConstellation([
                    NarrativeTag(.identity, "weaver"),
                    NarrativeTag(.identity, "woman"),
                    NarrativeTag(.relational, "household"),
                ])
            ),
        ]
    }

    // MARK: - Memory Traces

    /// Discoverable memory traces.
    public static func starterMemoryTraces() -> [MemoryTrace] {
        [
            MemoryTrace(
                name: "Potsherd with Inscription",
                tags: TagConstellation([
                    NarrativeTag(.identity, "Philistine"),
                    NarrativeTag(.relational, "son_of"),
                ]),
                era: .ironAgeII
            ),
            MemoryTrace(
                name: "Grain Jar with Ownership Mark",
                tags: TagConstellation([
                    NarrativeTag(.identity, "farmer"),
                    NarrativeTag(.cultural, "highland_village"),
                    NarrativeTag(.relational, "household"),
                ]),
                era: .ironAgeII
            ),
            MemoryTrace(
                name: "Throne Name Inscription Fragment",
                tags: TagConstellation([
                    NarrativeTag(.identity, "ruler"),
                    NarrativeTag(.cultural, "conquest"),
                    NarrativeTag(.era, "early_bronze_age"),
                ]),
                era: .earlyBronze
            ),
        ]
    }

    // MARK: - Complete World Setup

    /// Create a complete game world with the Ridge of Elah vertical slice.
    /// NPCs and root identities are loaded from the canon JSON bundle.
    public static func createWorld() -> (
        region: RegionState,
        sites: [RitualSite]
    ) {
        let region = createRegion()
        var sites = allSites()
        for i in 0..<sites.count {
            sites[i].regionID = region.id
        }

        return (
            region: region,
            sites: sites
        )
    }

    /// Load Kfar Shalem NPCs from the canon JSON bundle.
    public static func kfarShalemNPCs() throws -> [NPC] {
        try CanonDataLoader.loadNPCs()
    }

    /// Load all root identities from the canon JSON bundle.
    public static func rootIdentities() throws -> [RootIdentity] {
        try CanonDataLoader.loadRootIdentities()
    }

    // MARK: - Named NPC Accessors (convenience — look up from canon bundle)

    public static func abiGad() -> NPC? {
        try? CanonDataLoader.loadNPCs().first { $0.name == "Abi-Gad" }
    }
    public static func tamarBatYoav() -> NPC? {
        try? CanonDataLoader.loadNPCs().first { $0.name == "Tamar bat Yoav" }
    }
    public static func huramTheTrader() -> NPC? {
        try? CanonDataLoader.loadNPCs().first { $0.name == "Huram" }
    }
    public static func yoelBenShimri() -> NPC? {
        try? CanonDataLoader.loadNPCs().first { $0.name == "Yoel ben Shimri" }
    }
    public static func devorah() -> NPC? {
        try? CanonDataLoader.loadNPCs().first { $0.name == "Devorah" }
    }
    public static func barukTheSmith() -> NPC? {
        try? CanonDataLoader.loadNPCs().first { $0.name == "Baruk" }
    }

    // MARK: - Named RootIdentity Accessors (convenience — look up from canon bundle)

    public static func hiramSonOfDagon() -> RootIdentity? {
        try? CanonDataLoader.loadRootIdentities().first { $0.trueName == "Hiram, son of Dagon" }
    }
    public static func scribeOfBaal() -> RootIdentity? {
        try? CanonDataLoader.loadRootIdentities().first { $0.trueName == nil && $0.culture == "Canaanite" }
    }
    public static func abdiResheph() -> RootIdentity? {
        try? CanonDataLoader.loadRootIdentities().first { $0.trueName == "Abdi-Resheph" }
    }
}
