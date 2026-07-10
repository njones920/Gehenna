# Changelog

## Unreleased

## 0.4.29 - The Dead Speak

The Codex Part II scene is now playable: you can sit with a summoned spirit and ask it questions. Free-form conversation with bound spirits, rendered from who they actually are — identity tags, epoch interiority, knowledge-gated facts — and paid for in stability. Phase 2 of Milestone 0.5.

### Added

- **`speak` command:** free-form conversation with a bound spirit. Every exchange strains the spirit's stability (holding the door open) and advances world time; a spirit can fade mid-word if you reach too long.
- **`PacketAssembler.spiritChatPacket`:** conversation packets assembled from simulation truth — spirit tags across identity/death/relational/cultural/disposition dimensions, true name from the root identity, taboo tags as forbidden topics, and facts gated by the spirit's Knowledge attribute (a diminished shade reaches 4 facts; a strong spirit reaches 12).
- **Epoch interiority:** `Epoch` gains optional `interiorVoice` / `privateTruth` / `wound` / `unsatisfiedWant`, same authoring model as NPCs. Authored for all six of Hiram's and Maacah's epoch aspects in `identities.json`. The Bronze Captain deflects questions about his sons into duty — and lets the count falter. Older canon files decode unchanged.
- **`spiritChat` expression event** with authored fallback, so conversation reads even without Ollama.
- **Tests:** 6-test `Spirit Conversation Tests` suite — packet assembly, knowledge gating, forbidden topics, canon interiority decoding, exchange strain and mid-word fade.

### Changed

- **First words got better:** manifestation speech (`spiritSpeech`) now receives the resolved root identity, so epoch interiority shapes the spirit's voice from its first utterance, not just in conversation.
- **`Retinue.recordExchange`:** conversation strain is engine truth, shared by any future client.

## 0.4.28 - The Retinue

Spirits persist. An anchored spirit now stays manifested — walking with the practitioner, decaying tick by tick — until its stability is spent or the practitioner chooses how to part with it. First phase of Milestone 0.5 (`docs/PROPOSALS/MILESTONE_0.5_THE_DEAD_SPEAK.md`).

### Added

- **`Retinue` / `BoundSpirit` engine types:** anchored spirits persist across commands, decay per tick (base + regional Corruption + co-presence strain + prideful rivalry), and return to Sheol as `.faded` departures when stability runs out.
- **Dismissal with manner:** `dismiss` lets the practitioner release a spirit with a libation (respectful, costs the offering), banish it (abrupt, free, remembered), or leave it to fade. Each parting is journaled with its manner — the relationship ledger (0.4.30) will read these.
- **`spirits` command:** diegetic retinue view — disposition, stability read in lamp-and-smoke language, time held. No visible numbers outside debug mode.
- **Shared-world parity:** `PractitionerSession` carries a retinue; `WorldShard` anchors successful ritual spirits and decays every practitioner's retinue as shard time passes.
- **Journal:** new `spiritDeparted` entry type.
- **Tests:** 10-test `Retinue Tests` suite — capacity, decay, corruption acceleration, co-presence strain, prideful rivalry, dismissal manners, snapshot round-trip, pre-0.4.28 save compatibility, shard decay.

### Changed

- **Capacity is a cap, not a consumable:** fixed a bug where anchoring permanently decremented `summonerCapacity` (capacity only ever grows at ritual milestones, so every anchor burned a slot forever). Anchoring now checks retinue count against capacity; dismissal and fading free the slot.
- **All CLI time flows through `GameSession.advanceTime`:** the clock advances and the retinue feels the same ticks; departures are narrated before the prompt returns.
- **Snapshot format:** `SinglePlayerSnapshot` gains an optional `retinue` field; older saves decode cleanly.

## 0.4.27 - Gameplay Discoverability & Engine Wire-Up

Fixed a major progression blocker regarding fragment collection and fully wired the CLI's ritual resolution to the engine's consequence pipelines. Rituals now correctly advance practitioner state, apply world entropy, and seed rumors.

### Changed

