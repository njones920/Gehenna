// MARK: - Persistence
// Typed snapshot formats for local save/load and future replay boundaries.
// Canon data remains authored truth; snapshots capture mutable runtime state.

import Foundation

public struct PractitionerInventorySnapshot: Codable, Sendable {
    public var fragments: [Fragment]
    public var artifacts: [LifeArtifact]
    public var memoryTraces: [MemoryTrace]
    public var libations: [LibationType]

    public init(
        fragments: [Fragment],
        artifacts: [LifeArtifact],
        memoryTraces: [MemoryTrace],
        libations: [LibationType]
    ) {
        self.fragments = fragments
        self.artifacts = artifacts
        self.memoryTraces = memoryTraces
        self.libations = libations
    }
}

public struct SinglePlayerSnapshot: Codable, Sendable {
    public let engineVersion: String
    public let codexVersion: String
    public let savedAtTick: Int
    public var world: WorldSimulation
    public var profile: PractitionerProfile
    public var codex: CodexOfTheDead
    public var sites: [RitualSite]
    public var inventory: PractitionerInventorySnapshot
    public var currentSiteIndex: Int
    public var ritualCount: Int
    public var rootIdentities: [RootIdentity]
    public var npcs: [NPC]
    public var clock: WorldClock

    public init(
        engineVersion: String = GehennaEngine.version,
        codexVersion: String = GehennaEngine.codexVersion,
        savedAtTick: Int,
        world: WorldSimulation,
        profile: PractitionerProfile,
        codex: CodexOfTheDead,
        sites: [RitualSite],
        inventory: PractitionerInventorySnapshot,
        currentSiteIndex: Int,
        ritualCount: Int,
        rootIdentities: [RootIdentity],
        npcs: [NPC],
        clock: WorldClock
    ) {
        self.engineVersion = engineVersion
        self.codexVersion = codexVersion
        self.savedAtTick = savedAtTick
        self.world = world
        self.profile = profile
        self.codex = codex
        self.sites = sites
        self.inventory = inventory
        self.currentSiteIndex = currentSiteIndex
        self.ritualCount = ritualCount
        self.rootIdentities = rootIdentities
        self.npcs = npcs
        self.clock = clock
    }
}

public enum SnapshotStore {
    public static func encode(_ snapshot: SinglePlayerSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(snapshot)
    }

    public static func decodeSinglePlayerSnapshot(from data: Data) throws -> SinglePlayerSnapshot {
        let decoder = JSONDecoder()
        return try decoder.decode(SinglePlayerSnapshot.self, from: data)
    }

    public static func save(_ snapshot: SinglePlayerSnapshot, to url: URL) throws {
        let data = try encode(snapshot)
        try data.write(to: url, options: .atomic)
    }

    public static func loadSinglePlayerSnapshot(from url: URL) throws -> SinglePlayerSnapshot {
        let data = try Data(contentsOf: url)
        return try decodeSinglePlayerSnapshot(from: data)
    }
}
