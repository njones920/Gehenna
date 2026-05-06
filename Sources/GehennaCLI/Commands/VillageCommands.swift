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

        print()
        let greeting = await expressionEngine.npcGreeting(targetNPC)
        print("  \(greeting)")

        if targetNPC.isAtThreshold {
            let thresholdResp = await expressionEngine.npcThresholdResponse(
                targetNPC,
                recentEvents: [], // Would get these from ledger if we had it handy here
                interactionCount: 1
            )
            print("  \(thresholdResp)")
            npcs[mainIndex].lastInteractionTick = clock.currentTick
            let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)
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
            // Free-form chat — neutral interaction. No trust/suspicion change.
            let resp = await expressionEngine.npcChat(
                targetNPC,
                input: text,
                recentEvents: [],
                interactionCount: 1
            )
            print("  \(resp)")
        }
        npcs[mainIndex].lastInteractionTick = clock.currentTick
        
        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)
        processWorldEvents(events)
        processDirectorEvents()
    }
}
