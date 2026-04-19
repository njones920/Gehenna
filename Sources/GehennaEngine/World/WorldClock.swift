// MARK: - World Clock
// Time flows through the world. Every command advances it.
// The clock is the single entry point for time advancement.
// The CLI calls clock.advance() — never world.tick() directly.
//
// The world may act before the prompt returns. Travel takes time.
// Waiting takes more. The world director fires after ticks complete.

import Foundation

/// A high-level event produced during clock advancement — the CLI renders these.
public struct WorldEvent: Sendable {
    public let type: WorldEventType
    public let description: String
    public let severity: EventSeverity
    public let siteID: UUID?
    public let npcID: UUID?
    public let tick: Int

    public init(
        type: WorldEventType,
        description: String,
        severity: EventSeverity = .notable,
        siteID: UUID? = nil,
        npcID: UUID? = nil,
        tick: Int = 0
    ) {
        self.type = type
        self.description = description
        self.severity = severity
        self.siteID = siteID
        self.npcID = npcID
        self.tick = tick
    }

    public enum WorldEventType: String, Sendable {
        case thresholdCrossed     // a regional threshold fired
        case siteChanged          // a site's state shifted noticeably
        case npcActed             // an NPC approached, fled, or changed posture
        case spiritLingered       // traces of a prior manifestation remain
        case ambientChange        // atmospheric shift at the current location
        case directorNarration    // the world speaks — authored moment
    }
}

/// The world clock — manages time progression and collects events across ticks.
public struct WorldClock: Sendable {

    /// Current simulation tick.
    public var currentTick: Int

    /// How many ticks a basic command (look, talk, etc.) costs.
    public let ticksPerCommand: Int

    /// How many ticks traveling between sites costs.
    public let ticksPerTravel: Int

    /// How many ticks resting/waiting costs.
    public let ticksPerRest: Int

    public init(
        startingTick: Int = 0,
        ticksPerCommand: Int = 1,
        ticksPerTravel: Int = 2,
        ticksPerRest: Int = 5
    ) {
        self.currentTick = startingTick
        self.ticksPerCommand = ticksPerCommand
        self.ticksPerTravel = ticksPerTravel
        self.ticksPerRest = ticksPerRest
    }

    // MARK: - Time Advancement

    /// Advance time by a number of ticks. Runs world simulation, site state,
    /// and NPC processing for each tick. Collects all events.
    ///
    /// This is the only way time should advance. The CLI must not call
    /// `world.tick()` directly.
    public mutating func advance(
        by ticks: Int,
        world: inout WorldSimulation,
        sites: inout [RitualSite],
        npcs: inout [NPC]
    ) -> [WorldEvent] {
        var collectedEvents: [WorldEvent] = []

        for _ in 0..<ticks {
            currentTick += 1
            world.currentTick = currentTick

            // 1. World simulation tick (entropy decay, thresholds, propagation, corrections)
            world.tick()

            // 2. Site state tick (scarring decay, trace fading, disturbance cooling)
            for i in sites.indices {
                sites[i].tickSiteState()
            }

            // 3. NPC state tick (suspicion/trust drift, schedule movement)
            for i in npcs.indices {
                npcs[i].tickState()
            }

            // 4. Collect threshold events from this tick
            for event in world.pendingEvents {
                collectedEvents.append(WorldEvent(
                    type: .thresholdCrossed,
                    description: event.description,
                    severity: eventSeverity(for: event.type),
                    tick: currentTick
                ))
            }
        }

        return collectedEvents
    }

    /// Advance time for a basic command (look, talk, use).
    public mutating func advanceForCommand(
        world: inout WorldSimulation,
        sites: inout [RitualSite],
        npcs: inout [NPC]
    ) -> [WorldEvent] {
        advance(by: ticksPerCommand, world: &world, sites: &sites, npcs: &npcs)
    }

    /// Advance time for travel between sites.
    public mutating func advanceForTravel(
        world: inout WorldSimulation,
        sites: inout [RitualSite],
        npcs: inout [NPC]
    ) -> [WorldEvent] {
        advance(by: ticksPerTravel, world: &world, sites: &sites, npcs: &npcs)
    }

    /// Advance time for resting/waiting.
    public mutating func advanceForRest(
        world: inout WorldSimulation,
        sites: inout [RitualSite],
        npcs: inout [NPC]
    ) -> [WorldEvent] {
        advance(by: ticksPerRest, world: &world, sites: &sites, npcs: &npcs)
    }

    // MARK: - Helpers

    private func eventSeverity(for type: ThresholdEvent.EventType) -> EventSeverity {
        switch type {
        case .sebittiSpawned, .motApproaching: return .rupture
        case .deepSheolBreached, .cosmologicalScarring: return .significant
        case .inquisitionTriggered, .settlementFailing: return .significant
        case .ghostsHostile, .corruptionDegrading: return .notable
        case .regionRecovery: return .ambient
        }
    }
}
