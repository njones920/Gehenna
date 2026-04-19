// MARK: - Ritual Autopsy
// The astragali diagnose before. The autopsy interprets after.
//
// Not numbers. Not a UI overlay. A sentence or two in the practitioner's own
// internal voice, naming the factors that dominated the resolution.
//
// The autopsy preserves mystery — the player still cannot see scores or
// exact thresholds — while preserving learnability. Outcomes remain uncertain;
// their causes do not.
//
// v3 §3.7: The autopsy is a Codex authoring surface. Over hundreds of rituals,
// the practitioner's autopsies accumulate into a personal phenomenology.
// The autopsy of an Apprentice reads differently from the autopsy of a Master
// performing the same ritual. The system grows with the practitioner.

/// Generates diegetic post-ritual interpretation text.
///
/// The autopsy is engineered to teach. Over hundreds of rituals, the practitioner
/// develops intuition about which factors dominate — because the autopsy tells them
/// in the grammar's own language.
public struct RitualAutopsy: Sendable {

    public init() {}

    /// Generate the autopsy text for a completed ritual result.
    /// The voice adapts to the practitioner's mastery phase — an Apprentice sees
    /// uncertainty and wonder; a Master sees precision and pattern.
    public func interpret(
        _ result: RitualResult,
        configuration: RitualConfiguration,
        masteryPhase: MasteryPhase = .apprentice
    ) -> String {
        var lines: [String] = []

        // Mastery-phase-specific opening — how the practitioner frames the experience
        switch masteryPhase {
        case .apprentice:
            lines.append(openingApprentice(result))
        case .practitioner:
            lines.append(openingPractitioner(result))
        case .adept:
            lines.append(openingAdept(result, configuration: configuration))
        case .master:
            lines.append(openingMaster(result, configuration: configuration))
        }

        // Core autopsy factors from the pipeline (always included)
        lines.append(contentsOf: result.autopsy)

        // Epoch-specific insight (if the spirit came from a root identity)
        if let spirit = result.spirit, let epochName = spirit.epochName {
            switch masteryPhase {
            case .apprentice:
                lines.append("There was something specific about this one. A name almost forming.")
            case .practitioner:
                lines.append("The \(epochName). You've heard this shape before, or one like it.")
            case .adept:
                lines.append("The \(epochName) — one aspect of a larger identity. There may be others.")
            case .master:
                lines.append("The \(epochName). You know now that they have other faces. The question is which fragments unlock them.")
            }
        }

        // Outcome-class-specific closing — voice adapts to mastery
        lines.append(closingForOutcome(result.outcomeClass, masteryPhase: masteryPhase))

        // Tier perception — how the practitioner reads the weight of the spirit
        if let spirit = result.spirit {
            lines.append(tierPerception(spirit.tier, masteryPhase: masteryPhase))
        }

        return lines.joined(separator: " ")
    }

    // MARK: - Phase-Specific Openings

    /// Apprentice: wonder, uncertainty, the body's response.
    private func openingApprentice(_ result: RitualResult) -> String {
        switch result.outcomeClass {
        case .targeted, .guided:
            return "Something answered. You felt it before you understood it."
        case .wildDraw:
            return "Something came through. You're not sure it was what you meant."
        case .hostile:
            return "Your hands were shaking before it arrived. You didn't know why."
        case .mutation:
            return "The air changed. Not the way it usually changes. Something wrong."
        case .failure:
            return "Silence. The kind that has weight."
        }
    }

    /// Practitioner: pattern recognition, emerging grammar.
    private func openingPractitioner(_ result: RitualResult) -> String {
        switch result.outcomeClass {
        case .targeted:
            return "The configuration held. You're beginning to understand why."
        case .guided:
            return "Close to what you were composing for. The edges were soft."
        case .wildDraw:
            return "The pull was unguided. The fragments weren't specific enough — you can feel the difference now."
        case .hostile:
            return "Conflict in the configuration produced conflict in the manifestation. That's a pattern."
        case .mutation:
            return "The contradictions in the configuration compiled into something that shouldn't exist. You felt the grammar break."
        case .failure:
            return "The ritual didn't compile. Something in the configuration was wrong."
        }
    }

    /// Adept: systemic understanding, deliberate analysis.
    private func openingAdept(_ result: RitualResult, configuration: RitualConfiguration) -> String {
        let domainName = configuration.remains.domain.rawValue
        let affinityName = configuration.remains.affinity.rawValue

        switch result.outcomeClass {
        case .targeted:
            return "Targeted resolution. The \(domainName)-domain configuration with \(affinityName) affinity produced exactly what it should."
        case .guided:
            return "Guided draw. The coherence was high but not complete — one input was slightly misaligned."
        case .wildDraw:
            return "Wild draw from the tier pool. The tag constellation was too thin to constrain the pull."
        case .hostile:
            return "Hostile manifestation. The conflict axis dominated — the affinities were opposed and the site amplified it."
        case .mutation:
            return "Mutation. Conflict exceeded coherence under sufficient regional pressure. The grammar generated something new."
        case .failure:
            return "Authority gate rejection. The credentials did not meet the configuration's requirements."
        }
    }

