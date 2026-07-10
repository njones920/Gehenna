// MARK: - Conversational Intent
// Talk has consequences without the LLM deciding truth. A constrained
// classifier pass maps free-form practitioner speech into this closed
// enum; the engine applies deterministic consequences. The LLM parses;
// it does not decide. Classification failure degrades to .none — words
// fail safe, never fail weird.

import Foundation

/// What the practitioner was doing when they spoke.
public enum ConversationalIntent: String, Codable, Sendable, CaseIterable {
    case promise      // committing to something — the dead keep accounts
    case insult       // contempt or mockery
    case threaten     // menace
    case plea         // asking for help or mercy
    case comfort      // consolation, sympathy, respect for grief
    case respect      // courtesy — please, deference, thanks
    case forbidden    // pressing a topic the entity will not speak of
    case reveal       // admitting the practice to the living
    case none         // ordinary speech — no relational charge

    /// Deterministic first pass. Catches unmistakable cases without a
    /// model, so consequence works replayably even with the LLM absent.
    /// Returns nil when the utterance needs a semantic read.
    public static func heuristic(for input: String, forbiddenTopics: [String] = []) -> ConversationalIntent? {
        let lowered = input.lowercased()
        // Word-boundary matching: rejoin the tokenized words so phrase
        // markers match regardless of punctuation.
        let words = lowered.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        let normalized = " " + words.joined(separator: " ") + " "

        for topic in forbiddenTopics {
            let phrase = topic.lowercased().replacingOccurrences(of: "_", with: " ")
            if !phrase.isEmpty, normalized.contains(" \(phrase) ") {
                return .forbidden
            }
        }
        for marker in ["i promise", "i swear", "i vow", "you have my word"] {
            if normalized.contains(" \(marker) ") { return .promise }
        }
        for marker in ["please", "thank you", "forgive me", "i honor you"] {
            if normalized.contains(" \(marker) ") { return .respect }
        }
        for marker in ["i am a necromancer", "i raise the dead", "i speak with the dead", "i practice the forbidden"] {
            if normalized.contains(" \(marker) ") { return .reveal }
        }
        return nil
    }

    /// The relational moment a spirit records for this intent, if any.
    /// Deterministic — this table, with `RelationalMoment.valence`, is
    /// where "talk matters" becomes simulation truth.
    public var spiritMoment: RelationalMoment.Kind? {
        switch self {
        case .respect: return .spokeRespectfully
        case .insult, .threaten: return .insulted
        case .comfort: return .comforted
        case .promise: return .promiseMade
        case .forbidden: return .askedForbidden
        case .plea, .reveal, .none: return nil
        }
    }
}

extension NPC {
    /// Apply a classified conversational intent to this NPC's state.
    /// Returns a short diegetic cue when the shift is visible, nil when
    /// the consequence should stay beneath the surface.
    public mutating func apply(_ intent: ConversationalIntent) -> String? {
        switch intent {
        case .respect:
            positiveInteraction(strength: 0.2)
            return nil
        case .comfort:
            positiveInteraction(strength: 0.3)
            return nil
        case .plea:
            positiveInteraction(strength: 0.1)
            return nil
        case .insult, .threaten:
            trust = max(0.0, trust - 0.12)
            personalSuspicion = min(1.0, personalSuspicion + 0.08)
            return "Their face closes like a door."
        case .reveal:
            witnessActivity(severity: 0.6)
            return "Something shifts behind their eyes. They will not forget what you just said."
        case .promise:
            return "They mark your words. Villages remember promises."
        case .forbidden, .none:
            return nil
        }
    }
}
