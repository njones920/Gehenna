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

        // ── Spirit manifestation ─────────────────────────────────────────
        if let spirit = result.spirit {
            printManifestation(spirit, result: result)

            let spiritRoot = spirit.rootIdentityID.flatMap { rid in
                rootIdentities.first { $0.id == rid }
            }
            let speech = await expressionEngine.spiritSpeech(
                spirit,
                practitioner: profile,
                rootIdentity: spiritRoot
            )
            print("  \"\(speech)\"")

            // Archive encounter in the Codex of the Dead.
            let autopsyLines = autopsyText.components(separatedBy: ". ").filter { !$0.isEmpty }
            _ = codex.recordEncounter(
                spirit: spirit,
                autopsy: autopsyLines,
                ritualID: UUID(),
                tick: clock.currentTick
            )
            codex.crossLinkEpochs()

            let anchored = retinue.anchor(
                spirit,
                atTick: clock.currentTick,
                originSiteID: site.id,
                capacity: profile.summonerCapacity
            )
            if anchored {
                print("\n  You anchor the spirit. It walks with you now — for as long as it holds.")
                print("  (Type 'spirits' to see who is with you, 'dismiss' to part ways.)")
                if retinue.count > 1 {
                    print("  The others feel the new presence. The strain of company is shared.")
                }
            } else {
                print("\n  You cannot hold another. The anchor slips, and the spirit disperses")
                print("  like breath in cold air. It noticed the attempt.")
            }
        } else {
            print("  The libation sinks into the earth. Nothing answers.")
        }

        // ── Profile consequences ─────────────────────────────────────────
        // Applies contagion, purity drain, taboo detection (graveRobbing,
        // uncleanSacrifice, tophethPact), and fatigue from the specific
        // fragment + site + libation combination.
        profile.applyRitualConsequences(configuration: config, result: result)

        // Advances totalRituals, successfulRituals/failedRituals, wasMutation,
        // domainExperience, entropyFootprint, ritualFatigue, summonerSkill,
        // and capacity milestone checks.
        let wasMutation = result.outcomeClass == .mutation
        let entropyCost = result.worldEffects.corruptionDelta
            + result.worldEffects.ghostActivityDelta
            + result.worldEffects.spiritualPressureDelta
        profile.recordRitual(
            success: result.spirit != nil,
            wasMutation: wasMutation,
            domain: fragment.domain,
            entropyCost: entropyCost
        )

        // ── World state effects ──────────────────────────────────────────
        // Push ritual entropy into the region and update site scarring.
        if let regionID = world.regions.values.first?.id {
            world.applyRitualEffects(result.worldEffects, regionID: regionID, site: &site)
        }

        // Apply site-level scarring from the result.
        if result.worldEffects.corruptionDelta > 0.3 {
            print("  The site is permanently scarred by this interaction.")
        }
        site.localSuspicion = min(1.0, site.localSuspicion + result.worldEffects.suspicionDelta + 0.05)
        sites[currentSiteIndex] = site

        // ── Rumor seeding ────────────────────────────────────────────────
        // Village-type sites don't seed rumors (too public — no mystery).
        if site.type != .ancestorShrine {
            world.seedRitualRumor(
                site: site,
                wasMutation: wasMutation,
                libation: intent.libationType,
                timing: intent.timing,
                practitionerName: nil,
                npcs: &npcs
            )
        }

        // ── Journal entry ────────────────────────────────────────────────
        let journalType: JournalEntry.JournalEntryType = result.spirit != nil ? .spiritManifested : .ritualPerformed
        let journalDesc: String = {
            if let spirit = result.spirit {
                return "Manifested \(spirit.epochName ?? spirit.template.rawValue) at \(site.name)"
            } else {
                return "Ritual failed at \(site.name) — nothing answered"
            }
        }()
        world.journal.append(JournalEntry(
            tick: clock.currentTick,
            type: journalType,
            description: journalDesc,
            source: .practitioner,
            severity: wasMutation ? .rupture : (result.spirit != nil ? .significant : .notable),
            siteID: site.id,
            tags: Set(["ritual", wasMutation ? "mutation" : "standard"])
        ))

        // ── Advance time ─────────────────────────────────────────────────
        let events = advanceTime(.command)
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
        
        let events = advanceTime(.command)
        processWorldEvents(events)
        processDirectorEvents()
    }
}
