import Foundation
import GehennaEngine

extension GameSession {
    func printSplash() {
        print("""

        ╔══════════════════════════════════════════════╗
        ║                                              ║
        ║              G E H E N N A                   ║
        ║                                              ║
        ║   A physics engine for ancient cosmology,    ║
        ║           disguised as a game.               ║
        ║                                              ║
        ║          Ridge of Elah — v0.4.30             ║
        ║                                              ║
        ╚══════════════════════════════════════════════╝

        """)
    }

    func printArrival() {
        print("""
          You arrive at the Ridge of Elah as the light fails.

          The Shephelah stretches west toward the coast, low hills folding
          into each other like knuckles. Somewhere beyond the ridge, the
          coastal cities hold their ground. Somewhere behind you, the
          highlands rise into territory claimed by tribes who do not
          welcome strangers.

          You are between. That is where practitioners do their work.

          In your satchel: a set of clay jars — water and wine — and four
          sheep knucklebones, smooth from handling. The bone fragments are
          out there, waiting to be found. 'Scavenge' at each site to
          collect them. The dead do not come to you.

          Type 'help' for commands. Type 'look' to survey your surroundings.
        """)
    }

    func printPrompt() {
        let site = sites[currentSiteIndex]
        print("\n  [\(site.name)] > ", terminator: "")
    }

    func showCodex() {
        print("\n  ── Codex of the Dead ──")
        if codex.totalEncountered == 0 {
            print("    The pages are blank. You have not yet called anyone back.")
            return
        }

        print("    \(codex.progressSummary)")
        print()

        for entry in codex.recentEntries {
            let name = entry.epochName ?? entry.knownName ?? "Unknown"
            let template = entry.template.rawValue.capitalized
            let tier = describeTier(entry.tier)
            let completeness = entry.completeness.rawValue
            print("    ◆ \(name) — \(template) (\(tier))")
            print("      \(completeness.capitalized) | Encountered \(entry.encounterCount) time(s)")
            if !entry.observedTraits.isEmpty {
                print("      Traits: \(entry.observedTraits.map(\.rawValue).joined(separator: ", "))")
            }
            if !entry.observedDispositions.isEmpty {
                print("      Seen: \(entry.observedDispositions.map(\.rawValue).joined(separator: ", "))")
            }
            let identityTags = entry.knownTags.tags(in: .identity)
            if !identityTags.isEmpty {
                print("      Identity: \(identityTags.map(\.value).joined(separator: ", "))")
            }
            if !entry.linkedEntries.isEmpty {
                print("      └─ Cross-referenced: this one has other faces. \(entry.linkedEntries.count) linked aspect(s).")
            }
        }

        // Show discovered root identities
        let roots = codex.discoveredRootIdentities
        if !roots.isEmpty {
            print("\n    ── Root Identities Discovered ──")
            for (_, entries) in roots {
                let names = entries.compactMap(\.epochName).joined(separator: ", ")
                print("      ◇ Same person manifesting as: \(names)")
            }
        }
    }

    func showWorldState() {
        guard let region = world.regions.values.first else { return }
        print("\n  ── The World ──")
        print("    \(region.name) — Tick \(clock.currentTick)")
        print()

        // Diegetic state reporting — no numbers
        print("    Settlement: \(describeLevel(region.population, low: "depopulated", mid: "strained", high: "thriving"))")
        print("    Conflict:   \(describeLevel(region.warIntensity, low: "quiet", mid: "tense", high: "at war"))")
        print("    Dead:       \(describeLevel(region.ghostActivity, low: "settled", mid: "restless", high: "raging"))")
        print("    Corruption: \(describeLevel(region.corruption, low: "clean", mid: "seeping", high: "saturated"))")
        print("    Order:      \(describeLevel(region.stability, low: "collapsing", mid: "fragile", high: "stable"))")
        print("    Suspicion:  \(describeLevel(region.suspicion, low: "unnoticed", mid: "rumors", high: "hunted"))")
        print("    Pressure:   \(describeLevel(region.spiritualPressure, low: "dormant", mid: "building", high: "immense"))")
        print("    Veil:       \(describeLevel(region.veilThinness, low: "thick", mid: "thinning", high: "threadbare"))")

        if world.sebittiActive {
            print("\n    ⚠ THE SEVEN ARE ACTIVE — the correction is underway.")
        }
        if world.hasTerminalRegion {
            print("\n    ☠ MOT has claimed territory. The dead zone grows.")
        }
    }

