import Foundation
import GehennaEngine

extension GameSession {
    // MARK: - Ritual

    func ritualMenu() async {
        let site = sites[currentSiteIndex]
        print("\n  ── Compose Ritual at \(site.name) ──")
        
        if inventory.fragments.isEmpty {
            print("  You have no bone fragments to anchor a ritual.")
            return
        }

        print("  Select an anchor fragment:")
        for (i, frag) in inventory.fragments.enumerated() {
            print("  [\(i)] \(frag.remainsType.rawValue) (\(frag.era.rawValue))")
        }
        
        print("  [c] Cancel")
        print("\n  > ", terminator: "")
        
        guard let input = readLine(), input.lowercased() != "c", let index = Int(input), index < inventory.fragments.count else {
            return
        }
        
        print("\n  Speak a true name for this spirit (or leave blank if unknown):")
        print("  > ", terminator: "")
        let nameInput = readLine()?.trimmingCharacters(in: .whitespaces)
        let trueName = nameInput?.isEmpty == false ? nameInput : nil
        
        var artifactIndex: Int? = nil
        if !inventory.artifacts.isEmpty {
            print("\n  Offer an artifact? (optional)")
            for (i, art) in inventory.artifacts.enumerated() {
                print("  [\(i)] \(art.name)")
            }
            print("  [s] Skip")
            print("\n  > ", terminator: "")
            if let artInput = readLine(), let aIndex = Int(artInput), aIndex < inventory.artifacts.count {
                artifactIndex = aIndex
            }
        }
        
        var traceIndex: Int? = nil
        if !inventory.memoryTraces.isEmpty {
            print("\n  Burn a memory trace? (optional)")
            for (i, trace) in inventory.memoryTraces.enumerated() {
                print("  [\(i)] \(trace.name)")
            }
            print("  [s] Skip")
            print("\n  > ", terminator: "")
            if let trInput = readLine(), let trIndex = Int(trInput), trIndex < inventory.memoryTraces.count {
                traceIndex = trIndex
            }
        }
        
        print("\n  Pour a libation:")
        for (i, lib) in inventory.libations.enumerated() {
            print("  [\(i)] \(lib.rawValue)")
        }
        print("  [c] Cancel")
        print("\n  > ", terminator: "")
        
        guard let libInput = readLine(), let lIndex = Int(libInput), lIndex < inventory.libations.count else {
            return
        }
        
        let libation = inventory.libations.remove(at: lIndex)
        
        let intent = RitualIntent(
            fragmentIndex: index,
            trueName: trueName,
            artifactIndex: artifactIndex,
            traceIndex: traceIndex,
            libationType: libation,
            timing: WorldTiming(time: clock.currentTimeOfDay)
        )
        
        await executeRitual(intent)
    }

    private func executeRitual(_ intent: RitualIntent) async {
        var site = sites[currentSiteIndex]
        let fragment = inventory.fragments.remove(at: intent.fragmentIndex)
        let artifact = intent.artifactIndex.map { inventory.artifacts.remove(at: $0) }
        let trace = intent.traceIndex.map { inventory.memoryTraces.remove(at: $0) }
        
        let config = RitualConfiguration(
            remains: fragment,
            site: site,
            trueName: intent.trueName.map { TrueName($0, partial: false) },
            lifeArtifact: artifact,
            memoryTrace: trace,
            libation: Libation(intent.libationType),
            timing: intent.timing
        )
        
        let pipeline = ResolutionPipeline()
        let result = pipeline.resolve(
            configuration: config,
            regionState: world.regions.values.first ?? RegionState(name: "Unknown"),
            profile: profile,
            seed: UInt64(clock.currentTick),
            rootIdentities: self.rootIdentities
        )
        
        print("\n  ── Ritual Result ──\n")
        
        let autopsyText = autopsyReader.interpret(result, configuration: config, masteryPhase: profile.masteryPhase)
        print("\n  [Autopsy] \(autopsyText)\n")

        if let spirit = result.spirit {
            printManifestation(spirit, result: result)
            
            let speech = await expressionEngine.spiritSpeech(spirit, practitioner: profile)
            print("  \"\(speech)\"")
            
            let sustained = profile.summonerCapacity > 0
            if sustained {
                profile.summonerCapacity -= 1
                print("\n  You anchor the spirit to your will.")
            } else {
                print("\n  Your capacity is exceeded. The spirit breaks free and dissipates.")
            }
        } else {
            print("  The libation sinks into the earth. Nothing answers.")
        }
        
        if result.worldEffects.corruptionDelta > 0.3 {
            print("  The site is permanently scarred by this interaction.")
            site.scarring = min(1.0, site.scarring + 0.3)
        }
        
        // Traces and taboos are now handled automatically by world and profile methods,
        // but since this is CLI-driven, we just simulate the UI feedback.
        site.localSuspicion = min(1.0, site.localSuspicion + 0.1)
        sites[currentSiteIndex] = site
        profile.totalRituals += 1
        if result.spirit != nil {
            profile.successfulRituals += 1
        }
        
        // Detailed journal logging is handled by engine's applyRitualEffects.
        // We do a simple fallback entry here if the engine didn't catch it.
        let entry = JournalEntry(
            tick: clock.currentTick,
            type: .ritualPerformed,
            description: result.spirit != nil ? "Manifested \(result.spirit!.epochName ?? result.spirit!.template.rawValue)" : "Failed ritual",
            source: .practitioner,
            severity: result.worldEffects.corruptionDelta > 0.3 ? .rupture : .notable,
            siteID: site.id,
            involvedNPCs: [],
            tags: []
        )
        world.journal.append(entry)
        
        // Advance time
        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)
        processWorldEvents(events)
        processDirectorEvents()
    }

    func castAstragali() {
        if inventory.fragments.isEmpty {
            print("  You have no fragments to read against.")
            return
        }
        
        print("  Select a fragment to question:")
        for (i, frag) in inventory.fragments.enumerated() {
            print("  [\(i)] \(frag.remainsType.rawValue)")
        }
        print("  [c] Cancel")
        print("\n  > ", terminator: "")
        
        guard let input = readLine(), let index = Int(input), index < inventory.fragments.count else {
            return
        }
        
        let fragment = inventory.fragments[index]
        
        print("  You cast the sheep-knuckle bones over the \(fragment.era.rawValue) fragment.")
        
        let config = RitualConfiguration(remains: fragment, site: sites[currentSiteIndex])
        let astragali = Astragali()
        let reading = astragali.cast(
            configuration: config,
            regionState: world.regions.values.first ?? RegionState(name: "Unknown"),
            profile: profile,
            seed: UInt64(clock.currentTick)
        )
        
        print("\n  The Bones Say:")
        print("  Coherence: \(reading.coherence.rawValue)")
        print("  Resonance: \(reading.resonance.rawValue)")
        print("  Conflict: \(reading.conflict.rawValue)")
        print("  Veil State: \(reading.veilState.rawValue)")
        print("\n  (The reading consumes 1 tick)")
        
        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)
        processWorldEvents(events)
        processDirectorEvents()
    }
}
