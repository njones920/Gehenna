import Foundation
import GehennaEngine

extension GameSession {
    func showInventory() {
        print("\n  ── Your Satchel ──")
        print("  Fragments: \(inventory.fragments.count)")
        print("  Artifacts: \(inventory.artifacts.count)")
        print("  Memory Traces: \(inventory.memoryTraces.count)")
        print("  Libations: \(inventory.libations.map(\.rawValue).joined(separator: ", "))")
        print("\n  Type 'fragments', 'artifacts' for details.")
    }

    func listFragments() {
        print("\n  ── Bone Fragments ──")
        if inventory.fragments.isEmpty {
            print("    Your satchel is empty of bone.")
            return
        }
        for (i, frag) in inventory.fragments.enumerated() {
            let condition = describeIntegrity(frag.integrity)
            let era = describeEra(frag.era)
            print("    \(i + 1). \(describeRemainsType(frag.remainsType)) — \(era), \(condition)")
            if let name = frag.inscribedName {
                print("       Inscribed: \"\(name)\"")
            }
            let identityTags = frag.tags.tags(in: .identity)
            if !identityTags.isEmpty {
                print("       Traces: \(identityTags.map(\.value).joined(separator: ", "))")
            }
        }
    }

    func listArtifacts() {
        print("\n  ── Life Artifacts ──")
        for (i, art) in inventory.artifacts.enumerated() {
            print("    \(i + 1). \(art.name) — \(art.domain.rawValue) domain")
        }
        if inventory.artifacts.isEmpty {
            print("    None carried.")
        }
        print("\n  ── Memory Traces ──")
        for (i, trace) in inventory.memoryTraces.enumerated() {
            print("    \(i + 1). \(trace.name)")
        }
        if inventory.memoryTraces.isEmpty {
            print("    None found.")
        }
    }

    func inspectFragment() {
        if inventory.fragments.isEmpty {
            print("  Your satchel contains no fragments.")
            return
        }

        listFragments()

        print("\n  Which fragment do you wish to inspect? (Enter a number)")
        guard let input = readLine(), let index = Int(input), index > 0, index <= inventory.fragments.count else {
            print("  You leave the bone where it lies.")
            return
        }

        let frag = inventory.fragments[index - 1]

        print("\n  ── Fragment Details ──")
        print("    Type: \(describeRemainsType(frag.remainsType).capitalized)")
        print("    Condition: \(describeIntegrity(frag.integrity)) (\(Int(frag.integrity.value * 100))%)")
        print("    Era: \(describeEra(frag.era))")
        print("    Domain: \(frag.domain.rawValue.capitalized)")
        print("    Affinity: Aligned with \(frag.affinity.rawValue), Opposed to \(frag.affinity.opposition.rawValue)")
        
        if let name = frag.inscribedName {
            print("    Inscribed Name: \"\(name)\"")
        }
        
        print("    Intrinsic Traces: \(frag.tags.tags.map { $0.value }.joined(separator: ", "))")
        print("    Coherence Weight: \(String(format: "%.2f", frag.coherenceWeight))")
    }
}
