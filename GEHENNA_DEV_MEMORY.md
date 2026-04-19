# GEHENNA Dev Memory

Last updated: 2026-04-19

Related orientation:

- `GEHENNA_DESIGN_HISTORY.md` reconciles Codex Two and v3 while treating `GEHENNA_CODEX v3.md` as the active design authority.

## Current Assessment

The current codebase is pointed in the right direction for the vision. It implements the correct first layer: a Swift ritual engine and terminal prototype centered on the Codex's ritual-as-compiler thesis.

What is working:

- The 13-stage ritual resolution pipeline exists and is tested.
- The seven ritual inputs are modeled.
- Coherence, Resonance, Conflict, Apotropaic Rule, Mutation checks, tier resolution, personality binding, and manifestation are present.
- Ridge of Elah prototype content exists with five locations, fragments, artifacts, memory traces, root identities, and named NPCs.
- Epoch manifestations are implemented and are important to keep.
- NPC interiority exists in the model and should be expanded, not flattened.
- The CLI has the right tone and should remain a serious proof interface.

The main weakness is not lack of ritual options. The main weakness is that the world still feels command-response, closer to Zork than to an active cosmology. The simulation changes when the player acts, but the world does not yet have enough independent initiative.

The other major weakness is canon density. The engine is meant to operate on a rich historically grounded canon dataset from the Iron Age and Late Bronze Age southern Levant. The current Ridge content proves the data path, but it is far too small to create the intended density of real history, archaeology, names, objects, social roles, mortuary practice, and ritual context.

## Design Call

Build GEHENNA as a persistent occult operating system, not a conventional real-time MMORPG.

The desired long-term shape is a persistent, server-authoritative, event-driven MMO simulation with fine ticks and shock cascades:

- Fine heartbeat for presence, ambience, due events, local motion, and interruptions.
- Routine schedules for ordinary NPC movement, rumor propagation, social pressure, decay, and recovery.
- Immediate cascade engine for ruptures: taboo violations, mutations, Veil tears, threshold crossings, Sebitti correction, Rephaim/Sovereign access.
- Event journal as the durable source of truth.
- Region/site actors or equivalent ownership boundaries for future scaling.
- Thin clients over a public API later.

Do not make the core game a twitch real-time avatar MMO. Ritual composition should remain deliberate and consequence-heavy.

## Near-Term Priority

The next milestone should be a local, single-process version of world autonomy.

Recommended build order:

1. Event journal
   - Every consequential action becomes an event: travel, ritual, NPC interaction, rumor seed, site scar, threshold crossing, spirit manifestation.
   - Events should be replayable and eventually persistable.

2. World clock
   - Every command advances local time.
   - A heartbeat can also fire due background events.
   - Waiting advances more time.
   - The world may interrupt before the prompt returns.

3. Site state
   - Each site tracks local scarring, suspicion, active traces, recent events, witness exposure, and local instability.
   - Battlefield Ridge, Kfar Shalem, Nahal Caves, Tel Keshet, and The Burning Ground should diverge over play.

4. World director
   - After ticks and cascades, decide what the practitioner perceives.
   - Sometimes nothing happens. Sometimes the world speaks first.

5. Rumor engine
   - Rituals, taboo acts, witnessed behavior, and strange site events produce rumor seeds.
   - Rumors move through factions and named NPCs over time.

6. Spirit persistence
   - Some spirits should linger, remember, drift, refuse, haunt, or act after manifestation.
   - Relationship memory matters more than combat utility.

7. Codex persistence
   - Save practitioner profile, world/site state, Codex entries, and ritual/event history.

## Noob Catalyst Principle

New practitioners with clean hands should be able to trigger rare profound changes, but not through naked RNG.

The right model:

- A novice can be catalytic because they are clean, socially invisible, ignorant of taboos, and not yet burdened by Profile contamination.
- Rare events should come from hidden alignment among fragment tags, site state, timing, world pressure, witness state, and practitioner profile.
- A master can force doors open. A novice can sometimes fit a door that force would close.

Avoid:

- "1% chance for beginner legendary summon."

Prefer:

- "Clean Channel" / "Empty-Hand" conditions that unlock alternate paths when a low-contamination practitioner happens to supply the right catalyst.

This keeps mystery without making the world feel random.

## Taboo Shock Principle

Taboo acts should be high-energy inputs, not morality buttons.

A novice performing a taboo sacrifice should be able to shock the world into a chain of consequences if the cultural, site, and spirit conditions are loaded.

Taboo consequences should layer:

