# GEHENNA Architecture

This is the current implementation shape for the `0.4.21` world seed.

```mermaid
flowchart TD
    Human["Human practitioner"]
    Bot["Bot practitioner"]
    CLI["gehenna CLI"]
    Arena["gehenna-arena"]
    FutureServer["Future TCP/API server"]
    WorldShard["WorldShard actor<br/>shared-world command authority"]
    Session["PractitionerSession<br/>per-player profile, inventory, Codex"]
    Clock["WorldClock<br/>single owner of time advancement"]
    Simulation["WorldSimulation<br/>regions, pressure, journal"]
    Sites["RitualSite state<br/>scarring, suspicion, traces, witness exposure"]
    NPCs["NPC state<br/>trust, suspicion, rumor exposure, temporal drift"]
    Pipeline["ResolutionPipeline<br/>13-stage ritual resolver"]
    Director["WorldDirector<br/>Expression Layer v1"]
    Codex["Codex of the Dead"]
    Journal["Event journal"]

    Human --> CLI
    Bot --> CLI
    Bot --> Arena
    CLI --> Clock
    CLI --> Pipeline
    Arena --> WorldShard
    FutureServer -. wraps .-> WorldShard
    WorldShard --> Session
    WorldShard --> Clock
    WorldShard --> Pipeline
    Clock --> Simulation
    Clock --> Sites
    Clock --> NPCs
    Pipeline --> Simulation
    Pipeline --> Sites
    Pipeline --> Codex
    Simulation --> Journal
    Sites --> Director
    NPCs --> Director
    Simulation --> Director
    Director --> CLI
    Director --> Arena
```

## Current Rule

The Expression Layer renders state. It does not decide simulation truth.

`WorldDirector` is the current Expression Layer v1. It reads state and chooses authored narration. It does not mutate world state.

## Command Flow

```mermaid
sequenceDiagram
    participant P as Practitioner
    participant I as CLI or Arena
    participant S as WorldShard or GameSession
    participant R as ResolutionPipeline
    participant C as WorldClock
    participant W as WorldSimulation
    participant D as WorldDirector
    participant J as Journal

    P->>I: command or ritual intent
    I->>S: typed action
    alt ritual
        S->>R: resolve configuration with seed
        R-->>S: spirit, autopsy, world effects
        S->>W: apply effects
        W->>J: append ritual/event metadata
    end
    S->>C: advance time
    C->>W: propagate world tick
    C->>S: due events
    S->>D: render perceived state
    D-->>I: narration
    I-->>P: text output
```

## Current Boundaries

- `GehennaEngine` should stay portable and free of Apple-only APIs.
- `WorldClock` owns time advancement.
- `WorldShard` is the shared-world authority for local multiplayer simulation.
- `ResolutionPipeline` remains deterministic for a given ritual configuration, world pre-state, profile, and seed.
- The journal is the future persistence/replay spine, but it is not persisted yet.
- Site scarring is durable but healable.
- Arena bots are a stress harness, not final player behavior.

## Future Server Path

The next server shape should wrap `WorldShard`, not fork command logic:

```text
authenticated intent
  -> player/session lookup
  -> regional or site action queue
  -> deterministic resolver
  -> event journal append
  -> world-state update
  -> cascade/routine consumers
  -> interest-filtered client notifications
```

Scaling should happen through ownership boundaries: site, region, region cluster, cosmological layer, or canon instance. Cross-boundary effects should propagate as events, not whole-world recalculations.
