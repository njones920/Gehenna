import Testing
import Foundation
@testable import GehennaEngine

@Suite("Retinue Tests")
struct RetinueTests {

    func makeSpirit(
        stability: Double = 0.5,
        traits: [PersonalityTrait] = [.loyal],
        epochName: String? = nil
    ) -> Spirit {
        Spirit(
            template: .warrior,
            tier: .common,
            tags: TagConstellation([NarrativeTag(.identity, "soldier")]),
            era: .ironAgeII,
            epochName: epochName,
            personalityTraits: traits,
            disposition: .calm,
            attributes: SpiritAttributes(
                strength: 0.5, knowledge: 0.3, will: 0.4,
                stability: stability, disposition: 0.5
            )
        )
    }

    @Test("Anchor respects summoner capacity")
    func anchorRespectsCapacity() {
        var retinue = Retinue()
        let first = retinue.anchor(makeSpirit(), atTick: 0, capacity: 1)
        let second = retinue.anchor(makeSpirit(), atTick: 0, capacity: 1)
        #expect(first)
        #expect(!second)
        #expect(retinue.count == 1)
        let third = retinue.anchor(makeSpirit(), atTick: 0, capacity: 2)
        #expect(third)
        #expect(retinue.count == 2)
    }

    @Test("Bound spirits decay and fade to Sheol")
    func spiritsDecayAndFade() {
        var retinue = Retinue()
        retinue.anchor(makeSpirit(stability: 0.1), atTick: 0, capacity: 1)

        // Base decay 0.02/tick: 0.1 stability is spent within 5 ticks.
        let departures = retinue.advance(ticks: 6, regionCorruption: 0.0, endingAtTick: 6)
        #expect(departures.count == 1)
        #expect(departures.first?.manner == .faded)
        #expect(retinue.isEmpty)
        // The departure tick is within the advanced window.
        #expect((1...6).contains(departures.first?.tick ?? -1))
    }

    @Test("Corruption accelerates decay")
    func corruptionAcceleratesDecay() {
        var clean = Retinue()
        var corrupt = Retinue()
        clean.anchor(makeSpirit(stability: 0.5), atTick: 0, capacity: 1)
        corrupt.anchor(makeSpirit(stability: 0.5), atTick: 0, capacity: 1)

        _ = clean.advance(ticks: 5, regionCorruption: 0.0, endingAtTick: 5)
        _ = corrupt.advance(ticks: 5, regionCorruption: 0.8, endingAtTick: 5)

        let cleanStability = clean.bound.first?.spirit.currentStability ?? 0
        let corruptStability = corrupt.bound.first?.spirit.currentStability ?? 0
        #expect(corruptStability < cleanStability)
    }

    @Test("Co-presence strains every bound spirit")
    func coPresenceStrain() {
        var solo = Retinue()
        solo.anchor(makeSpirit(stability: 0.9), atTick: 0, capacity: 3)

        var pair = Retinue()
        pair.anchor(makeSpirit(stability: 0.9), atTick: 0, capacity: 3)
        pair.anchor(makeSpirit(stability: 0.9), atTick: 0, capacity: 3)

        _ = solo.advance(ticks: 10, regionCorruption: 0.0, endingAtTick: 10)
        _ = pair.advance(ticks: 10, regionCorruption: 0.0, endingAtTick: 10)

        let soloStability = solo.bound.first?.spirit.currentStability ?? 0
        let pairStability = pair.bound.first?.spirit.currentStability ?? 0
        #expect(pairStability < soloStability)
    }

    @Test("Two prideful spirits strain each other further")
    func pridefulRivalry() {
        var mixed = Retinue()
        mixed.anchor(makeSpirit(stability: 0.9, traits: [.prideful]), atTick: 0, capacity: 3)
        mixed.anchor(makeSpirit(stability: 0.9, traits: [.loyal]), atTick: 0, capacity: 3)

        var rivals = Retinue()
        rivals.anchor(makeSpirit(stability: 0.9, traits: [.prideful]), atTick: 0, capacity: 3)
        rivals.anchor(makeSpirit(stability: 0.9, traits: [.prideful]), atTick: 0, capacity: 3)

        #expect(rivals.decayPerTick(regionCorruption: 0.0) > mixed.decayPerTick(regionCorruption: 0.0))
    }

