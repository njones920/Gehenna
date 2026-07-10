// MARK: - Gehenna Arena
// A headless shared-world bot arena.
// Multiple bot practitioners act inside the same Ridge of Elah,
// scar the same sites, hear the same rumors, and collide through
// shared consequences.
//
// Usage: swift run gehenna-arena [--bots N] [--ticks T] [--seed S] [--verbose]
//
// This is the multiplayer proof: clone, build, launch a swarm,
// watch the world scar itself.

import Foundation
import GehennaEngine

// MARK: - Bot Personality

/// A bot practitioner with a strategy that guides its decisions.
struct BotPersonality {
    let name: String
    let strategy: Strategy
    let preferredSiteIndex: Int
    let preferredFragmentIndex: Int
    let aggressiveness: Double  // 0.0 = cautious, 1.0 = reckless

    enum Strategy: String {
        case scholar
        case reckless
        case social
        case explorer
        case balanced
        case humanProxy  // Represents a slow, deliberate human player
        case healer      // Represents a bot optimizing for purification
    }
}

let botNames: [(String, BotPersonality.Strategy, Int, Int, Double)] = [
    ("Practitioner Aleph",   .scholar,   2, 2, 0.2),  // Nahal Caves, skull
    ("Practitioner Bet",     .reckless,  4, 0, 0.9),  // Burning Ground, long bone
    ("Practitioner Gimel",   .social,    3, 5, 0.3),  // Kfar Shalem, ossuary chip
    ("Practitioner Dalet",   .explorer,  0, 4, 0.5),  // Battlefield, MB long bone
    ("Practitioner He",      .balanced,  1, 6, 0.4),  // Tel Keshet, archaic skull
    ("Practitioner Vav",     .reckless,  4, 7, 0.8),  // Burning Ground, cremated bone
    ("Practitioner Zayin",   .scholar,   2, 3, 0.3),  // Nahal Caves, hand bones
    ("Practitioner Chet",    .social,    3, 1, 0.2),  // Kfar Shalem, rib fragment
    ("Practitioner Tet",     .explorer,  0, 0, 0.6),  // Battlefield, long bone
    ("Practitioner Yod",     .balanced,  1, 2, 0.5),  // Tel Keshet, skull
    ("Practitioner Kaf",     .reckless,  4, 8, 1.0),  // Burning Ground, tooth
    ("Practitioner Lamed",   .scholar,   2, 6, 0.1),  // Nahal Caves, archaic skull
]

// MARK: - Bot Decision Engine

