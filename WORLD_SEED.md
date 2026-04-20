# GEHENNA World Seed

This file describes what exists in the public `0.4.20` seed. It is an orientation layer for humans, bots, and future agents. It is not the full canon.

## Build Identity

| Field | Value |
| --- | --- |
| Version | `0.4.20` |
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
- Astragali diagnostic reading before ritual execution.
- Ritual autopsy output for mastery feedback.
- Codex of the Dead entries and epoch manifestation support.
- WorldClock for command, travel, ritual, and rest time advancement.
- WorldDirector v1 for authored unsolicited world narration.
- Site-local state: scarring, suspicion, witness exposure, active traces, visit ticks, ritual ticks, and recent event count.
- Healable site scarring through quiet recovery and purification hooks.
- NPC interiority with trust, suspicion, rumor exposure, and temporal drift.
- Append-only journal metadata with source, severity, site IDs, NPC IDs, tags, and query paths.
- `WorldShard` actor as a single shared-world authority for local multiplayer simulation.
- Headless arena where multiple bot practitioners share sites, NPCs, and consequences.

## Not Live Yet

- Persistence for world, site, practitioner, Codex, and journal state.
- Networked multiplayer server.
- Public API.
- Full rumor propagation and mutation chains.
- Witness system.
- Taboo shock cascade engine.
- Clean-channel / noob-catalyst system.
- Spirit persistence after manifestation.
- Stable canon IDs for all root identities.
- Deep historically grounded canon dataset.
- Identity/accountability layer.
- Evidence chain.
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

1. Persistence.
2. Stable canon IDs and richer historical canon data.
3. Stronger site-local timelines.
4. Rumor propagation and mutation.
5. Witness state.
6. Spirit persistence and relationship memory.
7. Taboo shock cascades.
8. Clean-channel catalyst events.
9. Network server wrapping `WorldShard`.

Core invariant: the Expression Layer renders state. It does not decide simulation truth.
