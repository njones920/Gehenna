// MARK: - Expression Cache
// Packet-keyed cache for generated expression text.
// Avoids re-generating the same text for identical world states.
// Cache is invalidated when world state changes affect the packet inputs.
//
// Keys are stable composite strings derived from semantic packet fields.
// Using hashValue directly risks cross-NPC collisions (two different entity
// names with the same hash) which would silently serve one NPC's line to
// another. String keys are deterministic and unique within any real session.

import Foundation

/// Thread-safe expression cache keyed by stable composite string.
public actor ExpressionCache {
    private var lightCache: [String: CacheEntry] = [:]
    private var fullCache: [String: CacheEntry] = [:]
    private let maxEntries: Int
    private let maxAge: TimeInterval

    private struct CacheEntry: Sendable {
        let text: String
        let timestamp: Date
    }

    /// Create a cache with configurable limits.
    /// - Parameters:
    ///   - maxEntries: Maximum cached entries per tier (default: 200)
    ///   - maxAge: Maximum age in seconds before eviction (default: 300 = 5 minutes)
    public init(maxEntries: Int = 200, maxAge: TimeInterval = 300) {
        self.maxEntries = maxEntries
        self.maxAge = maxAge
    }

    // MARK: - Key construction

    /// Stable composite key for a light packet.
    /// All fields that meaningfully distinguish one response context from
    /// another are included. entityTags is omitted to keep hit rates
    /// reasonable for routine interactions.
    private func key(for packet: LightExpressionPacket) -> String {
        let parts: [String] = [
            packet.entityType.rawValue,
            packet.entityName ?? "",
            packet.eventType.rawValue,
            packet.disposition ?? "",
            packet.culture ?? "",
            packet.trustLevel.map { String(format: "%.1f", $0) } ?? "",
            packet.practitionerInput ?? ""
        ]
        return parts.joined(separator: "|")
    }

    /// Stable composite key for a full packet.
    /// Includes all interiority and constraint fields that materially shape
    /// the generated response.
    private func key(for packet: FullExpressionPacket) -> String {
        // Join with a separator that cannot appear in normal event strings.
        // Do NOT use hashValue — two distinct sequences can produce the same hash.
        let recentKey = packet.recentEvents.isEmpty
            ? ""
            : packet.recentEvents.joined(separator: "\u{001F}")  // ASCII Unit Separator
        let parts: [String] = [
            packet.entityType.rawValue,
            packet.entityName ?? "",
            packet.eventType.rawValue,
            packet.disposition ?? "",
            packet.culture ?? "",
            packet.era.map { String($0.rawValue) } ?? "",
            packet.registerKey ?? "",
            packet.trustLevel.map { String(format: "%.1f", $0) } ?? "",
            packet.suspicionLevel.map { String(format: "%.1f", $0) } ?? "",
            packet.isAtThreshold ? "threshold" : "",
            String(packet.interactionHistory),
            packet.wound ?? "",
            packet.unsatisfiedWant ?? "",
            recentKey,
            packet.practitionerInput ?? ""
        ]
        return parts.joined(separator: "|")
    }

    // MARK: - Cache access

    /// Look up a cached result for a light packet.
    public func get(for packet: LightExpressionPacket) -> String? {
        let k = key(for: packet)
        guard let entry = lightCache[k],
              Date().timeIntervalSince(entry.timestamp) < maxAge else {
            return nil
        }
        return entry.text
    }

    /// Store a result for a light packet.
    public func set(_ text: String, for packet: LightExpressionPacket) {
        evictIfNeeded(from: &lightCache)
        lightCache[key(for: packet)] = CacheEntry(text: text, timestamp: Date())
    }

    /// Look up a cached result for a full packet.
    public func get(for packet: FullExpressionPacket) -> String? {
        let k = key(for: packet)
        guard let entry = fullCache[k],
              Date().timeIntervalSince(entry.timestamp) < maxAge else {
            return nil
        }
        return entry.text
    }

    /// Store a result for a full packet.
    public func set(_ text: String, for packet: FullExpressionPacket) {
        evictIfNeeded(from: &fullCache)
        fullCache[key(for: packet)] = CacheEntry(text: text, timestamp: Date())
    }

    /// Clear the entire cache (e.g., after a significant world state change).
    public func clear() {
        lightCache.removeAll()
        fullCache.removeAll()
    }

    /// Evict oldest entries if over capacity.
    private func evictIfNeeded(from cache: inout [String: CacheEntry]) {
        guard cache.count >= maxEntries else { return }
        // Secondary sort by key ensures deterministic order when timestamps tie.
        let sorted = cache.sorted {
            ($0.value.timestamp, $0.key) < ($1.value.timestamp, $1.key)
        }
        let toRemove = sorted.prefix(cache.count / 4) // remove oldest 25%
        for (key, _) in toRemove {
            cache.removeValue(forKey: key)
        }
    }
}
