// MARK: - World Director
// After ticks and cascades, the director decides what the practitioner perceives.
// Sometimes the world speaks first. Sometimes nothing happens.
// The director renders state. It must not decide simulation truth.
//
// The Expression Layer renders. It must not decide simulation truth. (GEHENNA_DEV_MEMORY.md)

import Foundation

/// An event produced by the world director — unsolicited world narration.
public struct DirectorEvent: Sendable {
    public let type: DirectorEventType
    public let description: String
    public let severity: EventSeverity
    public let siteID: UUID?
    public let npcID: UUID?

    public init(
        type: DirectorEventType,
        description: String,
        severity: EventSeverity = .notable,
        siteID: UUID? = nil,
        npcID: UUID? = nil
    ) {
        self.type = type
        self.description = description
        self.severity = severity
        self.siteID = siteID
        self.npcID = npcID
    }

    public enum DirectorEventType: String, Sendable {
        case siteDisturbance      // the practitioner arrives at a changed site
        case npcInitiative        // an NPC approaches, flees, or changes posture
        case ambientPresence      // ghost activity, spiritual pressure made tangible
        case rumorPropagation     // rituals have reached NPC ears
        case spiritTrace          // lingering traces of a prior manifestation
        case veilInstability      // the boundary is critically thin
        case silence              // nothing happens — the director chose quietness
        case siteMemory           // the site remembers what was done here
    }
}

/// The world director — evaluates conditions and produces 0–2 unsolicited events per evaluation.
/// Each condition has authored template text keyed to site type, NPC state, and world state.
/// The director never decides simulation truth. It only renders what is already true.
public struct WorldDirector: Sendable {

    /// Maximum events per evaluation. The world should not talk too much.
    private let maxEventsPerEval: Int = 2

    public init() {}

    /// Evaluate the current state and produce director events.
    /// Called after clock advancement, before the prompt returns.
    public func evaluate(
        world: WorldSimulation,
        sites: [RitualSite],
        npcs: [NPC],
        currentSiteIndex: Int,
        clock: WorldClock
    ) -> [DirectorEvent] {
        var events: [DirectorEvent] = []
        let currentSite = sites[currentSiteIndex]

        // Priority order: ruptures → NPC initiative → site state → ambient

        // 1. Veil instability — if critically thin, something might be perceived
        if let veilEvent = checkVeilInstability(currentSite, world: world) {
            events.append(veilEvent)
        }

        // 2. NPC initiative — did an NPC cross a behavioral threshold?
        if let npcEvent = checkNPCInitiative(npcs: npcs, currentSite: currentSite) {
            events.append(npcEvent)
        }

        // 3. Site disturbance — has the current site changed since last visit?
        if events.count < maxEventsPerEval,
           let siteEvent = checkSiteDisturbance(currentSite, clock: clock) {
            events.append(siteEvent)
        }

        // 4. Site memory — durable scarring narration
        if events.count < maxEventsPerEval,
           let memoryEvent = checkSiteMemory(currentSite) {
            events.append(memoryEvent)
        }

        // 5. Spirit traces — lingering residue from recent rituals
        if events.count < maxEventsPerEval,
           let traceEvent = checkSpiritTraces(currentSite) {
            events.append(traceEvent)
        }

        // 6. Ambient presence — ghost activity, spiritual pressure
        if events.count < maxEventsPerEval,
           let ambientEvent = checkAmbientPresence(currentSite, world: world) {
            events.append(ambientEvent)
        }

        // 7. Rumor propagation — have rituals been noticed?
        if events.count < maxEventsPerEval,
           let rumorEvent = checkRumorPropagation(
                npcs: npcs,
                sites: sites,
                clock: clock,
                ledger: world.rumorLedger
           ) {
            events.append(rumorEvent)
        }

        return events
    }

    // MARK: - Condition Checks

    private func checkVeilInstability(_ site: RitualSite, world: WorldSimulation) -> DirectorEvent? {
        guard site.effectiveVeilThinness > 0.7 else { return nil }

        let descriptions: [SiteType: String] = [
            .burialCave: "The cave walls pulse. For a moment, you are not sure the stone is solid.",
            .battlefield: "The air above the ridge shimmers. Something is closer than it should be.",
            .topheth: "The ash stirs without wind. The Veil here is so thin you can taste charcoal and copper.",
            .collapsingTemple: "The temple stones groan. The boundary between the ruin and what lies beneath it is barely there.",
            .ancestorShrine: "The shrine hums. The ancestors are close — closer than the living would want.",
        ]

        let text = descriptions[site.type] ?? "The boundary feels thin. Dangerously thin."

        return DirectorEvent(
            type: .veilInstability,
            description: text,
            severity: site.effectiveVeilThinness > 0.85 ? .significant : .notable,
            siteID: site.id
        )
    }