    /// Master: precise, economical, reads the grammar like code.
    private func openingMaster(_ result: RitualResult, configuration: RitualConfiguration) -> String {
        let completeness = configuration.completeness
        let hasName = configuration.trueName != nil
        let eraName = configuration.dominantEra.rawValue

        switch result.outcomeClass {
        case .targeted:
            return "Clean compile. \(completeness)/5 inputs, \(eraName) era dominant\(hasName ? ", name-locked" : ""). The grammar behaved."
        case .guided:
            return "Guided. The configuration was almost complete — \(completeness)/5 inputs. One more constraint would have locked it."
        case .wildDraw:
            return "Unbound pull. \(completeness)/5 constraints insufficient for targeting. The grammar defaulted to tier selection."
        case .hostile:
            return "Hostile compile. The opposing affinities generated enough conflict to flip the disposition axis."
        case .mutation:
            return "Mutation protocol activated. The conflict/coherence ratio exceeded the threshold at current regional entropy."
        case .failure:
            return "Gate failure at authority stage. Insufficient credentials for the requested tier."
        }
    }

    // MARK: - Outcome Closings

    private func closingForOutcome(_ outcome: OutcomeClass, masteryPhase: MasteryPhase) -> String {
        switch (outcome, masteryPhase) {
        // Apprentice closings — emotional, uncertain
        case (.targeted, .apprentice):
            return "What came was what you called for. You think."
        case (.guided, .apprentice):
            return "It was close. Close enough to feel right. But the edges were soft in a way you can't name."
        case (.wildDraw, .apprentice):
            return "A stranger answered. You don't know why."
        case (.hostile, .apprentice):
            return "It came angry. You don't know what you did wrong."
        case (.mutation, .apprentice):
            return "What came was broken. Or you were. You're not sure which."
        case (.failure, .apprentice):
            return "Nothing. The silence was worse than failure."

        // Practitioner closings — observational
        case (.targeted, .practitioner):
            return "The configuration held. What came was what you called for."
        case (.guided, .practitioner):
            return "Close. The shape was right but one element wasn't."
        case (.wildDraw, .practitioner):
            return "A stranger answered. The fragments were not specific enough."
        case (.hostile, .practitioner):
            return "It came unwilling. The configuration was conflicted."
        case (.mutation, .practitioner):
            return "What came was not whole. Something new compiled from the contradictions."
        case (.failure, .practitioner):
            return "Nothing answered. The attempt cost you something anyway."

        // Adept closings — analytical
        case (.targeted, .adept):
            return "The resolution pipeline produced the expected outcome. The grammar is becoming legible."
        case (.guided, .adept):
            return "One input away from a targeted pull. Review the configuration's weakest constraint."
        case (.wildDraw, .adept):
            return "Wild draw. Insufficient coherence to constrain the tier pool. Consider adding identity-bearing inputs."
        case (.hostile, .adept):
            return "Hostile resolution. The conflict axis is a tool — used deliberately, it accesses outcomes that safe configurations cannot."
        case (.mutation, .adept):
            return "Mutation produced. The Veil tore. The site is permanently altered. This is not a mistake — it is a consequence."
        case (.failure, .adept):
            return "Authority gate failed. Check purity state and contagion levels before attempting again."

        // Master closings — spare, precise
        case (.targeted, .master):
            return "Clean."
        case (.guided, .master):
            return "Close. One constraint short."
        case (.wildDraw, .master):
            return "Unbound. Acceptable if exploratory, wasteful if not."
        case (.hostile, .master):
            return "Hostile. Managed?"
        case (.mutation, .master):
            return "Mutation logged. Check the Veil."
        case (.failure, .master):
            return "Gate failure. Purify and reassess."
        }
    }

    // MARK: - Tier Perception

    private func tierPerception(_ tier: SpiritTier, masteryPhase: MasteryPhase) -> String {
        switch (tier, masteryPhase) {
        // Apprentice — sensory, impressionistic
        case (.common, .apprentice):
            return "The presence was faint. Like a voice from across a field."
        case (.uncommon, .apprentice):
            return "There was weight to it. Someone who mattered to someone."
        case (.rare, .apprentice):
            return "The presence was heavy. Old. It remembered more than you do."
        case (.legendary, .apprentice):
            return "The cave changed when it arrived. The stone knew this one."
        case (.mythic, .apprentice):
            return "You felt it before it spoke. The air itself bent."

        // Practitioner — comparative, building a scale
        case (.common, .practitioner):
            return "A common shade. Recently settled, recently forgotten."
        case (.uncommon, .practitioner):
            return "More substantial than most. Someone with a history worth hearing."
        case (.rare, .practitioner):
            return "Old and heavy. You've felt enough shades now to know the difference."
        case (.legendary, .practitioner):
            return "This one pressed against the Veil with force. Legendary tier — you can feel the weight."
        case (.mythic, .practitioner):
            return "The air bent. Mythic. You are out of your depth and you know it."

        // Adept — precise, calibrated
        case (.common, .adept):
            return "Common tier. Baseline attributes, minimal stability. Functional for scouting."
        case (.uncommon, .adept):
            return "Uncommon tier. Elevated attributes, reasonable stability. A working-grade spirit."
        case (.rare, .adept):
            return "Rare tier. Deep era, strong attributes, significant knowledge potential."
        case (.legendary, .adept):
            return "Legendary tier. This one warps the local Veil. Handle with care."
        case (.mythic, .adept):
            return "Mythic tier resolution. Sovereign-class. The grammar is producing something that exceeds normal parameters."

        // Master — minimal notation
        case (.common, .master):
            return "Common. Functional."
        case (.uncommon, .master):
            return "Uncommon. Solid."
        case (.rare, .master):
            return "Rare. Worth keeping."
        case (.legendary, .master):
            return "Legendary. The Veil felt it."
        case (.mythic, .master):
            return "Mythic. Mind the room."
        }
    }
}
