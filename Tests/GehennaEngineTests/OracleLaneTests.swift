import Testing
import Foundation
@testable import GehennaEngine

@Suite("Oracle Lane Tests")
struct OracleLaneTests {

    func makeSpirit(rootIdentityID: UUID? = nil) -> Spirit {
        Spirit(
            template: .warrior, tier: .common,
            tags: TagConstellation([NarrativeTag(.identity, "soldier")]),
            era: .ironAgeII, epochName: "Bronze Captain",
            rootIdentityID: rootIdentityID,
            personalityTraits: [.loyal], disposition: .calm,
            attributes: SpiritAttributes(strength: 0.5, knowledge: 0.5, will: 0.5, stability: 0.5, disposition: 0.5)
        )
    }

    @Test("Spoken claims are recorded, deduplicated, and capped")
    func spokenClaimsRecorded() {
        var ledger = RelationshipLedger()
        let spirit = makeSpirit()
        let key = RelationshipLedger.key(for: spirit)
        ledger.noteSummon(of: spirit, atTick: 1)

        ledger.recordSpokenClaims(["Hiram's sergeant Ittai fell at the west wall"], forKey: key)
        ledger.recordSpokenClaims(["Hiram's sergeant Ittai fell at the west wall"], forKey: key)
        ledger.recordSpokenClaims(["Hiram served the seren of Gath"], forKey: key)

        let claims = ledger.relationship(forKey: key)?.spokenClaims ?? []
        #expect(claims.count == 2)

        // The cap holds against a talkative shade.
        for i in 0..<40 {
            ledger.recordSpokenClaims(["claim number \(i)"], forKey: key)
        }
        #expect((ledger.relationship(forKey: key)?.spokenClaims ?? []).count <= 24)
    }

    @Test("Spoken canon re-enters conversation packets as memory")
    func claimsReenterPackets() {
        var ledger = RelationshipLedger()
        let spirit = makeSpirit()
        let key = RelationshipLedger.key(for: spirit)
        ledger.noteSummon(of: spirit, atTick: 1)
        ledger.recordSpokenClaims(["Hiram's sergeant Ittai fell at the west wall"], forKey: key)

        let packet = PacketAssembler().spiritChatPacket(
            for: BoundSpirit(spirit: spirit, anchoredAtTick: 1),
            input: "Tell me of your men.",
            relationship: ledger.relationship(forKey: key)
        )
        #expect(packet.knownFacts.contains { $0.contains("you have said before") && $0.contains("Ittai") })
    }

    @Test("Spoken claims survive the snapshot")
    func claimsPersist() throws {
        var ledger = RelationshipLedger()
        let spirit = makeSpirit()
        let key = RelationshipLedger.key(for: spirit)
        ledger.noteSummon(of: spirit, atTick: 1)
        ledger.recordSpokenClaims(["Hiram served the seren of Gath"], forKey: key)

        let content = RidgeOfElah.createWorld()
        let snapshot = SinglePlayerSnapshot(
            savedAtTick: 1,
            world: WorldSimulation(regions: [content.region]),
            profile: PractitionerProfile(),
            codex: CodexOfTheDead(),
            sites: content.sites,
            inventory: PractitionerInventorySnapshot(fragments: [], artifacts: [], memoryTraces: [], libations: []),
            currentSiteIndex: 0, ritualCount: 0, rootIdentities: [], npcs: [],
            clock: WorldClock(startingTick: 1),
            relationships: ledger
        )
        let decoded = try SnapshotStore.decodeSinglePlayerSnapshot(from: SnapshotStore.encode(snapshot))
        #expect(decoded.relationships?.relationship(forKey: key)?.spokenClaims == ["Hiram served the seren of Gath"])
    }

    @Test("Codex entries accumulate what the spirit spoke of")
    func codexAnnotation() {
        var codex = CodexOfTheDead()
        let rootID = UUID()
        let spirit = makeSpirit(rootIdentityID: rootID)
        _ = codex.recordEncounter(spirit: spirit, autopsy: [], ritualID: UUID(), tick: 1)

        codex.annotate(rootIdentityID: rootID, epochName: nil, note: "Spoke of: his sergeant Ittai, fallen at the west wall")
        codex.annotate(rootIdentityID: rootID, epochName: nil, note: "Spoke of: his sergeant Ittai, fallen at the west wall")

        let entry = codex.entries.values.first { $0.rootIdentityID == rootID }
        #expect(entry?.notes.filter { $0.contains("Ittai") }.count == 1)
    }

    @Test("Proposal validation gates the Conway lane")
    func proposalValidation() {
        let names = ["Devorah", "Baruk"]

        let good = WorldEventProposal(kind: .npcAction, actor: "Devorah", text: "Devorah left herbs at the shrine before first light.")
        #expect(ProposalValidator.validate(good, npcNames: names))

        let unknownActor = WorldEventProposal(kind: .npcAction, actor: "Nobody", text: "Nobody did a thing that was reasonably long.")
        #expect(!ProposalValidator.validate(unknownActor, npcNames: names))

        let tooShort = WorldEventProposal(kind: .omen, actor: nil, text: "Birds flew.")
        #expect(!ProposalValidator.validate(tooShort, npcNames: names))

        let tooLong = WorldEventProposal(kind: .rumor, actor: nil, text: String(repeating: "word ", count: 50))
        #expect(!ProposalValidator.validate(tooLong, npcNames: names))
    }

    @Test("Proposal parsing extracts JSON from model chatter and fails safe")
    func proposalParsing() {
        let chatty = """
        Here is the event:
        {"kind": "omen", "actor": null, "text": "The spring ran cloudy for a morning and cleared by dusk."}
        Hope that helps!
        """
        let parsed = ProposalValidator.parse(chatty)
        #expect(parsed?.kind == .omen)
        #expect(parsed?.text.contains("spring") == true)

        #expect(ProposalValidator.parse("no json here") == nil)
        #expect(ProposalValidator.parse("{\"kind\": \"conquest\", \"text\": \"invalid kind\"}") == nil)
    }
}
