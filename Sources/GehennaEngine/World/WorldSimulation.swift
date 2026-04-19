// MARK: - World Simulation
// The tick-based simulation that processes all regions, applies entropy decay,
// evaluates threshold events, propagates effects across boundaries,
// and advances the cosmology.
//
// The simulation is the runtime. The grammar is the compiler.
// Every consequential action resolves through this layer.

import Foundation

/// A threshold event triggered by regional state crossing a boundary.
public struct ThresholdEvent: Sendable {
    public let type: EventType
    public let regionID: UUID
    public let description: String
    public let tick: Int

    public enum EventType: String, Sendable {
        case ghostsHostile          // Ghost Activity crossed hostile threshold
        case corruptionDegrading    // Corruption degrading fragment Integrity
        case settlementFailing      // Stability collapsed — survival override
        case inquisitionTriggered   // Suspicion at critical — organized hunt
        case cosmologicalScarring   // Veil permanently altered
        case deepSheolBreached      // Triple threshold crossed — deep access
        case sebittiSpawned         // Correction layer activated
        case motApproaching         // Terminal cosmology imminent
        case regionRecovery         // Region crossed back below threshold
    }
}

/// The origin system that produced this event.
public enum EventSource: String, Sendable {
    case ritual         // produced by ritual resolution
    case worldTick      // produced by the tick/decay cycle
    case cascade        // produced by threshold crossings or cascades
    case npc            // produced by NPC behavior
    case site           // produced by site state changes
    case spirit         // produced by lingering spirit behavior
    case director       // produced by the world director
    case practitioner   // produced by direct practitioner action
}

/// How important this event is — guides director attention and journal queries.
public enum EventSeverity: Int, Sendable, Comparable {
    case ambient = 0        // background noise — wind, silence, passage of time
    case notable = 1        // worth mentioning — a state change the practitioner might notice
    case significant = 2    // demands attention — threshold crossing, NPC reaction, site disturbance
    case rupture = 3        // cannot be ignored — mutation, Veil tear, Sebitti, Mot

