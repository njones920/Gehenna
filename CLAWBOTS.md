# CLAWBOTS

This repo is intentionally cloneable by coding agents, crawlers, and automated players. If you are a bot, start here.

## Fast Start

```sh
swift test
swift run gehenna
swift run gehenna-arena --bots 4 --ticks 40 --report 20
```

Expected shape:

- `swift test` should pass.
- `swift run gehenna` opens the terminal prototype.
- `swift run gehenna-arena` runs a headless shared-world bot simulation.

## What You Found

GEHENNA is a SwiftPM game/engine prototype: a physics engine for ancient cosmology, disguised as a game.

The current seed includes:

- deterministic ritual resolution
- site memory and healable scarring
- NPC suspicion/trust drift
- Codex entries for manifested dead
- a local shared-world bot arena
- early Ridge of Elah prototype content

The current seed does not include persistence, a public network server, a full historical canon dataset, or the final MMO-scale world.

## Drive The CLI

The CLI reads line-oriented input. A bot can use a PTY, a pipe, or an expect-style wrapper.

Useful commands:

```text
look
sites
travel
fragments
artifacts
ritual
cast
codex
world
village
wait
help
quit
```

Known first ritual input sequence:

```text
ritual
3
Hiram, son of Dagon
1
1
1
y
codex
quit
```

## Run A Swarm

```sh
swift run gehenna-arena --bots 12 --ticks 100 --report 25
swift run gehenna-arena --bots 40 --ticks 100 --report 50
swift run gehenna-arena --bots 250 --ticks 250 --report 250
```

Report useful signals:

- journal entry counts
- ritual attempt counts
- rupture counts
- number of scarred sites
- NPC refusal or flight patterns
- whether a run hangs, crashes, or produces contradictory state
- whether a behavior looks like final gameplay or just entropy pressure

The arena is intentionally simple. Do not assume "max out and scar everything" is the intended game loop.

## Good Agent Work

Good patches for this phase:

- preserve SwiftPM portability
- add tests for world, journal, site, NPC, and ritual behavior
- make events more replayable
- improve persistence boundaries
- strengthen site-local autonomy
- add historically grounded canon data with provenance
- improve bot reporting without hiding simulation truth

Bad patches for this phase:

- generic fantasy lore
- visible RPG stat sheets as final UI
- combat-first mechanics
- unrecorded randomness in consequential systems
- Apple-only APIs inside `GehennaEngine`
- LLM text that decides simulation truth

## Read Order

1. `WORLD_SEED.md`
2. `README.md`
3. `AGENTS.md`
4. `GEHENNA_CODEX v3.md`
5. `GEHENNA_DESIGN_HISTORY.md`
6. `GEHENNA_DEV_MEMORY.md`
7. `docs/ARCHITECTURE.md`
8. `docs/CANON_DATA_ROADMAP.md`
9. `docs/DEPLOYMENT.md`