    func showProfile() {
        print("\n  ── The Practitioner ──")
        print("    Phase: \(profile.masteryPhase.rawValue.capitalized)")
        switch profile.masteryPhase {
        case .apprentice:
            print("    You have attempted the rite only a few times. The grammar is still unfamiliar.")
        case .practitioner:
            print("    You have performed the rite enough times to know what failure feels like.")
        case .adept:
            print("    You have learned through repetition what cannot be taught.")
        case .master:
            print("    The rite is memory now. You no longer think about the steps.")
        }
        if debugMode {
            print("    [debug] Rituals performed: \(profile.totalRituals)")
            print("    [debug] Successful: \(profile.successfulRituals)")
        }
        if profile.mutationRituals > 0 {
            print("    Mutations: \(profile.mutationRituals)")
        }
        if retinue.isEmpty {
            print("    No spirit walks with you. You could hold \(capacityDescription(profile.summonerCapacity)).")
        } else {
            print("    \(retinue.count == 1 ? "One spirit walks" : "\(retinue.count) spirits walk") with you. You can hold \(capacityDescription(profile.summonerCapacity)).")
        }
        print("    Purity: \(describeLevel(profile.tokens.effectivePurity, low: "unclean", mid: "adequate", high: "purified"))")
        if profile.tokens.corpseContagion > 0.3 {
            print("    ⚠ Heavy contagion from handling the dead.")
        }
        if let dominant = profile.dominantDomain {
            print("    Dominant practice: \(dominant.rawValue)")
        }
        print("    Entropy footprint: \(describeLevel(profile.entropyFootprint / 10.0, low: "faint", mid: "visible", high: "heavy"))")
    }

    func showTaboos() {
        print("\n  ── The Marks You Bear ──")
        if profile.taboosBroken.isEmpty {
            print("    Your hands are clean. You have broken no laws of the deep earth.")
            return
        }

        for taboo in profile.taboosBroken.sorted(by: { $0.rawValue < $1.rawValue }) {
            let description: String
            switch taboo {
            case .bloodshed:      description = "You have shed blood where the dead sleep."
            case .graveRobbing:   description = "You have taken from the dead without offering."
            case .falseName:      description = "You have lied to the dead about who they are."
            case .uncleanSacrifice: description = "You have brought corruption to a holy place."
            case .oathBreaking:   description = "You have broken a vow to a spirit."
            case .tophethPact:    description = "You have made pacts in Gehenna."
            }
            print("    ◆ \(description)")
        }
    }

    func showHelp() {
        print("""

          ── Commands ──
            look (l)         Survey your current location
            sites / map      List all known locations
            go (g)           Travel to another location
            scavenge         Search the site for bone fragments and artifacts
            inventory (i)    View your satchel
            fragments (f)    Examine bone fragments
            artifacts (a)    Examine artifacts and memory traces
            inspect          Inspect a fragment in detail
            ritual (r)       Compose and perform a ritual
            spirits          See who walks with you (retinue)
            speak            Converse with a bound spirit — every word costs
            call             Call someone you know back by name
            dismiss          Part ways with a bound spirit
            cast / bones     Cast the astragali (diagnostic bones)
            codex (c)        Browse your Codex of the Dead
            village (v)      Talk to the people of Kfar Shalem
            rumors / gossip  What the village is saying
            world (w)        Read the state of the region
            wait / rest      Let time pass
            profile (p)      View your practitioner record
            taboos / sins    View the marks you carry
            save             Seal the current state to gehenna-save.json
            load             Restore the current state from gehenna-save.json
            help (h / ?)     Show this help
            quit (q)         Leave
        """)
    }

    // MARK: - World Event Processing

    /// Process clock-generated events and display them diegetically.
    func processWorldEvents(_ events: [WorldEvent]) {
        for event in events {
            let icon: String = switch event.severity {
            case .rupture: "☠"
            case .significant: "⚠"
            case .notable: "◇"
            case .ambient: "·"
            }
            print("\n  \(icon) \(event.description)")
        }
    }