    public static func < (lhs: EventSeverity, rhs: EventSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// An entry in the append-only event journal.
public struct JournalEntry: Sendable, Identifiable {
    public let id: UUID
    public let tick: Int
    public let type: JournalEntryType
    public let source: EventSource
    public let severity: EventSeverity
    public let description: String
    public let regionID: UUID?
    public let siteID: UUID?
    public let involvedNPCs: [UUID]
    public let tags: Set<String>

    public init(
        tick: Int,
        type: JournalEntryType,
        description: String,
        source: EventSource = .worldTick,
        severity: EventSeverity = .notable,
        regionID: UUID? = nil,
        siteID: UUID? = nil,
        involvedNPCs: [UUID] = [],
        tags: Set<String> = []
    ) {
        self.id = UUID()
        self.tick = tick
        self.type = type
        self.source = source
        self.severity = severity
        self.description = description
        self.regionID = regionID
        self.siteID = siteID
        self.involvedNPCs = involvedNPCs
        self.tags = tags
    }

    public enum JournalEntryType: String, Sendable {
        case ritualPerformed
        case spiritManifested
        case thresholdEvent
        case worldTick
        case practitionerAction
        case sebittiEvent
        case motEvent
        case siteChange
        case npcReaction
        case rumorSeed
        case directorEvent
        case spiritLingering
    }
}

/// The world simulation — processes all regions, tracks global state, runs the cosmology.
public struct WorldSimulation: Sendable {

    /// All regions in the simulation.
    public var regions: [UUID: RegionState]

    /// Adjacency map — which regions influence each other.
    public var adjacency: [UUID: [UUID]]

    /// Current simulation tick.
    public var currentTick: Int

    /// The append-only event journal.
    public var journal: [JournalEntry]

    /// Threshold events that fired this tick.
    public var pendingEvents: [ThresholdEvent]

    /// Active threshold states per region (for hysteresis — sticky transitions).
    public var activeThresholds: [UUID: Set<ThresholdEvent.EventType>]

    /// Whether the Sebitti are currently active.
    public var sebittiActive: Bool

    /// Regions in Mot state (terminal cosmology).
    public var motRegions: Set<UUID>

    public init(regions: [RegionState], adjacency: [UUID: [UUID]] = [:]) {
        self.regions = Dictionary(uniqueKeysWithValues: regions.map { ($0.id, $0) })
        self.adjacency = adjacency
        self.currentTick = 0
        self.journal = []
        self.pendingEvents = []
        self.activeThresholds = [:]
        self.sebittiActive = false
        self.motRegions = []
    }

    // MARK: - Simulation Tick

    /// Advance the simulation by one tick.
    /// Processes: entropy decay → threshold evaluation → cross-regional propagation → correction check.
    /// NOTE: The caller is responsible for incrementing `currentTick` before calling this.
    /// When using WorldClock (the correct path), the clock manages tick counting.
    public mutating func tick() {
        pendingEvents = []

        // 1. Entropy decay for all regions
        for id in regions.keys {
            if !motRegions.contains(id) {
                regions[id]?.tickDecay()
            }
        }

        // 2. Threshold evaluation
        for id in regions.keys {
            evaluateThresholds(regionID: id)
        }

        // 3. Cross-regional propagation
        propagateAcrossBoundaries()

        // 4. Sebitti check (correction layer)
        evaluateSebittiConditions()

        // 5. Mot check (terminal state)
        evaluateMotConditions()

        // 6. Log tick
        if !pendingEvents.isEmpty {
            for event in pendingEvents {
                let severity: EventSeverity = switch event.type {
                case .sebittiSpawned, .motApproaching: .rupture
                case .deepSheolBreached, .cosmologicalScarring: .significant
                case .inquisitionTriggered, .settlementFailing: .significant
                default: .notable
                }
                journal.append(JournalEntry(
                    tick: currentTick,
                    type: .thresholdEvent,
                    description: event.description,
                    source: .cascade,
                    severity: severity,
                    regionID: event.regionID,
                    tags: Set([event.type.rawValue])
                ))
            }
        }
    }

    // MARK: - Apply Ritual Effects

    /// Apply the world effects from a completed ritual to its region and site.
    public mutating func applyRitualEffects(
        _ effects: WorldEffects,
        regionID: UUID,
        site: inout RitualSite
    ) {
        regions[regionID]?.applyRitualEntropy(
            ghostActivityDelta: effects.ghostActivityDelta,
            corruptionDelta: effects.corruptionDelta,
            spiritualPressureDelta: effects.spiritualPressureDelta,
            suspicionDelta: effects.suspicionDelta
        )

        site.recordRitualPerformed(corruption: effects.corruptionDelta)

        journal.append(JournalEntry(
            tick: currentTick,
            type: .ritualPerformed,
            description: "A ritual was performed at \(site.name).",
            source: .ritual,
            severity: .significant,
            regionID: regionID,
            siteID: site.id,
            tags: Set(["ritual", "entropy"])
        ))
    }

    // MARK: - Threshold Evaluation

    /// Evaluate threshold crossings for a single region.
    /// Uses hysteresis — trigger values and reset values differ to prevent oscillation.
    private mutating func evaluateThresholds(regionID: UUID) {
        guard let region = regions[regionID] else { return }
        var active = activeThresholds[regionID] ?? []

        // Ghost Activity hostile threshold (trigger: 0.6, reset: 0.45)
        if region.ghostsHostile && !active.contains(.ghostsHostile) {
            active.insert(.ghostsHostile)
            pendingEvents.append(ThresholdEvent(
                type: .ghostsHostile, regionID: regionID,
                description: "The dead are restless in \(region.name). Ambient hostility rising.",
                tick: currentTick
            ))
        } else if !region.ghostsHostile && region.ghostActivity < 0.45 {
            active.remove(.ghostsHostile)
        }

        // Corruption degrading threshold (trigger: 0.5, reset: 0.35)
        if region.corruptionDegrading && !active.contains(.corruptionDegrading) {
            active.insert(.corruptionDegrading)
            pendingEvents.append(ThresholdEvent(
                type: .corruptionDegrading, regionID: regionID,
                description: "Corruption seeps through \(region.name). Fragment integrity degrades.",
                tick: currentTick
            ))
        } else if !region.corruptionDegrading && region.corruption < 0.35 {
            active.remove(.corruptionDegrading)
        }

        // Settlement failure threshold (trigger: stability < 0.2, reset: stability > 0.35)
        if region.settlementFailing && !active.contains(.settlementFailing) {
            active.insert(.settlementFailing)
            pendingEvents.append(ThresholdEvent(
                type: .settlementFailing, regionID: regionID,
                description: "Settlements in \(region.name) are failing. Survival override active.",
                tick: currentTick
            ))
        } else if !region.settlementFailing && region.stability > 0.35 {
            active.remove(.settlementFailing)
        }

        // Inquisition threshold (trigger: 0.8, reset: 0.6)
        if region.inquisitionActive && !active.contains(.inquisitionTriggered) {
            active.insert(.inquisitionTriggered)
            pendingEvents.append(ThresholdEvent(
                type: .inquisitionTriggered, regionID: regionID,
                description: "The priests of \(region.name) have organized. They are looking for you.",
                tick: currentTick
            ))
        } else if !region.inquisitionActive && region.suspicion < 0.6 {
            active.remove(.inquisitionTriggered)
        }

        // Cosmological scarring (trigger: veil > 0.85, never resets — permanent)
        if region.cosmologicallyScarred && !active.contains(.cosmologicalScarring) {
            active.insert(.cosmologicalScarring)
            pendingEvents.append(ThresholdEvent(
                type: .cosmologicalScarring, regionID: regionID,
                description: "The Veil in \(region.name) has scarred. The boundary is permanently thinned.",
                tick: currentTick
            ))
        }

        // Deep Sheol access (trigger: triple threshold)
        if region.deepSheolAccessible && !active.contains(.deepSheolBreached) {
            active.insert(.deepSheolBreached)
            pendingEvents.append(ThresholdEvent(
                type: .deepSheolBreached, regionID: regionID,
                description: "The deep opens beneath \(region.name). The Rephaim stir.",
                tick: currentTick
            ))
        } else if !region.deepSheolAccessible {
            active.remove(.deepSheolBreached)
        }

        activeThresholds[regionID] = active
    }

    // MARK: - Cross-Regional Propagation

    /// Adjacent regions influence each other with diminishing strength.
    private mutating func propagateAcrossBoundaries() {
        let propagationFactor = 0.15  // 15% of excess propagates

        // Snapshot current state to avoid order-dependent updates
        let snapshot = regions

        for (regionID, neighbors) in adjacency {
            guard let region = snapshot[regionID] else { continue }

            for neighborID in neighbors {
                guard var neighbor = regions[neighborID],
                      !motRegions.contains(neighborID) else { continue }

                // Ghost Activity propagation (above threshold)
                if region.ghostActivity > 0.5 {
                    let excess = (region.ghostActivity - 0.5) * propagationFactor
                    neighbor.ghostActivity = min(1.0, neighbor.ghostActivity + excess)
                }

                // Corruption seepage
                if region.corruption > 0.4 {
                    let seepage = (region.corruption - 0.4) * propagationFactor * 0.5
                    neighbor.corruption = min(1.0, neighbor.corruption + seepage)
                }

                // Spiritual Pressure propagation (very slow)
                if region.spiritualPressure > 0.6 {
                    let pressure = (region.spiritualPressure - 0.6) * propagationFactor * 0.3
                    neighbor.spiritualPressure = min(1.0, neighbor.spiritualPressure + pressure)
                }

                // Suspicion travels with refugees from failing settlements
                if region.settlementFailing {
                    neighbor.suspicion = min(1.0, neighbor.suspicion + 0.02)
                    neighbor.population = min(1.0, neighbor.population + 0.01) // refugees arrive
                }

                regions[neighborID] = neighbor
            }
        }
    }

    // MARK: - Correction Layer (Sebitti)

    /// When global Spiritual Pressure and average Veil Thinness exceed containment,
    /// the simulation spawns the Sebitti — the kernel panic handler.
    private mutating func evaluateSebittiConditions() {
        let activeRegions = regions.values.filter { !motRegions.contains($0.id) }
        guard !activeRegions.isEmpty else { return }

        let avgPressure = activeRegions.map(\.spiritualPressure).reduce(0, +) / Double(activeRegions.count)
        let avgVeil = activeRegions.map(\.veilThinness).reduce(0, +) / Double(activeRegions.count)

        if avgPressure > 0.7 && avgVeil > 0.6 && !sebittiActive {
            sebittiActive = true
            pendingEvents.append(ThresholdEvent(
                type: .sebittiSpawned, regionID: activeRegions.first!.id,
                description: "The Seven have been released. The correction has begun.",
                tick: currentTick
            ))
            journal.append(JournalEntry(
                tick: currentTick, type: .sebittiEvent,
                description: "SEBITTI SPAWNED — global pressure \(String(format: "%.0f%%", avgPressure * 100)), average veil \(String(format: "%.0f%%", avgVeil * 100))",
                source: .cascade,
                severity: .rupture,
                tags: Set(["sebitti", "correction"])
            ))
        }

        // Sebitti actively purge instability
        if sebittiActive {
            for id in regions.keys where !motRegions.contains(id) {
                guard var region = regions[id] else { continue }
                region.ghostActivity = max(0.0, region.ghostActivity - 0.1)
                region.corruption = max(0.0, region.corruption - 0.05)
                region.spiritualPressure = max(0.0, region.spiritualPressure - 0.03)
                // Sebitti reduce population as collateral
                region.population = max(0.0, region.population - 0.02)
                regions[id] = region
            }

            // Sebitti deactivate when pressure drops
            let newAvgPressure = regions.values
                .filter { !motRegions.contains($0.id) }
                .map(\.spiritualPressure).reduce(0, +) / Double(activeRegions.count)
            if newAvgPressure < 0.4 {
                sebittiActive = false
                journal.append(JournalEntry(
                    tick: currentTick, type: .sebittiEvent,
                    description: "The Seven have withdrawn. The correction is complete.",
                    source: .cascade,
                    severity: .significant,
                    tags: Set(["sebitti", "correction", "recovery"])
                ))
            }
        }
    }

    // MARK: - Mot (Terminal State)

    /// If a region's stability reaches near-zero with high corruption, it enters Mot.
    private mutating func evaluateMotConditions() {
        for (id, region) in regions where !motRegions.contains(id) {
            if region.stability < 0.05 && region.corruption > 0.8 {
                motRegions.insert(id)
                // Mot overwrites the region
                regions[id]?.ghostActivity = 0.0  // absorbed
                regions[id]?.corruption = 1.0      // sterility
                regions[id]?.population = 0.0      // collapse
                regions[id]?.warIntensity = 0.0    // nothing left to fight over
                regions[id]?.stability = 0.0

                pendingEvents.append(ThresholdEvent(
                    type: .motApproaching, regionID: id,
                    description: "Mot has claimed \(region.name). The region produces nothing. Life has ended here.",
                    tick: currentTick
                ))
                journal.append(JournalEntry(
                    tick: currentTick, type: .motEvent,
                    description: "MOT STATE — \(region.name) has entered terminal cosmology.",
                    source: .cascade,
                    severity: .rupture,
                    regionID: id,
                    tags: Set(["mot", "terminal", "death"])
                ))
            }
        }
    }

    // MARK: - Queries

    /// Get all events for a specific region.
    public func events(for regionID: UUID) -> [JournalEntry] {
        journal.filter { $0.regionID == regionID }
    }

    /// Get all events at a specific site.
    public func events(at siteID: UUID) -> [JournalEntry] {
        journal.filter { $0.siteID == siteID }
    }

    /// Get all events since a given tick.
    public func events(since tick: Int) -> [JournalEntry] {
        journal.filter { $0.tick >= tick }
    }

    /// Get all events at or above a given severity.
    public func events(severity minimum: EventSeverity) -> [JournalEntry] {
        journal.filter { $0.severity >= minimum }
    }

    /// Get recent rupture-level events.
    public func recentRuptures(limit: Int = 5) -> [JournalEntry] {
        journal.filter { $0.severity == .rupture }
            .suffix(limit)
            .reversed()
    }

    /// Get events involving a specific NPC.
    public func events(involving npcID: UUID) -> [JournalEntry] {
        journal.filter { $0.involvedNPCs.contains(npcID) }
    }

    /// Get events matching a tag.
    public func events(tagged tag: String) -> [JournalEntry] {
        journal.filter { $0.tags.contains(tag) }
    }

    /// Whether any region is in Mot state.
    public var hasTerminalRegion: Bool { !motRegions.isEmpty }

    /// Global average stability.
    public var globalStability: Double {
        let active = regions.values.filter { !motRegions.contains($0.id) }
        guard !active.isEmpty else { return 0.0 }
        return active.map(\.stability).reduce(0, +) / Double(active.count)
    }

    /// Percentage of regions in Mot state.
    public var motPercentage: Double {
        guard !regions.isEmpty else { return 0.0 }
        return Double(motRegions.count) / Double(regions.count)
    }
}