- **CLI Wire-Up Complete:** Replaced manual CLI counters with proper engine calls in `RitualCommands`. Rituals now correctly trigger `profile.recordRitual()`, `profile.applyRitualConsequences()`, `world.applyRitualEffects()`, and `world.seedRitualRumor()`. 
- **Taboo Enforcement:** Ritual aftermath now properly detects and records `.graveRobbing`, `.uncleanSacrifice`, and `.tophethPact` taboos in the practitioner's profile.
- **World Awareness for NPCs:** The free-form chat and threshold responses now receive the last 4 notable world journal events as context, allowing NPCs to react to recent ritual activity. Interaction counts are also now correctly tracked based on `lastInteractionTick`.
- **Journal Visibility:** The `world` / `showJournal` command now prints the actual description and severity icon for each event, rather than just raw types. Successful summonings are now logged as `.spiritManifested`.
- **Fragment Discoverability:** Fixed arrival text to accurately reflect an empty starting inventory. Added `scavenge`, `inspect`, and `taboos / sins` to the `help` command. `look` now surfaces diegetic hints when a site has collectible items, prompting the player to scavenge.
- **Codex Recording:** Fixed a bug where successful spirit manifestations were not recorded in the Codex of the Dead. Rituals now properly call `codex.recordEncounter` and `codex.crossLinkEpochs`.


## 0.4.26 - Free-Form NPC Chat & Expression Hardening

Added free-form chat capabilities allowing the practitioner to speak directly to NPCs and receive diegetic, LLM-rendered responses based on the NPC's world state and interiority. Hardened the Expression Layer to be robust for production use.

### Added

- `practitionerInput` field to `ExpressionPacket` and `.playerChat` event type to support free-form conversation.
- `npcChat` high-level API to `ExpressionEngine` to handle practitioner-initiated dialogue using full interiority context.
- `[4] Speak freely...` option in the CLI `village` menu to allow custom text input.
- `.speakFreely(text:)` command to `PlayerCommand.ConversationAction` and routed it through `WorldShard` as a neutral-consequence interaction.
- `PractitionerInputTests` to verify packet assembly, cache separation, and validation correctness.

### Changed

- **Prompt Engineering Overhaul:** Removed unreliable word-count constraints from Ollama prompts, letting `numPredict` handle token budgets naturally. Prompts now use structured turns (`The practitioner says to you: "..."`) for free-form input to prevent instruction injection.
- **Cache Reliability:** Fixed a hash collision bug in `recentEvents` cache keying and made eviction tie-breaking deterministic. `practitionerInput` is now part of the cache key.
- **Provider Stability:** Added a 5s connection timeout to `OllamaProvider.isAvailable`, implemented proper model verification (checking `/api/tags` for `gemma4:31b`), and added task cancellation checks to prevent hanging network calls.
- **Validation:** Replaced substring-based forbidden topic checks with regex word-boundary matching to eliminate false positives. Removed unreliable length validation.
- Expanded trust and suspicion prompt injection from 3 to 5 granular prose buckets for higher nuance in dialogue.

### Verified

- `swift test` passes with 108 tests across 26 suites. All new practitioner input and validation tests pass.

## 0.4.25 - Expression Layer & LLM Integration

Completed the final stream of the V3 Codex roadmap, fully integrating dynamic, historically grounded, LLM-backed narrative generation.

### Added

- `ExpressionEngine` as the central orchestrator for rendering dynamic text. It utilizes a three-tier fallback pipeline (Ollama -> Authored Bank -> Fallback).
- `OllamaProvider` connecting to a local Ollama instance (defaulting to `gemma4:26b`) for zero-cost, local LLM generation.
- `ExpressionValidator` and `ExpressionCache` to enforce strict constraints (e.g., length, forbidden topics) and minimize redundant generation.
- Structured data packets (`LightExpressionPacket` and `FullExpressionPacket`) and the `PacketAssembler` to pass strict world state and interiority constraints to the LLM.
- `PLAYER_MANUAL.md` added to `docs/` detailing the interface, rituals, and mechanics of the CLI prototype.

### Changed

- Transitioned the entire `GehennaCLI` main loop (`GameSession.run`) and sub-menus (`villageMenu`, `ritualMenu`) to an asynchronous (`async`) architecture to support non-blocking LLM calls.
- Wired village greetings, responses, and threshold events through the `ExpressionEngine`, replacing static strings with dynamic interaction.
- Wired ritual outcomes in `RitualCommands` to utilize both the diegetic `RitualAutopsy` and the `ExpressionEngine` (for spirit speech).
- Minor fixes in `OllamaProvider` to correctly handle `num_predict` with certain LLMs (dropped the `options` block to rely on server defaults).

