// MARK: - Spirit Commands
// The retinue view and the partings. No visible numbers: a spirit's
// remaining stability is read in the language of lamps and smoke.

import Foundation
import GehennaEngine

extension GameSession {

    func spiritDisplayName(_ spirit: Spirit) -> String {
        spirit.epochName ?? "the \(spirit.template.rawValue)"
    }

    /// Diegetic reading of a bound spirit's remaining stability.
    func stabilityReading(_ spirit: Spirit) -> String {
        switch spirit.currentStability {
        case 0.7...: return "burns steady"
        case 0.4..<0.7: return "holds, but wavers"
        case 0.15..<0.4: return "gutters like a lamp at a door"
        default: return "is nearly spent"
        }
    }

    /// How long a spirit has walked with the practitioner, in world days.
    func heldDuration(_ bound: BoundSpirit) -> String {
        let ticks = clock.currentTick - bound.anchoredAtTick
        let days = ticks / WorldClock.ticksPerDay
        switch days {
        case 0: return "since this day"
        case 1: return "for a day and its night"
        default: return "for \(days) days"
        }
    }

    // MARK: - Retinue View

    func showRetinue() {
        guard !retinue.isEmpty else {
            print("\n  No one walks with you. The night is only the night.")
            return
        }

        print("\n  ── Those Who Walk With You ──\n")
        for (index, bound) in retinue.bound.enumerated() {
            let spirit = bound.spirit
            print("  \(index + 1). \(spiritDisplayName(spirit).capitalized)")
            print("     \(dispositionDescription(spirit.disposition)) Its presence \(stabilityReading(spirit)).")
            print("     Bound \(heldDuration(bound)).")
            if debugMode {
                print("     [debug] stability \(String(format: "%.2f", spirit.currentStability)), traits \(spirit.personalityTraits.map(\.rawValue).joined(separator: ", "))")
            }
        }

        if retinue.count > 1 {
            print("\n  The air between them is not empty. Holding more than one is a strain they all feel.")
        }
    }

    func dispositionDescription(_ disposition: Disposition) -> String {
        switch disposition {
        case .calm: return "It waits, patient as stone."
        case .hostile: return "It watches you the way a blade watches a throat."
        case .curious: return "It leans toward the living world, asking without words."
        case .sorrowful: return "It carries its grief where you can see it."
        case .hungry: return "It wants something. It has not said what."
        case .honored: return "It stands as one properly called, and it knows it."
        }
    }

    // MARK: - Conversation

    /// Choose a bound spirit to speak with.
    func speakMenu() async {
        guard !retinue.isEmpty else {
            print("\n  There is no one to speak with. The dead do not come to you.")
            return
        }

        let target: BoundSpirit
        if retinue.count == 1 {
            target = retinue.bound[0]
        } else {
            showRetinue()
            print("\n  With whom do you speak? (1-\(retinue.count), or 'back'): ", terminator: "")
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
                  input != "back",
                  let choice = Int(input), choice >= 1, choice <= retinue.count else {
                return
            }
            target = retinue.bound[choice - 1]
        }
        await converse(with: target.spirit.id)
    }

    /// The conversation loop. Every exchange strains the spirit and lets
    /// world time pass — talking to the dead is holding a door open.
    func converse(with spiritID: UUID) async {
        guard let opening = retinue.boundSpirit(withID: spiritID) else { return }
        let name = spiritDisplayName(opening.spirit)

        print("\n  You turn your attention to \(name). The air changes register —")
        print("  the small sounds of the night withdraw, the way a room goes quiet")
        print("  when someone is about to speak.")
        print("  (Speak plainly. Say 'enough' to end. Every word holds the door open.)")

        while true {
            print("\n  [you → \(name)] > ", terminator: "")
            guard let raw = readLine() else { return }
            let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if input.isEmpty { continue }
            if ["enough", "leave", "farewell", "back", "quit"].contains(input.lowercased()) {
                print("\n  You let the attention drop. \(name.capitalized) settles back")
                print("  into its own silence, still present, no longer listening.")
                return
            }

            guard let bound = retinue.boundSpirit(withID: spiritID) else { return }
            let relationshipKey = RelationshipLedger.key(for: bound.spirit)

            // Giving your true name to the dead: trust, and a liability.
            // It cannot be ungiven.
            if input.lowercased().hasPrefix("my name is ") {
                let givenName = String(input.dropFirst("my name is ".count))
                    .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
                if !givenName.isEmpty,
                   relationships.relationship(forKey: relationshipKey)?.nameGiven == nil {
                    relationships.record(
                        .gaveTrueName,
                        for: bound.spirit,
                        atTick: clock.currentTick,
                        detail: givenName
                    )
                    print("\n  You have given the dead your name. That cannot be ungiven.")
                }
            }

            let rootIdentity = bound.spirit.rootIdentityID.flatMap { rid in
                rootIdentities.first { $0.id == rid }
            }
            let siteEvents: [String] = bound.originSiteID.map { siteID in
                world.journal.filter { $0.siteID == siteID }.suffix(3).map(\.description)
            } ?? []

            let response = await expressionEngine.spiritChat(
                bound,
                input: input,
                rootIdentity: rootIdentity,
                relationship: relationships.relationship(forKey: relationshipKey),
                recentEvents: siteEvents
            )
            print("\n  \"\(response)\"")
            relationships.noteExchange(withKey: relationshipKey)

            // What you said, typed and recorded. The dead keep accounts.
            let forbidden = bound.spirit.tags.tags
                .filter { $0.dimension == .taboo }
                .map(\.value)
            let intent = await expressionEngine.classifyIntent(input, forbiddenTopics: forbidden)
            if let momentKind = intent.spiritMoment {
                relationships.record(
                    momentKind,
                    for: bound.spirit,
                    atTick: clock.currentTick,
                    detail: momentKind == .promiseMade ? input : nil
                )
                switch momentKind {
                case .promiseMade:
                    print("  (The words hang in the air a moment longer than they should.)")
                    world.journal.append(JournalEntry(
                        tick: clock.currentTick,
                        type: .practitionerAction,
                        description: "A promise was made to \(spiritDisplayName(bound.spirit)): \"\(input)\"",
                        source: .practitioner,
                        severity: .notable,
                        siteID: sites[currentSiteIndex].id,
                        tags: ["promise", "retinue"]
                    ))
                case .insulted:
                    print("  (Something in the air goes taut.)")
                case .askedForbidden:
                    print("  (The silence after has edges.)")
                default:
                    break
                }
            }

            // The exchange itself strains the spirit.
            if let departure = retinue.recordExchange(with: spiritID, atTick: clock.currentTick) {
                print("\n  The voice thins mid-word. You held the door open too long,")
                print("  and what was holding it from the other side let go.")
                recordDeparture(departure)
                return
            }

            // Authored threads listen to what the dead are asked.
            if let refreshed = retinue.boundSpirit(withID: spiritID) {
                maacahThreadDuringConversation(with: refreshed)
            }

            // And the world does not wait while you speak.
            let events = advanceTime(.command)
            processWorldEvents(events)

            guard let after = retinue.boundSpirit(withID: spiritID) else {
                // Faded during the tick — already narrated by recordDeparture.
                return
            }
            if after.spirit.currentStability < 0.15 {
                print("  (Its presence \(stabilityReading(after.spirit)).)")
            }
        }
    }

