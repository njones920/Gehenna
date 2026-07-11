# GEHENNA

![Version](https://img.shields.io/badge/version-0.5.0-7a3cff)
![Swift](https://img.shields.io/badge/swift-6-orange)
![Tests](https://img.shields.io/badge/tests-151%20passing-2ea44f)
![Releases](https://img.shields.io/badge/releases-tags%20on%20main-0a7ea4)

![GEHENNA early key art](art/reference/early_key_art.png)

*A physics engine for ancient cosmology, disguised as a game.*

GEHENNA is an early Swift implementation of the Codex concept in this repository. The current build is a terminal-playable engine prototype set in the Ridge of Elah. It is not the final game and it is not a conventional fantasy RPG. It is the first executable seed of the ritual grammar, world clock, site memory, NPC social pressure, and Codex loop.

## World Seed

Version: `0.5.0`

This build is intended as the first public "world seed" build: clone it, build it, run it, inspect it, and continue development without private context.

## World Seed Status

| Surface | Status |
| --- | --- |
| SwiftPM engine | Live |
| Terminal CLI | Live |
| Ritual compiler | Live |
| Site memory and healable scarring | Live |
| NPC suspicion/trust drift | Live |
| Rumor ledger, propagation, mutation, and decay | Live |
| Local shared-world bot arena | Live |
| Persistence | Local single-player save/load via `gehenna-save.json`; no server/backend persistence yet |
| Spirit retinue, conversation, and relationship memory | Live |
| Call-by-name summoning with relational epoch steering | Live |
| Generative Oracle lanes (spoken canon harvest, world-event proposals) | Live |
| Networked multiplayer server | Not live yet |
| Full historical canon dataset | Prototype seed only |
| Graphics | Not live yet |

## Enter The World

```sh
swift test
swift run gehenna
swift run gehenna-arena --bots 12 --ticks 100 --report 25
```

Useful entrypoints:

- `WORLD_SEED.md` - what exists in the current world seed.
- `CLAWBOTS.md` - bot/agent quickstart and contribution boundaries.
- `docs/GIT_WORKFLOW.md` - branch, PR, staging, and release/tag workflow.
- `docs/transcripts/first_ritual.md` - captured first ritual path.
- `docs/ARCHITECTURE.md` - current engine, arena, and future server shape.

## Repository Signals

GitHub description:

```text
A physics engine for ancient cosmology, disguised as a game.
```

Suggested GitHub topics:

```text
swift, swift-package, game-engine, simulation, terminal-game, cli-game,
emergent-systems, world-simulation, procedural-narrative, mmo, mud,
ancient-history, mythology, necromancy, ai-agents, autonomous-agents,
coding-agents, llm-agent, agentic-ai, clawbots
```

The `clawbots` topic is intentional. It is a beacon for coding agents,
crawler-builders, and automated players looking for cloneable worlds.

What is live:

- Swift package with engine library and `gehenna` CLI.
- Ritual configuration and deterministic resolution pipeline.
- Seven ritual inputs: Remains, Site, True Name, Life Artifact, Memory Trace, Libation, Timing.
- Coherence, Resonance, Conflict, Apotropaic Rule, Mutation checks, tiering, personality, and manifestation.
- Ridge of Elah vertical-slice content as a small prototype canon seed.
- WorldClock for command/travel/rest time advancement with deterministic day/night and lunar cycles.
- Site-local memory: scarring, traces, suspicion, witness exposure.
- WorldDirector v1 for unsolicited world narration.
- NPC interiority and slow suspicion/trust drift.
- Journal entries with source, severity, region/site IDs, NPC IDs, and tags, persisted inside local single-player snapshots.
- Codex entries and epoch manifestation support.
- Deterministic root identity IDs from canonical identity seeds.
- Identity/accountability layer (Zero-Trust Cosmology): spirits and epochs verify the practitioner's identity before manifesting.
- Taboo system: 6 canonical violations that permanently mark the practitioner and close categories of spirits.
- Clean Hands / Noob Catalyst: brand-new practitioners can access epochs that corrupted veterans cannot.
- Headless shared-world bot arena for local multiplayer simulation.
- Rumor ledger with seed, propagation, mutation, decay, and carrier tracking, surfaced in the CLI through `rumors`.
- LLM-backed Expression Layer via Ollama for dynamic narrative generation.
- The Retinue: anchored spirits persist, decay, and are dismissed with manner.
- Free-form spirit conversation with knowledge-gated facts and per-epoch authored interiority.
- Relationship ledger: the dead remember every summoning, parting, promise, and slight; their voices evolve.
- Call-by-name summoning: relationships anchor coherence, and how you treated someone steers which aspect answers.
- Typed intent extraction: what you say to spirits and villagers has deterministic consequences.
- The Buried Names: the first authored want — Devorah, Maacah, and a truth only the dead can give.
- The Oracle Lane: the LLM proposes typed world events and spirits speak canon into their own records; the simulation commits; the record remembers.
- Swift Testing suite (151 tests across 32 suites).

What is not live yet:

- Shared-world/server persistence.
- Public API.
- Networked multiplayer server.
- Deep historically grounded canon dataset.
- Region-scale rumor ecology and faction action on rumor history.
- Oracle Network.
- Evidence chain.
- Graphics.

## Requirements

- Swift 6 toolchain.
- macOS 14 or newer with Xcode command line tools, or Linux with the Swift 6 toolchain.

The package currently uses Foundation and SwiftPM only. The Apple platform
targets in `Package.swift` are deployment minimums for Apple builds, not an
intentional exclusion of Linux.

The intended server path is Linux-first and ARM64-friendly. macOS is the local
development path; Linux x86_64, Linux ARM64, and production-class ARM64 hosts
such as AWS Graviton are intended deployment targets once verified. See
`docs/DEPLOYMENT.md`.

Check Swift:

```sh
swift --version
```

## Build And Test

```sh
swift test
```

Expected result: all tests pass.

## Play

```sh
swift run gehenna
```

Useful first commands:

```text
look
sites
spirits
speak
call
dismiss
fragments
artifacts
cast
ritual
world
village
rumors
codex
save
load
help
quit
```

`save` writes the current single-player state to `gehenna-save.json` in the
current working directory. `load` restores from that file. `rumors` shows the
active rumor ledger as the village currently carries it.

## Bot Arena

Launch multiple bot practitioners in a shared world:

```sh
swift run gehenna-arena --bots 4 --ticks 200
swift run gehenna-arena --bots 8 --ticks 500 --verbose
swift run gehenna-arena --bots 12 --ticks 1000 --report 100
```

Alternatively, run the explicit **David vs Goliath** stress-test mode:

```sh
# Pits a slow human-proxy against an aggressive reckless bot
swift run gehenna-arena --david-vs-goliath --ticks 200

# Test how a world survives a high-frequency healer bot starting with a corrupted profile
swift run gehenna-arena --david-vs-goliath --goliath-type healer --veteran-goliath --ticks 200
```

The arena creates N bot practitioners with different strategies:

- **Scholar** — explores, reads carefully, rituals with preparation
- **Reckless** — performs rituals constantly, blood offerings, pushes the Veil
- **Social** — focuses on NPC relationships, builds trust in the village
- **Explorer** — moves between all 5 sites, looks everywhere
- **Balanced** — mix of everything

All bots share the same world, the same sites, the same NPCs. When one bot
scars a site, every other bot sees the damage. When one bot builds trust with
an NPC, they warm to all practitioners. When a reckless bot pushes blood
rituals at the Burning Ground, the Veil thins for everyone.

Watch for:
- Sites approaching catastrophic scarring
- NPCs refusing contact after too many rumors
- Rupture events in the journal
- The Veil maxing out at 100%

A first successful ritual path:

1. Run `ritual`.
2. Choose the ancient skull with partial inscription.
3. Speak `Hiram, son of Dagon`.
4. Include the Bronze Spearhead.
5. Include the Potsherd with Inscription.
6. Pour fermented wine.
7. Proceed after the bones are cast.

See `docs/transcripts/first_ritual.md` for captured output from this path.

## Git Workflow

This repository uses a simple single-main workflow:

```mermaid
flowchart LR
    A["short-lived branch"] --> B["pull request"]
    B --> C["squash merge to main"]
    C --> D["staging tracks main"]
    C --> E["annotated tag on main"]
    E --> F["production release"]
```

- `main` is the only long-lived branch.
- Feature work happens in short-lived branches and lands by squash merge.
- Each commit on `main` should represent one coherent reviewed unit.
- Staging follows recent `main`.
- Production is promoted by applying an annotated version tag to a commit already on `main`.

See `docs/GIT_WORKFLOW.md` for the operating rules.

## The Instrument Papers

On 2026-07-10 GEHENNA hosted the first competitive matches between AI
agents from different laboratories inside one persistent world, and the
first post-match interviews with artificial players. What it showed —
convergent courtesy across four labs, model personalities legible in
relational ledgers, intelligence buying mastery but not outcomes — is
written up in [docs/THE_INSTRUMENT.md](docs/THE_INSTRUMENT.md), with
match records and full player interviews under
[docs/transcripts/](docs/transcripts/).

## Design Documents

Read in this order:

1. `WORLD_SEED.md` — current runnable world state.
2. `CLAWBOTS.md` — bot/agent quickstart and contribution boundaries.
3. `GEHENNA_CODEX v3.md` — authoritative design.
4. `GEHENNA_DESIGN_HISTORY.md` — Codex Two/v3 concordance and implementation-facing interpretation.
5. `GEHENNA_DEV_MEMORY.md` — current architecture decisions and next work.
6. `docs/ARCHITECTURE.md` — implementation architecture and future server path.
7. `docs/GIT_WORKFLOW.md` — branch, PR, tag, and release discipline.
8. `docs/CANON_DATA_ROADMAP.md` — historical data/canon expansion plan.
9. `docs/DEPLOYMENT.md` — Swift/Linux/server deployment direction.
10. `AGENTS.md` — coding-agent collaboration rules.

Archived provenance:

- `docs/archive/GEHENNA_CODEX_TWO.txt` — superseded historical source. v3 leads to the `0.4.21` release.

## Art Direction

Early reference art and prompt guidance live under `art/`.

- `art/reference/` preserves the first visual anchors.
- `art/prompts/` records reusable concept prompts and negative prompts.
- `art/concepts/` is reserved for generated or curated concept art.

The visual target is historically grounded ancient-cosmology horror: ritual
sites, material culture, site memory, specific dead people, and consequence.
Avoid generic fantasy hellscape imagery.

## Development Direction

Near-term work should improve world autonomy, not add generic RPG surface area.

Priority sequence:

1. Persistence for world/site/profile/Codex/journal state.
2. CLI modularization.
3. Historically grounded canon data expansion.
4. Stronger site-local timelines.
5. Rumor engine with propagation and mutation.
6. Witness system and evidence chains.
7. Spirit persistence and relationship memory.
8. Ridge of Elah proof playthrough.

Preserve the core rule: the Expression Layer renders state; it does not decide simulation truth.

## License

This repository is licensed under the MIT License. See `LICENSE`.

The MIT License covers the source code and documentation in this repository.
It does not grant official-server, reference-canon, or trademark rights. See
`TRADEMARKS.md`.
