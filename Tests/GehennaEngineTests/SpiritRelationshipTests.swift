import Testing
import Foundation
@testable import GehennaEngine

@Suite("Spirit Relationship Tests")
struct SpiritRelationshipTests {

    func makeSpirit(
        rootIdentityID: UUID? = nil,
        epochName: String? = "Bronze Captain",
        traits: [PersonalityTrait] = [.prideful, .loyal]
    ) -> Spirit {
        Spirit(
            template: .warrior,
            tier: .common,
            tags: TagConstellation([NarrativeTag(.identity, "soldier")]),
            era: .ironAgeII,
            epochName: epochName,
            rootIdentityID: rootIdentityID,
            personalityTraits: traits,
            disposition: .calm,
            attributes: SpiritAttributes(
                strength: 0.5, knowledge: 0.5, will: 0.5,
                stability: 0.5, disposition: 0.5
            )
        )
    }

    @Test("Epoch aspects share one relationship through the root identity")
    func aspectsShareMemory() {
        var ledger = RelationshipLedger()
        let rootID = UUID()
        let captain = makeSpirit(rootIdentityID: rootID, epochName: "Bronze Captain")
        let butcher = makeSpirit(rootIdentityID: rootID, epochName: "Ashkelon Butcher")

        ledger.noteSummon(of: captain, atTick: 1)
        ledger.noteSummon(of: butcher, atTick: 10)

        let rel = ledger.relationship(for: captain)
        #expect(rel?.timesSummoned == 2)
        // The Captain remembers what was done to the Butcher.
        #expect(ledger.relationship(for: butcher)?.rootKey == rel?.rootKey)
    }

    @Test("Partings carry valence — banishment sours, libation warms")
    func partingsCarryValence() {
        var ledger = RelationshipLedger()
        let spirit = makeSpirit()
        ledger.noteSummon(of: spirit, atTick: 1)
        let anchored = ledger.relationship(for: spirit)?.netValence ?? 0

        ledger.recordDeparture(SpiritDeparture(spirit: spirit, manner: .banished, tick: 2))
        let banished = ledger.relationship(for: spirit)?.netValence ?? 0
        #expect(banished < anchored)

        ledger.noteSummon(of: spirit, atTick: 3)
        ledger.recordDeparture(SpiritDeparture(spirit: spirit, manner: .releasedWithLibation, tick: 4))
        let released = ledger.relationship(for: spirit)?.netValence ?? 0
        #expect(released > banished)
    }

    @Test("Repeated banishment turns a spiteful spirit hostile faster")
    func spitefulSoursFaster() {
        var ledger = RelationshipLedger()
        let spirit = makeSpirit(traits: [.spiteful])
        ledger.noteSummon(of: spirit, atTick: 1)
        ledger.recordDeparture(SpiritDeparture(spirit: spirit, manner: .banished, tick: 2))
        ledger.noteSummon(of: spirit, atTick: 3)
        ledger.recordDeparture(SpiritDeparture(spirit: spirit, manner: .banished, tick: 4))

        let rel = ledger.relationship(for: spirit)!
        #expect(rel.stage(traits: [.spiteful]) == .hostile)
        // The same record against a forgiving personality is merely cold.
        #expect(rel.stage(traits: [.loyal]) != .hostile)
    }

    @Test("Familiarity deepens with summons and conversation")
    func familiarityDeepens() {
        var ledger = RelationshipLedger()
        let spirit = makeSpirit()
        let key = RelationshipLedger.key(for: spirit)

        ledger.noteSummon(of: spirit, atTick: 1)
        #expect(ledger.relationship(for: spirit)?.stage(traits: [.loyal]) == .stranger)

        ledger.noteSummon(of: spirit, atTick: 8)
        #expect(ledger.relationship(for: spirit)?.stage(traits: [.loyal]) == .named)

        ledger.noteSummon(of: spirit, atTick: 15)
        for _ in 0..<4 { ledger.noteExchange(withKey: key) }
        #expect(ledger.relationship(for: spirit)?.stage(traits: [.loyal]) == .acquainted)

        // Respectful partings + a given name + long conversation → bonded.
        ledger.recordDeparture(SpiritDeparture(spirit: spirit, manner: .releasedWithLibation, tick: 16))
        ledger.noteSummon(of: spirit, atTick: 20)
        ledger.record(.gaveTrueName, for: spirit, atTick: 21, detail: "Natan")
        for _ in 0..<5 { ledger.noteExchange(withKey: key) }
        let rel = ledger.relationship(for: spirit)!
        #expect(rel.stage(traits: [.loyal]) == .bonded)
        #expect(rel.nameGiven == "Natan")
    }

    @Test("A resentful spirit never bonds")
    func resentfulNeverBonds() {
        var ledger = RelationshipLedger()
        let spirit = makeSpirit(traits: [.resentful])
        let key = RelationshipLedger.key(for: spirit)
        for tick in 1...6 {
            ledger.noteSummon(of: spirit, atTick: tick)
            ledger.recordDeparture(SpiritDeparture(spirit: spirit, manner: .releasedWithLibation, tick: tick))
        }
        ledger.record(.gaveTrueName, for: spirit, atTick: 7, detail: "Natan")
        for _ in 0..<12 { ledger.noteExchange(withKey: key) }

        let rel = ledger.relationship(for: spirit)!
        #expect(rel.netValence > 1.0)
        #expect(rel.stage(traits: [.resentful]) != .bonded)
    }

