# GEHENNA Dev Memory

Last updated: 2026-04-24

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
- ~~Codex output can duplicate tags because tag merging concatenates arrays.~~ **Resolved**: `TagConstellation.merged(with:)` now deduplicates exact duplicate tags while preserving first-seen order.
- ~~Root identity IDs are generated UUIDs and should become stable canon IDs before persistence.~~ **Resolved**: root identity IDs are deterministic from a widened canonical seed (name + culture + era + core tags + epochs).
- The historical canon/lore dataset is thin. Ridge content is a small seed, not the target reference canon.
- Player-facing CLI still exposes several raw counts. Keep debug utility, but final interface should become more diegetic.
- ~~Ritual seeds are generated from wall-clock time in the CLI; eventual ritual history should record replayable envelopes.~~ **Resolved**: ritual and astragali entropy now derive from tick/state.
- ~~No persistence yet.~~ **Resolved for local single-player CLI snapshots** via `gehenna-save.json`. Shared-world/server persistence is still open.
- ~~No event journal yet.~~ **Resolved**: journal entries now carry source, severity, siteID, involvedNPCs, and tags. Queryable by site, tick, severity, tag, and NPC.
- ~~No active world clock yet.~~ **Resolved**: WorldClock is the single entry point for time; CLI never calls world.tick() directly.
- ~~Rumor propagation is basic (seeding only, no mutation or chains). Full rumor engine is next milestone.~~ **Resolved in local working tree**: the engine now has a typed rumor ledger with propagation, mutation, decay, carrier tracking, director integration, and a CLI `rumors` / `gossip` view.
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

## Architecture Decisions (Session 2026-04-19 0.4.20 Prep)

### 0.4.20 World Seed
- **Decision**: Build identity is now `0.4.20`; Codex version is `3.0`; the CLI splash says `Ridge of Elah — v0.4.20`.
- **Rationale**: Prepare the 0.4.20 world-seed build as a clear clone/build/play/dev artifact.
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
- **Rationale**: The root should make the current hierarchy obvious: v3 is the active Codex, and it leads the 0.4.20 release.
- **Implication**: Agents should not treat Codex Two as a competing spec. Read it only for provenance after v3 and `GEHENNA_DESIGN_HISTORY.md`.

### Headless Bot Arena
- **Decision**: Added `gehenna-arena`, `PlayerCommand`, `PractitionerSession`, and `WorldShard` as the local shared-world multiplayer proof.
- **Rationale**: Bots and humans need one authoritative world before a network server matters. The arena proves multiple practitioners can scar the same sites, perturb the same NPCs, and write into one journal without adding TCP/server complexity to the 0.4.20 seed.
- **Implication**: This is local multiplayer simulation, not networked multiplayer. Future TCP/MUD work should wrap `WorldShard` rather than duplicating command logic. Keep ritual journal entries single-source and attributable; do not double-log practitioner rituals.

### Canon Data Gap
- **Decision**: Added `docs/CANON_DATA_ROADMAP.md` and explicitly marked the Ridge content as a prototype canon seed.
- **Rationale**: GEHENNA should be driven by structured historical data, not generic fantasy lore. The 0.4.20 build proves the engine and local bot arena, but the reference canon still needs deep real-world content from the period.
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

3. ~~**The CLI (`GehennaCLI/main.swift`) is 44KB in a single file.**~~ **Resolved in `0.4.22`.** The CLI is now split into `GameSession.swift`, `Commands.swift`, `Display.swift`, and a minimal `main.swift`.

4. ~~**Root identity IDs are generated UUIDs.**~~ **Resolved.** Root identity IDs now derive from a widened canonical seed and are stable across runs/snapshots.

5. **`WorldShard.execute()` uses `world.regions.keys.first` to find the region ID.** This works with one region but will silently pick an arbitrary region if multiple regions exist. The shard should either track which region a site belongs to, or sites should carry a `regionID` reference.

6. ~~**Ritual entropy seeds in the CLI use wall-clock time** (`Date().timeIntervalSince1970`).~~ **Resolved in the interactive CLI.** Ritual and astragali seeds now derive from tick/state rather than wall-clock time, matching the replayability goal established in the arena path.

