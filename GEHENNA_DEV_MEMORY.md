# GEHENNA Dev Memory

Last updated: 2026-04-20

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

Swift remains the intended implementation language for the authoritative engine and server path. The project should preserve a SwiftPM-first package that develops cleanly on macOS and deploys cleanly to Linux. Linux x86_64, Linux ARM64, and production-class ARM64 hosts such as AWS Graviton are intended targets, but ARM64 Linux/Graviton support must be verified before being claimed.

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

### SwiftPM Portable Server Path
- **Decision**: Added `docs/DEPLOYMENT.md` and documented the intended Swift/Linux/ARM64 server path.
- **Rationale**: GEHENNA should remain a compiled, typed, portable simulation engine: macOS for local development, Linux for server deployment, ARM64 as a first-class architecture target.
- **Implication**: Keep `GehennaEngine` free of Apple-only APIs. Treat AWS Graviton as an intended production-class target, not a verified target, until Linux ARM64 CI or deployment smoke tests exist.

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

## Linux Cross-Platform Verification (2026-04-20)

### Verification Performed

- **Platform**: Linux x86_64, Fedora, Swift 6 toolchain.
- **Clone source**: `https://github.com/njones920/Gehenna.git` (public repository).
- **Build**: `swift test` — clean compile, no warnings, no Apple-specific API failures.
- **Test suite**: 71 tests in 17 suites — all passed in 0.010 seconds.
- **Arena simulation**: `swift run gehenna-arena --bots 12 --ticks 100 --report 25` — ran to completion. 310 rituals, 8 ruptures, 3/5 sites scarred, 0/6 NPCs refusing contact.

### Verdict

The 0.4.20 world seed is **fully portable across macOS and Linux x86_64**. The package uses only Foundation and SwiftPM. No Apple-specific APIs were detected anywhere in `GehennaEngine`, `GehennaCLI`, or `GehennaArena`. The `platforms` block in `Package.swift` specifies `.macOS(.v14)` and `.iOS(.v17)` as deployment minimums for Apple builds; these are correctly ignored by the Linux toolchain.

Linux x86_64 is now a **verified** target. ARM64 Linux and AWS Graviton remain intended but unverified; update `docs/DEPLOYMENT.md` accordingly when CI or a deployment smoke test confirms them.

## Architecture Decisions (Session 2026-04-20 Linux Audit)

### Linux x86_64 Verified
- **Decision**: Mark Linux x86_64 as a verified target in the deployment matrix. Previously it was intended but unverified.
- **Rationale**: Full build + test suite + bot arena simulation passed cleanly on Fedora Linux with the Swift 6 toolchain. No code changes were required.
- **Implication**: `docs/DEPLOYMENT.md` "Configured but not yet proven" section should be updated to reflect that Linux x86_64 is now proven. The repo can credibly claim cross-platform readiness for x86_64 development and hobby deployment.

## Codebase Analysis — Full Audit From Fresh Eyes (2026-04-20)

### Scale

~8,300 lines of Swift across 27 source files, 1 test file, 3 executables, and 5 documentation files. For a 0.x prototype, this is a well-shaped codebase. The code-to-documentation ratio is excellent.

### What Is Genuinely Impressive

1. **The ritual-as-compiler thesis is implemented, not just described.** The 13-stage `ResolutionPipeline` is a real, tested, deterministic pipeline. Coherence, Resonance, Conflict, Apotropaic evaluation, Mutation check, Tier resolution, Attribute generation, Template selection, Epoch resolution, Personality binding, and Manifestation all exist as discrete, testable stages. This is not a design document — it is a working compiler.

2. **The Epoch Manifestation system is a genuinely novel collection mechanic.** Hiram son of Dagon can manifest as the Bronze Captain, the Ashkelon Butcher, or the Nameless Shield-Bearer depending on what fragments, site, and world state the practitioner configures. This creates combinatorial depth that most games simulate with random drops. The `EpochResolver` scoring system is well-designed: era alignment, domain matching, tag trigger intersection, site type preference, corruption gating, and libation influence all feed into a single score.

3. **The NPC interiority system is remarkable.** Every NPC has a private truth, an unsatisfied want, a wound, a threshold, and an interior voice. These are not gameplay-facing yet (the CLI shows behavior descriptions, not interiority), but the data is structured and ready for an Expression Layer that can draw on it. The writing quality of the interiority text is exceptionally high — Yoel ben Shimri's theological doubt, Devorah's suppressed practitioner past, Baruk's bronze mirror. These are people.

4. **The `WorldShard` actor is the correct multiplayer primitive.** It serializes all consequential actions, owns the shared state, and is wrappable by any interface (CLI, arena, future server). The arena already proves that 12 practitioners can act in the same world without data races.

