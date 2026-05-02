import Foundation
import GehennaEngine

extension GameSession {
    func advanceTime() {
        print("\n  You wait. The night passes.")

        // Rest advances more time — the world has room to change
        let events = clock.advanceForRest(world: &world, sites: &sites, npcs: &npcs)

        if events.isEmpty {
            print("  The world turns. Nothing of note.")
        } else {
            processWorldEvents(events)
        }

        // The director gets a chance to speak after rest
        processDirectorEvents()
    }

    func showRumors() {
        let activeRumors = world.rumorLedger.active
        print("\n  ── What The Village Is Hearing ──")
        if activeRumors.isEmpty {
            print("    Nothing carries your name yet. The bones have not yet reached the well.")
            return
        }

        for rumor in activeRumors.prefix(8) {
            let carriers = npcs.filter { rumor.hearers.contains($0.id) }
            let factions = Set(carriers.map(\.faction)).map(\.rawValue).sorted().joined(separator: ", ")
            let descriptor = factions.isEmpty ? "not yet carried" : "carried by \(factions)"
            let strengthWord = rumor.strength > 0.5 ? "loud" : rumor.strength > 0.2 ? "steady" : "faint"
            let mutationTag = rumor.mutationCount > 0 ? " — retold \(rumor.mutationCount)x" : ""
            print("    • \(rumor.sentence) [\(strengthWord), \(descriptor)\(mutationTag)]")
        }

        let extinctCount = world.rumorLedger.rumors.count - activeRumors.count
        if extinctCount > 0 {
            print("    (\(extinctCount) rumor(s) have faded.)")
        }
    }

    func saveGame() {
        do {
            try SnapshotStore.save(makeSnapshot(), to: saveURL)
            print("  The record is sealed at tick \(clock.currentTick). [\(saveURL.lastPathComponent)]")
        } catch {
            print("  The record would not hold. Save failed: \(error.localizedDescription)")
        }
    }

    func loadGame() {
        do {
            let snapshot = try SnapshotStore.loadSinglePlayerSnapshot(from: saveURL)
            applySnapshot(snapshot)

            if snapshot.engineVersion != GehennaEngine.version || snapshot.codexVersion != GehennaEngine.codexVersion {
                print("  The record returns, but it was sealed under \(snapshot.engineVersion) / Codex \(snapshot.codexVersion).")
            }

            print("  The old work returns. You stand again at \(sites[currentSiteIndex].name), tick \(clock.currentTick).")
        } catch {
            print("  No intact record could be opened. Load failed: \(error.localizedDescription)")
        }
    }
}