7. **The `RitualSite` suspicion multiplier `default` case** returns 1.0 but doesn't cover `springCaveMouth`, `ossuaryNiche`, or `wadiBed`. These site types exist in the enum but have no Ridge of Elah content yet. If content is added for them, the suspicion behavior will be the untuned default.

8. ~~**NPC rumor propagation is uniform.**~~ **Resolved in the local working tree.** Rumor strength is now derived from both site type and faction. Village shrine rumors hit elders and priesthood harder than traders; isolated cave rumors spread more weakly; topheth rumors carry most strongly into priestly suspicion. The interactive CLI and `WorldShard` now use the same site-level rumor rule.

9. ~~**No `Codable` conformance on `JournalEntry`.**~~ **Resolved in `fd216b8`.** `JournalEntry`, `ThresholdEvent`, `EventSource`, `EventSeverity`, and related enums now conform to `Codable`, removing the first serialization blocker for persistence.

10. ~~**Clock-derived timing exists, but the CLI ritual path is not fully wired to it yet.**~~ **Resolved in the interactive CLI.** The ritual menu and astragali diagnostic now default to `clock.currentTiming`, and their entropy seeds are derived from tick/state rather than wall-clock time.
   - *Remaining follow-up*: Keep an explicit override path for deliberate waiting/timing choices once the CLI grows a more expressive ritual input flow.

### Architectural Observations

1. **The engine is genuinely server-ready.** The `WorldShard` actor + `PlayerCommand` + `CommandResult` pattern is a clean request/response loop. A Vapor or Hummingbird server could wrap it with minimal adapter code. The journal is already the event-sourcing spine — adding persistence means persisting journal entries and projecting state from them.

2. **The Expression Layer boundary is well-maintained.** The `WorldDirector` reads state and emits text. It never mutates state. This invariant is preserved throughout the codebase.

3. **The Content/Grammar/Models/World/Diagnostics directory structure is clean and should be preserved.** Content (RidgeOfElah) is separated from models, grammar (pipeline + DSL), world systems, and diagnostics. New regions should go in Content/. New systems should go in World/.

4. **The test suite covers the right things.** Deterministic resolution, NPC state drift, site scarring, Veil computation, era alignment, affinity opposition, journal queries, mastery-phase autopsy, shared-world practitioner interaction, clock-derived timing, tag deduplication, rumor attenuation, deterministic root identity IDs, identity/accountability accrual, persistence snapshots, and the rumor engine are all tested. The main remaining gap is CLI integration coverage beyond smoke testing. **98 tests across 21 suites as of 2026-04-23.**

5. **`Sendable` conformance is thorough.** Every model type is `Sendable`. The `WorldShard` is an `actor`. This is correct for the Swift 6 concurrency model and will make the server path straightforward.

### Recommended Near-Term Sequence

Based on this audit, the most valuable next work is:

1. ~~**Fix the typo** (`summmonerCapacity` → `summonerCapacity`) before any persistence work serializes it.~~ **Done** (`c8a0add`). Renamed across PractitionerProfile, CLI, and tests.
2. ~~**Add `Codable` to `JournalEntry`** and its associated enums. This is the smallest step toward persistence.~~ **Done** (`fd216b8`). Added Codable to ThresholdEvent, EventType, EventSource, EventSeverity, JournalEntry, JournalEntryType.
3. ~~**Derive `WorldTiming` from `WorldClock`** tick count.~~ **Done** (`a137bf4`). 7 ticks per day (dawn → deepNight), 8-day lunar cycle (56-tick full cycle). Deterministic, replayable. 3 new tests added.
4. ~~**Stabilize root identity IDs** with deterministic UUID generation.~~ **Done, then tightened in the local working tree.** Root identity IDs are now derived from a canonical seed built from normalized name, culture, native era, core tags, and epoch descriptors before hashing into a stable Version 8 UUID. This reduces collisions compared with the earlier `trueName + culture + nativeEra` seed.
5. ~~**Identity / Accountability Layer (Zero-Trust Cosmology)** — spirits and epochs verify the practitioner's identity before manifesting.~~ **Done.** Added `Taboo` enum, `IdentityRequirements` struct, `SpiritTemplate.identityRequirements`, `Epoch.identityRequirements`, and Stage 11.8 (Spirit Verification) to the pipeline. 3 new tests in a dedicated `ZeroTrustCosmologyTests` suite. 82/82 tests pass.
6. ~~**Make identity/accountability earned in play** rather than only test/setup state.~~ **Done in local working tree.** `PractitionerProfile.applyRitualConsequences` now accrues contagion, purity damage, and the first concrete taboo writes from actual ritual actions. Mortuary rituals without compensation mark `.graveRobbing`; corrupted fragments at high-sanctity sites mark `.uncleanSacrifice`; blood or mimic-blood sacrifice at a `topheth` marks `.tophethPact`. Both CLI and `WorldShard` call the same engine hook. 4 focused tests added.
7. ~~**Persist journal entries** to a local file (JSON lines or SQLite).~~ **Done in local working tree, with a broader but still narrow cut.** Added typed single-player snapshot persistence (`SinglePlayerSnapshot`, `SnapshotStore`) and CLI `save` / `load` commands. The saved snapshot now carries world state, journal, practitioner profile, Codex, sites, inventory, NPCs, root identities, and clock in one JSON file (`gehenna-save.json`).
8. ~~**Split the CLI** into multiple files before it grows further.~~ **Done in `0.4.22`.**
9. **Broaden persistence coverage for shared-world/server paths** (`PractitionerSession`, shard snapshots, replay/import format) once the CLI save boundary settles.

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