    /// Run the world director and display any unsolicited narration.
    /// This is where the world speaks first.
    func processDirectorEvents() {
        let directorEvents = director.evaluate(
            world: world,
            sites: sites,
            npcs: npcs,
            currentSiteIndex: currentSiteIndex,
            clock: clock
        )

        for event in directorEvents {
            print()
            printWrapped("  \(event.description)", indent: 2)
        }
    }

    // MARK: - Rendering

    func printAstragaliReading(_ reading: AstragaliReading) {
        print("    You cast the four knucklebones on the stone.")
        print()
        print("    Coherence: \(renderBoneReading(reading.coherence))")
        print("    Resonance: \(renderBoneReading(reading.resonance))")
        print("    Conflict:  \(renderBoneReading(reading.conflict))")
        print("    Veil:      \(renderBoneReading(reading.veilState))")
        print()
        if reading.reliableCount < 4 {
            let unreliable = 4 - reading.reliableCount
            print("    ⚠ \(unreliable) bone(s) fell wrong. The reading is degraded.")
            print("      The Veil here is too thin for clean divination.")
        }
    }

    func renderBoneReading(_ reading: AstragalusReading) -> String {
        switch reading {
        case .favorable:  return "◈ favorable — the bone rests cleanly"
        case .warning:    return "◇ warning — the bone hesitates"
        case .hostile:    return "◆ hostile — the bone turns against you"
        case .unreliable: return "? — the bone will not speak clearly"
        }
    }

    func printManifestation(_ spirit: Spirit, result: RitualResult) {
        print("  Something changes in the space.")
        print()

        switch result.outcomeClass {
        case .targeted:
            print("  The presence arrives with specificity. It knows why it is here.")
        case .guided:
            print("  A presence forms. Close to what you intended, but with its own edges.")
        case .wildDraw:
            print("  A stranger answers. You are not sure who you have called.")
        case .hostile:
            print("  The presence arrives unwilling. The air sharpens.")
        case .mutation:
            print("  What forms is not whole. The fragments did not agree, and")
            print("  what filled the gaps was not from any person who ever lived.")
        case .failure:
            print("  Nothing answers.")
            return
        }

        print()

        // Disposition
        switch spirit.disposition {
        case .calm:      print("  It waits. Patient. Neutral.")
        case .hostile:   print("  It is angry. You feel the cold of it.")
        case .curious:   print("  It leans toward you. Interested.")
        case .sorrowful: print("  Grief comes off it like heat from stone at dusk.")
        case .hungry:    print("  It wants something from you. You feel the pull.")
        case .honored:   print("  It arrives with dignity. You called it well.")
        }

        // Tier impression
        print()
        let tier = describeTier(spirit.tier)
        let template = spirit.template.rawValue.capitalized
        print("  [\(template) — \(tier)\(spirit.isMutation ? " — MUTATION" : "")\(spirit.epochName != nil ? " — \(spirit.epochName!)" : "")]")
    }

    // MARK: - Village Interaction