    @Test("Call coherence bonus scales with the relationship")
    func callBonusScales() {
        var ledger = RelationshipLedger()
        let spirit = makeSpirit()
        ledger.noteSummon(of: spirit, atTick: 1)
        let strangerBonus = ledger.relationship(for: spirit)!.callCoherenceBonus(traits: [.loyal])

        ledger.noteSummon(of: spirit, atTick: 5)
        ledger.noteSummon(of: spirit, atTick: 9)
        let namedBonus = ledger.relationship(for: spirit)!.callCoherenceBonus(traits: [.loyal])
        #expect(namedBonus > strangerBonus)
    }

    @Test("Invocation confines resolution to the called identity and adds coherence")
    func invocationConfinesAndBoosts() throws {
        let identities = try RidgeOfElah.rootIdentities()
        let hiram = try #require(identities.first { $0.trueName?.contains("Hiram") == true })

        // A weak configuration: bare rib fragment, no name spoken aloud.
        let config = RitualConfiguration(
            remains: Fragment(
                remains: .ribFragment, era: .ironAgeII, domain: .war, affinity: .fire,
                tags: TagConstellation([NarrativeTag(.identity, "soldier")])
            ),
            site: RitualSite(name: "Ridge", type: .battlefield, affinity: .fire),
            trueName: TrueName(hiram.trueName ?? "", partial: false)
        )
        let region = RegionState(name: "Test", stability: 0.8)
        let pipeline = ResolutionPipeline()

        let cold = pipeline.resolve(
            configuration: config, regionState: region,
            profile: PractitionerProfile(), seed: 99, rootIdentities: identities
        )
        let called = pipeline.resolve(
            configuration: config, regionState: region,
            profile: PractitionerProfile(), seed: 99, rootIdentities: identities,
            invocation: RelationalInvocation(rootIdentityID: hiram.id, coherenceBonus: 0.4, valence: 1.0)
        )

        // Same seed, same config: the relationship is the only difference.
        #expect(called.autopsy.contains { $0.contains("The knowing itself was an anchor") })
        if let coldSpirit = cold.spirit, let calledSpirit = called.spirit {
            // When both manifest, the called one must be Hiram's.
            #expect(calledSpirit.rootIdentityID == hiram.id)
            _ = coldSpirit
        }
    }

    @Test("Soured relationships steer resolution toward dark aspects")
    func valenceSteersEpochs() throws {
        let identities = try RidgeOfElah.rootIdentities()
        let hiram = try #require(identities.first { $0.trueName?.contains("Hiram") == true })
        let resolver = EpochResolver()

        // A neutral configuration that slightly favors the Captain.
        let config = RitualConfiguration(
            remains: Fragment(
                remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire,
                tags: TagConstellation([NarrativeTag(.identity, "soldier")])
            ),
            site: RitualSite(name: "Ridge", type: .battlefield, affinity: .fire),
            trueName: TrueName(hiram.trueName ?? "", partial: false)
        )
        let region = RegionState(name: "Test", stability: 0.8)

        let warm = resolver.resolve(
            identity: hiram, configuration: config, regionState: region, relationalValence: 1.0
        )
        let soured = resolver.resolve(
            identity: hiram, configuration: config, regionState: region, relationalValence: -1.5
        )

        #expect(warm?.name == "Bronze Captain")
        #expect(soured?.name == "Ashkelon Butcher", "Banish the Captain often enough and the Butcher answers")
    }

    @Test("Ledger round-trips through the snapshot")
    func ledgerPersists() throws {
        var ledger = RelationshipLedger()
        let spirit = makeSpirit()
        ledger.noteSummon(of: spirit, atTick: 3)
        ledger.record(.gaveTrueName, for: spirit, atTick: 4, detail: "Natan")

        let content = RidgeOfElah.createWorld()
        let snapshot = SinglePlayerSnapshot(
            savedAtTick: 4,
            world: WorldSimulation(regions: [content.region]),
            profile: PractitionerProfile(),
            codex: CodexOfTheDead(),
            sites: content.sites,
            inventory: PractitionerInventorySnapshot(fragments: [], artifacts: [], memoryTraces: [], libations: []),
            currentSiteIndex: 0,
            ritualCount: 1,
            rootIdentities: [],
            npcs: [],
            clock: WorldClock(startingTick: 4),
            relationships: ledger
        )

        let data = try SnapshotStore.encode(snapshot)
        let decoded = try SnapshotStore.decodeSinglePlayerSnapshot(from: data)
        let rel = decoded.relationships?.relationship(for: spirit)
        #expect(rel?.timesSummoned == 1)
        #expect(rel?.nameGiven == "Natan")
    }

    @Test("Chat packets carry relationship memory as concrete facts")
    func packetCarriesMemory() {
        var ledger = RelationshipLedger()
        let spirit = makeSpirit()
        ledger.noteSummon(of: spirit, atTick: 1)
        ledger.recordDeparture(SpiritDeparture(spirit: spirit, manner: .banished, tick: 2))
        ledger.noteSummon(of: spirit, atTick: 5)

        let bound = BoundSpirit(spirit: spirit, anchoredAtTick: 5)
        let packet = PacketAssembler().spiritChatPacket(
            for: bound,
            input: "Do you know me?",
            relationship: ledger.relationship(for: spirit)
        )

        #expect(packet.knownFacts.contains { $0.contains("banished") })
        #expect(packet.knownFacts.contains { $0.contains("called you back 2 times") })
        #expect(packet.trustLevel != nil)
    }
}
