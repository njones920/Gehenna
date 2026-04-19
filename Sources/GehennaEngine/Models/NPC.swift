// MARK: - NPC Model
// NPCs are not behavioral specifications. They are people. (v3 §5.7)
//
// It is tempting — and it is a trap — to model NPCs as variable configurations.
// A simulation engine that treats an NPC as a state machine produces NPCs who
// feel like state machines. The mechanical layer is necessary. It is not sufficient.
//
// Every named NPC needs:
// - An interior voice — how they narrate their own life to themselves
// - A private truth — something true about them the practitioner may never learn
// - A want the system cannot satisfy — something beyond their mechanical function
// - A wound — what shaped them before the practitioner arrived
// - A register — how they speak, what they reference, what they avoid
// - A threshold — what would break them open

import Foundation

/// The faction an NPC belongs to — determines their social role and suspicion response.
public enum Faction: String, Codable, Hashable, Sendable {
    case elders          // the village leadership, conservative, protective
    case traders         // merchant class, pragmatic, information-connected
    case priesthood      // religious authority, hostile to necromancy, network of informants
}

/// An NPC's voice register — how they speak, drawn from culture, role, and personality.
public struct VoiceRegister: Codable, Hashable, Sendable {
    /// The vocabulary range and cadence this NPC uses.
    public let style: Style

    /// Topics this NPC references naturally in conversation.
    public let references: [String]

    /// Topics this NPC actively avoids.
    public let avoids: [String]

    public enum Style: String, Codable, Hashable, Sendable {
        case formal       // precise, measured, official
        case vernacular   // common speech, earthy, practical
        case priestly     // ritualistic language, indirect, authoritative
        case merchant     // transactional, evaluating, worldly
        case guarded      // terse, evasive, watching
        case warm         // open, generous, familial
    }

    public init(
        style: Style,
        references: [String] = [],
        avoids: [String] = []
    ) {
        self.style = style
        self.references = references
        self.avoids = avoids
    }
}

/// The interiority of a named NPC — what makes them a person, not a state machine.
public struct NPCInteriority: Codable, Hashable, Sendable {
    /// How they narrate their own life to themselves.
    /// This is what the Expression Layer draws on to render their voice.
    public let interiorVoice: String

    /// Something true about them the practitioner may never learn.
    public let privateTruth: String

    /// Something they want that the system cannot satisfy.
    public let unsatisfiedWant: String

    /// What shaped them before the practitioner arrived.
    public let wound: String

    /// What would break them open — the condition under which they reveal depth.
    public let threshold: String

    public init(
        interiorVoice: String,
        privateTruth: String,
        unsatisfiedWant: String,
        wound: String,
        threshold: String
    ) {
        self.interiorVoice = interiorVoice
        self.privateTruth = privateTruth
        self.unsatisfiedWant = unsatisfiedWant
        self.wound = wound
        self.threshold = threshold
    }
}

