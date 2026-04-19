// MARK: - Player Command
// The non-interactive command model for the world.
// Every consequential player action is one of these.
// The CLI translates readLine() menus into commands.
// Bots emit commands directly.
// The WorldShard executes commands against shared state.

import Foundation

/// A command a practitioner can issue against the world.
/// These are the verbs of the game. Everything else is rendering.
public enum PlayerCommand: Sendable {
    case look
    case travel(siteIndex: Int)
    case wait
    case talkTo(npcIndex: Int, action: ConversationAction)
    case castAstragali
    case performRitual(RitualIntent)

    public enum ConversationAction: Sendable {
        case friendly
        case askRegion
        case askDead
    }
}

/// The inputs needed to perform a ritual without interactive prompts.
public struct RitualIntent: Sendable {
    public let fragmentIndex: Int
    public let trueName: String?
    public let artifactIndex: Int?
    public let traceIndex: Int?
    public let libationType: LibationType
    public let timing: WorldTiming

    public init(
        fragmentIndex: Int,
        trueName: String? = nil,
        artifactIndex: Int? = nil,
        traceIndex: Int? = nil,
        libationType: LibationType = .water,
        timing: WorldTiming = WorldTiming(time: .night)
    ) {
        self.fragmentIndex = fragmentIndex
        self.trueName = trueName
        self.artifactIndex = artifactIndex
        self.traceIndex = traceIndex
        self.libationType = libationType
        self.timing = timing
    }
}

/// The result of executing a command — what the player perceives.
public struct CommandResult: Sendable {
    public let narration: [String]
    public let worldEvents: [WorldEvent]
    public let directorEvents: [DirectorEvent]

    public init(
        narration: [String] = [],
        worldEvents: [WorldEvent] = [],
        directorEvents: [DirectorEvent] = []
    ) {
        self.narration = narration
        self.worldEvents = worldEvents
        self.directorEvents = directorEvents
    }
}
