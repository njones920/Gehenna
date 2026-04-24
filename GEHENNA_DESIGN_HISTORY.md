# GEHENNA Design And History

This file reconciles the active v3 Codex with the archived Codex Two document and records how the current implementation should understand them.

It does not replace the active source document. It exists so future collaborators and coding agents can orient quickly without flattening the project's lineage.

## Document Hierarchy

Authoritative design:

- `GEHENNA_CODEX v3.md`

Historical source:

- `docs/archive/GEHENNA_CODEX_TWO.txt`

Working handoff:

- `AGENTS.md`
- `GEHENNA_DEV_MEMORY.md`

Use v3 as the source of truth for design decisions. Use Codex Two only to understand what the design grew from, what language was preserved, and which commitments predate the v3 additions.

## Provenance

Codex Two is the original complete Codex in this repository. It already contains the core GEHENNA thesis:

- a physics engine for ancient cosmology disguised as a game
- the practitioner as an unauthorized operator of cosmic infrastructure
- ritual as compiler
- spirits as specific dead people, not spell effects
- entropy asymmetry
- the Clean Hands Problem
- no visible numbers
- consequence as content
- open engine, official canon, self-hosting, public API
- Ridge of Elah as the vertical-slice proof

The v3 document is the newer, finalized Codex. It preserves the Codex Two spine while regularizing the document into Markdown and adding a significant new design layer around programmatic access, AI-mediated play, and persistent identity/accountability.

Treat v3 as a refinement and extension of Codex Two, not as a repudiation of it.

## Stable Core Across Codex Two And v3

These ideas are invariant. A feature that contradicts them is off-direction.

### GEHENNA Is Not A Conventional RPG

The player is not a chosen one, class build, wizard, or power-scaling hero. They are a practitioner who discovered how to operate a dangerous system.

Power flows through spirits, sites, objects, names, and conditions. The practitioner becomes more capable by understanding the grammar, not by becoming physically stronger.

### Ritual Is A Compiler

A ritual is a program assembled from inputs. The cosmology is the runtime. Resolution is deterministic in principle: same canon, same pre-state, same intent, same entropy envelope, same result.

The player should learn the grammar through observation:

- which fragments point to which identities
- which sites amplify or corrupt outcomes
- how timing and libation change the result space
- how world state alters manifestation
- what kinds of mistakes produce useful danger versus collapse

### The Seven Inputs Matter

The core ritual input model is stable:

- Remains
- Ritual Site
- True Name
- Life Artifact
- Memory Trace
- Libation
- World Timing

Two are mandatory: Remains and Ritual Site. The others are specificity, power, control, and risk modifiers.

### The Dual-Layer Model Matters

Structured properties determine mechanical behavior:

- Era
- Domain
- Affinity
- Integrity
- site state
- practitioner profile
- world state

Narrative tags determine specificity:

- who the dead person was
- how they died
- whom they served, loved, betrayed, or protected
- what culture, trade, god, city, or taboo shaped them
- what the practitioner can eventually learn

The tag dictionary is one of the most important content artifacts in the whole project.

### The World Keeps Score

Every consequential action leaves a record:

- regions destabilize or recover
- sites scar
- spirits remember
- NPCs react
- factions investigate
- the Codex accumulates
- server mythology emerges

Nothing important should disappear just because the player stopped looking.

### The Clean Hands Problem Is Structural

Necromancy is entropy. The practitioner may act carefully, respectfully, or strategically, but they are still disturbing the cosmology.

The game should not moralize. It should record consequences honestly.

### The Unsolvability Principle Is Load-Bearing

Skill controls what appears. Personality controls what it does.

A strong ritual can produce the intended spirit with strong attributes. It cannot guarantee that this person will respond as an obedient tool. Spirits are relationships, not solved problems.

### The Reference Proof Is Ridge Of Elah

Both documents point toward a small vertical slice before large-scale implementation:

- Battlefield Ridge
- Tel Keshet
- Nahal Caves
- Kfar Shalem
- The Burning Ground

The proof is not "do all systems exist as code?" The proof is:

1. A new player summons a useful spirit quickly.
2. The player forms deliberate hypotheses about the grammar.
3. The player perceives world change and connects it to their actions.
4. At least one unscripted moment occurs from systems interacting.

The fourth criterion is the heart of the design.

## What v3 Adds Or Clarifies

v3 is mostly congruent with Codex Two, but it adds material that should shape future architecture.

### Programmatic Access

v3 explicitly embraces mediated play:

- AI advisors
- custom clients
- automation scripts
- AI proxies

This is not a break in the fiction. It completes the fiction. The practitioner is an operator of cosmic infrastructure; a player using tools against the public API is acting in that same ontology.

### Identity As The Structural Precondition

v3 adds the requirement that all consequential action must attach to a persistent practitioner identity.

The identity layer must provide:

- non-repudiation
- uniqueness, subject to server policy
- continuity across clients, sessions, automation, and AI mediation

Without identity continuity, the entropy asymmetry can be bypassed by disposable accounts. With identity continuity, every action compounds onto one Profile, and spirits, NPCs, Sovereigns, and the world can read that history.

### AI-Assisted Play Is A Pentest

v3 reframes AI-assisted play as a test of the design rather than a threat to be banned.

If the Unsolvability Principle is real, an AI can improve mechanical mastery without guaranteeing relational success.

If entropy asymmetry is real, high-volume automated play creates visible contamination and social/cosmological debt.

If identity continuity is real, proxies cannot outrun consequence.

