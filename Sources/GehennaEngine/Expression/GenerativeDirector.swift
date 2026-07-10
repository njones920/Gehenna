// MARK: - Generative Director Lane
// The Conway lane. The LLM is admitted as one more actor in the world —
// not rendering state, proposing input. A proposal is a typed, bounded
// event; validation rejects anything malformed; the engine commits what
// survives to the journal with real mechanical effects. The model
// proposes. The simulation commits. The record remembers.

import Foundation

/// A world event proposed by the generative lane.
public struct WorldEventProposal: Codable, Sendable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case rumor      // village talk — carries a mechanical rumor effect
        case npcAction  // a named villager did something small
        case omen       // an ambient cosmological sign — slight pressure
        case visitor    // someone passed through — journal only
    }

    public let kind: Kind
    /// NPC name for `npcAction`; ignored otherwise.
    public let actor: String?
    /// One sentence, past tense, diegetic.
    public let text: String

    public init(kind: Kind, actor: String?, text: String) {
        self.kind = kind
        self.actor = actor
        self.text = text
    }
}

/// The gate between what the model wants and what the world accepts.
public enum ProposalValidator {
    public static func validate(_ proposal: WorldEventProposal, npcNames: [String]) -> Bool {
        let wordCount = proposal.text.split(separator: " ").count
        guard wordCount >= 4, wordCount <= 40 else { return false }
        if proposal.kind == .npcAction {
            guard let actor = proposal.actor, npcNames.contains(actor) else { return false }
        }
        return true
    }

    /// Lenient JSON extraction: find the first well-formed object in the
    /// model's output and decode it. Anything else is a failed proposal —
    /// fail-safe, never fail-weird.
    public static func parse(_ raw: String) -> WorldEventProposal? {
        guard let start = raw.firstIndex(of: "{"),
              let end = raw.lastIndex(of: "}"),
              start < end else { return nil }
        let jsonSlice = String(raw[start...end])
        guard let data = jsonSlice.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WorldEventProposal.self, from: data)
    }
}