5. **The Astragali degradation mechanic is brilliant design.** The diagnostic tool becomes unreliable exactly as the Veil thins — the training wheels come off when the practitioner needs them most, and the thing that removed them was the practitioner's own ritual activity. This is entropy asymmetry made mechanical.

6. **The Ritual Autopsy mastery-phase system is well-architected.** The same ritual produces different internal narration depending on whether the practitioner is an Apprentice, Practitioner, Adept, or Master. The language shifts from emotional/sensory to analytical/spare. This is diegetic progression without numbers.

### Specific Issues Found

1. ~~**Tag duplication on merge.**~~ **Resolved in the local working tree.** `TagConstellation.merged(with:)` now deduplicates exact duplicate tags while preserving first-seen order. This prevents Codex entries and spirit tag histories from growing duplicate tag rows over repeated encounters.

2. ~~**`PractitionerProfile.summmonerCapacity` has a typo** — triple 'm'.~~ **Resolved in `c8a0add`.** The field is now `summonerCapacity`, avoiding a bad serialized/public API name before persistence lands.

3. **The CLI (`GehennaCLI/main.swift`) is 44KB in a single file.** This is manageable for a prototype but will become unwieldy as features are added. The arena is 16KB in one file, which is fine.
   - *Recommendation*: Before adding persistence or richer CLI commands, split the CLI into at least `GameSession.swift`, `RitualFlow.swift`, `CommandParser.swift`, and `CLIRenderer.swift`.

4. **Root identity IDs are generated UUIDs.** Already noted in Known Gaps. Before persistence, these should become stable, deterministic IDs (e.g., UUID v5 from a canonical namespace + the trueName or a stable content hash).

5. **`WorldShard.execute()` uses `world.regions.keys.first` to find the region ID.** This works with one region but will silently pick an arbitrary region if multiple regions exist. The shard should either track which region a site belongs to, or sites should carry a `regionID` reference.

6. ~~**Ritual entropy seeds in the CLI use wall-clock time** (`Date().timeIntervalSince1970`).~~ **Resolved in the interactive CLI.** Ritual and astragali seeds now derive from tick/state rather than wall-clock time, matching the replayability goal established in the arena path.

7. **The `RitualSite` suspicion multiplier `default` case** returns 1.0 but doesn't cover `springCaveMouth`, `ossuaryNiche`, or `wadiBed`. These site types exist in the enum but have no Ridge of Elah content yet. If content is added for them, the suspicion behavior will be the untuned default.

8. **NPC rumor propagation is uniform.** In `WorldShard.executeRitual()`, when site suspicion exceeds 0.05, *all* NPCs hear the rumor at the same strength. This means a ritual at the Burning Ground (suspicion multiplier 0.2) and a ritual at the ancestor shrine (suspicion multiplier 3.0) both propagate to all six NPCs identically once the threshold is crossed. Rumors should attenuate by distance from the site and be weighted by NPC faction.

9. ~~**No `Codable` conformance on `JournalEntry`.**~~ **Resolved in `fd216b8`.** `JournalEntry`, `ThresholdEvent`, `EventSource`, `EventSeverity`, and related enums now conform to `Codable`, removing the first serialization blocker for persistence.

10. ~~**Clock-derived timing exists, but the CLI ritual path is not fully wired to it yet.**~~ **Resolved in the interactive CLI.** The ritual menu and astragali diagnostic now default to `clock.currentTiming`, and their entropy seeds are derived from tick/state rather than wall-clock time.
   - *Remaining follow-up*: Keep an explicit override path for deliberate waiting/timing choices once the CLI grows a more expressive ritual input flow.

### Architectural Observations

1. **The engine is genuinely server-ready.** The `WorldShard` actor + `PlayerCommand` + `CommandResult` pattern is a clean request/response loop. A Vapor or Hummingbird server could wrap it with minimal adapter code. The journal is already the event-sourcing spine — adding persistence means persisting journal entries and projecting state from them.

2. **The Expression Layer boundary is well-maintained.** The `WorldDirector` reads state and emits text. It never mutates state. This invariant is preserved throughout the codebase.

3. **The Content/Grammar/Models/World/Diagnostics directory structure is clean and should be preserved.** Content (RidgeOfElah) is separated from models, grammar (pipeline + DSL), world systems, and diagnostics. New regions should go in Content/. New systems should go in World/.

4. **The test suite covers the right things.** Deterministic resolution, NPC state drift, site scarring, Veil computation, era alignment, affinity opposition, journal queries, mastery-phase autopsy, shared-world practitioner interaction, clock-derived timing, and tag deduplication are all tested. The gaps are in CLI behavior (no integration tests for the interactive loop) and persistence (not yet implemented). **76 tests as of 2026-04-20.**