func chooseCommand(
    for bot: BotPersonality,
    session: PractitionerSession,
    tick: Int,
    siteCount: Int,
    npcCount: Int
) -> PlayerCommand {
    let phase = tick % 20  // 20-tick cycle

    switch bot.strategy {
    case .scholar:
        switch phase {
        case 0...2:   return .look
        case 3...4:   return .travel(siteIndex: bot.preferredSiteIndex)
        case 5:       return .castAstragali
        case 6...8:   return .look
        case 9...12:
            return .performRitual(RitualIntent(
                fragmentIndex: bot.preferredFragmentIndex % session.inventory.fragments.count,
                trueName: trueName(for: bot.preferredFragmentIndex),
                artifactIndex: 0,
                traceIndex: 0,
                libationType: .water,
                timing: WorldTiming(time: .deepNight)
            ))
        case 13...15: return .talkTo(npcIndex: 0, action: .friendly)
        case 16...17: return .wait
        default:      return .look
        }

    case .reckless:
        switch phase {
        case 0:       return .travel(siteIndex: bot.preferredSiteIndex)
        case 1...6:
            let fragIndex = (bot.preferredFragmentIndex + phase) % session.inventory.fragments.count
            return .performRitual(RitualIntent(
                fragmentIndex: fragIndex,
                trueName: trueName(for: fragIndex),
                libationType: phase % 2 == 0 ? .fermentedWine : .bloodOffering,
                timing: WorldTiming(time: .deepNight)
            ))
        case 7:       return .look
        case 8...13:
            return .performRitual(RitualIntent(
                fragmentIndex: bot.preferredFragmentIndex % session.inventory.fragments.count,
                trueName: trueName(for: bot.preferredFragmentIndex),
                artifactIndex: 2,
                libationType: .bloodOffering,
                timing: WorldTiming(time: .deepNight)
            ))
        case 14:      return .castAstragali
        default:      return .look
        }

    case .social:
        switch phase {
        case 0:       return .travel(siteIndex: 3)  // go to village
        case 1...5:   return .talkTo(npcIndex: phase % min(npcCount, 6), action: .friendly)
        case 6...7:   return .talkTo(npcIndex: 0, action: .askRegion)
        case 8:       return .travel(siteIndex: bot.preferredSiteIndex)
        case 9:       return .look
        case 10:
            return .performRitual(RitualIntent(
                fragmentIndex: bot.preferredFragmentIndex % session.inventory.fragments.count,
                trueName: trueName(for: bot.preferredFragmentIndex),
                libationType: .water,
                timing: WorldTiming(time: .dusk)
            ))
        case 11...13: return .travel(siteIndex: 3)  // back to village
        case 14...16: return .talkTo(npcIndex: (phase - 14) % min(npcCount, 6), action: .friendly)
        default:      return .wait
        }

    case .explorer:
        let siteForPhase = phase % siteCount
        switch phase {
        case 0...4:   return .travel(siteIndex: siteForPhase)
        case 5:       return .look
        case 6:       return .castAstragali
        case 7...9:   return .travel(siteIndex: (siteForPhase + 1) % siteCount)
        case 10:      return .look
        case 11...13:
            return .performRitual(RitualIntent(
                fragmentIndex: bot.preferredFragmentIndex % session.inventory.fragments.count,
                trueName: trueName(for: bot.preferredFragmentIndex),
                libationType: .fermentedWine,
                timing: WorldTiming(time: .deepNight)
            ))
        case 14...16: return .travel(siteIndex: (siteForPhase + 2) % siteCount)
        default:      return .look
        }

    case .balanced:
        switch phase {
        case 0...1:   return .look
        case 2:       return .travel(siteIndex: bot.preferredSiteIndex)
        case 3...4:   return .talkTo(npcIndex: phase % min(npcCount, 6), action: .friendly)
        case 5:       return .castAstragali
        case 6...8:
            return .performRitual(RitualIntent(
                fragmentIndex: bot.preferredFragmentIndex % session.inventory.fragments.count,
                trueName: trueName(for: bot.preferredFragmentIndex),
                artifactIndex: 0,
                libationType: .fermentedWine,
                timing: WorldTiming(time: .dusk)
            ))
        case 9...10:  return .travel(siteIndex: (bot.preferredSiteIndex + 1) % siteCount)
        case 11:      return .look
        case 12...14: return .wait
        case 15:      return .travel(siteIndex: 3)
        case 16...17: return .talkTo(npcIndex: 0, action: .askRegion)
        default:      return .look
        }
    case .humanProxy:
        // Slow down the human. A human doesn't act 20 times a minute.
        // E.g., one action every 15 ticks.
        if tick % 15 != 0 { return .wait }
        let humanPhase = (tick / 15) % 20
        switch humanPhase {
        case 0...1:   return .travel(siteIndex: 3) // Village
        case 2...4:   return .talkTo(npcIndex: 0, action: .friendly)
        case 5...6:   return .talkTo(npcIndex: 1, action: .friendly)
        case 7:       return .travel(siteIndex: bot.preferredSiteIndex)
        case 8...10:  return .look
        case 11:
            return .performRitual(RitualIntent(
                fragmentIndex: bot.preferredFragmentIndex % session.inventory.fragments.count,
                trueName: trueName(for: bot.preferredFragmentIndex),
                artifactIndex: 0,
                libationType: .water,
                timing: WorldTiming(time: .dawn)
            ))
        case 12:      return .castAstragali
        case 13...15: return .purifySite
        default:      return .look
        }

    case .healer:
        // Healer acts fast, but focuses on cleaning up the world.
        let siteForPhase = phase % siteCount
        switch phase {
        case 0:       return .travel(siteIndex: siteForPhase)
        case 1...2:   return .purifySite
        case 3:       return .look
        case 4:       return .travel(siteIndex: 3) // Village
        case 5...6:   return .talkTo(npcIndex: phase % min(npcCount, 6), action: .friendly)
        case 7:       return .travel(siteIndex: (siteForPhase + 1) % siteCount)
        case 8...10:  return .purifySite
        case 11...13:
            // Safe, respectful rituals only
            return .performRitual(RitualIntent(
                fragmentIndex: bot.preferredFragmentIndex % session.inventory.fragments.count,
                trueName: trueName(for: bot.preferredFragmentIndex),
                libationType: .water,
                timing: WorldTiming(time: .dawn)
            ))
        case 14...16: return .purifySite
        default:      return .purifySite
        }
    }
}