- Cosmological: Veil tear, site scarring, spirit release, threshold crossing.
- Social: witnesses panic, rumors mutate, priests respond, factions harden.
- Relational: spirits remember, debts form, taboos attach to the practitioner.
- Historical: the server/world records the event as a named or traceable rupture.

Witnesses matter:

- No witness: primarily cosmological.
- Villager witness: rumor.
- Priest witness: institution.
- Practitioner witness: technique.
- Spirit witness: debt.

This is how a noob can change a server without being "powerful."

## Scaling Direction

The scalable future is not one monolithic real-time scene. It is thousands of practitioners connected to persistent shared cosmology.

Architecture target:

```text
authenticated intent
  -> regional/site action queue
  -> deterministic resolver
  -> event journal
  -> world-state update
  -> cascade/routine consumers
  -> interest-filtered client notifications
```

Partition by geography, site, region cluster, cosmological layer, or canon instance. Cross-region effects should propagate through bounded events, not whole-world recalculation.

The Expression Layer is likely the real scaling bottleneck. It must be tiered:

- authored lines for common situations
- templates for routine state
- cached generated text for repeated conditions
- constrained LLM generation only for important moments
- batch generation for reports, rumors, and Codex summaries

The Expression Layer renders. It must not decide simulation truth.

## Known Gaps In Current Prototype

- Ridge is effectively one region plus site objects; local site autonomy is thin.
  → **Partially addressed**: sites now track scarring, traces, suspicion, and disturbance independently.
- World propagation exists in the engine but is not meaningfully used by the CLI yet.
  → **Addressed**: CLI now uses WorldClock for all time advancement; propagation fires every tick.
- Kfar Shalem does not yet generate the level of ritual suspicion its design implies.
  → **Partially addressed**: ancestor shrine site type has 3x suspicion multiplier; rituals propagate rumors to NPCs via localSuspicion.
- The Burning Ground is not yet dangerous enough as a systemic place.
- Codex output can duplicate tags because tag merging concatenates arrays.
- Root identity IDs are generated UUIDs and should become stable canon IDs before persistence.
- The historical canon/lore dataset is thin. Ridge content is a small seed, not the target reference canon.
- Player-facing CLI still exposes several raw counts. Keep debug utility, but final interface should become more diegetic.
- Ritual seeds are generated from wall-clock time in the CLI; eventual ritual history should record replayable envelopes.
- No persistence yet.
- ~~No event journal yet.~~ **Resolved**: journal entries now carry source, severity, siteID, involvedNPCs, and tags. Queryable by site, tick, severity, tag, and NPC.
- ~~No active world clock yet.~~ **Resolved**: WorldClock is the single entry point for time; CLI never calls world.tick() directly.
- Rumor propagation is basic (seeding only, no mutation or chains). Full rumor engine is next milestone.
- WorldDirector uses authored templates only. No LLM generation yet; templates are keyed to site type and NPC state.

## Architecture Decisions (Session 2026-04-19)

### WorldClock as Single Time Owner
- **Decision**: `WorldClock` owns `currentTick`. `WorldSimulation.tick()` no longer increments its own tick count; the clock sets it before calling `tick()`.
- **Rationale**: Prevents double-counting and establishes a single control point for time. The CLI calls `clock.advanceForTravel()`, `clock.advanceForCommand()`, or `clock.advanceForRest()` — never `world.tick()` directly.
- **Implication**: Any new system that needs to advance time must go through the clock.

### WorldDirector as Expression Layer v1
- **Decision**: The director evaluates 7 prioritized conditions (Veil instability, NPC initiative, site disturbance, site memory, spirit traces, ambient presence, rumor propagation) and emits 0–2 events per evaluation with authored template text.
- **Rationale**: Follows the design principle: "The Expression Layer renders. It must not decide simulation truth." The director reads world state and narrates what is already true. It never mutates state.
- **Implication**: Future LLM generation should only replace the template text selection, not the condition evaluation logic.

### Site State with Healable Scarring
- **Decision**: `RitualSite` tracks `scarring` as durable damage, not absolute permanence. It recovers only under quiet/clean conditions or through deliberate `purifySite` restoration. `localSuspicion`, `activeTraces`, `witnessExposure`, and `recentEventCount` still cool independently.
- **Rationale**: "Consequence is content," but repair is also content. Healable scarring creates a healer/firefighter role and makes restoration a real player strategy instead of reducing every shared world to entropy maximization.
- **Implication**: Persistence must save site state. The Veil modifier feeds back into the resolution pipeline through `effectiveVeilThinness`; future healer systems should call `purifySite` and record restoration events in the journal.

