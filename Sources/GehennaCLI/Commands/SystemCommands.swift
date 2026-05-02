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

    func showJournal() {
        let entries = world.journal.reversed().prefix(10)
        print("\n  ── The Chronicle of Events ──")
        if entries.isEmpty {
            print("    The pages are blank. No deeds have yet been recorded.")
            return
        }

        for entry in entries {
            print("    Tick \(entry.tick) — \(entry.type.rawValue) | \(entry.source.rawValue)")
        }
    }

    func searchJournal() {
        print("\n  ── Search the Chronicle ──")
        print("    How do you wish to look?")
        print("    1 — By weight of the event (Severity)")
        print("    2 — By the mark left upon it (Tag)")
        print("    3 — By the greatest fractures (Recent Ruptures)")
        
        guard let choice = readLine()?.trimmingCharacters(in: .whitespaces) else { return }
        
        let entries: [JournalEntry]
        
        switch choice {
        case "1":
            print("    Name the lowest weight you seek: ambient, notable, significant, or rupture?")
            guard let severityInput = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() else { return }
            let severity: EventSeverity
            switch severityInput {
            case "ambient": severity = .ambient
            case "notable": severity = .notable
            case "significant": severity = .significant
            case "rupture": severity = .rupture
            default:
                print("    That weight is not recognized. The chronicle remains closed.")
                return
            }
            entries = world.events(severity: severity)
        case "2":
            print("    Speak the mark you seek.")
            guard let tag = readLine()?.trimmingCharacters(in: .whitespaces) else { return }
            entries = world.events(tagged: tag)
        case "3":
            entries = world.recentRuptures()
        default:
            print("    The chronicle remains closed.")
            return
        }
        
        if entries.isEmpty {
            print("    The search yields nothing. The pages hold no such echoes.")
        } else {
            print("\n  ── The Chronicle of Events ──")
            for entry in entries.reversed() {
                print("    Tick \(entry.tick) — \(entry.type.rawValue) | \(entry.source.rawValue)")
            }
        }
    }

    func readCodexEntry() {
        let entries = codex.recentEntries
        if entries.isEmpty {
            print("\n  The Codex lies empty. You have yet to call the dead back.")
            return
        }

        print("\n  ── Entries in the Codex ──")
        for (i, entry) in entries.enumerated() {
            let name = entry.epochName ?? entry.knownName ?? "Unknown"
            let tier = describeTier(entry.tier)
            print("    \(i + 1). \(name) — \(entry.template.rawValue) (\(tier))")
        }

        print("\n  Which entry do you wish to read? (Enter a number)")
        guard let choice = readLine()?.trimmingCharacters(in: .whitespaces),
              let index = Int(choice) else {
            print("  The pages remain closed.")
            return
        }

        let idx = index - 1
        guard idx >= 0, idx < entries.count else {
            print("  That entry does not exist in the Codex.")
            return
        }

        let selected = entries[idx]
        let name = selected.epochName ?? selected.knownName ?? "Unknown"
        let tier = describeTier(selected.tier)
        print("\n  ── \(name) — \(tier) ──")
        for note in selected.notes {
            print("    \(note)")
        }
    }
}
