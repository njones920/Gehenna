import Foundation
import GehennaEngine

extension GameSession {
    func villageMenu() {
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
        
        print("\n  Approach how?")
        print("  [1] Friendly greeting")
        print("  [2] Ask about the region")
        print("  [3] Ask about the dead")
        print("  [4] Offer a trade (if merchant)")
        print("  [c] Cancel")
        print("\n  > ", terminator: "")
        
        guard let actInput = readLine(), let actionNum = Int(actInput) else { return }
        
        let action: PlayerCommand.ConversationAction
        switch actionNum {
        case 1: action = .friendly
        case 2: action = .askRegion
        case 3: action = .askDead
        default: return
        }
        
        print("\n  You speak to \(targetNPC.name).")
        
        // Very rudimentary trust update
        if action == .askDead {
            npcs[mainIndex].personalSuspicion += 0.2
            npcs[mainIndex].trust -= 0.1
        } else if action == .friendly {
            npcs[mainIndex].trust += 0.05
        }
        
        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)
        processWorldEvents(events)
        processDirectorEvents()
    }
}
