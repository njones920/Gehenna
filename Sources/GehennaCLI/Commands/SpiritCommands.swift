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