    func npcGreeting(_ npc: NPC) -> String {
        let style = npc.register.style
        let name = npc.name

        if npc.trust > 0.7 {
            switch style {
            case .formal:     return "\"\(name) inclines his head. 'You again. Sit. There is water.'\""
            case .warm:       return "\"\(name) sees you and her face opens. 'Come, come. The bread is still warm.'\""
            case .merchant:   return "\"\(name) waves you over with practiced ease. 'Friend! I have something you need to see.'\""
            case .guarded:    return "\"\(name) nods once. A small thing, but more than most get.\""
            case .priestly:   return "\"\(name) regards you carefully. 'Peace be upon you, stranger. What brings you?'\""
            case .vernacular: return "\"\(name) doesn't look up from the forge. 'Sit if you want. Don't touch anything.'\""
            }
        } else if npc.personalSuspicion > 0.4 {
            switch style {
            case .formal:     return "\"\(name) looks at you with measured distance. 'I see you are still among us.'\""
            case .warm:       return "\"\(name)'s smile doesn't reach her eyes today.\""
            case .merchant:   return "\"\(name) glances at your hands before meeting your eyes. 'Trading today?'\""
            case .guarded:    return "\"\(name) watches you approach from the corner of her eye.\""
            case .priestly:   return "\"\(name) stands straighter when he sees you. 'The LORD sees all who come to this place.'\""
            case .vernacular: return "\"\(name) pauses his hammering. Waiting.\""
            }
        } else {
            switch style {
            case .formal:     return "\"\(name) acknowledges your presence with the politeness owed to a stranger.\""
            case .warm:       return "\"\(name) looks up from her work. 'The morning is good. Are you hungry?'\""
            case .merchant:   return "\"\(name) sizes you up with commercial interest. 'New face. Where from?'\""
            case .guarded:    return "\"\(name) watches you. Says nothing. Waits.\""
            case .priestly:   return "\"\(name) steps forward. 'Shalom. Are you passing through, or do you intend to stay?'\""
            case .vernacular: return "\"\(name) nods at you from across the forge. 'Need something made?'\""
            }
        }
    }

    func friendlyResponse(_ npc: NPC) -> String {
        let refs = npc.register.references
        let topic = refs.first ?? "the weather"
        return "\"\(npc.name) talks about \(topic). The conversation is easy in the way that conversations between people with nothing to hide are easy. For a moment, you are just a traveler, and they are just a person, and the dead below the hill are not your concern.\""
    }

    func regionResponse(_ npc: NPC) -> String {
        switch npc.faction {
        case .elders:
            return "\"\(npc.name) speaks of the settlement carefully. The harvest is uncertain this year. Philistine patrols were seen near the wadi. The families are holding, but there is strain. They do not mention what lives under the ridge.\""
        case .traders:
            return "\"\(npc.name) talks about the roads. Caravans from the coast are running late. There is trouble in Ekron — the garrison is reinforcing. Copper prices are rising. Information wrapped in commerce, as always.\""
        case .priesthood:
            return "\"\(npc.name) speaks of the sanctuary, the tithes, the holy days approaching. Underneath the piety there is something else — a watchfulness that goes beyond pastoral care.\""
        }
    }

    func deadResponse(_ npc: NPC) -> String {
        switch npc.faction {
        case .priesthood:
            return "\"\(npc.name)'s expression hardens instantly. 'The dead are the LORD's concern, not ours. Why do you ask?' There is no curiosity in the question. It is a wall.\""
        case .elders:
            return "\"\(npc.name) goes still. A particular kind of stillness that comes from disciplined avoidance. 'We do not speak of such things. The caves are old and best left alone.' But you notice — they said 'the caves.' They did not ask which caves. They know.\""
        case .traders:
            return "\"\(npc.name) leans back. Something shifts behind their eyes — calculation, not fear. 'The coast has stories. Old stories. But stories don't buy grain, do they?' They're measuring what you know. And what you're willing to pay.\""
        }
    }

    func thresholdResponse(_ npc: NPC) -> String {
        // When the NPC reaches their threshold, their interiority breaks through.
        // The private truth or the wound surfaces, depending on context.
        return "\"Something shifts in \(npc.name). The professional face drops. For a moment you see the person underneath — the one who was here before you arrived, the one who will be here after you leave. '\(npc.interiority.threshold)'\""
    }

    // MARK: - Description Helpers

    func describeSite(_ site: RitualSite) -> String {
        switch site.type {
        case .battlefield:
            return "The ridge runs east-west, exposed to the wind. The earth is disturbed where recent fighting churned the soil. Fragments of bone surface after every rain. The smell of old fire lingers."
        case .collapsingTemple:
            return "Tel Keshet rises from the plain — a mound of ruins, each layer older than the last. Bronze Age walls crumble into Iron Age floors. The silence here is architectural, held in stone. Something in the deep levels was once holy."
        case .burialCave:
            return "The limestone opens into darkness. A spring murmurs somewhere deep inside, and the acoustic shifts — a low resonance you feel more than hear. Bench tombs line the walls. Bones rest in secondary burial niches. The air is cool and does not move."
        case .ancestorShrine:
            return "Kfar Shalem clusters on the hillside, mudbrick and limestone under a haze of cooking smoke. Dogs bark. A woman beats grain at a threshold. An old man watches you from the shade of a grapevine trellis. You are noticed here."
        case .topheth:
            return "The wadi narrows to a cleft in the rock. The ground is dark — ash, compacted over generations, mixed with bone fragments too small to collect. The fire affinity is overwhelming. This is Gehenna. This is where the game gets its name, and you are standing in it."
        default:
            return "A place in the Ridge of Elah."
        }
    }

