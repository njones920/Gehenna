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
    public var retinue: Retinue
    public var relationships: RelationshipLedger

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
        self.retinue = Retinue()
        self.relationships = RelationshipLedger()
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

    /// Optional Expression Layer for shared-world conversation. When nil,
    /// speak falls back to an authored line and no canon is harvested —
    /// mechanics still apply. Expression output only enters simulation
    /// state through the typed lanes (intents, claims).
    public let expression: ExpressionEngine?

    public init(
        world: WorldSimulation,
        sites: [RitualSite],
        npcs: [NPC],
        rootIdentities: [RootIdentity],
        expression: ExpressionEngine? = nil
    ) {
        self.world = world
        self.sites = sites
        self.npcs = npcs
        self.clock = WorldClock()
        self.director = WorldDirector()
        self.pipeline = ResolutionPipeline()
        self.astragali = Astragali()
        self.rootIdentities = rootIdentities
        self.expression = expression
        self.sessions = [:]
        self.commandLog = []
    }

    /// Register a new practitioner.
    public func addPractitioner(_ session: PractitionerSession) -> UUID {
        let id = session.id
        sessions[id] = session
        return id
    }

    /// Decay every practitioner's bound spirits for elapsed ticks.
    /// Fades are journaled quietly — the shared world notices, barely.
    private func decayRetinues(elapsed: Int) {
        let corruption = world.regions.values.first?.corruption ?? 0.0
        for id in sessions.keys {
            guard var session = sessions[id], !session.retinue.isEmpty else { continue }
            let departures = session.retinue.advance(
                ticks: elapsed,
                regionCorruption: corruption,
                endingAtTick: clock.currentTick
            )
            for departure in departures {
                session.relationships.recordDeparture(departure)
                world.journal.append(JournalEntry(
                    tick: departure.tick,
                    type: .spiritDeparted,
                    description: "\(departure.spirit.epochName ?? departure.spirit.template.rawValue) departed \(session.name)'s retinue (faded).",
                    source: .spirit,
                    severity: .ambient,
                    tags: ["retinue", "departure", "faded"]
                ))
            }
            sessions[id] = session
        }
    }

    // MARK: - Command Execution

    /// Execute a command for a given practitioner. Returns the result they perceive.
    public func execute(_ command: PlayerCommand, for playerID: UUID) async -> CommandResult {
        guard var session = sessions[playerID] else {
            return CommandResult(narration: ["You do not exist in this world."])
        }

        let tickBefore = clock.currentTick
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
        case .purifySite:
            result = executePurify(session: &session)
        case .scavenge:
            result = executeScavenge(session: &session)
        case .speak(let spiritIndex, let text):
            result = await executeSpeak(spiritIndex: spiritIndex, text: text, session: &session)
        case .callByName(let relationshipIndex, let fragmentIndex, let libation):
            result = executeCall(relationshipIndex: relationshipIndex, fragmentIndex: fragmentIndex, libation: libation, session: &session)
        case .dismiss(let spiritIndex, let manner):
            result = executeDismiss(spiritIndex: spiritIndex, manner: manner, session: &session)
        case .invokeName(let rivalID, let spiritIndex):
            result = executeInvokeName(rivalID: rivalID, spiritIndex: spiritIndex, session: &session)
        }

        // Write session back
        sessions[playerID] = session

        // Every practitioner's bound spirits feel the same elapsed time.
        let elapsed = clock.currentTick - tickBefore
        if elapsed > 0 {
            decayRetinues(elapsed: elapsed)
        }

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

        // Resting and observing the world restores energy.
        session.profile.tokens.ritualFatigue = max(0.0, session.profile.tokens.ritualFatigue - 0.05)

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
        case .speakFreely:
            // Free-form chat is neutral — no automatic trust/suspicion change.
            // The shard doesn't own an ExpressionEngine; the caller (CLI, server, arena)
            // handles LLM rendering for the response.
            narration.append("\(npc.name) listens to what you have to say.")
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

        let site = sites[session.currentSiteIndex]
        guard let regionID = site.regionID ?? world.regions.keys.first,
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

    private func executePurify(session: inout PractitionerSession) -> CommandResult {
        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)
        
        let siteIndex = session.currentSiteIndex
        var site = sites[siteIndex]
        
        let narration: [String]
        
        // Purification is hard physical and spiritual work. It requires energy.
        if session.profile.tokens.ritualFatigue >= 1.0 {
            return CommandResult(narration: ["You are too exhausted to attempt a Namburbi purification. Your body cannot bear it right now."], worldEvents: events)
        }
        
        if site.scarring > 0 || site.corruption > 0 {
            site.purifySite(strength: 0.5)
            session.profile.tokens.ritualFatigue = min(1.0, session.profile.tokens.ritualFatigue + 0.15)
            
            narration = [
                "You perform a Namburbi rite, working river clay and fresh water over the scarred stone.",
                "The physical toll is heavy, but the air feels tangibly lighter as the clay absorbs the corruption."
            ]
            
            // Add a journal entry for the purification
            if let regionID = site.regionID ?? world.regions.keys.first {
                world.journal.append(JournalEntry(
                    tick: clock.currentTick,
                    type: .practitionerAction,
                    description: "\(session.name) performed a Namburbi purification at \(site.name).",
                    source: .practitioner,
                    severity: .notable,
                    regionID: regionID,
                    siteID: site.id,
                    tags: Set(["purification", "namburbi", "practitioner:\(session.name)"])
                ))
            }
        } else {
            narration = ["The site is already clean. The Namburbi rite is unnecessary."]
        }
        
        sites[siteIndex] = site

        let directorEvents = director.evaluate(
            world: world, sites: sites, npcs: npcs,
            currentSiteIndex: session.currentSiteIndex, clock: clock
        )

        return CommandResult(narration: narration, worldEvents: events, directorEvents: directorEvents)
    }

    // MARK: - The 0.5 Verbs (shared world)

    private func executeScavenge(session: inout PractitionerSession) -> CommandResult {
        var site = sites[session.currentSiteIndex]
        var narration: [String] = []
        if !site.fragments.isEmpty {
            session.inventory.fragments.append(contentsOf: site.fragments)
            narration.append("Your hands find bone. \(site.fragments.count) fragment(s) join the satchel.")
            site.fragments.removeAll()
        }
        if !site.memoryTraces.isEmpty {
            session.inventory.memoryTraces.append(contentsOf: site.memoryTraces)
            narration.append("Fragments of a life lived: \(site.memoryTraces.count) memory trace(s).")
            site.memoryTraces.removeAll()
        }
        if narration.isEmpty {
            narration.append("You search the ground. The earth yields nothing here.")
        } else {
            site.localSuspicion = min(1.0, site.localSuspicion + 0.03)
        }
        sites[session.currentSiteIndex] = site
        return CommandResult(narration: narration)
    }

    private func executeDismiss(spiritIndex: Int, manner: DismissalManner, session: inout PractitionerSession) -> CommandResult {
        guard manner != .faded,
              spiritIndex >= 0, spiritIndex < session.retinue.bound.count else {
            return CommandResult(narration: ["There is no one at that station to release."])
        }
        let bound = session.retinue.bound[spiritIndex]
        let name = bound.spirit.epochName ?? bound.spirit.template.rawValue

        if manner == .releasedWithLibation {
            guard !session.inventory.libations.isEmpty else {
                return CommandResult(narration: ["The release needs an offering, and your hands are empty."])
            }
            session.inventory.libations.removeFirst()
        }
        guard let departure = session.retinue.dismiss(id: bound.spirit.id, manner: manner, atTick: clock.currentTick) else {
            return CommandResult(narration: ["The anchor does not answer."])
        }
        session.relationships.recordDeparture(departure)
        world.journal.append(JournalEntry(
            tick: clock.currentTick,
            type: .spiritDeparted,
            description: "\(name) departed \(session.name)'s retinue (\(manner.rawValue)).",
            source: .practitioner,
            severity: .notable,
            siteID: sites[session.currentSiteIndex].id,
            tags: ["retinue", "departure", manner.rawValue]
        ))
        let narration = manner == .releasedWithLibation
            ? ["You pour the offering and speak the release. \(name) inclines — almost a bow — and is gone."]
            : ["You cut the anchor with a word. \(name) is torn away mid-breath. Its last attention is on you."]
        return CommandResult(narration: narration)
    }

    private func executeCall(relationshipIndex: Int, fragmentIndex: Int, libation: LibationType, session: inout PractitionerSession) -> CommandResult {
        let known = session.relationships.all.filter { rel in
            rootIdentities.contains { $0.id == rel.rootKey }
        }
        guard relationshipIndex >= 0, relationshipIndex < known.count else {
            return CommandResult(narration: ["There is no one you know well enough to call by that reckoning."])
        }
        let rel = known[relationshipIndex]
        guard let root = rootIdentities.first(where: { $0.id == rel.rootKey }) else {
            return CommandResult(narration: ["You never learned who they truly were."])
        }
        guard fragmentIndex >= 0, fragmentIndex < session.inventory.fragments.count else {
            return CommandResult(narration: ["Even a call needs an anchor. That fragment is not in your satchel."])
        }
        guard let libIndex = session.inventory.libations.firstIndex(of: libation) else {
            return CommandResult(narration: ["You do not carry that offering."])
        }
        session.inventory.libations.remove(at: libIndex)

        let observedTraits = session.codex.entries.values
            .filter { $0.rootIdentityID == rel.rootKey }
            .flatMap(\.observedTraits)
        let invocation = RelationalInvocation(
            rootIdentityID: root.id,
            coherenceBonus: rel.callCoherenceBonus(traits: observedTraits),
            valence: rel.netValence
        )
        let intent = RitualIntent(
            fragmentIndex: fragmentIndex,
            trueName: root.trueName ?? rel.displayName,
            libationType: libation,
            timing: clock.currentTiming
        )
        return executeRitual(intent: intent, session: &session, invocation: invocation)
    }

    private func executeSpeak(spiritIndex: Int, text: String, session: inout PractitionerSession) async -> CommandResult {
        guard spiritIndex >= 0, spiritIndex < session.retinue.bound.count else {
            return CommandResult(narration: ["No one walks with you at that station."])
        }
        let bound = session.retinue.bound[spiritIndex]
        let key = RelationshipLedger.key(for: bound.spirit)
        let name = bound.spirit.epochName ?? bound.spirit.template.rawValue
        let rootIdentity = bound.spirit.rootIdentityID.flatMap { rid in
            rootIdentities.first { $0.id == rid }
        }
        var narration: [String] = []

        // Giving your true name: trust, and a liability a rival can read.
        if text.lowercased().hasPrefix("my name is ") {
            let givenName = String(text.dropFirst("my name is ".count))
                .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            if !givenName.isEmpty,
               session.relationships.relationship(forKey: key)?.nameGiven == nil {
                session.relationships.record(.gaveTrueName, for: bound.spirit, atTick: clock.currentTick, detail: givenName)
                narration.append("You have given the dead your name. That cannot be ungiven.")
            }
        }

        // Render — or fall back to the authored register.
        let response: String
        if let expression {
            response = await expression.spiritChat(
                bound,
                input: text,
                rootIdentity: rootIdentity,
                relationship: session.relationships.relationship(forKey: key)
            )
        } else {
            response = "The presence considers you. When it answers, the words arrive without sound."
        }
        narration.append("\(name): \"\(response)\"")
        session.relationships.noteExchange(withKey: key)

        // Typed intent lane — deterministic heuristics always run.
        let forbidden = bound.spirit.tags.tags
            .filter { $0.dimension == .taboo }
            .map(\.value)
        let intent: ConversationalIntent
        if let expression {
            intent = await expression.classifyIntent(text, forbiddenTopics: forbidden)
        } else {
            intent = ConversationalIntent.heuristic(for: text, forbiddenTopics: forbidden) ?? .none
        }
        if let momentKind = intent.spiritMoment {
            session.relationships.record(
                momentKind,
                for: bound.spirit,
                atTick: clock.currentTick,
                detail: momentKind == .promiseMade ? text : nil
            )
        }

        // Canon harvest lane — what it improvised becomes its record.
        if let expression {
            let claims = await expression.harvestClaims(from: response, speakerName: name)
            if !claims.isEmpty {
                session.relationships.recordSpokenClaims(claims, forKey: key)
                for claim in claims {
                    session.codex.annotate(
                        rootIdentityID: bound.spirit.rootIdentityID,
                        epochName: bound.spirit.epochName,
                        note: "Spoke of: \(claim)"
                    )
                }
            }
        }

        // The exchange strains the door.
        if let departure = session.retinue.recordExchange(with: bound.spirit.id, atTick: clock.currentTick) {
            session.relationships.recordDeparture(departure)
            narration.append("The voice thins mid-word. You held the door open too long.")
        }

        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)
        return CommandResult(narration: narration, worldEvents: events)
    }

    /// Codex v3 §8.2 — Invoke Name. Speaking a spirit's true name against
    /// its summoner's claim. Control does not transfer; doubt is planted.
    /// The invoker must genuinely know the name: their own Codex must
    /// hold this root identity. A well-treated spirit barely wavers; a
    /// poorly-treated one doubts hard.
    private func executeInvokeName(rivalID: UUID, spiritIndex: Int, session: inout PractitionerSession) -> CommandResult {
        guard var rival = sessions[rivalID], rival.id != session.id else {
            return CommandResult(narration: ["There is no such practitioner in this world."])
        }
        guard rival.currentSiteIndex == session.currentSiteIndex else {
            return CommandResult(narration: ["The rival is not here. A name must be spoken in a spirit's presence."])
        }
        guard spiritIndex >= 0, spiritIndex < rival.retinue.bound.count else {
            return CommandResult(narration: ["No spirit stands at that station."])
        }
        let target = rival.retinue.bound[spiritIndex]
        guard let rootID = target.spirit.rootIdentityID,
              let trueName = rootIdentities.first(where: { $0.id == rootID })?.trueName,
              session.codex.entries.values.contains(where: { $0.rootIdentityID == rootID }) else {
            return CommandResult(narration: ["You reach for a name and find only the shape of one. The spirit does not turn."])
        }

        // The contest: the summoner's bond is the spirit's resistance.
        let bondValence = rival.relationships.relationship(forKey: rootID)?.netValence ?? 0.0
        let doubt: Double = bondValence >= 0.9 ? 0.05 : bondValence > 0.3 ? 0.12 : 0.25
        rival.relationships.record(.nameContested, forKey: rootID, atTick: clock.currentTick, detail: session.name)

        var narration = [
            "You speak the name — \(trueName) — not to the air, to the person.",
            "The spirit turns. For one long moment its attention leaves its summoner."
        ]
        if let departure = rival.retinue.strain(id: target.spirit.id, by: doubt, atTick: clock.currentTick) {
            rival.relationships.recordDeparture(departure)
            narration.append("It could not hold under its own name. It returns to Sheol, unresolved.")
        } else if doubt >= 0.25 {
            narration.append("The doubt lands deep. Whatever binds it to \(rival.name), it is thinner now.")
        } else {
            narration.append("The bond holds. It knows its summoner — and now it knows you.")
        }

        world.journal.append(JournalEntry(
            tick: clock.currentTick,
            type: .practitionerAction,
            description: "\(session.name) invoked the true name of \(target.spirit.epochName ?? "a spirit") against \(rival.name)'s binding.",
            source: .practitioner,
            severity: .significant,
            siteID: sites[session.currentSiteIndex].id,
            tags: ["spiritPolitics", "invokeName"]
        ))
        sessions[rivalID] = rival

        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)
        return CommandResult(narration: narration, worldEvents: events)
    }

    private func executeRitual(intent: RitualIntent, session: inout PractitionerSession, invocation: RelationalInvocation? = nil) -> CommandResult {
        guard intent.fragmentIndex >= 0, intent.fragmentIndex < session.inventory.fragments.count else {
            return CommandResult(narration: ["You reach for bone fragments that are not there."])
        }

        let fragment = session.inventory.fragments[intent.fragmentIndex]
        let site = sites[session.currentSiteIndex]
        guard let regionID = site.regionID ?? world.regions.keys.first,
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
            rootIdentities: rootIdentities,
            invocation: invocation
        )

        // Apply effects to the shared world. This records the single ritual journal entry.
        world.applyRitualEffects(
            result.worldEffects,
            regionID: regionID,
            site: &sites[session.currentSiteIndex],
            practitionerName: session.name
        )

        let spiritSuccess = result.spirit != nil
        let wasMutation = result.spirit?.isMutation == true
        session.ritualCount += 1

        let totalEntropy = result.worldEffects.ghostActivityDelta + result.worldEffects.corruptionDelta + result.worldEffects.spiritualPressureDelta + result.worldEffects.veilDamage
        session.profile.recordRitual(
            success: spiritSuccess,
            wasMutation: wasMutation,
            domain: fragment.domain,
            entropyCost: totalEntropy
        )
        session.profile.applyRitualConsequences(configuration: config, result: result)

        // Record mutation at site if applicable
        if wasMutation {
            sites[session.currentSiteIndex].recordMutation()
        }
        sites[session.currentSiteIndex].lastRitualTick = clock.currentTick

        // Codex entry and anchoring
        if let spirit = result.spirit {
            _ = session.codex.recordEncounter(
                spirit: spirit,
                autopsy: ["Ritual performed by \(session.name) at tick \(clock.currentTick)."],
                ritualID: config.id,
                tick: clock.currentTick
            )
            session.relationships.noteSummon(of: spirit, atTick: clock.currentTick)
            session.retinue.anchor(
                spirit,
                atTick: clock.currentTick,
                originSiteID: sites[session.currentSiteIndex].id,
                capacity: session.profile.summonerCapacity
            )
        }

        world.seedRitualRumor(
            site: sites[session.currentSiteIndex],
            wasMutation: wasMutation,
            libation: intent.libationType,
            timing: intent.timing,
            practitionerName: session.name,
            npcs: &npcs
        )

        // Advance time — rumor propagation runs inside the clock tick.
        let events = clock.advanceForCommand(world: &world, sites: &sites, npcs: &npcs)

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