### Site And Faction Weighted Rumor Propagation
- **Decision**: Rumor spread now depends on both ritual site type and NPC faction instead of one flat `siteSuspicion * 0.3` broadcast.
- **Rationale**: A ritual at Kfar Shalem should move through elders and priesthood much faster than the same ritual in a remote cave. A topheth should trigger priestly attention more than trader chatter. The prior uniform spread flattened social texture.
- **Implication**: `RitualSite` now exposes a shared rumor-strength rule used by both the interactive CLI and `WorldShard`. This keeps the single-player and shared-world paths aligned and makes rumor propagation feel more local and culturally shaped without introducing a full rumor graph yet.

### Root Identity Seed Widened
- **Decision**: The deterministic root identity seed now includes normalized name, culture, native era, canonical core tags, and canonical epoch descriptors rather than only `trueName + culture + nativeEra`.
- **Rationale**: Same-named people in the same culture/era are plausible in a historical dataset. The wider canonical seed materially reduces accidental collisions before canon IDs exist.
- **Implication**: Root identity IDs remain deterministic across runs, but they are now more robust against future canon expansion. The exploratory `test_crypto.swift` scratch file was also removed; the package still avoids CryptoKit dependencies.

### Identity / Accountability Layer (Zero-Trust Cosmology)
- **Decision**: Spirits and epochs now act as active verification nodes in the resolution pipeline. A new Stage 11.8 (Spirit Verification) runs after template selection and epoch resolution. The pipeline extracts `IdentityRequirements` from the resolved epoch (if any) or the template, then evaluates the practitioner's `PractitionerProfile` against those requirements.
- **New Types**: `Taboo` enum (6 canonical violations: bloodshed, graveRobbing, falseName, uncleanSacrifice, oathBreaking, tophethPact). `IdentityRequirements` struct (forbiddenTaboos, requiredTokens, minimumPurity, requiresCleanHands). `PractitionerProfile.taboosBroken` (permanent set of broken taboos). `PractitionerProfile.cleanHands` (the Noob Catalyst computed property).
- **Rationale**: The original design agent identified the Identity/Authorization layer as the single most important conceptual gap. Rituals are not just syntax + world state; they must be syntax + world state + speaker identity, with spirits acting as verification nodes. This is the Zero-Trust Cosmology principle.
- **Rejection Logic**: If verification fails and the practitioner is heavily corrupted (conflict > 0.5 or effectivePurity < 0.3), the outcome shifts to `.hostile`. Otherwise it shifts to `.failure` and the spirit refuses to manifest. The autopsy records the specific rejection reason.
- **Template Defaults**: Wardens forbid `.graveRobbing`. Prophets require `minimumPurity: 0.6`. Sovereigns forbid `.uncleanSacrifice` and `.falseName`. Guardians forbid `.oathBreaking`. Butchers have no requirements. All other templates have empty requirements.
- **Epoch Override**: Any `Epoch` can define its own `identityRequirements` that override the template defaults. This enables specific canonical manifestations to be stricter or more permissive than their template class.
- **Implication**: The pipeline now enforces the "consequence is content" principle at the deepest level. A practitioner who breaks taboos will find entire categories of spirits closed to them. A brand-new practitioner with Clean Hands can access epochs that a corrupted master cannot. Power comes through relationships and accountability, not stat growth.

