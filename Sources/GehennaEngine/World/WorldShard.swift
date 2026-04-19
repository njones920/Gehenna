// MARK: - World Shard
// The shared world authority. All consequential actions serialize through this actor.
// Multiple practitioners can act in the same world. The shard owns the truth.
//
// The shard is not the server. It is the authoritative state.
// A server wraps a shard. A bot arena wraps a shard.
// The CLI could wrap a shard (single-player is just multiplayer with one player).

import Foundation

/// Per-practitioner state within a shared world.
public struct PractitionerSession: Sendable {
    public let id: UUID
    public let name: String
    public var profile: PractitionerProfile
    public var codex: CodexOfTheDead
    public var inventory: PlayerInventory
    public var currentSiteIndex: Int
    public var ritualCount: Int

    public struct PlayerInventory: Sendable {
        public var fragments: [Fragment]
        public var artifacts: [LifeArtifact]
        public var memoryTraces: [MemoryTrace]
        public var libations: [LibationType]
    }

    public init(
        name: String,
        fragments: [Fragment],
        artifacts: [LifeArtifact],
        memoryTraces: [MemoryTrace],
        libations: [LibationType] = [.water, .water, .water, .fermentedWine, .fermentedWine],
        startingSiteIndex: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.profile = PractitionerProfile()
        self.codex = CodexOfTheDead()
        self.inventory = PlayerInventory(
            fragments: fragments,
            artifacts: artifacts,
            memoryTraces: memoryTraces,
            libations: libations
        )
        self.currentSiteIndex = startingSiteIndex
        self.ritualCount = 0
    }
}

