import Testing
import Foundation
@testable import GehennaEngine

@Suite("Shared World Verb Tests")
struct SharedWorldVerbTests {

    func makeShard() -> WorldShard {
        let content = RidgeOfElah.createWorld()
        return WorldShard(
            world: WorldSimulation(regions: [content.region]),
            sites: content.sites,
            npcs: [],
            rootIdentities: (try? RidgeOfElah.rootIdentities()) ?? []
        )
    }

    func makeSpirit(rootIdentityID: UUID? = nil, stability: Double = 0.5) -> Spirit {
        Spirit(
            template: .warrior, tier: .common,
            tags: TagConstellation([NarrativeTag(.identity, "soldier")]),
            era: .ironAgeII, epochName: "Bronze Captain",
            rootIdentityID: rootIdentityID,
            personalityTraits: [.loyal], disposition: .calm,
            attributes: SpiritAttributes(strength: 0.5, knowledge: 0.5, will: 0.5, stability: stability, disposition: 0.5)
        )
    }

    @Test("Scavenging a shared site leaves nothing for the rival")
    func scavengeIsExclusive() async {
        let shard = makeShard()
        let a = await shard.addPractitioner(PractitionerSession(name: "A", fragments: [], artifacts: [], memoryTraces: []))
        let b = await shard.addPractitioner(PractitionerSession(name: "B", fragments: [], artifacts: [], memoryTraces: []))

        _ = await shard.execute(.scavenge, for: a)
        _ = await shard.execute(.scavenge, for: b)

        let sessionA = await shard.sessions[a]
        let sessionB = await shard.sessions[b]
        #expect((sessionA?.inventory.fragments.count ?? 0) > 0)
        #expect(sessionB?.inventory.fragments.isEmpty == true)
    }

    @Test("Shard dismissal consumes the offering and writes the ledger")
    func shardDismissal() async {
        let shard = makeShard()
        var session = PractitionerSession(name: "A", fragments: [], artifacts: [], memoryTraces: [])
        let spirit = makeSpirit()
        session.relationships.noteSummon(of: spirit, atTick: 0)
        session.retinue.anchor(spirit, atTick: 0, capacity: 1)
        let libationsBefore = session.inventory.libations.count
        let a = await shard.addPractitioner(session)

        let result = await shard.execute(.dismiss(spiritIndex: 0, manner: .releasedWithLibation), for: a)
        #expect(result.narration.contains { $0.contains("pour the offering") })

        let after = await shard.sessions[a]
        #expect(after?.retinue.isEmpty == true)
        #expect(after?.inventory.libations.count == libationsBefore - 1)
        let rel = after?.relationships.relationship(for: spirit)
        #expect(rel?.moments.contains { $0.kind == .releasedWithLibation } == true)
    }

    @Test("Speak works through the shard without an expression engine")
    func shardSpeakFallback() async {
        let shard = makeShard()
        var session = PractitionerSession(name: "A", fragments: [], artifacts: [], memoryTraces: [])
        let spirit = makeSpirit()
        session.relationships.noteSummon(of: spirit, atTick: 0)
        session.retinue.anchor(spirit, atTick: 0, capacity: 1)
        let a = await shard.addPractitioner(session)

        let result = await shard.execute(.speak(spiritIndex: 0, text: "I promise to bring wine to your grave."), for: a)
        #expect(result.narration.contains { $0.contains("presence considers you") })

        let after = await shard.sessions[a]
        // Heuristic intent lane ran with no model: the promise landed.
        let rel = after?.relationships.relationship(for: spirit)
        #expect(rel?.moments.contains { $0.kind == .promiseMade } == true)
        #expect(rel?.totalExchanges == 1)
        #expect(after?.retinue.bound.first?.exchangeCount == 1)
    }

    @Test("Invoke Name requires knowledge, plants doubt, and the ledger remembers")
    func invokeNameContest() async throws {
        let identities = try RidgeOfElah.rootIdentities()
        let hiram = try #require(identities.first { $0.trueName?.contains("Hiram") == true })
        let shard = makeShard()

        // Rival B holds Hiram with a middling bond.
        var rivalSession = PractitionerSession(name: "B", fragments: [], artifacts: [], memoryTraces: [])
        let spirit = makeSpirit(rootIdentityID: hiram.id, stability: 0.5)
        rivalSession.relationships.noteSummon(of: spirit, atTick: 0)
        rivalSession.retinue.anchor(spirit, atTick: 0, capacity: 1)
        let b = await shard.addPractitioner(rivalSession)

        // A has never met Hiram — the name has no purchase.
        let ignorant = await shard.addPractitioner(PractitionerSession(name: "A", fragments: [], artifacts: [], memoryTraces: []))
        let blind = await shard.execute(.invokeName(rivalID: b, spiritIndex: 0), for: ignorant)
        #expect(blind.narration.contains { $0.contains("only the shape of one") })

        // C knows Hiram from their own codex — the contest lands.
        var knower = PractitionerSession(name: "C", fragments: [], artifacts: [], memoryTraces: [])
        _ = knower.codex.recordEncounter(spirit: makeSpirit(rootIdentityID: hiram.id), autopsy: [], ritualID: UUID(), tick: 0)
        let c = await shard.addPractitioner(knower)

        let stabilityBefore = await shard.sessions[b]?.retinue.bound.first?.spirit.currentStability ?? 0
        let contest = await shard.execute(.invokeName(rivalID: b, spiritIndex: 0), for: c)
        #expect(contest.narration.contains { $0.contains("Hiram") })

        let rivalAfter = await shard.sessions[b]
        let stabilityAfter = rivalAfter?.retinue.bound.first?.spirit.currentStability ?? 0
        #expect(stabilityAfter < stabilityBefore, "Doubt costs stability")
        let rel = rivalAfter?.relationships.relationship(forKey: hiram.id)
        #expect(rel?.moments.contains { $0.kind == .nameContested } == true)

        let journal = await shard.world.journal
        #expect(journal.contains { $0.tags.contains("spiritPolitics") })
    }

    @Test("Call-by-name works through the shard and consumes the offering")
    func shardCall() async throws {
        let identities = try RidgeOfElah.rootIdentities()
        let hiram = try #require(identities.first { $0.trueName?.contains("Hiram") == true })
        let shard = makeShard()

        var session = PractitionerSession(name: "A", fragments: [], artifacts: [], memoryTraces: [])
        let spirit = makeSpirit(rootIdentityID: hiram.id)
        session.relationships.noteSummon(of: spirit, atTick: 0)
        session.inventory.fragments = [Fragment(
            remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire,
            tags: TagConstellation([NarrativeTag(.identity, "soldier")])
        )]
        let libationsBefore = session.inventory.libations.count
        let a = await shard.addPractitioner(session)

        let result = await shard.execute(.callByName(relationshipIndex: 0, fragmentIndex: 0, libation: .water), for: a)
        #expect(!result.narration.isEmpty)

        let after = await shard.sessions[a]
        #expect(after?.inventory.libations.count == libationsBefore - 1)
    }
}
