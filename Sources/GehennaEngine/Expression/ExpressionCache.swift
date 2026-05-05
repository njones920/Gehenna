// MARK: - Expression Cache
// Packet-hash keyed cache for generated expression text.
// Avoids re-generating the same text for identical world states.
// Cache is invalidated when world state changes affect the packet inputs.

import Foundation

/// Thread-safe expression cache keyed by packet hash.
public actor ExpressionCache {
    private var lightCache: [Int: CacheEntry] = [:]
    private var fullCache: [Int: CacheEntry] = [:]
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

    /// Look up a cached result for a light packet.
    public func get(for packet: LightExpressionPacket) -> String? {
        let key = packet.hashValue
        guard let entry = lightCache[key],
              Date().timeIntervalSince(entry.timestamp) < maxAge else {
            return nil
        }
        return entry.text
    }

    /// Store a result for a light packet.
    public func set(_ text: String, for packet: LightExpressionPacket) {
        evictIfNeeded(from: &lightCache)
        lightCache[packet.hashValue] = CacheEntry(text: text, timestamp: Date())
    }

    /// Look up a cached result for a full packet.
    public func get(for packet: FullExpressionPacket) -> String? {
        let key = packet.hashValue
        guard let entry = fullCache[key],
              Date().timeIntervalSince(entry.timestamp) < maxAge else {
            return nil
        }
        return entry.text
    }

    /// Store a result for a full packet.
    public func set(_ text: String, for packet: FullExpressionPacket) {
        evictIfNeeded(from: &fullCache)
        fullCache[packet.hashValue] = CacheEntry(text: text, timestamp: Date())
    }

    /// Clear the entire cache (e.g., after a significant world state change).
    public func clear() {
        lightCache.removeAll()
        fullCache.removeAll()
    }

    /// Evict oldest entries if over capacity.
    private func evictIfNeeded(from cache: inout [Int: CacheEntry]) {
        guard cache.count >= maxEntries else { return }
        let sorted = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        let toRemove = sorted.prefix(cache.count / 4) // remove oldest 25%
        for (key, _) in toRemove {
            cache.removeValue(forKey: key)
        }
    }
}