/// A named NPC in the world with behavioral state and authored interiority.
public struct NPC: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let role: String
    public let faction: Faction

    // -- Behavioral Layer (mechanical) --
    /// Trust toward the practitioner. Starts neutral.
    public var trust: Double

    /// How suspicious this NPC is of the practitioner's real activities.
    public var personalSuspicion: Double

    /// Whether this NPC has witnessed or heard about necromantic activity.
    public var hasHeardRumors: Bool

    /// Whether this NPC has directly witnessed the practitioner practicing.
    public var hasWitnessedDirectly: Bool

    /// Voice register for the Expression Layer.
    public let register: VoiceRegister

    /// Narrative tags for procedural generation of unnamed NPCs.
    public let tags: TagConstellation

    // -- Interiority Layer (authored) --
    /// The inner life that makes this NPC a person.
    public let interiority: NPCInteriority

    // -- Temporal State --
    /// When the practitioner last interacted with this NPC.
    public var lastInteractionTick: Int?

    public init(
        id: UUID = UUID(),
        name: String,
        role: String,
        faction: Faction,
        trust: Double = 0.5,
        personalSuspicion: Double = 0.0,
        hasHeardRumors: Bool = false,
        hasWitnessedDirectly: Bool = false,
        register: VoiceRegister,
        tags: TagConstellation = TagConstellation(),
        interiority: NPCInteriority
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.faction = faction
        self.trust = trust
        self.personalSuspicion = personalSuspicion
        self.hasHeardRumors = hasHeardRumors
        self.hasWitnessedDirectly = hasWitnessedDirectly
        self.register = register
        self.tags = tags
        self.interiority = interiority
        self.lastInteractionTick = nil
    }

    // MARK: - Behavioral Methods

    /// Process a rumor reaching this NPC. Suspicion increases;
    /// how much depends on their faction and existing trust.
    public mutating func hearRumor(strength: Double = 0.1) {
        hasHeardRumors = true
        let factionMultiplier: Double = switch faction {
        case .priesthood: 1.5  // priests are primed to notice
        case .elders:     1.2  // elders protect the community
        case .traders:    0.7  // traders are pragmatic
        }
        personalSuspicion = min(1.0, personalSuspicion + strength * factionMultiplier)
        trust = max(0.0, trust - strength * 0.3)
    }

    /// Process a positive interaction — trade, conversation, aid.
    public mutating func positiveInteraction(strength: Double = 0.1) {
        trust = min(1.0, trust + strength)
        // Positive interactions reduce suspicion slightly, but never below what was witnessed
        if !hasWitnessedDirectly {
            personalSuspicion = max(0.0, personalSuspicion - strength * 0.2)
        }
    }

    /// The NPC sees the practitioner doing something suspicious.
    public mutating func witnessActivity(severity: Double = 0.3) {
        hasWitnessedDirectly = true
        personalSuspicion = min(1.0, personalSuspicion + severity)
        trust = max(0.0, trust - severity * 0.5)
    }

    /// Per-tick state processing. Called by the world clock.
    /// Suspicion and trust drift slowly when the practitioner isn't interacting.
    public mutating func tickState() {
        // Suspicion from rumors fades very slowly (not from direct witnessing)
        if !hasWitnessedDirectly && personalSuspicion > 0 {
            personalSuspicion = max(0.0, personalSuspicion - 0.002)
        }

        // Trust drifts toward neutral (0.5) very slowly when not interacting
        if trust > 0.55 {
            trust = max(0.5, trust - 0.001)
        } else if trust < 0.45 {
            trust = min(0.5, trust + 0.001)
        }
    }

    /// Whether this NPC would refuse to interact with the practitioner.
    public var isRefusing: Bool {
        personalSuspicion > 0.7 && trust < 0.3
    }

    /// Whether this NPC would seek the practitioner out.
    /// High trust + some suspicion = they want to talk. Threshold proximity = they need to.
    public var wouldApproach: Bool {
        (trust > 0.75 && personalSuspicion > 0.2) || isAtThreshold
    }

    /// Whether this NPC would leave a location the practitioner enters.
    /// Very high suspicion + low trust = flee on sight.
    public var wouldFlee: Bool {
        personalSuspicion > 0.8 && trust < 0.2
    }

    /// Whether this NPC has reached their threshold — the condition under
    /// which their interiority breaks through and they reveal depth.
    /// This is a narrative opportunity, not a mechanical state.
    public var isAtThreshold: Bool {
        // Thresholds are crossed when trust is very high OR suspicion is very high
        // Combined with specific conditions described in their interiority.threshold
        trust > 0.85 || (personalSuspicion > 0.8 && trust > 0.4)
    }

    /// Behavioral descriptor for diegetic display — no numbers.
    public var behaviorDescription: String {
        if isRefusing {
            return "Steps back. Won't meet your eyes."
        } else if hasWitnessedDirectly {
            return "Watches you carefully. Something has changed in the way they see you."
        } else if personalSuspicion > 0.5 {
            return "Guarded. The easy warmth is gone."
        } else if hasHeardRumors {
            return "Polite but careful. Something they've heard has made them cautious."
        } else if trust > 0.7 {
            return "Open. Willing to talk. There is a warmth here that isn't forced."
        } else {
            return "Neutral. A stranger to a stranger."
        }
    }

    /// Stable-enough local salt for deterministic director scheduling.
    public var stableEventSalt: Int {
        name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
    }
}