func trueName(for fragmentIndex: Int) -> String? {
    switch fragmentIndex {
    case 2: return "Hiram, son of Dagon"
    case 6: return "Abdi-Resheph"
    case 3: return "Resheph"
    default: return nil
    }
}

// MARK: - Arena Runner

@main
struct GehennaArena {
    static func main() async {
        let args = CommandLine.arguments

        let botCount = argValue(args, flag: "--bots", default: 4)
        let totalTicks = argValue(args, flag: "--ticks", default: 200)
        let verbose = args.contains("--verbose")
        let reportInterval = argValue(args, flag: "--report", default: 50)

        let isDavidVsGoliath = args.contains("--david-vs-goliath")
        let goliathTypeArg = argString(args, flag: "--goliath-type", default: "reckless")
        let isVeteranGoliath = args.contains("--veteran-goliath")

        print("""

        ╔══════════════════════════════════════════════════╗
        ║                                                  ║
        ║           G E H E N N A   A R E N A              ║
        ║                                                  ║
        ║       Shared World Bot Arena — v0.5.0            ║
        ║                                                  ║
        ╚══════════════════════════════════════════════════╝

          Ticks: \(totalTicks)
          Mode: \(isDavidVsGoliath ? "David vs Goliath" : "Swarm (Bots: \(botCount))")
        """)

        if isDavidVsGoliath {
            print("          Goliath Strategy: \(goliathTypeArg)\(isVeteranGoliath ? " (VETERAN)" : "")")
        }
        print()

        // Create the shared world
        let content = RidgeOfElah.createWorld()
        let npcs: [NPC]
        let rootIdentities: [RootIdentity]
        do {
            npcs = try RidgeOfElah.kfarShalemNPCs()
            rootIdentities = try RidgeOfElah.rootIdentities()
        } catch {
            fatalError("Canon load failed: \(error). Cannot start with empty world state.")
        }
        let shard = WorldShard(
            world: WorldSimulation(regions: [content.region]),
            sites: content.sites,
            npcs: npcs,
            rootIdentities: rootIdentities
        )

        // Register bots
        var botIDs: [(UUID, BotPersonality)] = []
        
        if isDavidVsGoliath {
            let david = BotPersonality(name: "David (Human Proxy)", strategy: .humanProxy, preferredSiteIndex: 2, preferredFragmentIndex: 6, aggressiveness: 0.1)
            let goliathStrategy: BotPersonality.Strategy = goliathTypeArg == "healer" ? .healer : .reckless
            let goliath = BotPersonality(name: "Goliath (Bot)", strategy: goliathStrategy, preferredSiteIndex: 4, preferredFragmentIndex: 8, aggressiveness: 1.0)
            
            let dSession = PractitionerSession(name: david.name, fragments: [], artifacts: [], memoryTraces: [])
            var gSession = PractitionerSession(name: goliath.name, fragments: [], artifacts: [], memoryTraces: [])
            
            if isVeteranGoliath {
                gSession.ritualCount = 150
                gSession.profile.totalRituals = 150
                gSession.profile.taboosBroken.insert(.tophethPact)
                gSession.profile.taboosBroken.insert(.uncleanSacrifice)
            }
            
            let dID = await shard.addPractitioner(dSession)
            let gID = await shard.addPractitioner(gSession)
            botIDs.append((dID, david))
            botIDs.append((gID, goliath))
            
            print("  ◈ Registered: \(david.name) (\(david.strategy))")
            print("  ◈ Registered: \(goliath.name) (\(goliath.strategy))")
        } else {
            for i in 0..<botCount {
                let template = botNames[i % botNames.count]
                let personality = BotPersonality(
                    name: template.0,
                    strategy: template.1,
                    preferredSiteIndex: template.2,
                    preferredFragmentIndex: template.3,
                    aggressiveness: template.4
                )

                let session = PractitionerSession(
                    name: personality.name,
                    fragments: [],
                    artifacts: [],
                    memoryTraces: []
                )

                let id = await shard.addPractitioner(session)
                botIDs.append((id, personality))
                print("  ◈ Registered: \(personality.name) (\(personality.strategy)) → \(content.sites[personality.preferredSiteIndex].name)")
            }
        }
        print()

        // Run the simulation
        print("  ── Simulation Begin ──\n")

        for tick in 1...totalTicks {
            // Each bot acts once per tick
            for (id, personality) in botIDs {
                guard let session = await shard.session(for: id) else { continue }

                let command = chooseCommand(
                    for: personality,
                    session: session,
                    tick: tick,
                    siteCount: await shard.sites.count,
                    npcCount: await shard.npcs.count
                )

                let result = await shard.execute(command, for: id)

                if verbose {
                    for line in result.narration {
                        print("    [\(personality.name)] \(line)")
                    }
                    for event in result.worldEvents {
                        print("    ⚠ \(event.description)")
                    }
                    for event in result.directorEvents {
                        print("    ◇ \(event.description)")
                    }
                }
            }

            // Periodic report
            if tick % reportInterval == 0 || tick == totalTicks {
                await printReport(shard: shard, tick: tick, botIDs: botIDs)
            }
        }

        // Final summary
        print("\n  ── Simulation Complete ──\n")
        await printFinalSummary(shard: shard, botIDs: botIDs)
    }

