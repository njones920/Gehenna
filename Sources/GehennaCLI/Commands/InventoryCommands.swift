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
}
