import Testing
import Foundation
@testable import GehennaEngine

@Suite("Expression Cache Tests")
struct ExpressionCacheTests {
    @Test("Cache stores and retrieves by packet hash")
    func cacheStorage() async {
        let cache = ExpressionCache()
        let tags = TagConstellation([NarrativeTag(.identity, "warrior")])
        let packet = LightExpressionPacket(
            entityType: .npc,
            entityName: "Test",
            entityTags: tags,
            disposition: "neutral",
            trustLevel: 0.5,
            eventType: .greeting,
            culture: "highland_village"
        )
        
        await cache.set("Hello", for: packet)
        let retrieved = await cache.get(for: packet)
        #expect(retrieved == "Hello")
        
        await cache.clear()
        let cleared = await cache.get(for: packet)
        #expect(cleared == nil)
    }
}

@Suite("Expression Validator Tests")
struct ExpressionValidatorTests {
    @Test("Validator catches forbidden topics")
    func catchesForbiddenTopics() {
        let validator = ExpressionValidator()
        let tags = TagConstellation([])
        let packet = FullExpressionPacket(
            entityType: .spirit,
            entityName: "Shade",
            entityTags: tags,
            disposition: "neutral",
            trustLevel: nil,
            eventType: .spiritSpeech,
            culture: nil,
            suspicionLevel: nil,
            isAtThreshold: false,
            era: .ironAgeII,
            registerKey: "spare",
            knownFacts: [],
            forbiddenTopics: ["Yahweh", "the old country"],
            allowedLengthMin: 1,
            allowedLengthMax: 50,
            interactionHistory: 0,
            recentEvents: []
        )
        
        let validText = "I see nothing here."
        let invalidText = "I worship Yahweh."
        
        let validResult = validator.validate(validText, packet: packet)
        let invalidResult = validator.validate(invalidText, packet: packet)
        
        switch validResult {
        case .valid: break
        default: Issue.record("Expected valid")
        }
        
        switch invalidResult {
        case .invalid(_, let issues):
            #expect(issues.contains(where: { $0.lowercased().contains("yahweh") }))
        default: Issue.record("Expected invalid")
        }
    }
    
    @Test("Validator accepts any non-empty text regardless of word count")
    func lengthIsNotEnforced() {
        // Length validation was removed deliberately:
        // - LLMs are unreliable at counting words.
        // - numPredict (token cap) in OllamaProvider handles the actual budget.
        // - Post-hoc rejection of slightly long/short text only causes fallbacks,
        //   not better output. Let the model breathe naturally.
        let validator = ExpressionValidator()
        let tags = TagConstellation([])
        let packet = FullExpressionPacket(
            entityType: .spirit,
            entityName: "Shade",
            entityTags: tags,
            disposition: "neutral",
            trustLevel: nil,
            eventType: .spiritSpeech,
            culture: nil,
            suspicionLevel: nil,
            isAtThreshold: false,
            era: .ironAgeII,
            registerKey: "spare",
            knownFacts: [],
            forbiddenTopics: [],
            allowedLengthMin: 5,
            allowedLengthMax: 10,
            interactionHistory: 0,
            recentEvents: []
        )

        // All three pass — length is not the validator's job.
        let short  = validator.validate("One two.", packet: packet)
        let medium = validator.validate("One two three four five six.", packet: packet)
        let long   = validator.validate("One two three four five six seven eight nine ten eleven.", packet: packet)

        switch short  { case .valid: break; default: Issue.record("Expected valid for short text") }
        switch medium { case .valid: break; default: Issue.record("Expected valid for medium text") }
        switch long   { case .valid: break; default: Issue.record("Expected valid for long text") }

        // Empty text still fails.
        let empty = validator.validate("", packet: packet)
        switch empty {
        case .invalid(_, let issues):
            #expect(issues.contains(where: { $0.contains("empty") }))
        default: Issue.record("Expected invalid for empty text")
        }
    }
}

@Suite("Practitioner Input Tests")
struct PractitionerInputTests {

    @Test("Packet assembler includes practitionerInput in full packet")
    func assemblerIncludesInput() {
        let assembler = PacketAssembler()
        let npc = NPC(
            name: "Yoel",
            role: "Elder",
            faction: .elders,
            register: VoiceRegister(style: .vernacular),
            interiority: NPCInteriority(
                interiorVoice: "He remembers the old ways.",
                privateTruth: "The dead speak louder than the living.",
                unsatisfiedWant: "Peace.",
                wound: "His daughter's death.",
                threshold: "Confronted with proof of the unseen."
            )
        )
        let packet = assembler.fullPacket(
            for: npc,
            event: .playerChat,
            practitionerInput: "Where are the bones of your fathers?"
        )
        #expect(packet.practitionerInput == "Where are the bones of your fathers?")
        #expect(packet.eventType == ExpressionEvent.playerChat)
    }

    @Test("Cache key changes with different practitioner input")
    func cacheKeyDistinguishesInput() async {
        let cache = ExpressionCache()
        let tags = TagConstellation([])
        let packet1 = FullExpressionPacket(
            entityType: .npc,
            entityName: "Yoel",
            entityTags: tags,
            eventType: .playerChat,
            practitionerInput: "Tell me about the dead."
        )
        let packet2 = FullExpressionPacket(
            entityType: .npc,
            entityName: "Yoel",
            entityTags: tags,
            eventType: .playerChat,
            practitionerInput: "Where is the nearest shrine?"
        )

        await cache.set("Response about the dead.", for: packet1)
        await cache.set("Response about shrines.", for: packet2)

        let retrieved1 = await cache.get(for: packet1)
        let retrieved2 = await cache.get(for: packet2)

        #expect(retrieved1 == "Response about the dead.")
        #expect(retrieved2 == "Response about shrines.")
        #expect(retrieved1 != retrieved2)
    }

    @Test("Validator does not false-positive on practitioner words in forbidden topics")
    func validatorIgnoresPractitionerInput() {
        // The validator checks the NPC's *response*, not the practitioner's input.
        // If "Yahweh" is forbidden and the practitioner said "Yahweh", that's fine —
        // the NPC's response is what matters.
        let validator = ExpressionValidator()
        let tags = TagConstellation([])
        let packet = FullExpressionPacket(
            entityType: .npc,
            entityName: "Baruk",
            entityTags: tags,
            eventType: .playerChat,
            forbiddenTopics: ["Yahweh"],
            practitionerInput: "Tell me about Yahweh."
        )

        // The NPC's response does not mention Yahweh — should pass.
        let result = validator.validate("I know nothing of what you ask, stranger.", packet: packet)
        switch result {
        case .valid: break
        default: Issue.record("Expected valid — the NPC didn't mention the forbidden topic")
        }
    }
}

@Suite("Ollama Live Tests")
struct OllamaLiveTests {
    @Test("Test live Ollama connection")
    func testOllamaLive() async throws {
        let provider = OllamaProvider()
        let isAvailable = await provider.isAvailable
        print("Ollama available: \(isAvailable)")
        
        let tags = TagConstellation([NarrativeTag(.identity, "warrior")])
        let packet = LightExpressionPacket(
            entityType: .npc,
            entityName: "TestNPC",
            entityTags: tags,
            disposition: "neutral",
            trustLevel: 0.5,
            eventType: .greeting,
            culture: "highland_village"
        )
        
        let result = await provider.generate(from: packet)
        switch result {
        case .generated(let text):
            print("Generated: \(text)")
        case .validationFailed(let text, let reason):
            print("Validation Failed for text '\(text)': \(reason)")
        case .unavailable(let err):
            print("Unavailable: \(err)")
        }
    }
}