    static func printReport(shard: WorldShard, tick: Int, botIDs: [(UUID, BotPersonality)]) async {
        let sites = await shard.siteStates
        let journal = await shard.journal

        print("  ┌─ Tick \(tick) Report ──────────────────────────────")

        // Site states
        print("  │")
        print("  │ Sites:")
        for site in sites {
            let scarLabel = site.isScarred ? " [SCARRED]" : ""
            let disturbLabel = site.isDisturbed ? " [DISTURBED]" : ""
            let traceCount = site.activeTraces.count
            let suspicion = site.localSuspicion > 0.3 ? " [WATCHED]" : ""
            print("  │   \(site.name): veil=\(String(format: "%.0f%%", site.effectiveVeilThinness * 100)) scar=\(String(format: "%.0f%%", site.scarring * 100)) traces=\(traceCount)\(scarLabel)\(disturbLabel)\(suspicion)")
        }

        // NPC states
        let npcs = await shard.npcs
        print("  │")
        print("  │ NPCs:")
        for npc in npcs {
            let status: String
            if npc.isRefusing { status = "REFUSING" }
            else if npc.wouldFlee { status = "FLEEING" }
            else if npc.wouldApproach { status = "APPROACHING" }
            else if npc.hasHeardRumors { status = "cautious" }
            else { status = "neutral" }
            print("  │   \(npc.name): trust=\(String(format: "%.0f%%", npc.trust * 100)) suspicion=\(String(format: "%.0f%%", npc.personalSuspicion * 100)) [\(status)]")
        }

        // Journal stats
        let ruptures = journal.filter { $0.severity == .rupture }.count
        let rituals = journal.filter { $0.type == .ritualPerformed }.count
        print("  │")
        print("  │ Journal: \(journal.count) entries, \(rituals) rituals, \(ruptures) ruptures")

        // Practitioner stats
        print("  │")
        print("  │ Practitioners:")
        for (id, personality) in botIDs {
            if let session = await shard.session(for: id) {
                print("  │   \(personality.name): \(session.profile.totalRituals) rituals, at \(sites[session.currentSiteIndex].name)")
            }
        }

        print("  └────────────────────────────────────────────────\n")
    }