### Identity Layer Now Accrues Through Play
- **Decision**: Ritual aftermath now writes the first concrete identity/accountability state back into `PractitionerProfile`. The new `applyRitualConsequences(configuration:result:)` hook runs in both the interactive CLI and `WorldShard` ritual path after `recordRitual`.
- **Rationale**: The verifier layer was structurally correct but too declarative. If taboos and contamination only exist in tests or hand-built profiles, the world is not actually producing the identity it claims to judge.
- **Rules Added**: Mortuary contexts (`burialCave`, `ancestorShrine`, `ossuaryNiche`) without any compensating libation now mark `.graveRobbing`. Corrupted fragments used at high-sanctity sites now mark `.uncleanSacrifice`. Blood or mimic-blood sacrifice at a `topheth` now marks `.tophethPact`. Fragment/site/libation exposure now feeds corpse contagion and, for harsher contexts, direct purity loss.
- **Implication**: Identity/accountability is no longer only a gate. The practitioner's future access begins to emerge from what they actually do in the world. This still needs broader event coverage (`oathBreaking`, `falseName`, faction-granted/revoked tokens), but the layer is now attached to real play.

### Local Single-Player Snapshot Persistence
- **Decision**: Added a typed snapshot boundary in the engine (`PractitionerInventorySnapshot`, `SinglePlayerSnapshot`, `SnapshotStore`) and wired the interactive CLI to `save` and `load` against `gehenna-save.json` in the current working directory.
- **Rationale**: The project needed a real restart boundary before chasing broader server/storage design. A single explicit JSON snapshot is the smallest useful persistence cut that proves world, journal, practitioner, and Codex state can survive process death together.
- **Scope**: The saved snapshot includes `WorldSimulation` (including the append-only journal), `WorldClock`, practitioner profile, Codex, sites, inventory, NPCs, current site, ritual count, and root identities. `WorldSimulation` and `WorldClock` are now `Codable`.
- **Verification**: Added a dedicated persistence test that round-trips world/journal/profile/inventory state through `SnapshotStore.encode` and `decodeSinglePlayerSnapshot`. Also smoke-tested `swift run gehenna` with scripted `save`, `load`, and `quit`, producing and restoring `gehenna-save.json`.
- **Implication**: Local CLI play can now be resumed cleanly. This is not yet a replay log or server persistence format; it is a typed snapshot. The next persistence work should decide whether shared-world state persists as snapshots, journal replay, or a hybrid.

## Repository Maintenance (Session 2026-04-20)

### GitHub Actions Checkout Updated To v5
- **Decision**: Updated `.github/workflows/ci.yml` from `actions/checkout@v4` to `actions/checkout@v5`.
- **Rationale**: GitHub warned that Node.js 20-based JavaScript actions are deprecated. `checkout@v5` moves the workflow onto the Node 24 runtime line and removes that warning source.
- **Implication**: This addresses the checkout deprecation warnings on both macOS and Linux CI jobs. Any remaining CI failure after this change is a real job failure, not the Node 20 warning.

### macOS CI Now Selects Xcode 16.2
- **Decision**: Added an explicit macOS workflow step to select `/Applications/Xcode_16.2.app` before running `swift test`.
- **Rationale**: The GitHub `macos-14-arm64` runner defaults to Apple Swift 5.10, which cannot build a package with Swift tools version 6.0. The workflow was failing in the macOS `Test` step with `package 'gehenna' is using Swift tools version 6.0.0 but the installed version is 5.10.0`.
- **Implication**: macOS CI should now run under a Swift 6-capable Xcode instead of the runner default. Linux was already green because it uses the `swift:6.0` container.

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
- Rumor spread is site- and faction-weighted, not globally uniform.
- Root identity IDs are deterministic from a widened canonical identity seed, not a thin three-field seed.
- Spirits and epochs verify practitioner identity via IdentityRequirements before manifesting (Stage 11.8).
- Taboos are permanent and cumulative — the world remembers transgressions.
- The Noob Catalyst (cleanHands) is a first-class pipeline concept, not a hack.
- Ritual aftermath, not just test setup, now produces the first taboo and contamination writes.
- A local single-player save boundary now exists via `gehenna-save.json`; journal persistence is no longer only theoretical.