5. **`Sendable` conformance is thorough.** Every model type is `Sendable`. The `WorldShard` is an `actor`. This is correct for the Swift 6 concurrency model and will make the server path straightforward.

### Recommended Near-Term Sequence

Based on this audit, the most valuable next work is:

1. ~~**Fix the typo** (`summmonerCapacity` → `summonerCapacity`) before any persistence work serializes it.~~ **Done** (`c8a0add`). Renamed across PractitionerProfile, CLI, and tests.
2. ~~**Add `Codable` to `JournalEntry`** and its associated enums. This is the smallest step toward persistence.~~ **Done** (`fd216b8`). Added Codable to ThresholdEvent, EventType, EventSource, EventSeverity, JournalEntry, JournalEntryType.
3. ~~**Derive `WorldTiming` from `WorldClock`** tick count.~~ **Done** (`a137bf4`). 7 ticks per day (dawn → deepNight), 8-day lunar cycle (56-tick full cycle). Deterministic, replayable. 3 new tests added.
4. **Attenuate NPC rumor propagation by site proximity and faction.** Village NPCs should hear village-site rumors loudly; cave-site rumors should travel slowly. ← **next**
5. **Stabilize root identity IDs** with deterministic UUID v5 generation from trueName/culture/era.
6. **Persist journal entries** to a local file (JSON lines or SQLite). This is the first real persistence step and enables replay.
7. **Split the CLI** into multiple files before it grows further.

## Architecture Decisions (Session 2026-04-20 Fixes)

### WorldTiming Derived From Tick Count
- **Decision**: `WorldClock` now owns the day/night cycle and lunar phase. `currentTimeOfDay`, `currentLunarPhase`, and `currentTiming` are computed properties derived from `currentTick`.
- **Constants**: 7 ticks per day (`ticksPerDay`), 8 days per lunar cycle (`daysPerLunarCycle`), 56-tick full lunar cycle.
- **Rationale**: The world needs a natural rhythm for world autonomy. Rituals performed at midday should be naturally penalized without the player manually selecting timing. This gives the Director a time-of-day signal for atmospheric narration and establishes the correct source of truth for timing.
- **Implication**: `WorldClock` is now the source of timing truth, and the interactive CLI ritual path consumes `clock.currentTiming` by default instead of a hardcoded `WorldTiming(time: .night)`. The Director can check `clock.currentTimeOfDay` to vary narration. The existing `WorldTiming` parameter on `RitualIntent` should remain as an override for player-specified timing (e.g., "wait until deepNight, then perform the ritual").
- **Invariant**: The mapping is deterministic from tick count alone. No wall-clock, no randomness. Replaying the same tick sequence produces the same timing.

### Journal Types Made Codable
- **Decision**: All journal and event types (`JournalEntry`, `ThresholdEvent`, `EventSource`, `EventSeverity`, etc.) now conform to `Codable`.
- **Rationale**: Prerequisite for any persistence layer. Auto-synthesis handles everything since all stored properties are already Codable-compatible.
- **Implication**: The journal can now be serialized to JSON lines or encoded for SQLite storage without additional work.

### Tag Constellation Merge Deduplication
- **Decision**: `TagConstellation.merged(with:)` now deduplicates exact duplicate tags after merging while preserving first-seen order.
- **Rationale**: Codex accumulation and ritual tag aggregation should not bloat with repeated identical tags. Similarity logic already treated tags as a set; the stored representation now matches that intent better.
- **Implication**: Repeated encounters with the same spirit or overlapping ritual inputs will not inflate `knownTags` counts artificially. Existing ordering remains stable for rendering/debugging.

## Repository Maintenance (Session 2026-04-20)

### GitHub Actions Checkout Updated To v5
- **Decision**: Updated `.github/workflows/ci.yml` from `actions/checkout@v4` to `actions/checkout@v5`.
- **Rationale**: GitHub warned that Node.js 20-based JavaScript actions are deprecated. `checkout@v5` moves the workflow onto the Node 24 runtime line and removes that warning source.
- **Implication**: This addresses the checkout deprecation warnings on both macOS and Linux CI jobs. Any remaining CI failure after this change is a real job failure, not the Node 20 warning.

### Preserve (Additions)

- Linux x86_64 as a verified deployment target.
- The `WorldShard` actor as the wrappable multiplayer primitive.
- The Epoch Manifestation system as the core collection mechanic.
- NPC interiority as authored depth, not generated filler.
- The Astragali degradation mechanic — training wheels that come off.
- Mastery-phase-aware autopsy voice.
- WorldClock as the sole derivation source for time-of-day and lunar phase. 7 ticks/day, 56-tick lunar cycle.
- Journal types are Codable and ready for persistence.
- Tag constellation merges preserve order while removing exact duplicates.
