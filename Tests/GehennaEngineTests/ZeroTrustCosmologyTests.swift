import Testing
import Foundation
@testable import GehennaEngine

@Suite("Zero-Trust Cosmology Tests")
struct ZeroTrustCosmologyTests {

    let pipeline = ResolutionPipeline()

    func stableRegion() -> RegionState {
        RegionState(name: "Test Region", stability: 0.8)
    }

    @Test("Spirit rejects corrupted practitioner")
    func spiritRejectsCorruptedPractitioner() {
        // A prophet requires at least 0.6 purity
        let config = RitualConfiguration(
            remains: Fragment(
                remains: .longBone, era: .ironAgeII, domain: .faith, affinity: .silence,
                tags: TagConstellation([NarrativeTag(.identity, "seer")])
            ),
            site: RitualSite(name: "High Place", type: .collapsingTemple, affinity: .silence)
        )

        // Setup a practitioner who passes Authority (effectivePurity > 0.2)
        // but fails the Prophet's purity requirement (effectivePurity < 0.6)
        var profile = PractitionerProfile()
        profile.tokens.purity = 0.5
        profile.tokens.corpseContagion = 0.1 // Effective purity = 0.4

        let result = pipeline.resolve(
            configuration: config,
            regionState: stableRegion(),
            profile: profile,
            seed: 12345
        )

        // Effective purity 0.4 < prophet's minimum 0.6 → verification fails
        // But conflict is not high and purity is not below 0.3, so → .failure
        #expect(result.outcomeClass == .failure, "Prophet should refuse impure practitioner")
        #expect(result.spirit == nil, "Spirit should not manifest when verification fails")
        
        let autopsyHasRejection = result.autopsy.contains { $0.contains("Verification Failed") }
        #expect(autopsyHasRejection, "Autopsy should contain the verification failure reason")
    }

    @Test("Warden rejects practitioner who broke grave robbing taboo")
    func wardenRejectsGraveRobber() {
        // Create a warden epoch with explicit graveRobbing taboo
        let wardenEpoch = Epoch(
            name: "Tomb Keeper",
            template: .warden,
            era: .ironAgeII,
            domain: .death,
            triggerTags: ["keeper"],
            identityRequirements: IdentityRequirements(forbiddenTaboos: [.graveRobbing])
        )

        let identity = RootIdentity(
            trueName: "The Keeper of Elah",
            coreTags: TagConstellation([NarrativeTag(.identity, "keeper")]),
            epochs: [wardenEpoch],
            nativeEra: .ironAgeII,
            culture: "Canaanite"
        )

        let config = RitualConfiguration(
            remains: Fragment(
                remains: .skull, era: .ironAgeII, domain: .death, affinity: .earth,
                tags: TagConstellation([NarrativeTag(.identity, "keeper")])
            ),
            site: RitualSite(name: "Burial Cave", type: .burialCave, affinity: .earth)
        )

        var profile = PractitionerProfile()
        profile.tokens.purity = 0.9 // High purity, but broke a taboo
        profile.taboosBroken.insert(.graveRobbing)

        let result = pipeline.resolve(
            configuration: config,
            regionState: stableRegion(),
            profile: profile,
            seed: 67890,
            rootIdentities: [identity]
        )

        #expect(result.outcomeClass == OutcomeClass.failure || result.outcomeClass == OutcomeClass.hostile, "Warden should reject grave robber")
        #expect(result.spirit == nil, "Spirit should not manifest")
    }

    @Test("Clean Hands practitioner unlocks special epoch")
    func cleanHandsUnlocksSpecialEpoch() {
        // Create an epoch that specifically requires Clean Hands
        let pureEpoch = Epoch(
            name: "The Nameless Shield-Bearer",
            template: .guardian,
            era: .ironAgeII,
            domain: .war,
            triggerTags: ["guardian"],
            identityRequirements: IdentityRequirements(requiresCleanHands: true)
        )

        // coreTags must overlap with the ritual configuration's tags
        // for epoch resolution (Stage 11.5) to match this identity
        let identity = RootIdentity(
            trueName: "Unknown",
            coreTags: TagConstellation([NarrativeTag(.identity, "guardian")]),
            epochs: [pureEpoch],
            nativeEra: .ironAgeII,
            culture: "Highlander"
        )

        let config = RitualConfiguration(
            remains: Fragment(
                remains: .longBone, era: .ironAgeII, domain: .war, affinity: .earth,
                tags: TagConstellation([NarrativeTag(.identity, "guardian")])
            ),
            site: RitualSite(name: "Battlefield", type: .battlefield, affinity: .earth)
        )

        // 1. Clean Profile
        let cleanProfile = PractitionerProfile() // Default init has 0 rituals and no taboos
        let cleanResult = pipeline.resolve(
            configuration: config,
            regionState: stableRegion(),
            profile: cleanProfile,
            seed: 11111,
            rootIdentities: [identity]
        )
        
        #expect(cleanResult.spirit != nil, "Clean practitioner should manifest the epoch")
        #expect(cleanResult.spirit?.epochName == "The Nameless Shield-Bearer")

        // 2. Veteran Profile (No longer clean)
        var veteranProfile = PractitionerProfile()
        veteranProfile.totalRituals = 50 // Hands are no longer clean
        
        let veteranResult = pipeline.resolve(
            configuration: config,
            regionState: stableRegion(),
            profile: veteranProfile,
            seed: 11111,
            rootIdentities: [identity]
        )

        #expect(veteranResult.spirit == nil, "Veteran practitioner should be rejected by Clean Hands epoch")
        #expect(veteranResult.outcomeClass == OutcomeClass.failure || veteranResult.outcomeClass == OutcomeClass.hostile)
    }
}