### NPC Temporal Drift
- **Decision**: NPCs have `tickState()` for per-tick processing: rumor-based suspicion decays very slowly, trust drifts toward neutral. Added `wouldApproach` and `wouldFlee` computed properties.
- **Rationale**: Relationships should not be frozen between player commands. The drift is slow enough that the player's actions still dominate, but the world has temporal texture even when the player is away.
- **Implication**: NPC movement/schedules are next. Currently NPCs are fixed at Kfar Shalem.

## Architecture Decisions (Session 2026-04-19 420 Prep)

### 0.4.20 World Seed
- **Decision**: Build identity is now `0.4.20`; Codex version is `3.0`; the CLI splash says `Ridge of Elah — v0.4.20`.
- **Rationale**: Prepare the April 20 "420" world-seed build as a clear clone/build/play/dev artifact.
- **Implication**: Future version bumps should update `GehennaEngine.version`, the CLI splash, `README.md`, and `CHANGELOG.md` together until package metadata is centralized.

### Public Clone Surface
- **Decision**: Added `README.md`, `CHANGELOG.md`, and `.gitignore`.
- **Rationale**: A crawler, bot, or human should be able to clone the repo and immediately know how to build, test, play, and continue development.
- **Implication**: README is now part of the release surface. Keep its "live/not live yet" sections accurate.

### Public License and Repository Signals
- **Decision**: Added MIT licensing, a trademark/canon notice, and `.github/repository-metadata.yml` with the public description and discovery topics.
- **Rationale**: The code should be freely cloneable and forkable while preserving the distinction between open source code, official operated worlds, and reference canon.
- **Implication**: GitHub topics are repository metadata, not Git metadata. After the remote exists, mirror the topics in GitHub settings; keep `clawbots` as an intentional agent/crawler beacon.

### Codex Two Archived
- **Decision**: Moved the superseded Codex Two text document to `docs/archive/GEHENNA_CODEX_TWO.txt`.
- **Rationale**: The root should make the current hierarchy obvious: v3 is the active Codex, and it leads the 420 release.
- **Implication**: Agents should not treat Codex Two as a competing spec. Read it only for provenance after v3 and `GEHENNA_DESIGN_HISTORY.md`.

### Headless Bot Arena
- **Decision**: Added `gehenna-arena`, `PlayerCommand`, `PractitionerSession`, and `WorldShard` as the local shared-world multiplayer proof.
- **Rationale**: Bots and humans need one authoritative world before a network server matters. The arena proves multiple practitioners can scar the same sites, perturb the same NPCs, and write into one journal without adding TCP/server complexity to the 420 seed.
- **Implication**: This is local multiplayer simulation, not networked multiplayer. Future TCP/MUD work should wrap `WorldShard` rather than duplicating command logic. Keep ritual journal entries single-source and attributable; do not double-log practitioner rituals.

### Canon Data Gap
- **Decision**: Added `docs/CANON_DATA_ROADMAP.md` and explicitly marked the Ridge content as a prototype canon seed.
- **Rationale**: GEHENNA should be driven by structured historical data, not generic fantasy lore. The 420 build proves the engine and local bot arena, but the reference canon still needs deep real-world content from the period.
- **Implication**: Near-term work should add stable canon IDs, provenance metadata, typed canon files, and a much richer tag dictionary before claiming the Ridge feels historically deep.

### Deterministic Director Gating
- **Decision**: Replaced process-random director/site trace gates with deterministic scheduling from local tick state and stable salts.
- **Rationale**: The eventual evidence chain needs replayable behavior. Ambient rendering can still be selective without using unrecorded randomness.
- **Implication**: If future systems need randomness, route it through a seed or recorded entropy envelope.

### Commands Advance Local Time
- **Decision**: `look`, `cast`, and NPC conversation now advance the WorldClock through `advanceForCommand`; travel/rest/ritual already did.
- **Rationale**: The CLI should feel less like static command-response. Even small actions let the world breathe.
- **Implication**: Purely informational commands such as `help`, `inventory`, and `fragments` still do not advance time. Revisit this once persistence and a stronger world clock are in place.

## Preserve

- v3 Codex as authority.
- Ritual grammar first.
- CLI as proof interface.
- Epoch manifestations.
- NPC interiority.
- Entropy asymmetry.
- Clean Hands Problem.
- Unsolvability Principle.
- No Visible Numbers as a final UI principle (with pragmatic flexibility during prototyping).
- WorldClock as single time owner.
- WorldDirector renders, never decides.
- Site scarring is durable but healable — consequence creates work for healers.