    // MARK: - Dismissal

    func dismissMenu() {
        guard !retinue.isEmpty else {
            print("\n  There is no one to release.")
            return
        }

        showRetinue()
        print("\n  Whom do you release? (1-\(retinue.count), or 'back'): ", terminator: "")
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
              input != "back",
              let choice = Int(input), choice >= 1, choice <= retinue.count else {
            print("  You keep your grip.")
            return
        }

        let bound = retinue.bound[choice - 1]
        let name = spiritDisplayName(bound.spirit)

        print("\n  How do you part with \(name)?")
        print("  1. Pour a libation and speak the release. (A respectful parting — costs a libation.)")
        print("  2. Banish it. (Abrupt. Free. It will not forget.)")
        print("  c. Keep it bound.")
        print("\n  > ", terminator: "")

        guard let mannerInput = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

        switch mannerInput {
        case "1":
            guard !inventory.libations.isEmpty else {
                print("\n  You have nothing to pour. The release needs an offering, and your hands are empty.")
                return
            }
            let libation = inventory.libations.removeFirst()
            if let departure = retinue.dismiss(id: bound.spirit.id, manner: .releasedWithLibation, atTick: clock.currentTick) {
                print("\n  You pour the \(libationName(libation)) onto the earth and speak the words of parting.")
                print("  \(name.capitalized) inclines toward the offering — a gesture almost like a bow —")
                print("  and is gone, the way water is gone into dry ground.")
                recordDeparture(departure)
            }
        case "2":
            if let departure = retinue.dismiss(id: bound.spirit.id, manner: .banished, atTick: clock.currentTick) {
                print("\n  You cut the anchor with a word. \(name.capitalized) is torn away mid-breath.")
                print("  The last thing to fade is its attention, and its attention is on you.")
                recordDeparture(departure)
            }
        default:
            print("  You keep your grip.")
        }
    }

    func capacityDescription(_ capacity: Int) -> String {
        switch capacity {
        case ...1: return "one"
        case 2: return "two at once"
        default: return "three at once — the ceiling most practitioners ever reach"
        }
    }

    func libationName(_ libation: LibationType) -> String {
        switch libation {
        case .water: return "plain water"
        case .fermentedWine: return "fermented wine"
        case .ritualMixture: return "ritual mixture"
        case .bloodOffering: return "blood offering"
        case .honeyWine: return "honey wine"
        case .mimicBlood: return "mimic blood"
        case .opiumTincture: return "opium tincture"
        }
    }

    // MARK: - Departure Records

    /// Narrate (for fades) and journal every departure. Dismissals narrate
    /// at the point of choice; fades narrate here, because they happen
    /// while the world is moving and the practitioner may not be watching.
    func recordDeparture(_ departure: SpiritDeparture) {
        let name = spiritDisplayName(departure.spirit)

        // The manner of parting is relational truth. The ledger reads it,
        // and the next summoning will remember.
        relationships.recordDeparture(departure)

        if departure.manner == .faded {
            print("\n  ✦ \(name.capitalized) thins. You feel the anchor let go — not broken, spent.")
            print("    Where it stood there is only the temperature of the night.")
        }

        let mannerDescription: String
        switch departure.manner {
        case .releasedWithLibation: mannerDescription = "released with libation"
        case .banished: mannerDescription = "banished"
        case .faded: mannerDescription = "faded — stability spent"
        }

        world.journal.append(JournalEntry(
            tick: departure.tick,
            type: .spiritDeparted,
            description: "\(name.capitalized) departed the retinue (\(mannerDescription)).",
            source: departure.manner == .faded ? .spirit : .practitioner,
            severity: .notable,
            regionID: world.regions.keys.first,
            siteID: sites[currentSiteIndex].id,
            tags: ["retinue", "departure", departure.manner.rawValue]
        ))
    }
}
