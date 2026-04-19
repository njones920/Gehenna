// MARK: - Ritual Site
// The location where the boundary is thin enough for contact.
// Sites accumulate history through use — they become more powerful and more volatile.
// The site is mandatory. Without a site, there is no boundary to cross.
//
// Sites remember. Scarring is permanent. Traces fade. Disturbance cools.
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

    /// Cumulative permanent site damage from rituals, mutations, and taboo acts.
    /// Scarring never fully heals. It is the stone's memory.
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

        // Scarring never heals. That is the point.
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

    /// Local Veil modifier from permanent scarring.
    /// Scarred sites have a permanently thinner Veil — consequence is structural.
    public var localVeilModifier: Double {
        scarring * 0.15
    }

    /// The effective Veil Thinness including scarring.
    public var effectiveVeilThinness: Double {
        min(1.0, veilThinness + localVeilModifier)
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
}
