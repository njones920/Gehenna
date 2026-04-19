// MARK: - Ritual Configuration & DSL
// The ritual system is a discoverable rule engine. The player assembles inputs;
// the grammar evaluates them through a deterministic pipeline; a spirit manifests.
//
// Mechanically, the grammar is a compiler. A ritual is a program.
// The practitioner is the programmer. The cosmology is the runtime.
//
// Swift result builders express ritual composition as a domain-specific language.

import Foundation

/// The complete assembled configuration of a ritual, ready for resolution.
public struct RitualConfiguration: Sendable {
    public let id: UUID

    // -- Mandatory Inputs --
    public let remains: Fragment
    public let site: RitualSite

    // -- Optional Inputs --
    public let trueName: TrueName?
    public let lifeArtifact: LifeArtifact?
    public let memoryTrace: MemoryTrace?
    public let libation: Libation?
    public let timing: WorldTiming?

    public init(
        id: UUID = UUID(),
        remains: Fragment,
        site: RitualSite,
        trueName: TrueName? = nil,
        lifeArtifact: LifeArtifact? = nil,
        memoryTrace: MemoryTrace? = nil,
        libation: Libation? = nil,
        timing: WorldTiming? = nil
    ) {
        self.id = id
        self.remains = remains
        self.site = site
        self.trueName = trueName
        self.lifeArtifact = lifeArtifact
        self.memoryTrace = memoryTrace
        self.libation = libation
        self.timing = timing
    }

    /// All narrative tags aggregated from all inputs.
    public var aggregatedTags: TagConstellation {
        var tags = remains.tags
        if let artifact = lifeArtifact {
            tags = tags.merged(with: artifact.tags)
        }
        if let trace = memoryTrace {
            tags = tags.merged(with: trace.tags)
        }
        if let siteTag = Optional(site.tags) {
            tags = tags.merged(with: siteTag)
        }
        return tags
    }

    /// All eras present in the configuration.
    public var eras: [Era] {
        var result = [remains.era]
        if let artifact = lifeArtifact { result.append(artifact.era) }
        if let trace = memoryTrace { result.append(trace.era) }
        return result
    }

    /// The dominant era — the era that appears most frequently or is deepest.
    public var dominantEra: Era {
        let eraCounts = eras.reduce(into: [Era: Int]()) { $0[$1, default: 0] += 1 }
        // If tied, prefer the deeper (older) era
        return eraCounts.max(by: { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key < rhs.key }
            return lhs.value < rhs.value
        })?.key ?? remains.era
    }

    /// Whether a war-domain Life Artifact is present (Apotropaic Rule).
    public var hasApotropaicArtifact: Bool {
        lifeArtifact?.isApotropaic ?? false
    }

    /// Count of optional inputs provided — more inputs = richer configuration.
    public var completeness: Int {
        var count = 0
        if trueName != nil { count += 1 }
        if lifeArtifact != nil { count += 1 }
        if memoryTrace != nil { count += 1 }
        if libation != nil { count += 1 }
        if timing != nil { count += 1 }
        return count
    }
}

// MARK: - Ritual Result Builder DSL

/// A marker protocol for ritual input components.
public protocol RitualInputComponent: Sendable {}

extension Fragment: RitualInputComponent {}
extension RitualSite: RitualInputComponent {}
extension TrueName: RitualInputComponent {}
extension LifeArtifact: RitualInputComponent {}
extension MemoryTrace: RitualInputComponent {}
extension Libation: RitualInputComponent {}
extension WorldTiming: RitualInputComponent {}

/// Accumulated inputs during ritual building.
public struct RitualComponents: Sendable {
    var remains: Fragment?
    var site: RitualSite?
    var trueName: TrueName?
    var lifeArtifact: LifeArtifact?
    var memoryTrace: MemoryTrace?
    var libation: Libation?
    var timing: WorldTiming?

    init() {}

    mutating func add(_ component: any RitualInputComponent) {
        switch component {
        case let f as Fragment:     remains = f
        case let s as RitualSite:   site = s
        case let n as TrueName:     trueName = n
        case let a as LifeArtifact: lifeArtifact = a
        case let m as MemoryTrace:  memoryTrace = m
        case let l as Libation:     libation = l
        case let t as WorldTiming:  timing = t
        default: break
        }
    }
}

/// Result builder for composing rituals in DSL form.
///
/// Usage:
/// ```swift
/// let config = Ritual {
///     Fragment(remains: .longBone, era: .ironAgeII, domain: .war, affinity: .fire)
///     RitualSite(name: "Nahal Cave", type: .burialCave, affinity: .earth)
///     TrueName("Hiram, son of Dagon", partial: true)
///     Libation(.fermentedWine)
///     WorldTiming(time: .night, lunar: .waxingGibbous)
/// }
/// ```
@resultBuilder
public struct RitualBuilder {
    public static func buildBlock(_ components: any RitualInputComponent...) -> RitualComponents {
        var result = RitualComponents()
        for component in components {
            result.add(component)
        }
        return result
    }
}

/// Ritual construction entry point using result builder syntax.
public enum Ritual {
    /// Compile a ritual configuration from component inputs.
    /// Returns nil if mandatory inputs (Remains, Site) are missing.
    public static func compile(@RitualBuilder _ builder: () -> RitualComponents) -> RitualConfiguration? {
        let components = builder()
        guard let remains = components.remains,
              let site = components.site else {
            return nil  // mandatory inputs missing — malformed ritual does not compile
        }

        return RitualConfiguration(
            remains: remains,
            site: site,
            trueName: components.trueName,
            lifeArtifact: components.lifeArtifact,
            memoryTrace: components.memoryTrace,
            libation: components.libation,
            timing: components.timing
        )
    }
}
