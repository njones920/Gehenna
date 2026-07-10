// MARK: - Story Threads
// A want is not a quest. No quest log, no marker, no reward screen —
// a thread is discovered in conversation, tracked in the journal, and
// advanced by observable predicates over state the simulation already
// owns: trust thresholds, Codex contents, intents spoken, epochs met.
// The thread type is deliberately minimal; the content lives in the
// beats, and the beats are authored.

import Foundation

/// Minimal state for one authored thread: a stage counter and a set of
/// observed flags. All transition logic lives with the thread's content;
/// this type only remembers.
public struct StoryThread: Codable, Sendable {
    public let key: String
    public var stage: Int
    public var flags: Set<String>

    public init(key: String) {
        self.key = key
        self.stage = 0
        self.flags = []
    }

    /// Stages only move forward.
    public mutating func advance(to newStage: Int) {
        stage = max(stage, newStage)
    }

    public mutating func mark(_ flag: String) {
        flags.insert(flag)
    }

    public func has(_ flag: String) -> Bool {
        flags.contains(flag)
    }
}
