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

    /// Checks if the underlying LLM provider is currently available.
    public var isLLMAvailable: Bool {
        get async {
            return await primary.isAvailable
        }
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
        practitioner: PractitionerProfile,
        rootIdentity: RootIdentity? = nil
    ) async -> String {
        let packet = assembler.spiritPacket(
            for: spirit,
            event: .spiritSpeech,
            practitioner: practitioner,
            rootIdentity: rootIdentity
        )
        return await renderFull(packet)
    }

    /// Render world narration. Uses light packet.
    public func worldNarration(siteName: String? = nil) async -> String {
        let packet = assembler.worldPacket(event: .worldNarration, siteName: siteName)
        return await renderLight(packet)
    }

    /// Render an NPC's response to free-form practitioner speech.
    /// Always uses a full packet — the practitioner speaking directly is an
    /// important moment that deserves the full interiority context.
    public func npcChat(
        _ npc: NPC,
        input: String,
        recentEvents: [String] = [],
        interactionCount: Int = 0
    ) async -> String {
        let packet = assembler.fullPacket(
            for: npc,
            event: .playerChat,
            practitionerInput: input,
            recentEvents: recentEvents,
            interactionCount: interactionCount
        )
        return await renderFull(packet)
    }

    /// Render a bound spirit's response to free-form practitioner speech.
    /// Always a full packet: identity, epoch interiority, knowledge-gated
    /// facts, and the exchange history of this manifestation.
    public func spiritChat(
        _ bound: BoundSpirit,
        input: String,
        rootIdentity: RootIdentity? = nil,
        relationship: SpiritRelationship? = nil,
        recentEvents: [String] = []
    ) async -> String {
        let packet = assembler.spiritChatPacket(
            for: bound,
            input: input,
            rootIdentity: rootIdentity,
            relationship: relationship,
            recentEvents: recentEvents
        )
        return await renderFull(packet)
    }

    /// Classify a practitioner utterance into a typed intent. Deterministic
    /// heuristics run first (replayable, model-free); the LLM handles the
    /// semantic remainder; anything unrecognized degrades to `.none`.
    /// The LLM parses speech into the same typed command space everything
    /// else uses — it never decides consequences.
    public func classifyIntent(
        _ input: String,
        forbiddenTopics: [String] = []
    ) async -> ConversationalIntent {
        if let heuristic = ConversationalIntent.heuristic(for: input, forbiddenTopics: forbiddenTopics) {
            return heuristic
        }
        guard llmEnabled else { return .none }
        guard let raw = await primary.classifyIntent(input, forbiddenTopics: forbiddenTopics) else {
            return .none
        }
        return ConversationalIntent(rawValue: raw) ?? .none
    }

    /// Harvest spoken canon from a spirit's generated speech. Empty when
    /// the LLM is off — authored lines assert no new facts.
    public func harvestClaims(from speech: String, speakerName: String) async -> [String] {
        guard llmEnabled else { return [] }
        return await primary.harvestClaims(from: speech, speakerName: speakerName)
    }

    /// Ask the generative lane to propose one world event. Nil when the
    /// LLM is off or the proposal fails validation — the world simply
    /// stays quiet, which is always a valid state for it.
    public func proposeWorldEvent(context: String, npcNames: [String]) async -> WorldEventProposal? {
        guard llmEnabled else { return nil }
        guard let proposal = await primary.proposeWorldEvent(context: context, npcNames: npcNames),
              ProposalValidator.validate(proposal, npcNames: npcNames) else {
            return nil
        }
        return proposal
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
            case .validationFailed(let text, let reason):
                #if DEBUG
                print("[ExpressionEngine] Validation failed (light/\(packet.eventType.rawValue)/\(packet.entityName ?? "?")):")
                print("  Reason: \(reason)")
                print("  Text:   \(text)")
                #endif
            case .unavailable(let reason):
                #if DEBUG
                print("[ExpressionEngine] LLM unavailable (light/\(packet.eventType.rawValue)): \(reason)")
                #endif
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

    /// Trim generated text to a word budget at a sentence boundary.
    /// Local models ignore length instructions often enough that the
    /// engine enforces the packet's contract deterministically.
    private func trimToLength(_ text: String, wordLimit: Int) -> String {
        let words = text.split(separator: " ")
        guard words.count > wordLimit else { return text }
        let head = words.prefix(wordLimit).joined(separator: " ")
        if let lastEnd = head.lastIndex(where: { ".!?".contains($0) }) {
            return String(head[...lastEnd])
        }
        return head + "…"
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
                let bounded = trimToLength(text, wordLimit: packet.allowedLengthMax)
                await cache.set(bounded, for: packet)
                return bounded
            case .validationFailed(let text, let reason):
                #if DEBUG
                print("[ExpressionEngine] Validation failed (full/\(packet.eventType.rawValue)/\(packet.entityName ?? "?")):")
                print("  Reason: \(reason)")
                print("  Text:   \(text)")
                #endif
            case .unavailable(let reason):
                #if DEBUG
                print("[ExpressionEngine] LLM unavailable (full/\(packet.eventType.rawValue)): \(reason)")
                #endif
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