## Current Implementation State

The current Swift package is a useful first implementation of the ritual engine and terminal prototype.

Implemented:

- Swift package with engine library and CLI executable
- ritual DSL / configuration model
- 13-stage resolution pipeline
- deterministic entropy source
- Coherence, Resonance, Conflict
- Apotropaic Rule
- Mutation check
- Spirit model with template, tier, traits, disposition, attributes, and epoch identity
- Region state with entropy asymmetry and threshold checks
- World simulation shell with ticks, propagation, Sebitti, and Mot
- Astragali diagnostic system
- Ritual Autopsy system
- Codex of the Dead model
- Ridge of Elah content
- root identities and epoch manifestations
- Kfar Shalem named NPCs with interiority
- terminal CLI loop
- tests covering core behavior

Partially implemented in the 0.4.20 seed:

- active world autonomy — WorldClock, WorldDirector, site-local state, and bot arena exist; the world acts between commands but does not yet have full cascade or rumor propagation
- event journal — append-only journal with source, severity, site/NPC IDs, tags, and queries by site/tick/severity/tag/NPC; not yet persisted
- site-local state — scarring, traces, suspicion, witness exposure, and disturbance tracking are live; site-local timelines are thin

Not yet implemented, or only skeletal:

- persistence
- rumor engine (seeding exists, no mutation or chains)
- witness system
- taboo shock/cascade system
- clean-channel/noob catalyst system
- spirit persistence after manifestation
- stable canon IDs for root identities
- public API
- identity/accountability layer
- Expression Layer runtime (director uses authored templates only)
- evidence chain
- Oracle Network intake
- networked multiplayer

## Current Design Diagnosis

The implementation has the right skeleton but still feels too command-response. It is closer to a Zork-like prompt loop than to an active world the practitioner happens to inhabit.

That is acceptable for the current phase, but the next milestone should address it directly.

The next design move is not more ritual options. It is world initiative.

The world should be able to act before the prompt returns:

- a villager sees something
- dogs begin barking below the ridge
- a rumor reaches a priest
- a site changes while the player is away
- a spirit lingers longer than expected
- a ritual shock triggers a cascade
- another practitioner, later, inherits the changed state

## Time Model

The desired long-term time model is hybrid.

Use fine ticks for presence:

- ambience
- due events
- local motion
- interruption timing
- active scene updates

Use slower rhythms for routine consequence:

- rumor spread
- social pressure
- NPC schedules
- regional decay and recovery
- long-term spiritual pressure

Use immediate cascades for ruptures:

- taboo sacrifices
- mutations
- Veil tears
- threshold crossings
- faction panic
- Sebitti correction
- Rephaim or Sovereign openings

The world should normally breathe. Under pressure, it should rupture.

## Noob Catalyst Principle

New practitioners with clean hands should be able to trigger profound events, but not because a random roll granted them greatness.

The correct model is catalytic alignment:

- clean Profile
- low contamination
- low prior relational debt
- unscarred or specially loaded site
- rare fragment tag constellation
- rare timing or world state
- taboo ignorance or unusually humble approach
- witness configuration

A master can force some doors open. A novice can sometimes fit through doors that force would close.

This creates rare noob impact without turning GEHENNA into loot-box RNG.

## Taboo Shock Principle

Taboo acts are high-energy inputs. They are not morality buttons.

A novice who performs a taboo sacrifice may change a region because they touched a loaded social and cosmological structure without understanding it.

Taboo consequences should be layered:

- Cosmological: Veil tear, scarring, spirit release, threshold crossing.
- Social: witness panic, rumors, priesthood response, faction hardening.
- Relational: spirits remember, debts form, taboos attach to the practitioner.
- Historical: the event becomes part of the world record.

Witnesses change the event:

- no witness: mostly cosmological
- villager witness: rumor
- priest witness: institution
- practitioner witness: technique
- spirit witness: debt

This is one path by which a new player can affect a server profoundly without being powerful.

## Multiplayer Shape

The scalable version of GEHENNA is a persistent shared cosmology, not a monolithic real-time crowd simulator.

Target shape:

```text
authenticated practitioner intent
  -> regional or site action queue
  -> deterministic resolver
  -> event journal
  -> state update
  -> cascade and routine consumers
  -> interest-filtered client notifications
```

Scale by partitioning ownership:

- regions
- sites
- region clusters
- cosmological layers
- canon instances
- high-load event zones

Cross-region effects should propagate through bounded events, not global recalculation.

The Expression Layer is likely the scaling bottleneck. It must render simulation truth, not decide it.

## Roadmap Interpretation

The roadmap implied by v3 should be interpreted as:

1. Prove the grammar and consequence loop in the CLI.
2. Add local world autonomy.
3. Add event journal and persistence.
4. Add site-local state and rumor/witness systems.
5. Add spirit persistence and relational memory.
6. Add cascade systems for taboo, mutation, Veil, and thresholds.
7. Run the Ridge of Elah proof.
8. Only then expand toward API, multiplayer, richer clients, and visual rendering.

Do not skip directly to a graphical MMORPG. That would risk building the wrong shell around an unproven simulation.

## Preservation Notes

Keep Codex Two archived.

Do not rewrite Codex Two into v3 or delete it. It is useful as historical evidence that the core commitments predate the v3 additions, but it is not implementation authority.

Do not treat this file as a new design authority over v3. This file is a concordance and implementation-facing memory.

If a future v4 Codex appears, update this file to describe the transition rather than silently changing the hierarchy.
