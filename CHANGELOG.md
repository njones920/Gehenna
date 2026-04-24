# Changelog

## Unreleased

## 0.4.24 - Architecture Polish & Rumor Consequence

Minor architectural cleanup, multi-region prep, and rumor consequence follow-through.

### Changed

- Sustained rumor carriers now bleed suspicion back into the sole-region prototype path, allowing regional suspicion and inquisition pressure to reflect social spread instead of only direct ritual entropy.
- Rumor seeding no longer overwrites the canonical ledger strength with per-hearer reach, so propagation and mutation now operate on the real rumor rather than a collapsed `0.12` floor.
- Explicit Site Suspicion Multipliers: `RitualSite.suspicionMultiplier` now strictly switches over all site types, removing the default fallback.
- Multi-Region Hardcode Fix: Added `regionID` to `RitualSite`. `WorldShard` now uses `site.regionID` instead of blindly grabbing the first region in the dictionary, ensuring future multi-region compatibility.
- `RidgeOfElah.createWorld()` now explicitly links initialized sites to the created region.

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