// MARK: - Kfar Shalem NPCs

/// The six named NPCs of Kfar Shalem — the village social zone in the Ridge of Elah.
extension RidgeOfElah {

    public static func kfarShalemNPCs() -> [NPC] {
        [
            abiGad(),
            tamarBatYoav(),
            huramTheTrader(),
            yoelBenShimri(),
            devorah(),
            barukTheSmith()
        ]
    }

    /// Abi-Gad — village elder, head of the three families. Faction: Elders.
    public static func abiGad() -> NPC {
        NPC(
            name: "Abi-Gad",
            role: "Village Elder",
            faction: .elders,
            register: VoiceRegister(
                style: .formal,
                references: ["the old ways", "the families", "the hill country", "the covenant"],
                avoids: ["the dead", "the caves", "the night work"]
            ),
            tags: TagConstellation([
                NarrativeTag(.identity, "elder"),
                NarrativeTag(.identity, "Israelite"),
                NarrativeTag(.cultural, "highland_clan"),
                NarrativeTag(.disposition, "duty"),
            ]),
            interiority: NPCInteriority(
                interiorVoice: "I hold the families together because no one else will. The hill country is hard and the Philistines are close and the young ones do not understand what it costs to keep a village standing for three generations. I was not made for this. I was a younger son. But the elder brothers went to the wars and did not come back, and so here I am, and I will hold it until I cannot.",
                privateTruth: "He visited. Once. When his wife was dying and the physician from Lachish could not help. He went to the cave above the wadi and tried to speak to his dead mother. Nothing answered. He has never told anyone. He has never tried again. But he knows, now, what desperation feels like, and he recognizes it in others.",
                unsatisfiedWant: "He wants his eldest son to come home from Gath. The son went to trade and stayed. The son is alive and well and does not write. Abi-Gad will not say this.",
                wound: "The elder brothers who went to the wars. He was not good enough to go with them. He was the one who stayed. He has never forgiven himself for surviving.",
                threshold: "If the practitioner discovers the midnight visit — if they find evidence of his attempt — he will break open. Not with rage. With relief. Someone else knows."
            )
        )
    }

    /// Tamar bat Yoav — the baker. Faction: Elders.
    public static func tamarBatYoav() -> NPC {
        NPC(
            name: "Tamar bat Yoav",
            role: "Baker",
            faction: .elders,
            trust: 0.6,  // slightly more open initially
            register: VoiceRegister(
                style: .warm,
                references: ["the children", "the harvest", "the bread", "the morning"],
                avoids: ["the war", "the Philistines", "things in the dark"]
            ),
            tags: TagConstellation([
                NarrativeTag(.identity, "adult_woman"),
                NarrativeTag(.identity, "Israelite"),
                NarrativeTag(.cultural, "highland_clan"),
                NarrativeTag(.disposition, "warmth"),
            ]),
            interiority: NPCInteriority(
                interiorVoice: "The bread rises or it does not. The flour is good or it is not. I have made bread every morning for twenty years and the simplicity of it is the thing that keeps me. The village talks and schemes and worries and I make bread. When the bread rises, the morning is good. I am not simple. I choose to do the simple thing because the complicated things are what kill people.",
                privateTruth: "She sees more than anyone thinks. She noticed the stranger carrying bone in their satchel. She noticed the oil lamp missing from the common store. She has not said anything because she is watching, and because she is not yet sure what she has seen.",
                unsatisfiedWant: "She wants to know what happens after. Whether the dead are somewhere. Whether her mother is somewhere. She would never ask the practitioner directly. But if someone she trusted said the dead can speak, she would listen.",
                wound: "Her mother died in the rains last spring. There was no one to sit with her at the end because Tamar was at the ovens. She arrived too late by the time it takes bread to cool.",
                threshold: "If the practitioner brings her something that belonged to her mother — even unknowingly, even a potsherd from the era and culture that matches — she will recognize it. And she will ask a question she has never asked anyone."
            )
        )
    }