    static func printFinalSummary(shard: WorldShard, botIDs: [(UUID, BotPersonality)]) async {
        let sites = await shard.siteStates
        let journal = await shard.journal
        let npcs = await shard.npcs

        let totalRituals = journal.filter { $0.type == .ritualPerformed }.count
        let ruptures = journal.filter { $0.severity == .rupture }.count
        let scarredSites = sites.filter { $0.isScarred }.count
        let refusingNPCs = npcs.filter { $0.isRefusing }.count

        print("  ═══ Final World State ═══")
        print()
        print("    Total journal entries:  \(journal.count)")
        print("    Total rituals:          \(totalRituals)")
        print("    Rupture events:         \(ruptures)")
        print("    Sites scarred:          \(scarredSites)/\(sites.count)")
        print("    NPCs refusing contact:  \(refusingNPCs)/\(npcs.count)")
        print()

        // Most scarred site
        if let mostScarred = sites.max(by: { $0.scarring < $1.scarring }) {
            print("    Most scarred site: \(mostScarred.name) (\(String(format: "%.0f%%", mostScarred.scarring * 100)))")
        }

        // Thinnest Veil
        if let thinnest = sites.max(by: { $0.effectiveVeilThinness < $1.effectiveVeilThinness }) {
            print("    Thinnest Veil:     \(thinnest.name) (\(String(format: "%.0f%%", thinnest.effectiveVeilThinness * 100)))")
        }

        // Most suspicious NPC
        if let mostSuspicious = npcs.max(by: { $0.personalSuspicion < $1.personalSuspicion }) {
            print("    Most suspicious:   \(mostSuspicious.name) (\(String(format: "%.0f%%", mostSuspicious.personalSuspicion * 100)))")
        }

        // World state
        let world = await shard.world
        if let region = world.regions.values.first {
            print()
            print("    Region: \(region.name)")
            print("      Ghost Activity:     \(String(format: "%.0f%%", region.ghostActivity * 100))")
            print("      Corruption:         \(String(format: "%.0f%%", region.corruption * 100))")
            print("      Spiritual Pressure: \(String(format: "%.0f%%", region.spiritualPressure * 100))")
            print("      Stability:          \(String(format: "%.0f%%", region.stability * 100))")
            print("      Suspicion:          \(String(format: "%.0f%%", region.suspicion * 100))")
            print("      Veil Thinness:      \(String(format: "%.0f%%", region.veilThinness * 100))")
        }

        // Check for extreme conditions
        if let region = world.regions.values.first {
            if region.corruption > 0.8 {
                print("\n    ☠ CORRUPTION CRITICAL. THE GROUND IS BREAKING.")
            }
            if region.ghostActivity > 0.8 {
                print("\n    ⚡ GHOST ACTIVITY EXTREME. THE DEAD ARE RESTLESS.")
            }
        }

        print()
        print("  The world remembers everything. The scars remain until someone repairs them.")
        print()
    }

    // MARK: - Arg Parsing

    static func argValue(_ args: [String], flag: String, default defaultValue: Int) -> Int {
        guard let index = args.firstIndex(of: flag),
              index + 1 < args.count,
              let value = Int(args[index + 1]) else {
            return defaultValue
        }
        return value
    }
    
    static func argString(_ args: [String], flag: String, default defaultValue: String) -> String {
        guard let index = args.firstIndex(of: flag),
              index + 1 < args.count else {
            return defaultValue
        }
        return args[index + 1]
    }
}
