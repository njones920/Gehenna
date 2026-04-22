// MARK: - GEHENNA Interactive Ritual Terminal
// A physics engine for ancient cosmology, disguised as a game.
//
// This is the practitioner's interface to the grammar.
// No visible numbers. Read the world, not a stat sheet.

import Foundation
import GehennaEngine

@main
struct GehennaCLI {
    static func main() {
        let game = GameSession()
        game.run()
    }
}

// MARK: - Game Session

final class GameSession: @unchecked Sendable {
    var world: WorldSimulation
    var profile: PractitionerProfile
    var codex: CodexOfTheDead
    var sites: [RitualSite]
    var inventory: Inventory
    var currentSiteIndex: Int
    var pipeline: ResolutionPipeline
    var astragali: Astragali
    var autopsyReader: RitualAutopsy
    var ritualCount: Int
    var running: Bool
    var rootIdentities: [RootIdentity]
    var npcs: [NPC]
    var clock: WorldClock
    var director: WorldDirector

    struct Inventory {
        var fragments: [Fragment]
        var artifacts: [LifeArtifact]
        var memoryTraces: [MemoryTrace]
        var libations: [LibationType]
    }

    init() {
        let content = RidgeOfElah.createWorld()
        self.world = WorldSimulation(regions: [content.region])
        self.profile = PractitionerProfile()
        self.codex = CodexOfTheDead()
        self.sites = content.sites
        self.inventory = Inventory(
            fragments: content.fragments,
            artifacts: content.artifacts,
            memoryTraces: content.memoryTraces,
            libations: [.water, .water, .water, .fermentedWine, .fermentedWine]
        )
        self.currentSiteIndex = 0
        self.pipeline = ResolutionPipeline()
        self.astragali = Astragali()
        self.autopsyReader = RitualAutopsy()
        self.ritualCount = 0
        self.running = true
        self.rootIdentities = RidgeOfElah.rootIdentities()
        self.npcs = RidgeOfElah.kfarShalemNPCs()
        self.clock = WorldClock()
        self.director = WorldDirector()
    }

    // MARK: - Main Loop

