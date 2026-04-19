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

    enum Strategy {
        case scholar      // explores, talks, reads carefully, rituals with preparation
        case reckless     // performs rituals constantly, pushes the Veil
        case social       // focuses on NPC relationships, builds trust
        case explorer     // moves between sites, looks everywhere
        case balanced     // mix of everything
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

        print("""

        ╔══════════════════════════════════════════════════╗
        ║                                                  ║
        ║           G E H E N N A   A R E N A              ║
        ║                                                  ║
        ║       Shared World Bot Arena — v0.4.20            ║
        ║                                                  ║
        ╚══════════════════════════════════════════════════╝

          Bots: \(botCount)
          Ticks: \(totalTicks)
          Mode: headless shared world

        """)

        // Create the shared world
        let content = RidgeOfElah.createWorld()
        let shard = WorldShard(
            world: WorldSimulation(regions: [content.region]),
            sites: content.sites,
            npcs: RidgeOfElah.kfarShalemNPCs(),
            rootIdentities: RidgeOfElah.rootIdentities()
        )

        // Register bots
        var botIDs: [(UUID, BotPersonality)] = []
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
                fragments: content.fragments,
                artifacts: content.artifacts,
                memoryTraces: content.memoryTraces
            )

            let id = await shard.addPractitioner(session)
            botIDs.append((id, personality))
            print("  ◈ Registered: \(personality.name) (\(personality.strategy)) → \(content.sites[personality.preferredSiteIndex].name)")
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
        print("  The world remembers everything. The scars are permanent.")
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
}
