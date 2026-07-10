import Testing
import Foundation
@testable import GehennaEngine

@Suite("Story Thread Tests")
struct StoryThreadTests {

    @Test("Threads remember stages and flags, and stages only move forward")
    func threadStateMachine() {
        var thread = StoryThread(key: "the-buried-names")
        #expect(thread.stage == 0)
        #expect(!thread.has("wantHeard"))

        thread.advance(to: 2)
        thread.mark("wantHeard")
        #expect(thread.stage == 2)
        #expect(thread.has("wantHeard"))

        // Stages never regress.
        thread.advance(to: 1)
        #expect(thread.stage == 2)
    }

    @Test("Thread state round-trips through the snapshot")
    func threadPersists() throws {
        var thread = StoryThread(key: "the-buried-names")
        thread.advance(to: 3)
        thread.mark("truthHeard")

        let content = RidgeOfElah.createWorld()
        let snapshot = SinglePlayerSnapshot(
            savedAtTick: 10,
            world: WorldSimulation(regions: [content.region]),
            profile: PractitionerProfile(),
            codex: CodexOfTheDead(),
            sites: content.sites,
            inventory: PractitionerInventorySnapshot(fragments: [], artifacts: [], memoryTraces: [], libations: []),
            currentSiteIndex: 0,
            ritualCount: 0,
            rootIdentities: [],
            npcs: [],
            clock: WorldClock(startingTick: 10),
            threads: [thread.key: thread]
        )

        let data = try SnapshotStore.encode(snapshot)
        let decoded = try SnapshotStore.decodeSinglePlayerSnapshot(from: data)
        let restored = decoded.threads?["the-buried-names"]
        #expect(restored?.stage == 3)
        #expect(restored?.has("truthHeard") == true)
    }

    @Test("Maacah's remains lie at Nahal and resolve to her when named")
    func maacahIsReachable() throws {
        let identities = try RidgeOfElah.rootIdentities()
        let maacah = try #require(identities.first { $0.trueName == "Maacah" })

        let fragments = RidgeOfElah.nahalCavesFragments()
        let hers = try #require(fragments.first { frag in
            frag.tags.tags.contains { $0.value == "keeps_asherah_figurine" }
        }, "Maacah's fragment must exist at Nahal Caves")
        #expect(hers.tags.tags.contains { $0.value == "childbirth" })

        // Speaking her name over her own remains at her burial ground
        // reaches her, and reaches a speaking aspect.
        let config = RitualConfiguration(
            remains: hers,
            site: RidgeOfElah.nahalCaves(),
            trueName: TrueName("Maacah", partial: false)
        )
        let result = ResolutionPipeline().resolve(
            configuration: config,
            regionState: RegionState(name: "Ridge of Elah", stability: 0.8),
            profile: PractitionerProfile(),
            seed: 7,
            rootIdentities: identities
        )
        let spirit = try #require(result.spirit, "The ritual should reach someone")
        #expect(spirit.rootIdentityID == maacah.id)
    }

    @Test("Broken promises reach the dead by key, unmanifested")
    func lieReachesTheDead() {
        var ledger = RelationshipLedger()
        let rootID = UUID()
        let spirit = Spirit(
            template: .mourner, tier: .common,
            tags: TagConstellation([NarrativeTag(.identity, "adult_woman")]),
            era: .ironAgeII, epochName: "The Mother Who Did Not Return",
            rootIdentityID: rootID,
            personalityTraits: [.loyal], disposition: .sorrowful,
            attributes: SpiritAttributes(strength: 0.2, knowledge: 0.5, will: 0.4, stability: 0.5, disposition: 0.4)
        )
        ledger.noteSummon(of: spirit, atTick: 1)

        ledger.record(.promiseBroken, forKey: rootID, atTick: 5, detail: "Her truth was traded for a comfortable lie.")
        let rel = ledger.relationship(forKey: rootID)!
        #expect(rel.moments.contains { $0.kind == .promiseBroken })
        // One betrayal outweighs the summons: the relationship sours.
        #expect(rel.netValence < 0)
    }
}
