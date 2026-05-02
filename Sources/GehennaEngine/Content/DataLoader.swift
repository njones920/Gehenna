// MARK: - Canon DataLoader
// Loads structured canon data from bundled JSON files.
// The engine treats these files as authoritative. Runtime state lives in the
// event journal. The canon bundle defines what can exist.

import Foundation

/// Errors that can occur when loading canon data from the bundle.
public enum CanonLoadError: Error, CustomStringConvertible {
    case bundleResourceNotFound(String)
    case decodingFailed(String, Error)

    public var description: String {
        switch self {
        case .bundleResourceNotFound(let name):
            return "Canon resource not found in bundle: \(name)"
        case .decodingFailed(let name, let error):
            return "Failed to decode canon resource '\(name)': \(error)"
        }
    }
}

/// Loads canon data (NPCs, RootIdentities, etc.) from JSON files bundled
/// with the GehennaEngine module.
public enum CanonDataLoader {

    // MARK: - Bundle Resolution

    private static var bundle: Bundle {
        // In a SwiftPM context, resources are in the module bundle.
        return Bundle.module
    }

    // MARK: - Generic Loader

    private static func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        guard let url = bundle.url(forResource: filename, withExtension: nil,
                                   subdirectory: "Data") else {
            throw CanonLoadError.bundleResourceNotFound(filename)
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch let error as CanonLoadError {
            throw error
        } catch {
            throw CanonLoadError.decodingFailed(filename, error)
        }
    }

    // MARK: - Public Loaders

    /// Load all NPCs from the bundled `npcs.json` canon file.
    public static func loadNPCs() throws -> [NPC] {
        try load([NPC].self, from: "npcs.json")
    }

    /// Load all root identities from the bundled `identities.json` canon file.
    public static func loadRootIdentities() throws -> [RootIdentity] {
        try load([RootIdentity].self, from: "identities.json")
    }
}
