# Proposed Feature: Free-Form NPC Chat via 31B LLM

## Context
With the integration of the `gemma4:31b` Dense model as the primary `ExpressionEngine` provider, the LLM is capable of deep reasoning, strict adherence to Iron Age canon, and complex conversational routing without losing character constraints. 

Currently, the `VillageCommands.swift` interaction menu forces the player to choose from pre-canned dialogue options (e.g., `[1] Friendly greeting`, `[2] Ask about the region`). This drastically underutilizes the 31B model's robust dialogue and gameplay capabilities.

## Proposal
Introduce a "free-form chat" input mechanism to allow the practitioner to type custom dialogue, which the LLM will respond to directly while adhering to the world state.

### Implementation Blueprint

1. **Update `ExpressionPacket.swift`**:
   - Add a new `case playerChat` to `ExpressionEvent`.
   - Add a `public let practitionerInput: String?` property to both `LightExpressionPacket` and `FullExpressionPacket`.

2. **Update `PacketAssembler.swift`**:
   - Modify `lightPacket()` and `fullPacket()` to accept and pass through `practitionerInput: String? = nil`.
   - Update `minLength` and `maxLength` switch statements to handle `.playerChat` (e.g., allow 10-60 words).

3. **Update `ExpressionEngine.swift`**:
   - Add a high-level API method: 
     `public func npcChat(_ npc: NPC, input: String) async -> String`
   - This method will assemble a `.playerChat` light packet containing the custom `practitionerInput`.

4. **Update `OllamaProvider.swift`**:
   - In `buildPrompt(from:)`, check if `packet.practitionerInput` exists. 
   - If present, append the strict instruction: 
     `The practitioner says to you: "{packet.practitionerInput}"`
     `Respond directly to what they said, while maintaining your character, mood, and Iron Age constraints.`

5. **Update `VillageCommands.swift`**:
   - In `villageMenu()`, replace or augment the fixed dialogue options with `[4] Speak freely...`.
   - If selected, prompt the player: `What do you say? > `
   - Capture the `readLine()` input and pass it to `await expressionEngine.npcChat(targetNPC, input: playerText)`.
   - Print the generated response dynamically.

## Implication for Future Agents
This fundamentally transforms the interaction loop. By implementing this, future agents can expand the `practitionerInput` concept to Rituals (e.g., typing custom incantations that the LLM grades for `Coherence` and `Resonance`) or negotiating with hostile spirits.

**Agent Action Required:** Implement the above blueprint and write the associated `swift test` cases to ensure the new custom string does not break the `ExpressionValidator`.
