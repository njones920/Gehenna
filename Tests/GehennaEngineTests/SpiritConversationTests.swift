import Testing
import Foundation
@testable import GehennaEngine

@Suite("Spirit Conversation Tests")
struct SpiritConversationTests {

    let assembler = PacketAssembler()

    func makeSpirit(
        knowledge: Double = 0.8,
        epochName: String? = "Bronze Captain",
        rootIdentityID: UUID? = nil,
        tags: TagConstellation = TagConstellation([
            NarrativeTag(.identity, "soldier"),
            NarrativeTag(.identity, "captain"),
            NarrativeTag(.deathContext, "battle"),
            NarrativeTag(.relational, "served_a_lord"),
            NarrativeTag(.cultural, "Ashkelon"),
            NarrativeTag(.taboo, "the_name_of_the_old_country")
        ])
    ) -> Spirit {
        Spirit(
            template: .warrior,
            tier: .uncommon,
            tags: tags,
            era: .ironAgeII,
            epochName: epochName,
            rootIdentityID: rootIdentityID,
            personalityTraits: [.prideful, .loyal],
            disposition: .calm,
            attributes: SpiritAttributes(
                strength: 0.6, knowledge: knowledge, will: 0.5,
                stability: 0.5, disposition: 0.5
            )
        )
    }

    @Test("Chat packet carries practitioner input and exchange history")
    func chatPacketCarriesInput() {
        var bound = BoundSpirit(spirit: makeSpirit(), anchoredAtTick: 0)
        bound.exchangeCount = 3

        let packet = assembler.spiritChatPacket(for: bound, input: "Who did you serve?")
        #expect(packet.eventType == .spiritChat)
        #expect(packet.practitionerInput == "Who did you serve?")
        #expect(packet.interactionHistory == 3)
        #expect(packet.entityName == "Bronze Captain")
    }

    @Test("Knowledge gates how many facts the dead can reach")
    func knowledgeGatesFacts() {
        let dim = BoundSpirit(spirit: makeSpirit(knowledge: 0.1), anchoredAtTick: 0)
        let sharp = BoundSpirit(spirit: makeSpirit(knowledge: 0.9), anchoredAtTick: 0)

        let dimFacts = assembler.spiritChatPacket(for: dim, input: "Tell me of your life.").knownFacts
        let sharpFacts = assembler.spiritChatPacket(for: sharp, input: "Tell me of your life.").knownFacts

        #expect(dimFacts.count == 4)
        #expect(sharpFacts.count > dimFacts.count)
    }

    @Test("Taboo tags become forbidden topics")
    func tabooTagsForbidden() {
        let bound = BoundSpirit(spirit: makeSpirit(), anchoredAtTick: 0)
        let packet = assembler.spiritChatPacket(for: bound, input: "Where do you come from?")
        #expect(packet.forbiddenTopics.contains("the_name_of_the_old_country"))
    }

    @Test("Root identity supplies true name and epoch interiority")
    func rootIdentitySuppliesInteriority() throws {
        let identities = try RidgeOfElah.rootIdentities()
        let hiram = try #require(identities.first { $0.trueName?.contains("Hiram") == true })
        let spirit = makeSpirit(rootIdentityID: hiram.id)
        let bound = BoundSpirit(spirit: spirit, anchoredAtTick: 0)

        let packet = assembler.spiritChatPacket(for: bound, input: "What do you count?", rootIdentity: hiram)
        #expect(packet.knownFacts.contains { $0.contains("Hiram") })
        #expect(packet.interiorVoice != nil)
        #expect(packet.wound?.contains("sons") == true)
    }

    @Test("Canon epochs decode interiority blocks")
    func canonInteriorityDecodes() throws {
        let identities = try RidgeOfElah.rootIdentities()
        let maacah = try #require(identities.first { $0.trueName == "Maacah" })
        let silenced = try #require(maacah.epochs.first { $0.name == "The Silenced Devotee" })
        #expect(silenced.interiorVoice != nil)
        #expect(silenced.privateTruth != nil)
        #expect(silenced.wound != nil)
        #expect(silenced.unsatisfiedWant != nil)

        // Epochs without authored interiority decode as nil, not as failures.
        let founder = identities.first { $0.epochs.contains { $0.name == "The Founder" } }
        let founderEpoch = founder?.epochs.first { $0.name == "The Founder" }
        #expect(founderEpoch != nil)
        #expect(founderEpoch?.interiorVoice == nil)
    }

    @Test("Conversation strains the spirit and can spend it")
    func exchangeStrainsSpirit() {
        var retinue = Retinue()
        let spirit = makeSpirit()
        retinue.anchor(spirit, atTick: 0, capacity: 1)

        let before = retinue.boundSpirit(withID: spirit.id)?.spirit.currentStability ?? 0
        let departure = retinue.recordExchange(with: spirit.id, atTick: 1)
        let after = retinue.boundSpirit(withID: spirit.id)?.spirit.currentStability ?? 0

        #expect(departure == nil)
        #expect(after < before)
        #expect(retinue.boundSpirit(withID: spirit.id)?.exchangeCount == 1)

        // Talk it to death: 0.5 stability / 0.015 per exchange ≈ 33 exchanges.
        var fade: SpiritDeparture?
        for tick in 2...40 {
            if let d = retinue.recordExchange(with: spirit.id, atTick: tick) {
                fade = d
                break
            }
        }
        #expect(fade?.manner == .faded)
        #expect(retinue.isEmpty)
    }
}
