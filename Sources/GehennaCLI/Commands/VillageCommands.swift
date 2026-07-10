import Foundation
import GehennaEngine

extension GameSession {
    func villageMenu() async {
        print("\n  ── Kfar Shalem ──")
        print("    The village watches. You are a stranger, and strangers are noticed.")
        
        let availableNPCs = npcs.filter { !$0.isRefusing && !$0.wouldFlee }
        
        if availableNPCs.isEmpty {
            print("    No one will speak to you. Doors are barred. Eyes turn away.")
        } else {
            for (i, npc) in availableNPCs.enumerated() {
                print("  [\(i)] Approach \(npc.name) (\(npc.role))")
            }
        }
        
        print("  [c] Leave village")
        print("\n  > ", terminator: "")
        
        guard let input = readLine(), input.lowercased() != "c", let index = Int(input), index < availableNPCs.count else {
            return
        }
        
        let targetNPC = availableNPCs[index]
        // Find actual index in the main npcs array
        guard let mainIndex = npcs.firstIndex(where: { $0.id == targetNPC.id }) else { return }

        // Build recent world events this NPC might be aware of —
        // pull the last few notable entries from the journal near this site.
        let recentJournal = world.journal.suffix(20)
        let recentEventStrings: [String] = recentJournal
            .filter { $0.severity >= .notable }
            .suffix(4)
            .map { $0.description }

        print()
        let greeting = await expressionEngine.npcGreeting(targetNPC)
        print("  \(greeting)")

        if targetNPC.isAtThreshold {
            let thresholdResp = await expressionEngine.npcThresholdResponse(
                targetNPC,
                recentEvents: recentEventStrings,
                interactionCount: targetNPC.lastInteractionTick != nil ? 2 : 0
            )
            print("  \(thresholdResp)")
            npcs[mainIndex].lastInteractionTick = clock.currentTick
            let events = advanceTime(.command)
            processWorldEvents(events)
            processDirectorEvents()
            return
        }
        
        print("\n  Approach how?")
        print("  [1] Friendly greeting")
        print("  [2] Ask about the region")
        print("  [3] Ask about the dead")
        print("  [4] Speak freely...")
        print("  [c] Cancel")
        print("\n  > ", terminator: "")
        
        guard let actInput = readLine(), let actionNum = Int(actInput) else { return }
        
        let action: PlayerCommand.ConversationAction
        switch actionNum {
        case 1: action = .friendly
        case 2: action = .askRegion
        case 3: action = .askDead
        case 4:
            print("\n  What do you say?\n  > ", terminator: "")
            guard let playerText = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !playerText.isEmpty else { return }
            action = .speakFreely(text: playerText)
        default: return
        }
        
        print()
        switch action {
        case .friendly:
            let resp = await expressionEngine.npcResponse(targetNPC, event: .friendlyResponse)
            print("  \(resp)")
            npcs[mainIndex].positiveInteraction(strength: 0.3)
        case .askRegion:
            let resp = await expressionEngine.npcResponse(targetNPC, event: .regionResponse)
            print("  \(resp)")
            npcs[mainIndex].positiveInteraction(strength: 0.1)
        case .askDead:
            let resp = await expressionEngine.npcResponse(targetNPC, event: .deadResponse)
            print("  \(resp)")
            npcs[mainIndex].witnessActivity(severity: 0.4)
        case .speakFreely(let text):
            let resp = await expressionEngine.npcChat(
                targetNPC,
                input: text,
                recentEvents: recentEventStrings,
                interactionCount: targetNPC.lastInteractionTick != nil ? 2 : 0
            )
            print("  \(resp)")

            // Words have weight. The classifier types the utterance; the
            // engine applies the consequence — trust, suspicion, memory.
            let intent = await expressionEngine.classifyIntent(
                text,
                forbiddenTopics: targetNPC.register.avoids
            )
            if let cue = npcs[mainIndex].apply(intent) {
                print("  \(cue)")
            }
            if intent == .reveal {
                world.journal.append(JournalEntry(
                    tick: clock.currentTick,
                    type: .npcReaction,
                    description: "The practitioner spoke openly of the practice to \(targetNPC.name).",
                    source: .practitioner,
                    severity: .significant,
                    siteID: sites[currentSiteIndex].id,
                    involvedNPCs: [targetNPC.id],
                    tags: ["confession"]
                ))
            }
        }
        npcs[mainIndex].lastInteractionTick = clock.currentTick
        
        let events = advanceTime(.command)
        processWorldEvents(events)
        processDirectorEvents()
    }
}
