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

        sites[currentSiteIndex].lastVisitTick = clock.currentTick
        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)
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
        let events = clock.advanceForTravel(world: &world, sites: &sites, npcs: &npcs)

        print("\n  You travel to \(site.name).")
        print("  \(travelDescription(site))")

        // Process world events and director narration
        processWorldEvents(events)
        processDirectorEvents()
        sites[currentSiteIndex].lastVisitTick = clock.currentTick
    }

    func showInventory() {
        print("\n  ── Your Satchel ──")
        print("  Fragments: \(inventory.fragments.count)")
        print("  Artifacts: \(inventory.artifacts.count)")
        print("  Memory Traces: \(inventory.memoryTraces.count)")
        print("  Libations: \(inventory.libations.map(\.rawValue).joined(separator: ", "))")
        print("\n  Type 'fragments', 'artifacts' for details.")
    }

    func listFragments() {
        print("\n  ── Bone Fragments ──")
        if inventory.fragments.isEmpty {
            print("    Your satchel is empty of bone.")
            return
        }
        for (i, frag) in inventory.fragments.enumerated() {
            let condition = describeIntegrity(frag.integrity)
            let era = describeEra(frag.era)
            print("    \(i + 1). \(describeRemainsType(frag.remainsType)) — \(era), \(condition)")
            if let name = frag.inscribedName {
                print("       Inscribed: \"\(name)\"")
            }
            let identityTags = frag.tags.tags(in: .identity)
            if !identityTags.isEmpty {
                print("       Traces: \(identityTags.map(\.value).joined(separator: ", "))")
            }
        }
    }

    func listArtifacts() {
        print("\n  ── Life Artifacts ──")
        for (i, art) in inventory.artifacts.enumerated() {
            print("    \(i + 1). \(art.name) — \(art.domain.rawValue) domain")
        }
        if inventory.artifacts.isEmpty {
            print("    None carried.")
        }
        print("\n  ── Memory Traces ──")
        for (i, trace) in inventory.memoryTraces.enumerated() {
            print("    \(i + 1). \(trace.name)")
        }
        if inventory.memoryTraces.isEmpty {
            print("    None found.")
        }
    }

    // MARK: - Ritual

    func ritualMenu() {
        let site = sites[currentSiteIndex]
        print("\n  ── Compose Ritual at \(site.name) ──")
        print()

        // Step 1: Choose fragment (mandatory)
        print("  Choose bone fragment:")
        for (i, frag) in inventory.fragments.enumerated() {
            let desc = describeRemainsType(frag.remainsType)
            let era = describeEra(frag.era)
            let name = frag.inscribedName.map { " [\($0)]" } ?? ""
            print("    \(i + 1). \(desc) — \(era)\(name)")
        }
        print("    0. Cancel")
        print("  > ", terminator: "")
        guard let fragInput = readLine(), let fragIdx = Int(fragInput), fragIdx > 0, fragIdx <= inventory.fragments.count else {
            print("  You set the bones aside. Not now.")
            return
        }
        let fragment = inventory.fragments[fragIdx - 1]

        // Step 2: True Name (optional)
        print("\n  Speak a name? (enter name, or press Enter to skip): ", terminator: "")
        let nameInput = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trueName: TrueName? = (nameInput != nil && !nameInput!.isEmpty)
            ? TrueName(nameInput!, partial: !nameInput!.contains(","))
            : nil

        // Step 3: Life Artifact (optional)
        var chosenArtifact: LifeArtifact? = nil
        if !inventory.artifacts.isEmpty {
            print("\n  Include a life artifact?")
            for (i, art) in inventory.artifacts.enumerated() {
                print("    \(i + 1). \(art.name)")
            }
            print("    0. None")
            print("  > ", terminator: "")
            if let artInput = readLine(), let artIdx = Int(artInput), artIdx > 0, artIdx <= inventory.artifacts.count {
                chosenArtifact = inventory.artifacts[artIdx - 1]
            }
        }

        // Step 4: Memory Trace (optional)
        var chosenTrace: MemoryTrace? = nil
        if !inventory.memoryTraces.isEmpty {
            print("\n  Include a memory trace?")
            for (i, trace) in inventory.memoryTraces.enumerated() {
                print("    \(i + 1). \(trace.name)")
            }
            print("    0. None")
            print("  > ", terminator: "")
            if let traceInput = readLine(), let traceIdx = Int(traceInput), traceIdx > 0, traceIdx <= inventory.memoryTraces.count {
                chosenTrace = inventory.memoryTraces[traceIdx - 1]
            }
        }

        // Step 5: Libation (optional)
        var chosenLibation: Libation? = nil
        if !inventory.libations.isEmpty {
            let uniqueLibations = Array(Set(inventory.libations)).sorted(by: { $0.rawValue < $1.rawValue })
            print("\n  Pour a libation?")
            for (i, lib) in uniqueLibations.enumerated() {
                let count = inventory.libations.filter { $0 == lib }.count
                print("    \(i + 1). \(describeLibation(lib)) (×\(count))")
            }
            print("    0. None — plain summoning")
            print("  > ", terminator: "")
            if let libInput = readLine(), let libIdx = Int(libInput), libIdx > 0, libIdx <= uniqueLibations.count {
                let chosen = uniqueLibations[libIdx - 1]
                chosenLibation = Libation(chosen)
                // Consume the libation
                if let idx = inventory.libations.firstIndex(of: chosen) {
                    inventory.libations.remove(at: idx)
                }
            }
        }

        // Step 6: Timing
        let timing = clock.currentTiming

        // Compile the ritual
        let config = RitualConfiguration(
            remains: fragment,
            site: site,
            trueName: trueName,
            lifeArtifact: chosenArtifact,
            memoryTrace: chosenTrace,
            libation: chosenLibation,
            timing: timing
        )

        // Cast the astragali first
        print("\n  ── Casting the Bones ──")
        print()
        let regionID = world.regions.keys.first!
        let seed = deterministicSeed(fragmentID: fragment.id)
        let reading = astragali.cast(
            configuration: config,
            regionState: world.regions[regionID]!,
            profile: profile,
            seed: seed
        )
        printAstragaliReading(reading)

        // Confirm
        print("\n  Proceed with the ritual? (y/n): ", terminator: "")
        guard readLine()?.lowercased().hasPrefix("y") == true else {
            print("  You gather the fragments. The moment passes.")
            return
        }

        // Execute
        print("\n  ── The Ritual ──")
        print()
        print("  You arrange the fragments on the stone.")
        if trueName != nil { print("  You speak the name into the dark.") }
        if chosenArtifact != nil { print("  The artifact rests beside the bone.") }
        if let lib = chosenLibation { print("  You pour the \(describeLibation(lib.type).lowercased()).") }
        print("  You begin to speak. Low, into your chest. Chirping and muttering.")
        print()

        let result = pipeline.resolve(
            configuration: config,
            regionState: world.regions[regionID]!,
            profile: profile,
            seed: seed,
            rootIdentities: rootIdentities
        )

        ritualCount += 1

        // Apply world effects
        var mutableSite = sites[currentSiteIndex]
        world.applyRitualEffects(result.worldEffects, regionID: regionID, site: &mutableSite)
        sites[currentSiteIndex] = mutableSite

        // Update profile
        profile.recordRitual(
            success: result.spirit != nil,
            wasMutation: result.spirit?.isMutation ?? false,
            domain: fragment.domain,
            entropyCost: result.worldEffects.ghostActivityDelta + result.worldEffects.corruptionDelta
        )
        profile.applyRitualConsequences(configuration: config, result: result)

        // Display result
        if let spirit = result.spirit {
            printManifestation(spirit, result: result)

            // Record in Codex
            let _ = codex.recordEncounter(
                spirit: spirit,
                autopsy: result.autopsy,
                ritualID: config.id,
                tick: world.currentTick
            )
            print("  [Codex entry \(result.spirit?.isMutation == true ? "created — MUTATION" : "updated")]")
        } else {
            print("  Nothing answers. The silence is heavy and final.")
            print()
        }

        // Print autopsy (mastery-aware)
        print("\n  ── The Reading ──")
        let autopsyText = autopsyReader.interpret(
            result,
            configuration: config,
            masteryPhase: profile.masteryPhase
        )
        printWrapped(autopsyText, indent: 4)

        // Cross-link epochs in the Codex
        codex.crossLinkEpochs()

        // Record mutation at site if applicable
        if result.spirit?.isMutation == true {
            sites[currentSiteIndex].recordMutation()
        }
        sites[currentSiteIndex].lastRitualTick = clock.currentTick

        world.seedRitualRumor(
            site: sites[currentSiteIndex],
            wasMutation: result.spirit?.isMutation == true,
            libation: chosenLibation?.type,
            timing: timing,
            practitionerName: nil,
            npcs: &npcs
        )

        // Advance time — rumor propagation runs inside the clock tick.
        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)

        // Process world events and director narration
        processWorldEvents(events)
        processDirectorEvents()
    }

    func castAstragali() {
        if inventory.fragments.isEmpty {
            print("  You have no fragments to read against.")
            return
        }

        print("\n  Which fragment to read? (1-\(inventory.fragments.count)): ", terminator: "")
        guard let input = readLine(), let idx = Int(input), idx > 0, idx <= inventory.fragments.count else {
            print("  You return the bones to the pouch.")
            return
        }

        let fragment = inventory.fragments[idx - 1]
        let site = sites[currentSiteIndex]

        // Minimal configuration for diagnostic
        guard let config = Ritual.compile({
            fragment
            site
            clock.currentTiming
        }) else { return }

        let regionID = world.regions.keys.first!
        let seed = deterministicSeed(fragmentID: fragment.id, salt: 1)
        let reading = astragali.cast(
            configuration: config,
            regionState: world.regions[regionID]!,
            profile: profile,
            seed: seed
        )

        print("\n  ── The Bones ──")
        printAstragaliReading(reading)

        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)
        processWorldEvents(events)
        processDirectorEvents()
    }

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

    func villageMenu() {
        print("\n  ── Kfar Shalem ──")
        print("    The village watches. You are a stranger, and strangers are noticed.")
        print()

        for (i, npc) in npcs.enumerated() {
            let statusIcon: String
            if npc.isRefusing {
                statusIcon = "✕"
            } else if npc.hasWitnessedDirectly {
                statusIcon = "⚠"
            } else if npc.hasHeardRumors {
                statusIcon = "◇"
            } else {
                statusIcon = "◈"
            }
            print("    \(i + 1). \(statusIcon) \(npc.name) — \(npc.role) (\(npc.faction.rawValue))")
            print("       \(npc.behaviorDescription)")
        }

        print("\n  Talk to whom? (1-\(npcs.count), or 'back'): ", terminator: "")
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
              let idx = Int(input), idx > 0, idx <= npcs.count else {
            print("  You leave the village square without speaking to anyone.")
            return
        }

        talkToNPC(index: idx - 1)
    }

    func talkToNPC(index: Int) {
        let npc = npcs[index]

        if npc.isRefusing {
            print("\n  \(npc.name) turns away. They will not speak with you.")
            return
        }

        print("\n  ── \(npc.name), \(npc.role) ──")
        print("    \(npc.behaviorDescription)")
        print()

        // NPC speaks based on their register and state
        let greeting = npcGreeting(npc)
        printWrapped(greeting, indent: 4)

        print()
        print("    1. Friendly conversation (builds trust)")
        print("    2. Ask about the region")
        print("    3. Ask about the dead (risky)")
        if npc.isAtThreshold {
            print("    4. ◈ Something deeper (threshold reached)")
        }
        print("    0. Walk away")

        print("\n  > ", terminator: "")
        guard let choice = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

        switch choice {
        case "1":
            npcs[index].positiveInteraction(strength: 0.1)
            npcs[index].lastInteractionTick = clock.currentTick
            let response = friendlyResponse(npc)
            print()
            printWrapped(response, indent: 4)
            print("\n  [Trust increased. \(npc.name) seems slightly warmer.]")

        case "2":
            let regionInfo = regionResponse(npc)
            print()
            printWrapped(regionInfo, indent: 4)

        case "3":
            // Asking about the dead raises suspicion
            npcs[index].hearRumor(strength: 0.15)
            npcs[index].lastInteractionTick = clock.currentTick
            let deadResponse = deadResponse(npc)
            print()
            printWrapped(deadResponse, indent: 4)
            print("\n  [Suspicion increased. You asked something you shouldn't have.]")

            // Propagate rumors to faction members
            for i in npcs.indices where i != index && npcs[i].faction == npc.faction {
                npcs[i].hearRumor(strength: 0.05)
            }

        case "4" where npc.isAtThreshold:
            npcs[index].lastInteractionTick = clock.currentTick
            print()
            printWrapped(thresholdResponse(npc), indent: 4)

        default:
            print("  You nod and step back. The conversation ends.")
        }

        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)
        processWorldEvents(events)
        processDirectorEvents()
    }

    // MARK: - NPC Dialogue Generation

}
