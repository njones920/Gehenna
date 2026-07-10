// MARK: - The Buried Names (Maacah / Devorah thread)
// The first want. No quest log, no marker. Devorah asks, once she trusts
// you, whether a dead woman rests. The answer is under the ground above
// the spring, and only the dead can give it. The beats here are authored
// (Tier 1); everything between them runs on the ordinary systems.

import Foundation
import GehennaEngine

extension GameSession {

    static let maacahThreadKey = "the-buried-names"

    var maacahThread: StoryThread {
        get { threads[Self.maacahThreadKey] ?? StoryThread(key: Self.maacahThreadKey) }
        set { threads[Self.maacahThreadKey] = newValue }
    }

    var maacahRootID: UUID? {
        rootIdentities.first { $0.trueName == "Maacah" }?.id
    }

    // MARK: - Hook: after any village conversation

    /// Runs after the practitioner talks with an NPC. Devorah's want
    /// surfaces once her trust crosses the threshold; the resolution
    /// choice appears once the truth has been heard.
    func maacahThreadAfterTalk(npcIndex: Int) {
        guard npcs[npcIndex].name == "Devorah" else { return }
        var thread = maacahThread

        // Resolution: the player has heard the truth and returns to her.
        if thread.has("truthHeard"), !thread.has("resolved") {
            presentMaacahResolution(npcIndex: npcIndex, thread: &thread)
            maacahThread = thread
            return
        }

        // The want surfaces.
        if thread.stage == 0, npcs[npcIndex].trust >= 0.65 {
            print("""

              Devorah is quiet for a moment, sorting leaves that are already sorted.

              "There was a woman here. Maacah. Before your time — before most of
              their times, now. When her hour came, no one went to her. The village
              found reasons. I was young, and I found reasons too."

              She ties the bundle with more attention than it needs.

              "They said things about her at the end that were not true. If the dead
              can be reached — and I am not saying they can — someone should ask her
              whether she rests. And if she does not… someone should know why."

              (The old women say Maacah lies in the caves above the spring,
              where the water comes out of the hill. She was buried without
              a name. Devorah has just given it back to you.)
            """)
            thread.advance(to: 1)
            thread.mark("wantHeard")
            world.journal.append(JournalEntry(
                tick: clock.currentTick,
                type: .npcReaction,
                description: "Devorah asked whether Maacah rests. The answer is under the ground at Nahal.",
                source: .npc,
                severity: .notable,
                siteID: sites[currentSiteIndex].id,
                involvedNPCs: [npcs[npcIndex].id],
                tags: ["thread", "maacah", "want"]
            ))
            maacahThread = thread
        }
    }

    // MARK: - Hook: after a successful manifestation

    /// Runs when any spirit manifests. Reaching Maacah advances the thread.
    func maacahThreadAfterManifestation(_ spirit: Spirit) {
        guard let maacahID = maacahRootID, spirit.rootIdentityID == maacahID else { return }
        var thread = maacahThread
        guard !thread.has("maacahReached") else { return }
        thread.advance(to: 2)
        thread.mark("maacahReached")
        world.journal.append(JournalEntry(
            tick: clock.currentTick,
            type: .spiritManifested,
            description: "Maacah was reached — manifesting as \(spirit.epochName ?? spirit.template.rawValue).",
            source: .ritual,
            severity: .notable,
            siteID: sites[currentSiteIndex].id,
            tags: ["thread", "maacah"]
        ))
        maacahThread = thread
    }

    // MARK: - Hook: during conversation with Maacah

