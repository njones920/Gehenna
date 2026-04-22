// MARK: - Ritual Site
// The location where the boundary is thin enough for contact.
// Sites accumulate history through use — they become more powerful and more volatile.
// The site is mandatory. Without a site, there is no boundary to cross.
//
// Sites remember. Scarring is durable. Traces fade. Disturbance cools.
// The practitioner who uses a site repeatedly transforms it.

import Foundation

/// A named type of ritual site.
public enum SiteType: String, Codable, Hashable, Sendable {
    case burialCave       // limestone caves, bench tombs — the primary site
    case battlefield      // recent or ancient fields of the dead
    case ancestorShrine   // domestic ancestor installation
    case collapsingTemple // ruined sanctuaries, former holy places
    case topheth          // defiled high place — child sacrifice site, the burning ground
    case springCaveMouth  // where water exits stone — liminal by nature
    case ossuaryNiche     // secondary burial recess
    case wadiBed          // seasonal waterway — carries death downstream

    /// Burial and ancestor contexts where the dead expect compensation.
    public var requiresFuneraryCompensation: Bool {
        switch self {
        case .burialCave, .ancestorShrine, .ossuaryNiche:
            return true
        default:
            return false
        }
    }
}

/// The properties of a ritual site.
public struct RitualSite: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let type: SiteType
    public let affinity: Affinity

    // -- Site state (mutable through use) --
    /// Accumulated presence of the dead. Increases with every ritual performed here.
    public var deathSaturation: Double

    /// How thin the boundary is at this location. Higher = easier passage.
    public var veilThinness: Double

    /// Residual holiness from prior consecration. Degrades with desecration.
    public var sanctity: Double

    /// Spiritual contamination. Accumulates from blood offerings and hostile manifestations.
    public var corruption: Double

    /// Narrative tags associated with this site's history.
    public var tags: TagConstellation

    // -- Site History (accumulated over play) --

    /// Cumulative durable site damage from rituals, mutations, and taboo acts.
    /// Scarring heals only under quiet conditions or through deliberate purification.
    public var scarring: Double

    /// Site-specific suspicion beyond regional. Kfar Shalem builds this fast.
    /// Decays slowly. Performing rituals at a village shrine is noticed.
    public var localSuspicion: Double

    /// Lingering spiritual traces from recent rituals. Fade over time.
    /// Other practitioners (or spirits) could detect these.
    public var activeTraces: [String]

    /// How "seen" the practitioner's activity is at this site.
    /// Witnessing a ritual here makes this spike. Decays with time and distance.
    public var witnessExposure: Double

    /// When the last ritual was performed here (tick number).
    public var lastRitualTick: Int?

    /// Recent event count at this site. Decays each tick.
    /// Used by the world director to assess site volatility.
    public var recentEventCount: Int

    /// The tick when the practitioner last visited this site.
    public var lastVisitTick: Int?

    /// Local site clock used for deterministic trace fading.
    public var siteTickCount: Int

    public init(
        id: UUID = UUID(),
        name: String,
        type: SiteType,
        affinity: Affinity,
        deathSaturation: Double = 0.0,
        veilThinness: Double = 0.3,
        sanctity: Double = 0.5,
        corruption: Double = 0.0,
        tags: TagConstellation = TagConstellation()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.affinity = affinity
        self.deathSaturation = deathSaturation
        self.veilThinness = veilThinness
        self.sanctity = sanctity
        self.corruption = corruption
        self.tags = tags
        self.scarring = 0.0
        self.localSuspicion = 0.0
        self.activeTraces = []
        self.witnessExposure = 0.0
        self.lastRitualTick = nil
        self.recentEventCount = 0
        self.lastVisitTick = nil
        self.siteTickCount = 0
    }

    /// Sites become more powerful and more volatile with use.
    public mutating func recordRitualPerformed(corruption corruptionDelta: Double = 0.02) {
        deathSaturation = min(1.0, deathSaturation + 0.05)
        veilThinness = min(1.0, veilThinness + 0.03)
        corruption = min(1.0, corruption + corruptionDelta)
        sanctity = max(0.0, sanctity - 0.01)

        // Site history updates
        scarring = min(1.0, scarring + 0.02)
        localSuspicion = min(1.0, localSuspicion + suspicionMultiplier * 0.05)
        witnessExposure = min(1.0, witnessExposure + 0.1)
        recentEventCount += 1
        activeTraces.append("ritual_residue")

        // Cap traces — old ones fade when the list grows
        if activeTraces.count > 8 {
            activeTraces.removeFirst()
        }
    }

    /// Record a mutation at this site — heavier scarring and contamination.
    public mutating func recordMutation() {
        scarring = min(1.0, scarring + 0.1)
        corruption = min(1.0, corruption + 0.08)
        witnessExposure = min(1.0, witnessExposure + 0.2)
        activeTraces.append("mutation_scar")
        recentEventCount += 2
    }

    /// Per-tick decay of site-local state. Called by the world clock.
    public mutating func tickSiteState() {
        siteTickCount += 1

        // Witness exposure cools
        witnessExposure = max(0.0, witnessExposure - 0.02)

        // Local suspicion decays very slowly
        localSuspicion = max(0.0, localSuspicion - 0.005)

        // Recent event count decays
        if recentEventCount > 0 {
            recentEventCount = max(0, recentEventCount - 1)
        }

        // Active traces fade — remove the oldest one every 4 local ticks.
        if !activeTraces.isEmpty && siteTickCount.isMultiple(of: 4) {
            activeTraces.removeFirst()
        }

        // Scarring heals only when the site is quiet and clean enough to recover.
        if activeTraces.isEmpty && witnessExposure < 0.05 && corruption < 0.2 {
            scarring = max(0.0, scarring - scarringRecoveryRate)
            veilThinness = max(baseVeilThinnessFloor, veilThinness - veilRecoveryRate)
            sanctity = min(1.0, sanctity + sanctityRecoveryRate)
        }
    }

    /// Deliberate restoration work. Future healer/firefighter play should call this.
    public mutating func purifySite(strength: Double = 0.1) {
        let clampedStrength = max(0.0, min(1.0, strength))
        guard clampedStrength > 0 else { return }

        scarring = max(0.0, scarring - clampedStrength * 0.35)
        corruption = max(0.0, corruption - clampedStrength * 0.5)
        veilThinness = max(baseVeilThinnessFloor, veilThinness - clampedStrength * 0.2)
        sanctity = min(1.0, sanctity + clampedStrength * 0.25)
        witnessExposure = max(0.0, witnessExposure - clampedStrength * 0.2)
        localSuspicion = max(0.0, localSuspicion - clampedStrength * 0.1)

        if !activeTraces.isEmpty && clampedStrength >= 0.25 {
            activeTraces.removeFirst(min(activeTraces.count, Int(clampedStrength * 4)))
        }
    }

    /// Whether the site shows visible signs of recent activity.
    /// The world director uses this to describe what the practitioner sees on arrival.
    public var isDisturbed: Bool {
        witnessExposure > 0.15 || recentEventCount > 0 || !activeTraces.isEmpty
    }

    /// Whether the site has been significantly scarred by prior use.
    public var isScarred: Bool {
        scarring > 0.1
    }

    /// Local Veil modifier from durable scarring.
    /// Scarred sites have a thinner Veil until restored — consequence is structural but healable.
    public var localVeilModifier: Double {
        scarring * 0.15
    }

    /// The effective Veil Thinness including scarring.
    public var effectiveVeilThinness: Double {
        min(1.0, veilThinness + localVeilModifier)
    }

    /// Rumor strength that reaches a given faction from this site.
    /// Site type determines how socially "near" the ritual feels to that faction.
    public func rumorStrength(for faction: Faction, baseScale: Double = 0.3) -> Double {
        let siteReach: Double = switch type {
        case .ancestorShrine:   1.0
        case .collapsingTemple: 0.55
        case .battlefield:      0.35
        case .burialCave:       0.25
        case .topheth:          0.15
        case .springCaveMouth:  0.3
        case .ossuaryNiche:     0.2
        case .wadiBed:          0.4
        }

        let factionReach: Double = switch (type, faction) {
        case (.ancestorShrine, .elders):          1.4
        case (.ancestorShrine, .priesthood):      1.2
        case (.ancestorShrine, .traders):         0.6
        case (.collapsingTemple, .priesthood):    1.4
        case (.collapsingTemple, .elders):        0.8
        case (.collapsingTemple, .traders):       0.7
        case (.battlefield, .traders):            1.1
        case (.battlefield, .elders):             0.7
        case (.battlefield, .priesthood):         0.6
        case (.burialCave, .priesthood):          0.9
        case (.burialCave, .elders):              0.5
        case (.burialCave, .traders):             0.4
        case (.topheth, .priesthood):             1.3
        case (.topheth, .elders):                 0.6
        case (.topheth, .traders):                0.3
        case (.springCaveMouth, .priesthood):     0.9
        case (.springCaveMouth, .elders):         0.8
        case (.springCaveMouth, .traders):        0.7
        case (.ossuaryNiche, .elders):            1.0
        case (.ossuaryNiche, .priesthood):        0.9
        case (.ossuaryNiche, .traders):           0.3
        case (.wadiBed, .traders):                1.0
        case (.wadiBed, .elders):                 0.6
        case (.wadiBed, .priesthood):             0.5
        }

        return localSuspicion * baseScale * siteReach * factionReach
    }

    /// Suspicion multiplier based on site type.
    /// Performing rituals at a living village is much more noticed.
    private var suspicionMultiplier: Double {
        switch type {
        case .ancestorShrine: return 3.0   // the village is watching
        case .battlefield:    return 0.5   // who visits a battlefield at night?
        case .burialCave:     return 0.3   // isolated
        case .collapsingTemple: return 0.4 // ruins attract scholars
        case .topheth:        return 0.2   // nobody goes there willingly
        default:              return 1.0
        }
    }

    /// Resonance bonus from site type and affinity matching.
    public func siteResonance(with fragmentAffinity: Affinity) -> Double {
        affinity.resonanceWith(fragmentAffinity)
    }

    /// Stable-enough local salt for deterministic director scheduling.
    public var stableEventSalt: Int {
        name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
    }

    private var scarringRecoveryRate: Double {
        switch type {
        case .springCaveMouth: return 0.003
        case .ancestorShrine: return 0.002
        case .burialCave, .ossuaryNiche: return 0.001
        case .battlefield, .wadiBed: return 0.0007
        case .collapsingTemple: return 0.0005
        case .topheth: return 0.0002
        }
    }

    private var veilRecoveryRate: Double { scarringRecoveryRate * 0.5 }
    private var sanctityRecoveryRate: Double { scarringRecoveryRate * 0.25 }

    private var baseVeilThinnessFloor: Double {
        switch type {
        case .springCaveMouth: return 0.25
        case .topheth: return 0.45
        default: return 0.1
        }
    }
}