    private func checkNPCInitiative(npcs: [NPC], currentSite: RitualSite) -> DirectorEvent? {
        // Only fire NPC events at or near the village
        guard currentSite.type == .ancestorShrine else { return nil }

        // Check for approaching NPCs
        if let approacher = npcs.first(where: { $0.wouldApproach && !$0.isRefusing }) {
            let text: String
            if approacher.isAtThreshold {
                text = "\(approacher.name) appears at the edge of the square. They have something to say, and they have been waiting."
            } else {
                text = "\(approacher.name) approaches you. There is purpose in their step — this is not casual."
            }
            return DirectorEvent(
                type: .npcInitiative,
                description: text,
                severity: approacher.isAtThreshold ? .significant : .notable,
                npcID: approacher.id
            )
        }

        // Check for fleeing NPCs
        if let fleer = npcs.first(where: { $0.wouldFlee }) {
            return DirectorEvent(
                type: .npcInitiative,
                description: "\(fleer.name) sees you and turns away. The movement is quick, deliberate. They do not want to be near you.",
                severity: .notable,
                npcID: fleer.id
            )
        }

        return nil
    }

    private func checkSiteDisturbance(_ site: RitualSite, clock: WorldClock) -> DirectorEvent? {
        // Only fire if the site has been disturbed AND the practitioner wasn't here recently
        guard site.isDisturbed else { return nil }
        if let lastVisit = site.lastVisitTick, clock.currentTick - lastVisit < 3 {
            return nil  // you just saw this
        }

        let descriptions: [SiteType: String] = [
            .burialCave: "Something has changed in the cave since you were last here. The air is different. The shadows sit wrong.",
            .battlefield: "The ridge looks different. The ground is disturbed where it was not before. Birds avoid part of the field.",
            .topheth: "The Burning Ground has shifted. New ash patterns. Something moved here while you were away.",
            .collapsingTemple: "A stone has fallen in the temple. Or was moved. The dust patterns suggest recent presence.",
            .ancestorShrine: "The village is quieter than before. Doors that were open are closed. Something was discussed while you were away.",
        ]

        let text = descriptions[site.type] ?? "This place has changed since you were last here."

        return DirectorEvent(
            type: .siteDisturbance,
            description: text,
            severity: .notable,
            siteID: site.id
        )
    }

    private func checkSiteMemory(_ site: RitualSite) -> DirectorEvent? {
        guard site.isScarred else { return nil }

        // Only fire this occasionally — the site doesn't need to remind you every visit.
        guard shouldEmit(clockTick: site.siteTickCount, salt: site.stableEventSalt, interval: 5) else { return nil }

        let descriptions: [SiteType: String] = [
            .burialCave: "The cave walls are darker where you worked before. The stone remembers.",
            .battlefield: "A patch of earth on the ridge refuses to grow anything. That is where you performed the ritual. The ground knows.",
            .topheth: "The Burning Ground was always scarred. But the new scars are yours, and they are deeper.",
            .collapsingTemple: "A crack in the temple floor has widened since your ritual. The ruin is settling into what you made of it.",
            .ancestorShrine: "The shrine stone has darkened. A stain that water will not remove. The families have noticed.",
        ]

        let text = descriptions[site.type] ?? "The site bears marks that were not here before you came."

        return DirectorEvent(
            type: .siteMemory,
            description: text,
            severity: .ambient,
            siteID: site.id
        )
    }

    private func checkSpiritTraces(_ site: RitualSite) -> DirectorEvent? {
        guard !site.activeTraces.isEmpty else { return nil }

        let hasMutationTrace = site.activeTraces.contains("mutation_scar")
        if hasMutationTrace {
            return DirectorEvent(
                type: .spiritTrace,
                description: "The air here is still wrong from what manifested. The Mutation left a residue — a feeling of incompleteness, of grammar broken mid-sentence.",
                severity: .notable,
                siteID: site.id
            )
        }

        if site.activeTraces.count >= 3 {
            return DirectorEvent(
                type: .spiritTrace,
                description: "Multiple summonings have left their mark. The space feels layered — echoes of different presences, none fully gone.",
                severity: .notable,
                siteID: site.id
            )
        }

        // Single trace — subtle.
        guard shouldEmit(clockTick: site.siteTickCount, salt: site.stableEventSalt, interval: 3) else { return nil }
        return DirectorEvent(
            type: .spiritTrace,
            description: "There is a faint residue in the air. Something was called here recently. The trace is fading, but not gone.",
            severity: .ambient,
            siteID: site.id
        )
    }