    func briefSiteDescription(_ site: RitualSite) -> String {
        switch site.type {
        case .battlefield:       return "recent dead, war domain"
        case .collapsingTemple:  return "ancient ruins, knowledge and faith"
        case .burialCave:        return "limestone tombs, mixed era"
        case .ancestorShrine:    return "living village, social zone"
        case .topheth:           return "defiled ground, high corruption"
        default:                 return site.type.rawValue
        }
    }

    func travelDescription(_ site: RitualSite) -> String {
        switch site.type {
        case .battlefield:       return "The ridge opens before you. The wind carries dust and the memory of conflict."
        case .collapsingTemple:  return "You climb the tel. Each step raises older dust."
        case .burialCave:        return "You descend into the caves. The temperature drops. The spring whispers."
        case .ancestorShrine:    return "You enter the village. Eyes follow you. You are an outsider here."
        case .topheth:           return "You enter the wadi. The ground darkens underfoot. The air tastes of old fire."
        default:                 return "You arrive."
        }
    }

    func describeRemainsType(_ type: RemainsType) -> String {
        switch type {
        case .skull:         return "Skull"
        case .longBone:      return "Long bone (femur)"
        case .ribFragment:   return "Rib fragment"
        case .handBones:     return "Hand bones"
        case .ossuaryChip:   return "Ossuary chip"
        case .crematedBone:  return "Cremated bone"
        case .toothFragment: return "Tooth fragment"
        }
    }

    func describeIntegrity(_ integrity: Integrity) -> String {
        switch integrity.value {
        case 0.9...1.0: return "pristine"
        case 0.6..<0.9: return "worn"
        case 0.3..<0.6: return "degraded"
        case 0.1..<0.3: return "corrupted"
        default:        return "ruined"
        }
    }

    func describeEra(_ era: Era) -> String {
        switch era {
        case .ironAgeII:    return "recent (Iron Age II)"
        case .ironAgeI:     return "a century old (Iron Age I)"
        case .lateBronze:   return "ancient (Late Bronze Age)"
        case .middleBronze: return "very old (Middle Bronze Age)"
        case .earlyBronze:  return "archaic (Early Bronze Age)"
        case .antediluvian:  return "before record"
        }
    }

    func describeLibation(_ type: LibationType) -> String {
        switch type {
        case .water:          return "Plain water"
        case .fermentedWine:  return "Fermented wine"
        case .ritualMixture:  return "Ritual mixture (wine, rue, lotus)"
        case .bloodOffering:  return "Blood offering"
        case .honeyWine:      return "Honey wine"
        case .mimicBlood:     return "Mimic blood"
        case .opiumTincture:  return "Opium tincture"
        }
    }

    func describeTier(_ tier: SpiritTier) -> String {
        switch tier {
        case .common:    return "common shade"
        case .uncommon:  return "remembered dead"
        case .rare:      return "the old ones"
        case .legendary: return "legendary"
        case .mythic:    return "mythic"
        }
    }

    func describeLevel(_ value: Double, low: String, mid: String, high: String) -> String {
        switch value {
        case 0.0..<0.3:  return low
        case 0.3..<0.6:  return mid
        default:         return high
        }
    }

    func printWrapped(_ text: String, indent: Int) {
        let prefix = String(repeating: " ", count: indent)
        let words = text.split(separator: " ")
        var line = prefix
        let maxWidth = 72

        for word in words {
            if line.count + word.count + 1 > maxWidth {
                print(line)
                line = prefix + String(word)
            } else {
                if line.count > indent { line += " " }
                line += String(word)
            }
        }
        if !line.trimmingCharacters(in: .whitespaces).isEmpty {
            print(line)
        }
    }
}