/// The shared world actor — all consequential actions serialize through here.
public actor WorldShard {
    public var world: WorldSimulation
    public var sites: [RitualSite]
    public var npcs: [NPC]
    public var clock: WorldClock
    public let director: WorldDirector
    public let pipeline: ResolutionPipeline
    public let astragali: Astragali
    public let rootIdentities: [RootIdentity]

    /// All registered practitioner sessions, keyed by ID.
    public var sessions: [UUID: PractitionerSession]

    /// Running log of all commands executed — the evidence chain.
    public var commandLog: [(tick: Int, playerID: UUID, playerName: String, command: String)]

    public init(
        world: WorldSimulation,
        sites: [RitualSite],
        npcs: [NPC],
        rootIdentities: [RootIdentity]
    ) {
        self.world = world
        self.sites = sites
        self.npcs = npcs
        self.clock = WorldClock()
        self.director = WorldDirector()
        self.pipeline = ResolutionPipeline()
        self.astragali = Astragali()
        self.rootIdentities = rootIdentities
        self.sessions = [:]
        self.commandLog = []
    }

    /// Register a new practitioner.
    public func addPractitioner(_ session: PractitionerSession) -> UUID {
        let id = session.id
        sessions[id] = session
        return id
    }

    // MARK: - Command Execution

    /// Execute a command for a given practitioner. Returns the result they perceive.
    public func execute(_ command: PlayerCommand, for playerID: UUID) -> CommandResult {
        guard var session = sessions[playerID] else {
            return CommandResult(narration: ["You do not exist in this world."])
        }

        let result: CommandResult

        switch command {
        case .look:
            result = executeLook(session: &session)
        case .travel(let siteIndex):
            result = executeTravel(siteIndex: siteIndex, session: &session)
        case .wait:
            result = executeWait(session: &session)
        case .talkTo(let npcIndex, let action):
            result = executeTalk(npcIndex: npcIndex, action: action, session: &session)
        case .castAstragali:
            result = executeCast(session: &session)
        case .performRitual(let intent):
            result = executeRitual(intent: intent, session: &session)
        }

        // Write session back
        sessions[playerID] = session

        // Log the command
        commandLog.append((
            tick: clock.currentTick,
            playerID: playerID,
            playerName: session.name,
            command: String(describing: command)
        ))

        return result
    }

    // MARK: - Command Implementations

    private func executeLook(session: inout PractitionerSession) -> CommandResult {
        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)
        sites[session.currentSiteIndex].lastVisitTick = clock.currentTick

        let site = sites[session.currentSiteIndex]
        var narration: [String] = []

        narration.append("[\(site.name)]")

        if site.isScarred {
            narration.append("The site bears scars. Your work — or another's — has marked this place.")
        }
        if !site.activeTraces.isEmpty {
            narration.append("Traces of prior workings linger in the air.")
        }
        if site.effectiveVeilThinness > 0.6 {
            narration.append("The boundary is thin here.")
        }
        if site.localSuspicion > 0.3 {
            narration.append("This location has drawn attention.")
        }

        let directorEvents = director.evaluate(
            world: world, sites: sites, npcs: npcs,
            currentSiteIndex: session.currentSiteIndex, clock: clock
        )

        return CommandResult(narration: narration, worldEvents: events, directorEvents: directorEvents)
    }

    private func executeTravel(siteIndex: Int, session: inout PractitionerSession) -> CommandResult {
        guard siteIndex >= 0, siteIndex < sites.count else {
            return CommandResult(narration: ["That path does not exist."])
        }

        session.currentSiteIndex = siteIndex
        let events = clock.advanceForTravel(world: &world, sites: &sites, npcs: &npcs)
        sites[siteIndex].lastVisitTick = clock.currentTick

        let site = sites[siteIndex]
        var narration = ["You travel to \(site.name)."]

        if site.isDisturbed {
            narration.append("Something has changed here since your last visit.")
        }

        let directorEvents = director.evaluate(
            world: world, sites: sites, npcs: npcs,
            currentSiteIndex: session.currentSiteIndex, clock: clock
        )

        return CommandResult(narration: narration, worldEvents: events, directorEvents: directorEvents)
    }

    private func executeWait(session: inout PractitionerSession) -> CommandResult {
        let events = clock.advanceForRest(world: &world, sites: &sites, npcs: &npcs)

        var narration = ["You wait. The night passes."]
        if events.isEmpty {
            narration.append("The world turns. Nothing of note.")
        }

        let directorEvents = director.evaluate(
            world: world, sites: sites, npcs: npcs,
            currentSiteIndex: session.currentSiteIndex, clock: clock
        )

        return CommandResult(narration: narration, worldEvents: events, directorEvents: directorEvents)
    }

    private func executeTalk(npcIndex: Int, action: PlayerCommand.ConversationAction, session: inout PractitionerSession) -> CommandResult {
        guard npcIndex >= 0, npcIndex < npcs.count else {
            return CommandResult(narration: ["There is no one there."])
        }

        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)

        var narration: [String] = []
        let npc = npcs[npcIndex]

        if npc.isRefusing {
            narration.append("\(npc.name) refuses to speak with you.")
            return CommandResult(narration: narration, worldEvents: events)
        }

        switch action {
        case .friendly:
            npcs[npcIndex].positiveInteraction()
            narration.append("You speak with \(npc.name). The conversation is careful but warm.")
        case .askRegion:
            narration.append("\(npc.name) tells you about the region. The information is guarded but useful.")
        case .askDead:
            npcs[npcIndex].witnessActivity(severity: 0.1)
            narration.append("You ask \(npc.name) about the dead. They pause. This question has weight.")
        }

        npcs[npcIndex].lastInteractionTick = clock.currentTick

        let directorEvents = director.evaluate(
            world: world, sites: sites, npcs: npcs,
            currentSiteIndex: session.currentSiteIndex, clock: clock
        )

        return CommandResult(narration: narration, worldEvents: events, directorEvents: directorEvents)
    }

    private func executeCast(session: inout PractitionerSession) -> CommandResult {
        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)

        guard let regionID = world.regions.keys.first,
              let regionState = world.regions[regionID] else {
            return CommandResult(narration: ["The world is empty."])
        }

        // Seed from ritual count, tick, and player ID byte — deterministic and replayable
        let idByte = UInt64(session.id.uuid.0)
        let seed = UInt64(bitPattern: Int64(session.ritualCount)) &+ UInt64(bitPattern: Int64(clock.currentTick)) &+ idByte

        // Astragali need a config with at least a fragment — use the first available
        guard !session.inventory.fragments.isEmpty else {
            return CommandResult(narration: ["You have no fragments to read against."], worldEvents: events)
        }
        let fragment = session.inventory.fragments[0]
        let site = sites[session.currentSiteIndex]
        let config = RitualConfiguration(remains: fragment, site: site)

        let reading = astragali.cast(
            configuration: config,
            regionState: regionState,
            profile: session.profile,
            seed: seed
        )

        var narration: [String] = ["You cast the four knucklebones on the stone."]
        narration.append("Coherence: \(reading.coherence.rawValue)")
        narration.append("Resonance: \(reading.resonance.rawValue)")
        narration.append("Conflict: \(reading.conflict.rawValue)")
        narration.append("Veil: \(reading.veilState.rawValue)")

        if reading.reliableCount < 4 {
            narration.append("The reading is degraded. \(4 - reading.reliableCount) bone(s) fell wrong.")
        }

        return CommandResult(narration: narration, worldEvents: events)
    }

    private func executeRitual(intent: RitualIntent, session: inout PractitionerSession) -> CommandResult {
        guard intent.fragmentIndex >= 0, intent.fragmentIndex < session.inventory.fragments.count else {
            return CommandResult(narration: ["You reach for bone fragments that are not there."])
        }

        let fragment = session.inventory.fragments[intent.fragmentIndex]
        let site = sites[session.currentSiteIndex]
        guard let regionID = world.regions.keys.first,
              let regionState = world.regions[regionID] else {
            return CommandResult(narration: ["The world is empty."])
        }

        // Build the ritual configuration using the proper init
        var artifactOpt: LifeArtifact? = nil
        if let ai = intent.artifactIndex, ai >= 0, ai < session.inventory.artifacts.count {
            artifactOpt = session.inventory.artifacts[ai]
        }
        var traceOpt: MemoryTrace? = nil
        if let ti = intent.traceIndex, ti >= 0, ti < session.inventory.memoryTraces.count {
            traceOpt = session.inventory.memoryTraces[ti]
        }

        let trueName: TrueName? = intent.trueName.map { TrueName($0) }

        let config = RitualConfiguration(
            remains: fragment,
            site: site,
            trueName: trueName,
            lifeArtifact: artifactOpt,
            memoryTrace: traceOpt,
            libation: Libation(intent.libationType),
            timing: intent.timing
        )

        // Deterministic seed from tick + player ID + ritual count
        let idByte = UInt64(session.id.uuid.0)
        let seed = UInt64(bitPattern: Int64(clock.currentTick)) &+ idByte &+ UInt64(bitPattern: Int64(session.ritualCount))

        // Resolve through the pipeline
        let result = pipeline.resolve(
            configuration: config,
            regionState: regionState,
            profile: session.profile,
            seed: seed,
            rootIdentities: rootIdentities
        )

        // Apply effects to the shared world
        world.applyRitualEffects(result.worldEffects, regionID: regionID, site: &sites[session.currentSiteIndex])

        let spiritSuccess = result.spirit != nil
        let wasMutation = result.spirit?.isMutation == true

        let totalEntropy = result.worldEffects.ghostActivityDelta + result.worldEffects.corruptionDelta + result.worldEffects.spiritualPressureDelta + result.worldEffects.veilDamage
        session.profile.recordRitual(
            success: spiritSuccess,
            wasMutation: wasMutation,
            domain: fragment.domain,
            entropyCost: totalEntropy
        )

        // Record mutation at site if applicable
        if wasMutation {
            sites[session.currentSiteIndex].recordMutation()
        }
        sites[session.currentSiteIndex].lastRitualTick = clock.currentTick

        // Codex entry
        if let spirit = result.spirit {
            _ = session.codex.recordEncounter(
                spirit: spirit,
                autopsy: ["Ritual performed by \(session.name) at tick \(clock.currentTick)."],
                ritualID: config.id,
                tick: clock.currentTick
            )
            session.ritualCount += 1
        }

        // Advance time
        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)

        // Propagate rumors
        let siteSuspicion = sites[session.currentSiteIndex].localSuspicion
        if siteSuspicion > 0.05 {
            for i in npcs.indices {
                npcs[i].hearRumor(strength: siteSuspicion * 0.3)
            }
        }

        // Build narration
        var narration: [String] = []
        narration.append("\(session.name) performs a ritual at \(site.name).")

        if let spirit = result.spirit {
            let spiritName = spirit.epochName ?? spirit.template.rawValue
            narration.append("A \(spirit.tier.rawValue) spirit manifests: \(spiritName).")
            if spirit.isMutation {
                narration.append("The manifestation is broken. A mutation. The grammar failed.")
            }
        } else {
            narration.append("The ritual fails. Nothing comes through.")
        }

        narration.append("Entropy: \(totalEntropy > 0.1 ? "heavy" : "light").")

        let directorEvents = director.evaluate(
            world: world, sites: sites, npcs: npcs,
            currentSiteIndex: session.currentSiteIndex, clock: clock
        )

        // Journal entry for multiplayer visibility
        world.journal.append(JournalEntry(
            tick: clock.currentTick,
            type: .ritualPerformed,
            description: "\(session.name) performed a ritual at \(site.name).",
            source: .practitioner,
            severity: .significant,
            regionID: regionID,
            siteID: site.id,
            tags: Set(["ritual", "practitioner:\(session.name)"])
        ))

        return CommandResult(narration: narration, worldEvents: events, directorEvents: directorEvents)
    }

    // MARK: - Queries

    /// Get the current tick.
    public var currentTick: Int { clock.currentTick }

    /// Get the journal.
    public var journal: [JournalEntry] { world.journal }

    /// Get the site state snapshot.
    public var siteStates: [RitualSite] { sites }

    /// Get a practitioner's session.
    public func session(for playerID: UUID) -> PractitionerSession? {
        sessions[playerID]
    }

    /// Summary of all practitioners.
    public var practitionerSummary: [(name: String, site: String, rituals: Int)] {
        sessions.values.map { s in
            (name: s.name, site: sites[s.currentSiteIndex].name, rituals: s.ritualCount)
        }
    }
}
