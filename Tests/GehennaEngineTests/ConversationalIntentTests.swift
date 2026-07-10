import Testing
import Foundation
@testable import GehennaEngine

@Suite("Conversational Intent Tests")
struct ConversationalIntentTests {

    @Test("Heuristics catch unmistakable intents deterministically")
    func heuristicsCatchObviousCases() {
        #expect(ConversationalIntent.heuristic(for: "I promise I will bring wine to your grave") == .promise)
        #expect(ConversationalIntent.heuristic(for: "You have my word, captain.") == .promise)
        #expect(ConversationalIntent.heuristic(for: "Please, tell me of the battle") == .respect)
        #expect(ConversationalIntent.heuristic(for: "Thank you for staying") == .respect)
        #expect(ConversationalIntent.heuristic(for: "I speak with the dead every night") == .reveal)
        #expect(ConversationalIntent.heuristic(for: "What did you eat for breakfast?") == nil)
    }

    @Test("Forbidden topics are matched from taboo tags")
    func forbiddenTopicsMatch() {
        let intent = ConversationalIntent.heuristic(
            for: "Tell me the name of the old country",
            forbiddenTopics: ["the_name_of_the_old_country"]
        )
        #expect(intent == .forbidden)
    }

    @Test("Intents map to spirit moments deterministically")
    func intentMomentMapping() {
        #expect(ConversationalIntent.respect.spiritMoment == .spokeRespectfully)
        #expect(ConversationalIntent.insult.spiritMoment == .insulted)
        #expect(ConversationalIntent.threaten.spiritMoment == .insulted)
        #expect(ConversationalIntent.comfort.spiritMoment == .comforted)
        #expect(ConversationalIntent.promise.spiritMoment == .promiseMade)
        #expect(ConversationalIntent.forbidden.spiritMoment == .askedForbidden)
        #expect(ConversationalIntent.none.spiritMoment == nil)
        #expect(ConversationalIntent.reveal.spiritMoment == nil)
    }

    @Test("Insults erode NPC trust; reveals make witnesses")
    func npcConsequences() throws {
        let npcs = try RidgeOfElah.kfarShalemNPCs()
        var npc = try #require(npcs.first)

        let trustBefore = npc.trust
        let cue = npc.apply(.insult)
        #expect(npc.trust < trustBefore)
        #expect(cue != nil)

        var witness = try #require(npcs.first)
        #expect(!witness.hasWitnessedDirectly)
        _ = witness.apply(.reveal)
        #expect(witness.hasWitnessedDirectly)
        #expect(witness.personalSuspicion > 0.0)
    }

    @Test("Respect and comfort warm an NPC without visible cues")
    func quietWarming() throws {
        let npcs = try RidgeOfElah.kfarShalemNPCs()
        var npc = try #require(npcs.first)
        let trustBefore = npc.trust
        let cue = npc.apply(.respect)
        #expect(npc.trust > trustBefore)
        #expect(cue == nil, "Warming stays beneath the surface — behavior shows it, not narration")
    }

    @Test("Engine classification degrades to none without a model")
    func failSafeWithoutModel() async {
        let engine = ExpressionEngine(llmEnabled: false)
        let intent = await engine.classifyIntent("An utterly ambiguous remark about weather")
        #expect(intent == .none)

        // Heuristics still fire with the LLM disabled.
        let promise = await engine.classifyIntent("I promise to return")
        #expect(promise == .promise)
    }

    @Test("A promise recorded against a spirit persists as a moment with detail")
    func promisePersistsWithDetail() {
        var ledger = RelationshipLedger()
        let spirit = Spirit(
            template: .warrior, tier: .common,
            tags: TagConstellation([NarrativeTag(.identity, "soldier")]),
            era: .ironAgeII, epochName: "Bronze Captain",
            personalityTraits: [.loyal], disposition: .calm,
            attributes: SpiritAttributes(strength: 0.5, knowledge: 0.5, will: 0.5, stability: 0.5, disposition: 0.5)
        )
        ledger.noteSummon(of: spirit, atTick: 1)
        ledger.record(.promiseMade, for: spirit, atTick: 2, detail: "I will bring wine to the ridge")

        let rel = ledger.relationship(for: spirit)!
        let promise = rel.moments.first { $0.kind == .promiseMade }
        #expect(promise?.detail == "I will bring wine to the ridge")
        // A promise made carries no valence — keeping or breaking it will.
        #expect(promise?.valence == 0.0)
    }
}