    /// Huram the Trader — caravan middleman. Faction: Traders.
    public static func huramTheTrader() -> NPC {
        NPC(
            name: "Huram",
            role: "Trader",
            faction: .traders,
            register: VoiceRegister(
                style: .merchant,
                references: ["the coast road", "Ashkelon", "copper", "wine jars", "the Egyptians"],
                avoids: ["his family", "debts", "what he carries for others"]
            ),
            tags: TagConstellation([
                NarrativeTag(.identity, "trader"),
                NarrativeTag(.identity, "mixed_heritage"),
                NarrativeTag(.cultural, "coast_and_hills"),
                NarrativeTag(.disposition, "pragmatism"),
            ]),
            interiority: NPCInteriority(
                interiorVoice: "I move things from where they are to where they are wanted, and I take a portion. This is the oldest profession that isn't. I speak to Philistines in their tongue and to Israelites in theirs and to Egyptians in the trade pidgin and I am none of these things and all of them. A trader is the ghost of a person — present everywhere, belonging nowhere.",
                privateTruth: "He smuggles. Not just goods. Information. He carries messages between the coastal cities and the hill country, and some of those messages concern troop movements, and some of those messages have gotten people killed. He does not think about this if he can help it.",
                unsatisfiedWant: "He wants to stop. He wants a farm. A hill with olives. He wants to be from somewhere. He will never have this because the trade is the only thing he is good at and the debts never end.",
                wound: "He had a partner once. The partner was caught smuggling by the Philistine garrison at Ekron. Huram was not caught. He did not try to help. The partner's family does not know where Huram is.",
                threshold: "If the practitioner discovers his smuggling — or better, if the practitioner needs something moved that legitimate trade cannot move — Huram will drop the merchant mask entirely. He will be direct, honest, and dangerous."
            )
        )
    }

    /// Yoel ben Shimri — the young priest. Faction: Priesthood.
    public static func yoelBenShimri() -> NPC {
        NPC(
            name: "Yoel ben Shimri",
            role: "Priest",
            faction: .priesthood,
            trust: 0.35,  // inherently suspicious of outsiders
            register: VoiceRegister(
                style: .priestly,
                references: ["the LORD", "the Torah", "the sanctuary", "the ancestors", "purity"],
                avoids: ["the ba'alim", "the foreign gods", "the cave practices", "the ov"]
            ),
            tags: TagConstellation([
                NarrativeTag(.identity, "young_man"),
                NarrativeTag(.identity, "Levite"),
                NarrativeTag(.cultural, "priestly_lineage"),
                NarrativeTag(.disposition, "devotion"),
                NarrativeTag(.disposition, "fear"),
            ]),
            interiority: NPCInteriority(
                interiorVoice: "I am the priest of this place and I am twenty-three years old and I know less than the elders think I do. The sanctuary is my responsibility and the sanctuary is a room with an altar and the altar has not heard the voice of God in my lifetime. I perform the rites because the rites are what we do. I believe in the rites. I do not know if the rites believe in me.",
                privateTruth: "He has doubts. Real, consuming, theological doubts. The silence of the sanctuary is not peaceful to him — it is terrifying. He does not know if God speaks, and he is the one whose job it is to listen. If he admits this to anyone in his faction, he loses everything.",
                unsatisfiedWant: "He wants proof. He wants the heavens to answer. He wants to hear the voice that the scriptures promise. He is the priest of a silent god and the silence is eating him alive.",
                wound: "His father was the priest before him. His father had certainty — genuine, unshakeable, joyful certainty. Yoel watched his father die slowly of a stomach cancer that no prayer alleviated, and the certainty did not waver, and Yoel could not understand how that was possible.",
                threshold: "If the practitioner demonstrates — conclusively, undeniably, in front of him — that the dead can speak, Yoel will not report them. He will come back at night. He will ask to see it again. He will ask whether the dead know anything about God."
            )
        )
    }

