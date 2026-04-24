# GEHENNA World Seed

This file describes what exists in the public `0.4.24` seed. It is an orientation layer for humans, bots, and future agents. It is not the full canon.

## Build Identity

| Field | Value |
| --- | --- |
| Version | `0.4.24` |
| Codex | `3.0` |
| Interface | SwiftPM engine, terminal CLI, headless bot arena |
| Current region | Ridge of Elah |
| Canon status | Prototype canon seed |
| License | MIT for code and repository documentation |

GEHENNA is currently a runnable seed of the ritual grammar, world clock, site memory, NPC pressure, Codex loop, and local shared-world arena. It is not yet the finished MMO, full historical canon layer, or network server.

## Live Systems

- Swift package with `GehennaEngine`, `gehenna`, and `gehenna-arena`.
- Ritual configuration model with seven inputs: remains, site, true name, life artifact, memory trace, libation, and timing.
- 13-stage resolution pipeline with coherence, resonance, conflict, apotropaic rule, mutation checks, tiering, personality, and manifestation.
- Stage 11.8: Spirit Verification (Zero-Trust Cosmology) — spirits and epochs verify the practitioner's identity before manifesting.
- Taboo system: 6 canonical violations (bloodshed, graveRobbing, falseName, uncleanSacrifice, oathBreaking, tophethPact) that permanently mark the practitioner.
- Clean Hands / Noob Catalyst: unburdened practitioners can access epochs closed to corrupted veterans.
- Astragali diagnostic reading before ritual execution.
- Ritual autopsy output for mastery feedback.
- Codex of the Dead entries and epoch manifestation support.
- Deterministic root identity IDs from canonical identity seeds (FNV-1a hash, Version 8 UUID).
- WorldClock for command, travel, ritual, and rest time advancement with deterministic day/night (7 ticks/day) and lunar (56-tick) cycles.
- WorldDirector v1 for authored unsolicited world narration.
- Site-local state: scarring, suspicion, witness exposure, active traces, visit ticks, ritual ticks, and recent event count.
- Healable site scarring through quiet recovery and purification hooks.
- NPC interiority with trust, suspicion, rumor exposure, and temporal drift.
- Rumor ledger with site- and faction-weighted seeding, propagation, mutation, decay, and carrier tracking.
- Append-only journal metadata with source, severity, site IDs, NPC IDs, tags, and query paths, persisted inside local single-player snapshots.
- `WorldShard` actor as a single shared-world authority for local multiplayer simulation.
- Headless arena where multiple bot practitioners share sites, NPCs, and consequences.
- Local single-player snapshot save/load via `gehenna-save.json`.
- CLI `rumors` / `gossip` command for reading the active rumor field.
- Swift Testing suite (96 tests across 21 suites).

## Not Live Yet

- Shared-world/server persistence and replay import/export.
- Networked multiplayer server.
- Public API.
- Region-scale rumor ecology and faction response beyond one settlement.
- Witness system and evidence chains.
- Spirit persistence after manifestation.
- Deep historically grounded canon dataset.
- Oracle Network intake.
- LLM-backed Expression Layer runtime.
- Graphics.

## Current Region

The current seed is the Ridge of Elah: a small prototype region in the Shephelah built to prove the engine path, not to represent final canon density.

Known sites:

- Battlefield Ridge
- Tel Keshet
- Nahal Caves
- Kfar Shalem
- The Burning Ground

Implemented content includes bone fragments, life artifacts, memory traces, libations, root identities, epoch manifestations, named NPCs, and site-specific pressure.

## First Ritual Path

One known successful opening path:

1. Run `swift run gehenna`.
2. Enter `ritual`.
3. Choose fragment `3`, the ancient skull with partial inscription.
4. Speak `Hiram, son of Dagon`.
5. Include `1`, the Bronze Spearhead.
6. Include `1`, the Potsherd with Inscription.
7. Pour `1`, Fermented wine.
8. Proceed with `y`.

Captured output lives in `docs/transcripts/first_ritual.md`.

## Arena Path

Run a local shared-world bot simulation:

```sh
swift run gehenna-arena --bots 12 --ticks 100 --report 25
```

The arena is a stress and emergence harness. It is not final gameplay. Current bots tend to drive entropy, scarring, suspicion, and NPC refusal when scaled hard. Treat that as a useful signal about the systems, not as the intended player loop.

## Current Development Pressure

Near-term work should make the world more autonomous before adding conventional game surface:

1. Shared-world/server persistence.
2. Historically grounded canon data expansion.
3. Stronger site-local timelines.
4. Witness state and evidence chains.
5. Faction action and movement driven by rumor history.
6. Spirit persistence and relationship memory.
7. Network server wrapping `WorldShard`.

Core invariant: the Expression Layer renders state. It does not decide simulation truth.
