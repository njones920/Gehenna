import Foundation
import GehennaEngine

extension GameSession {
    func lookAround() {
        let site = sites[currentSiteIndex]
        let region = world.regions.values.first!

        print()
        print("  \(describeSite(site))")
        print()

        // Environmental reading — no numbers, behavioral
        if region.ghostActivity > 0.5 {
            print("  The air is uneasy. Something moves at the edge of perception.")
        } else if region.ghostActivity > 0.3 {
            print("  A faint restlessness. The dead are not fully settled.")
        }

        if region.corruption > 0.4 {
            print("  There is a wrongness in the ground. The stone feels bruised.")
        }

        if region.suspicion > 0.5 {
            print("  You sense watchful eyes. The living are aware that something has changed.")
        }

        if site.effectiveVeilThinness > 0.6 {
            print("  The boundary is thin here. You can feel it in your teeth.")
        } else if site.effectiveVeilThinness > 0.3 {
            print("  The boundary hums faintly. This place remembers its dead.")
        }

        if site.corruption > 0.4 {
            print("  The corruption here is palpable. Even the stone tastes of it.")
        }

        if site.sanctity > 0.5 {
            print("  There is residual holiness. Old consecrations linger in the walls.")
        }

        // Site history — what has accumulated through play
        if site.isScarred {
            print("  The site bears scars that were not here when you arrived. Your work has marked this place.")
        }

        if !site.activeTraces.isEmpty {
            let traceCount = site.activeTraces.count
            if site.activeTraces.contains("mutation_scar") {
                print("  A wrongness lingers here from what came through broken. The grammar of the place is damaged.")
            } else if traceCount >= 3 {
                print("  The air is layered with traces of prior workings. This ground has been used hard.")
            } else {
                print("  Faint traces of a prior summoning remain. They are fading.")
            }
        }

        if site.localSuspicion > 0.3 {
            print("  This location has drawn attention. Others have noticed activity here.")
        }

        // Surface collectible clues diegetically — no UI numbers.
        let site2 = sites[currentSiteIndex]
        let hasItems = !site2.fragments.isEmpty || !site2.artifacts.isEmpty || !site2.memoryTraces.isEmpty
        if hasItems {
            if !site2.fragments.isEmpty {
                print("  The ground here gives up its dead slowly. You sense bone close to the surface.")
            }
            if !site2.artifacts.isEmpty {
                print("  Something worked — metal or clay — catches light at the edge of the disturbed earth.")
            }
            if !site2.memoryTraces.isEmpty {
                print("  Fragments of inscription are visible where the soil has shifted.")
            }
            print("  (Type 'scavenge' to search.)")
        }

        sites[currentSiteIndex].lastVisitTick = clock.currentTick
        let events = advanceTime(.command)
        processWorldEvents(events)
        processDirectorEvents()
    }

    func listSites() {
        print("\n  ── Known Locations ──")
        for (i, site) in sites.enumerated() {
            let marker = i == currentSiteIndex ? "  ▶ " : "    "
            let description = briefSiteDescription(site)
            print("\(marker)\(i + 1). \(site.name) — \(description)")
        }
    }

    func travelMenu() {
        listSites()
        print("\n  Where do you go? (1-\(sites.count), or 'back'): ", terminator: "")
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        if input == "back" { return }
        guard let choice = Int(input), choice >= 1, choice <= sites.count else {
            print("  You hesitate. That path is not clear.")
            return
        }

        currentSiteIndex = choice - 1
        let site = sites[currentSiteIndex]

        // Advance time when traveling — travel costs more ticks
        let events = advanceTime(.travel)

        print("\n  You travel to \(site.name).")
        print("  \(travelDescription(site))")

        // Process world events and director narration
        processWorldEvents(events)
        processDirectorEvents()
        sites[currentSiteIndex].lastVisitTick = clock.currentTick
    }

    func scavengeSite() {
        var site = sites[currentSiteIndex]
        var foundAnything = false

        if !site.fragments.isEmpty {
            inventory.fragments.append(contentsOf: site.fragments)
            print("  You search the ground. Your hands find what they find.")
            if debugMode {
                print("  [debug] Bone fragments found: \(site.fragments.count)")
            }
            site.fragments.removeAll()
            foundAnything = true
        }

        if !site.artifacts.isEmpty {
            inventory.artifacts.append(contentsOf: site.artifacts)
            print("  You unearth \(site.artifacts.count) life artifact(s).")
            site.artifacts.removeAll()
            foundAnything = true
        }

        if !site.memoryTraces.isEmpty {
            inventory.memoryTraces.append(contentsOf: site.memoryTraces)
            print("  You discover \(site.memoryTraces.count) memory trace(s).")
            site.memoryTraces.removeAll()
            foundAnything = true
        }

        if foundAnything {
            site.localSuspicion = min(1.0, site.localSuspicion + 0.3)
            sites[currentSiteIndex] = site
            print("\n  You spend hours digging. The earth yields its secrets, but you feel watched.")
            let events = advanceTime(.command)
            if !events.isEmpty {
                processWorldEvents(events)
            }
            processDirectorEvents()
        } else {
            print("  You search the area, but the earth yields nothing.")
        }
    }
}