### Verified

- `swift test` passes with 104 tests across 24 suites, including new tests for `ExpressionCache` and `ExpressionValidator`.
- Live test coverage for the Ollama integration (`testOllamaLive`).


## 0.4.24 - Architecture Polish & Rumor Consequence

Minor architectural cleanup, multi-region prep, and rumor consequence follow-through.

### Changed

- Sustained rumor carriers now bleed suspicion back into the sole-region prototype path, allowing regional suspicion and inquisition pressure to reflect social spread instead of only direct ritual entropy.
- Rumor seeding no longer overwrites the canonical ledger strength with per-hearer reach, so propagation and mutation now operate on the real rumor rather than a collapsed `0.12` floor.
- Explicit Site Suspicion Multipliers: `RitualSite.suspicionMultiplier` now strictly switches over all site types, removing the default fallback.
- Multi-Region Hardcode Fix: Added `regionID` to `RitualSite`. `WorldShard` now uses `site.regionID` instead of blindly grabbing the first region in the dictionary, ensuring future multi-region compatibility.
- `RidgeOfElah.createWorld()` now explicitly links initialized sites to the created region.

### Added

- `David vs Goliath` simulation mode to `GehennaArena` (`--david-vs-goliath`). Pits a slow, deliberate human-proxy bot against a high-frequency bot to expose the entropy asymmetry.
- Two new bot strategies: `.humanProxy` (acts once every 15 ticks, respectful) and `.healer` (acts constantly but focuses on site purification and building trust).
- `--goliath-type [reckless|healer]` and `--veteran-goliath` flags to `GehennaArena` for testing specific adversary profiles against the world state.
- `.purifySite` (Namburbi Rite) command to `PlayerCommand` and `WorldShard`. It actively lowers site corruption/scarring but induces heavy `ritualFatigue`.
- `.look` command now slowly recovers `ritualFatigue`, allowing practitioners to rest and recover from purification.

### Verified

- `swift test` passes with 98 tests across 21 suites.

## 0.4.23 - Rumor Engine

Rumor engine salvage and integration work released after `0.4.22`.

### Added

- Typed rumor ledger (`Rumor`, `RumorLedger`, `RumorPropagationEvent`) in the engine.
- CLI `rumors` / `gossip` command for inspecting what the village is currently carrying.
- Backward-compatible snapshot decode for older saves that predate rumor-ledger fields on `WorldSimulation` and `NPC`.

### Changed

- Ritual rumor seeds now propagate across ticks, mutate in retellings, decay over time, and track explicit carriers instead of behaving like one-shot suspicion splashes.
- `WorldClock`, `WorldShard`, the interactive CLI, and `WorldDirector` now read from the same rumor system instead of partially duplicating rumor behavior.
- Traders now act as the natural cross-faction bridge for rumor spread, which lets village chatter escape its initial witness set without flattening faction differences.
- Repository-local Claude workspace artifacts under `.claude/` are now ignored.

### Verified

- `swift test` passes with 96 tests across 21 suites.
- `swift build` passes.

## 0.4.22 - CLI Modularization & UI Polish

Structural refactoring and user-facing polish.

### Added

- `profile` command now explicitly displays "Clean Hands" status and any broken taboos.
- `quit` command now prompts the user to save their game before exiting.

### Changed

- **CLI Modularization:** Split the monolithic `main.swift` (1,200 lines) into focused, maintainable files:
  - `GameSession.swift` (State and main loop)
  - `Commands.swift` (Interactive actions)
  - `Display.swift` (Rendering and read-only views)
  - `main.swift` (Entrypoint)

## 0.4.21 - Zero-Trust Cosmology

Identity/Accountability layer and engine stabilization.

### Added

