// MARK: - Expression Engine
// The orchestrator. Three tiers, tried in order:
//   1. Authored lines (critical beats, always available)
//   2. Ollama generation (constrained, validated)
//   3. Fallback authored lines (if generation fails)
//
// The Expression Layer renders state but never decides simulation truth.

import Foundation

/// The main expression engine — orchestrates generation, caching, and fallback.
public actor ExpressionEngine {
    private let primary: any ExpressionProvider    // Ollama
    private let fallback: AuthoredLineProvider      // Always available
    private let cache: ExpressionCache
    private let assembler: PacketAssembler

    /// Whether to attempt LLM generation or go straight to authored lines.
    public var llmEnabled: Bool

    /// Create the expression engine.
    /// - Parameters:
    ///   - primary: The LLM provider (OllamaProvider by default)
    ///   - lineBank: The authored line bank for fallback
    ///   - llmEnabled: Whether to attempt LLM generation (default: true)
    public init(
        primary: any ExpressionProvider = OllamaProvider(),
        lineBank: AuthoredLineBank = .loadFromBundle(),
        llmEnabled: Bool = true
    ) {
        self.primary = primary
        self.fallback = AuthoredLineProvider(lineBank: lineBank)
        self.cache = ExpressionCache()
        self.assembler = PacketAssembler()
        self.llmEnabled = llmEnabled
    }

    // MARK: - High-Level API

    /// Render an NPC greeting. Uses light packet (routine event).
    public func npcGreeting(_ npc: NPC) async -> String {
        let packet = assembler.lightPacket(for: npc, event: .greeting)
        return await renderLight(packet)
    }

    /// Render an NPC response for a specific event type. Uses light packet.
    public func npcResponse(_ npc: NPC, event: ExpressionEvent) async -> String {
        let packet = assembler.lightPacket(for: npc, event: event)
        return await renderLight(packet)
    }

    /// Render an NPC threshold response. Uses full packet (important moment).
    public func npcThresholdResponse(
        _ npc: NPC,
        recentEvents: [String] = [],
        interactionCount: Int = 0
    ) async -> String {
        let packet = assembler.fullPacket(
            for: npc,
            event: .thresholdResponse,
            recentEvents: recentEvents,
            interactionCount: interactionCount
        )
        return await renderFull(packet)
    }

    /// Render spirit speech. Uses full packet (always important).
    public func spiritSpeech(
        _ spirit: Spirit,
        practitioner: PractitionerProfile
    ) async -> String {
        let packet = assembler.spiritPacket(
            for: spirit,
            event: .spiritSpeech,
            practitioner: practitioner
        )
        return await renderFull(packet)
    }

    /// Render world narration. Uses light packet.
    public func worldNarration(siteName: String? = nil) async -> String {
        let packet = assembler.worldPacket(event: .worldNarration, siteName: siteName)
        return await renderLight(packet)
    }

    // MARK: - Rendering Pipeline

    /// Render a light packet through the tiered pipeline.
    private func renderLight(_ packet: LightExpressionPacket) async -> String {
        // Check cache first
        if let cached = await cache.get(for: packet) {
            return cached
        }

        // Try primary (LLM) if enabled
        if llmEnabled {
            let result = await primary.generate(from: packet)
            switch result {
            case .generated(let text):
                await cache.set(text, for: packet)
                return text
            case .validationFailed(_, _), .unavailable(_):
                break // fall through to fallback
            }
        }

        // Fallback to authored lines
        let result = await fallback.generate(from: packet)
        if case .generated(let text) = result {
            return text
        }

        // Should never reach here — AuthoredLineProvider always returns .generated
        return "..."
    }

    /// Render a full packet through the tiered pipeline.
    private func renderFull(_ packet: FullExpressionPacket) async -> String {
        // Check cache first
        if let cached = await cache.get(for: packet) {
            return cached
        }

        // Try primary (LLM) if enabled
        if llmEnabled {
            let result = await primary.generate(from: packet)
            switch result {
            case .generated(let text):
                await cache.set(text, for: packet)
                return text
            case .validationFailed(_, _), .unavailable(_):
                break // fall through to fallback
            }
        }

        // Fallback to authored lines
        let result = await fallback.generate(from: packet)
        if case .generated(let text) = result {
            return text
        }

        return "..."
    }

    /// Invalidate the cache (e.g., after a world state change).
    public func invalidateCache() async {
        await cache.clear()
    }
}