    @Test("Dismissal frees the slot and reports the manner")
    func dismissalFreesSlot() {
        var retinue = Retinue()
        let spirit = makeSpirit(epochName: "Bronze Captain")
        retinue.anchor(spirit, atTick: 0, capacity: 1)

        let departure = retinue.dismiss(id: spirit.id, manner: .banished, atTick: 3)
        #expect(departure?.manner == .banished)
        #expect(departure?.spirit.epochName == "Bronze Captain")
        #expect(retinue.isEmpty)
        // Slot is free again.
        let reanchored = retinue.anchor(makeSpirit(), atTick: 4, capacity: 1)
        #expect(reanchored)
    }

    @Test("Fading is not a chosen dismissal manner")
    func cannotChooseFade() {
        var retinue = Retinue()
        let spirit = makeSpirit()
        retinue.anchor(spirit, atTick: 0, capacity: 1)
        #expect(retinue.dismiss(id: spirit.id, manner: .faded, atTick: 1) == nil)
        #expect(retinue.count == 1)
    }

    @Test("Retinue round-trips through the single-player snapshot")
    func snapshotRoundTrip() throws {
        var retinue = Retinue()
        retinue.anchor(makeSpirit(epochName: "Bronze Captain"), atTick: 12, capacity: 2)

        let content = RidgeOfElah.createWorld()
        let snapshot = SinglePlayerSnapshot(
            savedAtTick: 12,
            world: WorldSimulation(regions: [content.region]),
            profile: PractitionerProfile(),
            codex: CodexOfTheDead(),
            sites: content.sites,
            inventory: PractitionerInventorySnapshot(
                fragments: [], artifacts: [], memoryTraces: [], libations: [.water]
            ),
            currentSiteIndex: 0,
            ritualCount: 1,
            rootIdentities: [],
            npcs: [],
            clock: WorldClock(startingTick: 12),
            retinue: retinue
        )

        let data = try SnapshotStore.encode(snapshot)
        let decoded = try SnapshotStore.decodeSinglePlayerSnapshot(from: data)
        #expect(decoded.retinue?.count == 1)
        #expect(decoded.retinue?.bound.first?.spirit.epochName == "Bronze Captain")
        #expect(decoded.retinue?.bound.first?.anchoredAtTick == 12)
    }

    @Test("Snapshots written before 0.4.28 still decode")
    func backwardCompatibleDecoding() throws {
        let content = RidgeOfElah.createWorld()
        let snapshot = SinglePlayerSnapshot(
            savedAtTick: 0,
            world: WorldSimulation(regions: [content.region]),
            profile: PractitionerProfile(),
            codex: CodexOfTheDead(),
            sites: content.sites,
            inventory: PractitionerInventorySnapshot(
                fragments: [], artifacts: [], memoryTraces: [], libations: []
            ),
            currentSiteIndex: 0,
            ritualCount: 0,
            rootIdentities: [],
            npcs: [],
            clock: WorldClock()
        )

        // Simulate a pre-0.4.28 save by stripping the retinue key entirely.
        let data = try SnapshotStore.encode(snapshot)
        var json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        json.removeValue(forKey: "retinue")
        let strippedData = try JSONSerialization.data(withJSONObject: json)

        let decoded = try SnapshotStore.decodeSinglePlayerSnapshot(from: strippedData)
        #expect(decoded.retinue == nil)
    }

    @Test("Shard practitioners anchor spirits and feel decay")
    func shardRetinueDecay() async {
        let content = RidgeOfElah.createWorld()
        let shard = WorldShard(
            world: WorldSimulation(regions: [content.region]),
            sites: content.sites,
            npcs: [],
            rootIdentities: (try? RidgeOfElah.rootIdentities()) ?? []
        )

        var session = PractitionerSession(
            name: "Testbot",
            fragments: [],
            artifacts: [],
            memoryTraces: []
        )
        // Pre-anchor a fragile spirit directly, then let shard time pass.
        session.retinue.anchor(makeSpirit(stability: 0.05), atTick: 0, capacity: 1)
        let id = await shard.addPractitioner(session)

        _ = await shard.execute(.wait, for: id)

        let after = await shard.sessions[id]
        #expect(after?.retinue.isEmpty == true, "A near-spent spirit should fade during a wait")

        let journal = await shard.world.journal
        #expect(journal.contains { $0.type == .spiritDeparted })
    }
}