    /// Devorah — the herbalist and healer. Faction: Elders (loosely).
    public static func devorah() -> NPC {
        NPC(
            name: "Devorah",
            role: "Herbalist",
            faction: .elders,
            trust: 0.55,
            register: VoiceRegister(
                style: .guarded,
                references: ["the plants", "the wadi", "the seasons", "what grows where"],
                avoids: ["her past", "the coast", "the old practices"]
            ),
            tags: TagConstellation([
                NarrativeTag(.identity, "elder_woman"),
                NarrativeTag(.identity, "Israelite"),
                NarrativeTag(.cultural, "herbalist"),
                NarrativeTag(.disposition, "caution"),
            ]),
            interiority: NPCInteriority(
                interiorVoice: "I know what the plants do because my grandmother knew, and her grandmother knew, and the knowledge goes back to a time before the village had a name. I do not call it practice. I call it knowing what grows. The priest calls the other things practice and he is probably right and I do not have those things and I do not want them. I had them once. That was enough. That was more than enough.",
                privateTruth: "She was, once, something very close to what the practitioner is now. In her youth, in another village, she learned more than herbs. She learned the other things — the fragment reading, the nightwork, the chirping and muttering. She stopped when someone she loved was hurt by it. She will not say who.",
                unsatisfiedWant: "She wants to know that the person she hurt has forgiven her. The person is dead. This is the kind of want the system cannot satisfy.",
                wound: "She hurt someone with the practice. Not a stranger. Someone close. The specifics she will never share unprompted, but the knowledge of what she did is in every cautious word she speaks.",
                threshold: "If the practitioner comes to her injured by the practice — if the work has gone wrong and they need help — she will recognize what has happened. She will help. And in helping, she will reveal that she knows exactly what the practitioner is, because she was one."
            )
        )
    }

    /// Baruk the Smith — the metalworker. Faction: Traders.
    public static func barukTheSmith() -> NPC {
        NPC(
            name: "Baruk",
            role: "Smith",
            faction: .traders,
            trust: 0.45,
            register: VoiceRegister(
                style: .vernacular,
                references: ["iron", "copper", "the forge", "the military", "tools"],
                avoids: ["the priest", "the elders' politics", "his own opinions"]
            ),
            tags: TagConstellation([
                NarrativeTag(.identity, "smith"),
                NarrativeTag(.identity, "Israelite"),
                NarrativeTag(.cultural, "craftsman"),
                NarrativeTag(.disposition, "practicality"),
            ]),
            interiority: NPCInteriority(
                interiorVoice: "Iron is honest. You heat it and you hit it and it becomes what it becomes and if it breaks it is because you did something wrong and not because it decided to betray you. People are not honest. I prefer iron. I make what the village needs — plowshares, sickles, knives — and what the military needs when they come through, which is spearheads and arrowheads, and I do not ask which army they serve because iron does not care.",
                privateTruth: "He makes weapons for both sides of the conflict. He does not advertise this. The Philistine garrison at Gath places orders through Huram, and the Israelite militia places orders directly, and neither knows about the other, and Baruk sleeps fine.",
                unsatisfiedWant: "He wants to make something beautiful. Not a tool. Not a weapon. Something beautiful. He has never had time and will never have time and the one time he tried — a bronze mirror, years ago — his wife sold it for grain during a lean year. He said nothing.",
                wound: "The bronze mirror. His wife sold it because they were hungry and he knows she was right. He has never made anything for himself since.",
                threshold: "If the practitioner brings him a piece of ancient metalwork — genuine, old, beautiful — he will hold it and study it and forget to put on his professional face. For a moment he will be the person he might have been."
            )
        )
    }
}
