import Foundation
import GehennaEngine

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
            case "rumors", "gossip":
                showRumors()
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

}