    private func checkAmbientPresence(_ site: RitualSite, world: WorldSimulation) -> DirectorEvent? {
        guard let region = world.regions.values.first else { return nil }

        if region.ghostActivity > 0.5 {
            let descriptions: [SiteType: String] = [
                .burialCave: "Movement in the peripheral darkness. You turn and it stops. The dead are not settled here.",
                .battlefield: "Something walks the ridge that is not alive. You hear footsteps that do not match your own.",
                .topheth: "The ash shifts. A shape forms and dissolves before you can focus. The Burning Ground is restless.",
                .collapsingTemple: "A whisper echoes through the collapsed halls. Not words you can catch — just the shape of speech.",
                .ancestorShrine: "A cold draft from nowhere moves through the village. Dogs flatten their ears.",
            ]
            let text = descriptions[site.type] ?? "The dead are restless. You feel it in the air."
            return DirectorEvent(
                type: .ambientPresence,
                description: text,
                severity: region.ghostActivity > 0.7 ? .significant : .notable,
                siteID: site.id
            )
        }

        // Spiritual pressure as ambient background
        if region.spiritualPressure > 0.6 {
            guard shouldEmit(clockTick: world.currentTick, salt: site.stableEventSalt, interval: 3) else { return nil }
            return DirectorEvent(
                type: .ambientPresence,
                description: "A heaviness in the air. Not weather — something older. The cosmology is under pressure, and you feel it in your teeth.",
                severity: .ambient,
                siteID: site.id
            )
        }

        return nil
    }

    private func checkRumorPropagation(
        npcs: [NPC],
        sites: [RitualSite],
        clock: WorldClock,
        ledger: RumorLedger
    ) -> DirectorEvent? {
        // Check if any recently-used site with high localSuspicion would generate rumors
        let recentRitualSites = sites.filter { site in
            guard let lastTick = site.lastRitualTick else { return false }
            return clock.currentTick - lastTick < 20 && site.localSuspicion > 0.05
        }

        let suspiciousNPCs = npcs.filter {
            ($0.hasHeardRumors || !$0.heardRumorIDs.isEmpty) && $0.personalSuspicion > 0.2
        }
        guard !suspiciousNPCs.isEmpty || !recentRitualSites.isEmpty else { return nil }

        // Only fire occasionally.
        guard shouldEmit(clockTick: clock.currentTick, salt: recentRitualSites.count + suspiciousNPCs.count, interval: 4) else { return nil }

        let carriers = suspiciousNPCs.filter { $0.lastHeardRumorID != nil }
        if !carriers.isEmpty {
            let orderedCarriers = carriers.sorted { $0.stableEventSalt < $1.stableEventSalt }
            let npc = orderedCarriers[(clock.currentTick + recentRitualSites.count) % orderedCarriers.count]
            if let rumorID = npc.lastHeardRumorID,
               let rumor = ledger.rumors[rumorID],
               !rumor.isExtinct {
                let framing: String = switch npc.faction {
                case .priesthood:
                    "\(npc.name) murmurs to another priest: \""
                case .elders:
                    "Two of the elders are talking near the well. \(npc.name) stops you to ask: \""
                case .traders:
                    "\(npc.name) leans in over the trade stall, voice low: \""
                }

                let tail: String = switch npc.faction {
                case .priesthood:
                    "\" They do not look away when they see you."
                case .elders:
                    "\" They watch your face as they ask."
                case .traders:
                    "\" They are not asking to warn you."
                }

                return DirectorEvent(
                    type: .rumorPropagation,
                    description: framing + rumor.sentence + tail,
                    severity: rumor.kind == .mutation || rumor.kind == .tabooViolation ? .significant : .notable,
                    npcID: npc.id
                )
            }
        }

        let orderedNPCs = suspiciousNPCs.sorted { $0.stableEventSalt < $1.stableEventSalt }
        guard !orderedNPCs.isEmpty else { return nil }
        let npc = orderedNPCs[(clock.currentTick + recentRitualSites.count) % orderedNPCs.count]
        let text: String = switch npc.faction {
        case .priesthood:
            "You catch \(npc.name) watching from the sanctuary doorway. When your eyes meet, they don't look away. They are collecting evidence."
        case .elders:
            "Two of the elders are talking quietly near the well. When you approach, the conversation stops. \(npc.name) nods at you with careful neutrality."
        case .traders:
            "\(npc.name) mentions casually that someone was asking about travelers who visit the caves at night. The someone was from Lachish."
        }

        return DirectorEvent(
            type: .rumorPropagation,
            description: text,
            severity: .notable,
            npcID: npc.id
        )
    }

    private func shouldEmit(clockTick: Int, salt: Int, interval: Int) -> Bool {
        guard interval > 0 else { return true }
        return (clockTick + salt).isMultiple(of: interval)
    }
}
