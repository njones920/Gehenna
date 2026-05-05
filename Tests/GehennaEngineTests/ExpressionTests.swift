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
    
    @Test("Validator checks bounds")
    func checksBounds() {
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
        
        let validResult = validator.validate("One two three four five six.", packet: packet)
        let tooShortResult = validator.validate("One two.", packet: packet)
        let tooLongResult = validator.validate("One two three four five six seven eight nine ten eleven.", packet: packet)
        
        switch validResult {
        case .valid: break
        default: Issue.record("Expected valid")
        }
        
        switch tooShortResult {
        case .invalid(_, let issues): 
            #expect(issues.contains(where: { $0.contains("Too short") }))
        default: Issue.record("Expected invalid length")
        }
        
        switch tooLongResult {
        case .invalid(_, let issues):
            #expect(issues.contains(where: { $0.contains("Too long") }))
        default: Issue.record("Expected invalid length")
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