## Architecture Decisions (Session 2026-04-21)

### CLI Modularization
- **Decision**: Split the 1,200-line monolithic `GehennaCLI/main.swift` into `GameSession.swift`, `Commands.swift`, `Display.swift`, and a minimal `main.swift`.
- **Rationale**: The core engine was already separate, but the CLI became too unwieldy to navigate. Grouping state/loop, interactive commands, and display/formatting into separate files lowers the friction for adding new mechanics.
- **Implication**: `main.swift` is now just a top-level script runner. Any new CLI-specific logic should go into the appropriate `extension GameSession` file.

### 0.4.22 Release Polish
- **Decision**: Bumped version to `0.4.22` after validating CLI modularization. Added "Clean Hands" and Taboo reporting to the `profile` command, and an auto-save prompt on `quit`.
- **Rationale**: User-facing consequence (Zero-Trust Cosmology) needs to be diegetic and readable. Auto-save ensures the newly added local persistence boundary actually gets used before exit.
- **Implication**: Next features should build on this stable, modularized foundation, particularly expanding canon and social consequence (rumor chains).

### Rumor Engine Integration
- **Decision**: Replaced the earlier rumor splash logic with a typed rumor engine built around `Rumor`, `RumorLedger`, and `RumorPropagationEvent`. Ritual aftermath now seeds rumors into the ledger; per-tick world advancement propagates them, allows mutated retellings, decays stale entries, and tracks explicit carriers on NPCs.
- **Rationale**: The old site/faction weighting was a useful attenuation rule, but it was not yet a rumor system. The project needed actual social state that could survive beyond the first witnesses, mutate in the telling, and feed back into `WorldDirector` and the CLI.
- **Integration Surface**: `WorldSimulation` now owns `rumorLedger`; `WorldClock` advances rumor propagation/decay; `WorldShard` and the interactive CLI both seed rumors through the same engine hook; `WorldDirector` can render actual carried rumors through `lastHeardRumorID`; NPCs persist carried rumor IDs in snapshots; the CLI exposes a `rumors` / `gossip` command.
- **Polish Decision**: Traders now act as the natural cross-faction bridge during propagation, which prevents village chatter from stalling inside the first witness faction set while keeping faction weighting intact.
- **Verification**: Added focused rumor-engine tests for seeding, blood/mutation typing, propagation growth, mutation forking, decay, NPC carrier state, and backward-compatible snapshot decoding. `swift test` now passes with **96 tests across 21 suites**; `swift build` also passes.
- **Implication**: The next rumor work should move outward, not inward: region-scale rumor ecology, witness/evidence chains, and faction action on rumor history rather than more local CLI-only behavior.

### 0.4.23 Release Bump
- **Decision**: Treat the rumor engine integration as `0.4.23`, not a silent post-`0.4.22` patch.
- **Rationale**: This is a meaningful engine surface change: new persistent rumor types, new CLI command surface, new world/director behavior, new snapshot fields, and new tests. It is too large to hide under an unreleased note.
- **Implication**: Version-bearing surfaces now report `0.4.23` across the engine constant, CLI splash, arena splash, README, world-seed docs, and changelog.

### Rumor Pressure Feeds Regional Suspicion
- **Decision**: `WorldSimulation.tickRumors` now bleeds sustained rumor pressure back into `RegionState.suspicion` before rumor decay runs.
- **Rationale**: The rumor engine and the inquisition system were previously parallel systems. NPCs could become suspicious and hostile, but organized regional suspicion never rose from rumor spread, so `inquisitionTriggered` still depended only on direct ritual entropy. That broke the intended "the village talks itself into a hunt" path.
- **Scope**: This hook is currently limited to the **sole-region prototype path**. Until sites and NPCs carry explicit region ownership, rumor pressure only writes back when `regions.count == 1`. That keeps the current Ridge of Elah simulation causal without inventing fake multi-region routing.
- **Companion Fix**: `seedRitualRumor` no longer overwrites the canonical ledger rumor strength while walking initial hearers. NPCs still hear a reach-scaled rumor, but the ledger keeps the actual rumor strength, which restored stable propagation and mutation behavior.
- **Verification**: Added focused tests proving that rumor carriers raise regional suspicion over time and that a watchful low-stability region can tip into `inquisitionTriggered` from rumor pressure on the following tick. `swift test` now passes with **98 tests across 21 suites**.