    func run() {
        printSplash()
        printArrival()

        while running {
            printPrompt()
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
                continue
            }

            switch input {
            case "look", "l":
                lookAround()
            case "sites", "map":
                listSites()
            case "go", "travel", "g":
                travelMenu()
            case "fragments", "f":
                listFragments()
            case "artifacts", "a":
                listArtifacts()
            case "inventory", "i", "inv":
                showInventory()
            case "ritual", "r":
                ritualMenu()
            case "cast", "bones":
                castAstragali()
            case "codex", "c":
                showCodex()
            case "village", "v", "talk":
                villageMenu()
            case "world", "w":
                showWorldState()
            case "wait", "rest":
                advanceTime()
            case "profile", "p":
                showProfile()
            case "save":
                saveGame()
            case "load":
                loadGame()
            case "help", "h", "?":
                showHelp()
            case "quit", "q", "exit":
                running = false
                print("\n  The bones settle. The night continues without you.\n")
            default:
                print("  You consider \"\(input)\" but it means nothing here. Type 'help' for guidance.")
            }
        }
    }

    // MARK: - Display

    func printSplash() {
        print("""

        ╔══════════════════════════════════════════════╗
        ║                                              ║
        ║              G E H E N N A                   ║
        ║                                              ║
        ║   A physics engine for ancient cosmology,    ║
        ║           disguised as a game.               ║
        ║                                              ║
        ║          Ridge of Elah — v0.4.21             ║
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

          In your satchel: bone fragments gathered from old battlefields
          and older caves. A bronze spearhead green with oxide. Clay jars
          of water and wine. Four sheep knucklebones, smooth from handling.

          The dead are here. They have been here a long time.
          You have come to ask them questions.

          Type 'help' for commands. Type 'look' to survey your surroundings.
        """)
    }

    func printPrompt() {
        let site = sites[currentSiteIndex]
        print("\n  [\(site.name)] > ", terminator: "")
    }

    func deterministicSeed(fragmentID: UUID? = nil, salt: UInt64 = 0) -> UInt64 {
        let practitionerBytes = profile.id.uuid
        let practitionerSalt =
            (UInt64(practitionerBytes.0) << 56) |
            (UInt64(practitionerBytes.1) << 48) |
            (UInt64(practitionerBytes.2) << 40) |
            (UInt64(practitionerBytes.3) << 32) |
            (UInt64(practitionerBytes.4) << 24) |
            (UInt64(practitionerBytes.5) << 16) |
            (UInt64(practitionerBytes.6) << 8) |
            UInt64(practitionerBytes.7)

        let fragmentSalt: UInt64
        if let fragmentID {
            let fragmentBytes = fragmentID.uuid
            fragmentSalt =
                (UInt64(fragmentBytes.8) << 56) |
                (UInt64(fragmentBytes.9) << 48) |
                (UInt64(fragmentBytes.10) << 40) |
                (UInt64(fragmentBytes.11) << 32) |
                (UInt64(fragmentBytes.12) << 24) |
                (UInt64(fragmentBytes.13) << 16) |
                (UInt64(fragmentBytes.14) << 8) |
                UInt64(fragmentBytes.15)
        } else {
            fragmentSalt = 0
        }

        return UInt64(bitPattern: Int64(clock.currentTick))
            &+ practitionerSalt
            &+ fragmentSalt
            &+ UInt64(ritualCount)
            &+ UInt64(currentSiteIndex)
            &+ salt
    }

    var saveURL: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("gehenna-save.json")
    }

    func makeSnapshot() -> SinglePlayerSnapshot {
        SinglePlayerSnapshot(
            savedAtTick: clock.currentTick,
            world: world,
            profile: profile,
            codex: codex,
            sites: sites,
            inventory: PractitionerInventorySnapshot(
                fragments: inventory.fragments,
                artifacts: inventory.artifacts,
                memoryTraces: inventory.memoryTraces,
                libations: inventory.libations
            ),
            currentSiteIndex: currentSiteIndex,
            ritualCount: ritualCount,
            rootIdentities: rootIdentities,
            npcs: npcs,
            clock: clock
        )
    }

    func applySnapshot(_ snapshot: SinglePlayerSnapshot) {
        world = snapshot.world
        profile = snapshot.profile
        codex = snapshot.codex
        sites = snapshot.sites
        inventory = Inventory(
            fragments: snapshot.inventory.fragments,
            artifacts: snapshot.inventory.artifacts,
            memoryTraces: snapshot.inventory.memoryTraces,
            libations: snapshot.inventory.libations
        )
        currentSiteIndex = snapshot.currentSiteIndex
        ritualCount = snapshot.ritualCount
        rootIdentities = snapshot.rootIdentities
        npcs = snapshot.npcs
        clock = snapshot.clock
    }

    // MARK: - Commands

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

        // Advance time — rituals cost standard time
        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)

        // Propagate rumors to nearby NPCs based on site suspicion
        let rumorSite = sites[currentSiteIndex]
        if rumorSite.localSuspicion > 0.05 {
            for i in npcs.indices {
                let rumorStrength = rumorSite.rumorStrength(for: npcs[i].faction)
                if rumorStrength > 0.01 {
                    npcs[i].hearRumor(strength: rumorStrength)
                }
            }
        }

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

    func showProfile() {
        print("\n  ── The Practitioner ──")
        print("    Phase: \(profile.masteryPhase.rawValue.capitalized)")
        print("    Rituals performed: \(profile.totalRituals)")
        print("    Successful: \(profile.successfulRituals)")
        if profile.mutationRituals > 0 {
            print("    Mutations: \(profile.mutationRituals)")
        }
        print("    Spirits sustained: \(profile.summonerCapacity)")
        print("    Purity: \(describeLevel(profile.tokens.effectivePurity, low: "unclean", mid: "adequate", high: "purified"))")
        if profile.tokens.corpseContagion > 0.3 {
            print("    ⚠ Heavy contagion from handling the dead.")
        }
        if let dominant = profile.dominantDomain {
            print("    Dominant practice: \(dominant.rawValue)")
        }
        print("    Entropy footprint: \(describeLevel(profile.entropyFootprint / 10.0, low: "faint", mid: "visible", high: "heavy"))")
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

    func showHelp() {
        print("""

          ── Commands ──
            look (l)         Survey your current location
            sites / map      List all known locations
            go (g)           Travel to another location
            inventory (i)    View your satchel
            fragments (f)    Examine bone fragments
            artifacts (a)    Examine artifacts and memory traces
            ritual (r)       Compose and perform a ritual
            cast / bones     Cast the astragali (diagnostic bones)
            codex (c)        Browse your Codex of the Dead
            village (v)      Talk to the people of Kfar Shalem
            world (w)        Read the state of the region
            wait / rest      Let time pass
            profile (p)      View your practitioner record
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