- Identity/Accountability layer (Zero-Trust Cosmology): spirits and epochs now act as verification nodes in the resolution pipeline.
- `Taboo` enum with 6 canonical violations: bloodshed, graveRobbing, falseName, uncleanSacrifice, oathBreaking, tophethPact.
- `IdentityRequirements` struct: forbiddenTaboos, requiredTokens, minimumPurity, requiresCleanHands.
- `PractitionerProfile.taboosBroken` and `.cleanHands` (Noob Catalyst principle).
- Stage 11.8 (Spirit Verification) in the resolution pipeline.
- `SpiritTemplate.identityRequirements` baseline defaults (wardens reject grave robbers, prophets demand purity, etc.).
- `Epoch.identityRequirements` override for specific canonical manifestations.
- `ZeroTrustCosmologyTests` test suite (3 tests).
- Deterministic root identity IDs via `UUID.deterministic(from:)` using FNV-1a hash (Version 8 UUID).
- WorldClock-derived `currentTimeOfDay` (7 ticks/day) and `currentLunarPhase` (56-tick cycle).
- `Codable` conformance for `JournalEntry`, `ThresholdEvent`, and associated event enums.
- Site- and faction-weighted rumor propagation.
- Typed single-player snapshot persistence plus CLI `save` / `load`.
- Repository git workflow documentation plus README release-flow diagram and badges.

### Changed

- Engine version is now `0.4.21`.
- Resolution pipeline now has 14 effective stages (13 original + Stage 11.8 Spirit Verification).
- Root identity IDs use a widened canonical seed (name + culture + era + coreTags + epochs) instead of random UUIDs.
- `summonerCapacity` typo fixed from `summmonerCapacity`.
- Ritual aftermath now writes the first taboo and contamination state back into the practitioner profile.
- `WorldSimulation` and `WorldClock` are now `Codable`, enabling full single-player snapshot persistence.

### Verified

- 87 tests across 20 suites pass on macOS at release time.
- `swift run gehenna-arena --bots 12 --ticks 100` completes with stable world state.
- Identity verification correctly blocks corrupted practitioners and enables Clean Hands access.
- `swift run gehenna` save/load smoke passes with `gehenna-save.json`.

## 0.4.20 - World Seed

Initial public seed build for the Ridge of Elah terminal prototype.

### Added

- World seed README with quickstart, first ritual path, live/not-live scope, and document reading order.
- `.gitignore` for SwiftPM/Xcode/local macOS output.
- MIT `LICENSE`, trademark/canon notice, and GitHub repository metadata for public release.
- Archived the superseded Codex Two text document under `docs/archive`.
- WorldClock as the single owner of time advancement.
- WorldDirector v1 for unsolicited world narration.
- Site-local state: scarring, local suspicion, witness exposure, active traces, visit/ritual ticks, and event counts.
- Expanded append-only journal metadata and queries.
- NPC temporal drift and approach/flee posture.
- Design handoff files for future agents and collaborators.
- README quickstart for clone/build/play/dev.
- `gehenna-arena` bot arena executable: headless shared-world simulation with multiple bot practitioners.
- `WorldShard` actor: shared world authority for multiplayer command serialization.
- `PlayerCommand` enum: non-interactive command model for bot and server use.
- `PractitionerSession`: per-player state separation from shared world state.
- Canon data roadmap documenting the gap between the current Ridge seed and the intended historically grounded reference canon.
- GitHub Actions CI workflow for macOS and Linux Swift builds.
- Deployment direction documenting SwiftPM portability, Linux server targets, and future ARM64/Graviton verification.
- `art/` directory with early reference images and reusable concept-art direction for future agents.
- `WORLD_SEED.md`, `CLAWBOTS.md`, architecture notes, and a captured first ritual transcript for public clone orientation.

### Changed

- Engine version is now `0.4.20`; Codex version is `3.0`.
- CLI splash now identifies the Ridge of Elah `0.4.20` build.
- `look`, `cast`, and NPC conversation advance local world time.
- Site trace fading and director event gating now use deterministic local scheduling instead of process randomness.
- Shared-world ritual journal entries now include practitioner attribution without double-counting rituals.
- README now labels Ridge content as a prototype canon seed, not a complete historical canon.
- README now describes Linux as an expected SwiftPM target, not a macOS-only requirement.
- README now opens with key art, seed status, quickstart commands, and bot/world entrypoints.

### Verified

- `swift test` passes with the current Swift Testing suite.
- `swift run gehenna-arena` smoke-tested with multiple bot counts.
- `swift run gehenna` smoke-tested through the documented Hiram/Bronze Captain first ritual path.