## Architecture Decisions (Session 2026-04-23 Polish)

### Explicit Site Suspicion Multipliers
- **Decision**: Removed the `default` fallback in `RitualSite.suspicionMultiplier` and added explicit weights for `.springCaveMouth`, `.ossuaryNiche`, and `.wadiBed`.
- **Rationale**: Prevents new site types from silently receiving untuned default suspicion behavior.
- **Implication**: The compiler will enforce explicitly weighting any new site types added in the future.

### Multi-Region Hardcode Removed
- **Decision**: Added an optional `regionID` to `RitualSite`. `RidgeOfElah.createWorld()` now stamps this onto sites during initialization. `WorldShard` now uses `site.regionID ?? world.regions.keys.first`.
- **Rationale**: The shard was previously assuming only one region existed and pulling the first dictionary key. This prepares the engine for multi-region mapping without breaking the 60+ test cases that build isolated sites without a region.
- **Implication**: When full multi-region play is introduced, sites will correctly route their events and lookups to their parent region.

### 0.4.24 Polish Release
- **Decision**: Bumped version to `0.4.24` and pushed.
- **Rationale**: Captures these two small but structurally important fixes before moving on to larger canon or rumor consequence changes.

## Architecture Decisions (Session 2026-05-04 Expression Layer)

### Expression Engine & 0.4.25 Release
- **Decision**: Integrated the `ExpressionEngine` and `OllamaProvider` using `gemma4:26b` for dynamic narrative rendering. The engine version is now `0.4.25`.
- **Rationale**: Replaces static string responses in Kfar Shalem and ritual aftermaths with a live LLM generation pipeline.
- **Scope**: Includes a three-tier fallback pipeline (Ollama -> Authored Bank -> Fallback), structured constraint packets (`LightExpressionPacket`, `FullExpressionPacket`), and rigid validation (`ExpressionValidator`). The entire interactive CLI was refactored to `async` to support non-blocking LLM calls.
- **Implication**: The simulation remains completely mathematically deterministic (`ResolutionPipeline`); the LLM acts only as a rendering layer, unable to hallucinate game state or break the physics engine. Added `PLAYER_MANUAL.md` to document the playable prototype.

## Architecture Decisions (Session 2026-05-06 Free-Form Chat)

### Free-Form NPC Chat & 0.4.26 Release
- **Decision**: Added free-form `practitionerInput` to `ExpressionPacket` and wired it through the engine, updating the version to `0.4.26`.
- **Rationale**: Allows the player to speak freely to NPCs in the village, relying on the LLM to handle parsing and generate a context-appropriate, diegetic response based on the NPC's interiority and world state.
- **Scope**: Also includes critical stability hardening for the Expression Layer: removing unreliable word counts from prompts, fixing cache hash collisions, enforcing deterministic cache eviction, adding connection timeouts for `OllamaProvider`, and switching validation to strict regex word boundaries.
- **Implication**: Free-form chat is explicitly a **neutral consequence** interaction. The conversation itself has no mechanical side effects on trust or suspicion, strictly enforcing the rule that the Expression Layer renders but never decides truth.

## Architecture Decisions (Session 2026-05-06 Engine Wire-Up)

### CLI Engine Wire-Up & 0.4.27 Release
- **Decision**: Completed a full audit of missing connections between `GehennaCLI` and `GehennaEngine`, wiring all consequence pipelines and bumping the version to `0.4.27`.
- **Rationale**: The engine had rich consequence logic (taboos, contagion, rumor seeding, world entropy, capacity milestones) but the interactive CLI was bypassing it and manually incrementing simple counters.
- **Scope**: `executeRitual` now routes through `profile.recordRitual`, `profile.applyRitualConsequences`, `world.applyRitualEffects`, `world.seedRitualRumor`, and `codex.recordEncounter`. Added diegetic hints for fragment collection via `scavenge` to resolve a progression blocker. The journal is now readable, and NPCs receive recent world events as context for LLM chat generation.
- **Implication**: "Consequence is content" is now fully active in the CLI. The practitioner's actions permanently scar sites, seed rumors that reach the village, and potentially lock them out of certain spirit manifestations via taboo accrual.