    /// Runs after each conversational exchange with a bound spirit.
    /// Once the want is known and Maacah has been held in conversation,
    /// the truth surfaces — unless the aspect answering is the one they
    /// taught to be careful.
    func maacahThreadDuringConversation(with bound: BoundSpirit) {
        guard let maacahID = maacahRootID,
              bound.spirit.rootIdentityID == maacahID else { return }
        var thread = maacahThread
        guard thread.has("wantHeard"), !thread.has("truthHeard"),
              bound.exchangeCount >= 2 else { return }

        if bound.spirit.epochName == "The Silenced Devotee" {
            guard !thread.has("devoteeRefused") else { return }
            print("""

              The Silenced Devotee goes still. When she answers, each word is
              set down carefully, like a jar on a shelf that must not break.

              "Not this mouth. This is the part of me they taught to be careful.
              Call me another way, and perhaps another part of me can afford
              to remember."
            """)
            thread.mark("devoteeRefused")
            maacahThread = thread
            return
        }

        print("""

          Something changes in her voice — the register of a thing rehearsed
          through long silence, finally spoken:

          "I will tell you what the village would not. A man of standing came
          to the spring shrine at night, and I saw what he did there. Three
          days later I was a witch. When my time came, the doors stayed shut.
          I called until I could not. The child lived — I heard her cry.
          That is all I carried down with me: one cry.

          Devorah wept for me. Tell her I know. Tell her the fault was never
          hers. And if you would do the dead a kindness, practitioner — find
          out who raised my daughter, and whether they were kind."
        """)
        thread.advance(to: 3)
        thread.mark("truthHeard")
        world.journal.append(JournalEntry(
            tick: clock.currentTick,
            type: .practitionerAction,
            description: "Maacah spoke the truth of her death: accused after the spring shrine, left to labor alone. The child lived.",
            source: .spirit,
            severity: .significant,
            siteID: sites[currentSiteIndex].id,
            tags: ["thread", "maacah", "truth"]
        ))
        maacahThread = thread
    }

    // MARK: - Resolution

    private func presentMaacahResolution(npcIndex: Int, thread: inout StoryThread) {
        print("""

          Devorah reads your face before you speak. "You reached her."

          1. Tell her the truth — all of it.
          2. Tell her Maacah rests peacefully. (A kindness. A lie.)
          3. Say nothing yet.
        """)
        print("\n  > ", terminator: "")
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

        switch input {
        case "1":
            print("""

              You tell her. The shrine. The accusation. The doors that stayed
              shut. The cry. Devorah does not move while you speak, and when
              you finish she is quiet for a long time.

              "The fault was never mine," she repeats — not as if she believes
              it, but as if she intends to learn to.

              She goes to the back of the house and returns with a small
              sealed jar. "Wine, rue, and water lily. My grandmother's mixture.
              You walk into dark places — walk in with your eyes open."

              (Devorah has given you a ritual mixture. One door in this
              village, at least, is now fully open.)
            """)
            npcs[npcIndex].positiveInteraction(strength: 1.0)
            inventory.libations.append(.ritualMixture)
            thread.advance(to: 4)
            thread.mark("resolved")
            thread.mark("resolvedTruth")
            world.journal.append(JournalEntry(
                tick: clock.currentTick,
                type: .npcReaction,
                description: "The truth of Maacah's death was carried back to Devorah.",
                source: .practitioner,
                severity: .significant,
                siteID: sites[currentSiteIndex].id,
                involvedNPCs: [npcs[npcIndex].id],
                tags: ["thread", "maacah", "resolution", "truth"]
            ))

        case "2":
            print("""

              "At peace," Devorah repeats. She looks at you a moment too long —
              the look of a woman who has heard comfortable words before and
              knows what they are for. "Well. Thank you for carrying the
              question."

              (Somewhere beneath the ridge, in the place where the dead keep
              accounts, something is written down.)
            """)
            npcs[npcIndex].positiveInteraction(strength: 0.1)
            if let maacahID = maacahRootID {
                relationships.record(.promiseBroken, forKey: maacahID, atTick: clock.currentTick, detail: "Her truth was traded for a comfortable lie.")
            }
            thread.advance(to: 4)
            thread.mark("resolved")
            thread.mark("resolvedLie")
            world.journal.append(JournalEntry(
                tick: clock.currentTick,
                type: .npcReaction,
                description: "Devorah was told that Maacah rests peacefully.",
                source: .practitioner,
                severity: .notable,
                siteID: sites[currentSiteIndex].id,
                involvedNPCs: [npcs[npcIndex].id],
                tags: ["thread", "maacah", "resolution", "lie"]
            ))

        default:
            print("\n  You keep it a while longer. It does not get lighter.")
        }
    }
}
