# Milestone 0.5 — The Dead Speak

*Proposal. Restores the original loop: compile spirits, keep them, talk to them, watch their language evolve.*

Status: draft for review
Target: series of releases 0.4.28 → 0.5.0
Authority: subordinate to `GEHENNA_CODEX v3.md`; where this proposal bends a rule, the bend is named explicitly.

---

## 1. Why

The 0.4.27 build is a correct engine and a hollow game. Playtesting verdict: "a big soulless engine." The diagnosis, verified in code:

1. **You cannot talk to the dead.** After manifestation, a spirit produces one `spiritSpeech` line (`RitualCommands.swift`), is archived to the Codex, and is gone. The Codex Part II scene — sitting with a summoned spirit and asking questions — is unimplemented. NPCs received free-form chat; spirits, the point of the game, did not.
2. **There is no collection.** "You anchor the spirit to your will" decrements `summonerCapacity` and drops the `Spirit` value. No session or snapshot tracks a manifested spirit. Nothing persists, nothing is *kept*, nothing evolves.
3. **Conversation is explicitly consequence-free.** `VillageCommands.swift`: "Free-form chat — neutral interaction. No trust/suspicion change." Talking is mechanically meaningless, and the player can feel it.
4. **There is nothing to want.** No mystery, no debt, no need that necromancy answers. A grammar with no question to ask it.

The original concept — predating the Codex — was: **compile/collect spirits, Pokémon-like, and watch their language evolve free-form in a living world.** The Codex kept the compiler and lost the collection. Codex 5.3 already blesses the comparison ("In Pokémon, the thing you caught is definitely the thing…"); this milestone builds the loop the comparison implies, in Gehenna's own terms:

| Pokémon | GEHENNA |
| --- | --- |
| Pokédex | Codex of the Dead (exists) |
| Catching | First-contact ritual (exists) |
| Party | **The Retinue** (new) |
| Recall by ball | **Calling by name** (new) |
| Forms/evolutions | Epoch manifestations (exists) + **the evolving voice** (new) |
| Friendship stat | **Spirit relationship memory** (new) |

The difference that keeps it GEHENNA: spirits are relationships, not possessions. You never own the dead. You know them, and they know you back — and that mutual knowledge is the collection.

Everything below is game-making, not architecture. The engine is done enough.

---

## 2. System 1 — The Retinue (spirit persistence)

**The rule:** a successfully anchored spirit stays manifested until its Stability reaches zero or the practitioner dismisses it. Anchored spirits travel with the practitioner, persist across commands, survive save/load, and are present in the world.

### Engine

- New type `BoundSpirit: Codable, Sendable` — wraps `Spirit` plus binding state: `anchoredAtTick`, `originSiteID`, `exchangeCount` (conversation turns this manifestation).
- `GameSession` (and later `PractitionerSession` for the arena) holds `var retinue: [BoundSpirit]`, capped by `profile.summonerCapacity`.
- `WorldClock` tick advancement decays each bound spirit's `currentStability` (the existing `decayStability` hook, currently unused in the CLI). Decay rate scales with regional Corruption and co-presence Conflict, per Codex 5.6. At zero, the spirit returns to Sheol — narrated by the Director, recorded in the journal, and remembered (see System 3).
- `SinglePlayerSnapshot` gains `retinue: [BoundSpirit]` with backward-compatible decoding (same pattern as the rumor fields).

### Dismissal is a choice with texture

New `dismiss` command with manner, replacing silent expiry as the only exit:

- **Release with libation** — costs an inventory libation; recorded as a respectful parting. The strongest positive relational moment available.
- **Banish** — immediate, free, abrupt. Recorded as a slight. Spiteful/prideful spirits hold it.
- **Let fade** — do nothing; stability runs out. Neutral-to-negative depending on personality (a loyal guardian left to dissolve mid-watch remembers).

### Co-presence becomes real

With ≥2 spirits in the retinue, the existing co-presence rules (Reinforcement/Interference/Dominance from Codex 5.6) get their first live surface: interference accelerates stability decay, and the Director narrates friction ("The captain will not look at the mourner. The air between them hums.").

---

## 3. System 2 — Spirit Conversation

**The rule:** while a spirit is manifested you can speak with it, free-form, through the same Expression pipeline NPCs use — but the spirit's packet is built from who they are: identity, epoch, era, tags, personality, disposition, and relationship history.

### CLI

- New `speak` command (menu when multiple spirits are bound). Free-form input loop, same shape as village chat.
- Each exchange advances the WorldClock **and** costs a small amount of the spirit's Stability. Talking to the dead is holding a door open. You cannot chat forever; ask what matters. This makes conversation itself a resource decision, which is the game's idiom.

### Packet assembly (engine)

Extend the existing `FullExpressionPacket` path to spirits:

- `entityType: .spirit`, `registerKey` resolved from `voice_registers.json` — spirit registers to be authored per culture × template × disposition (see §7).
- `knownFacts` assembled deterministically from: tag constellation, era, epoch identity, root-identity authored facts (`identities.json`), and — for `witness`/`warden` templates — journal events at their origin site. What a spirit can tell you is simulation truth; the LLM only phrases it.
- `forbiddenTopics` from taboo tags and epoch (`The Silenced Devotee` does not speak of what silenced her — until threshold conditions are met).
- Relationship history fields from System 3.
- `interiorVoice`/`privateTruth`/`wound`/`unsatisfiedWant` — currently NPC-only — get authored equivalents on root identities. The eight existing identities each receive an interiority block per epoch.

### The knowledge economy

Spirits are the game's information system. A witness saw things. A scribe read things. A warden guards things. `attributes.knowledge` gates how much of the assembled `knownFacts` enters the packet — a diminished shade knows fragments of its own life; a Rephaim knows the shape of the age. This gives collection a *purpose* beyond completion: you collect the dead because the dead know things (see System 5).

---

## 4. System 3 — The Evolving Voice (relationship memory)

This is the heart of the milestone and the original vision: the same spirit sounds different at the tenth summoning than at the first, because of what has passed between you.

### Engine truth (deterministic)

New `SpiritRelationship: Codable` keyed by `rootIdentityID` (falling back to spirit identity for rootless spirits), owned by a `RelationshipLedger` on the practitioner profile:

- `timesSummoned`, `firstSummonTick`, `lastSummonTick`
- `moments: [RelationalMoment]` — an append-only, typed record: `.spokeRespectfully`, `.saidPlease`, `.gaveTrueName`, `.promiseMade(topic)`, `.promiseKept/.promiseBroken`, `.banished`, `.releasedWithLibation`, `.leftToFade`, `.askedForbidden(topic)`, `.foughtBesideThem`, `.summonedAsButcherEpoch` — each with tick and valence.
- `familiarity: FamiliarityStage` computed from moments: `stranger → named → acquainted → bonded`, with a parallel souring track `wary → cold → hostile`. Deterministic function of the moment record. Personality modulates thresholds (a `loyal` spirit bonds faster; a `resentful` one may never).

The ledger is simulation truth. The LLM never writes to it. This is "Expression renders, never decides" kept intact while the voice still evolves.

### Rendered evolution (Expression Layer)

- `registerKey` gains a familiarity suffix; `voice_registers.json` gets authored register *variants per stage*. A stranger-stage Philistine captain is formal, wary, addresses you as "necromancer." A bonded-stage one is dry, familiar, uses the name you gave him — and only if you gave it (see below).
- The most recent and most heavily weighted `moments` are injected as concrete `knownFacts` ("the practitioner poured wine at my departure, last time"). Small local models render concrete facts far better than abstract vibes — this is also the quality mitigation for gemma-class models.
- Authored-line fallbacks per stage in `authored_lines.json`, so the relationship reads even when Ollama is down.

### Giving your true name

New conversational act: the practitioner may give a spirit their true name. Mechanically: a strong bonding moment, a large familiarity accelerant — and a durable liability. A spirit that holds your name can be made to testify (Codex 8.2 influence actions, future multiplayer), and a hostile spirit holding your name deepens rumor damage if it manifests unbound. Trust as risk. This is the Unsolvability Principle given a lever.

### Calling by name (re-summoning)

New ritual path `call` alongside the full `ritual` flow: summon a spirit already in your Codex using its known name and your relationship instead of a full fragment assembly.

- Requires: Codex entry with `knownName`, at least one matching fragment in inventory, a site.
- Coherence bonus derived from familiarity stage; the relationship *is* the coherence. Bonded spirits come reliably; hostile ones may answer wrong — or answer eager.
- The manifested epoch is influenced by relationship valence: repeatedly banishing Hiram then calling him again risks the Butcher answering instead of the Captain. Epochs stop being random forms and become *moods of the relationship*.

First contact stays expensive and uncertain (catching). Calling is cheap and relational (recall). That asymmetry is the collection loop.

---

## 5. System 4 — Talk Has Consequences (typed intent extraction)

**The bend, named:** free-form chat is currently defined as consequence-free to protect "Expression renders, never decides." That protection over-shot: it made conversation meaningless. The fix preserves the rule exactly:

- After each player utterance (spirit or NPC chat), a second constrained LLM pass classifies the input into a small closed enum — `ConversationalIntent`: `.promise(topic)`, `.insult`, `.plea`, `.askForbidden(topic)`, `.revealPractitionerStatus`, `.giveTrueName`, `.askAbout(topic)`, `.threaten`, `.comfort`, `.none`.
- The **engine** applies deterministic consequences per intent: relational moments (System 3), NPC trust/suspicion deltas, rumor seeds (revealing practitioner status to the wrong villager seeds a rumor through the existing `RumorLedger`), journal entries.
- Classification failure or ambiguity → `.none` → no consequence. Fail-safe, never fail-weird. The classifier prompt returns bare JSON against a schema; malformed output is discarded.
- The LLM parses player intent into the same typed command space everything else uses. It decides nothing; it transcribes. Simulation truth stays deterministic and replayable (intent, not prose, enters the journal).

This retroactively gives village chat stakes, and it is the mechanism by which promises to the dead become promises the world enforces.

---

## 6. System 5 — The First Want

One authored thread that gives a new player a reason to compile anyone at all. Not a quest: no quest log, no marker, no reward screen. A want, discovered in conversation, tracked in the journal, answerable only through the dead.

**Sketch (canon details are Nate's call):** Devorah the herbalist — whose authored interiority already includes a suppressed practitioner past — recognizes what the player is becoming. Once trust crosses her threshold, she asks, obliquely, about **Maacah** ("The Mother Who Did Not Return," "Keeper of the Figurines," "The Silenced Devotee" — already in `identities.json`): what actually happened to her, and whether she rests. The player must locate the right fragments (a household figurine; an ossuary trace at Nahal), compile Maacah, earn enough of her voice to hear the truth — the Silenced Devotee epoch will not speak of it; another epoch might — and then decide what to carry back to Devorah, and whether to carry it truthfully.

- Implemented as a minimal `StoryThread` state machine: stages advance on observable predicates (trust threshold, Codex contains Maacah, specific `askAbout` intents, epoch encountered) — no scripting engine, no dialogue trees. All existing systems, pointed at one person.
- Branches produce consequences through existing machinery: truth strengthens Devorah's trust and opens her practitioner knowledge (a mentor surface); a comforting lie is a `.promiseBroken`-class moment if Maacah's spirit learns of it; showing Devorah the manifested Maacah is the high-risk, high-bond path — and a witnessed ritual, with everything that entails.
- Exit test for the thread: a new player who talks to villagers finds the want within ~30 minutes and understands that the answer is under the ground.

---

## 7. Canon work in this milestone

Scoped to what the systems above need — not the full density pass:

- **Spirit voice registers**: culture × template × disposition × familiarity-stage variants in `voice_registers.json`. Eight root identities get per-epoch interiority blocks (interior voice, private truth, wound, want, threshold) in `identities.json`.
- **Authored line banks** per familiarity stage and for load-bearing beats: first anchoring, a bonded spirit's return, a hostile named spirit answering a call, Maacah thread beats.
- **Tag dictionary**: only additions the thread and forbidden-topic system require.

The full historical-density pass (CANON_DATA_ROADMAP) stays queued behind the proof.

---

## 8. Engineering notes

- **New engine types:** `BoundSpirit`, `RelationalMoment`, `SpiritRelationship`, `RelationshipLedger`, `FamiliarityStage`, `ConversationalIntent`, `StoryThread`. All `Codable + Sendable`, snapshot-persisted with backward-compatible decoding.
- **Determinism:** familiarity computation, moment application, call-by-name coherence bonuses, and thread predicates are pure functions of recorded state — replayable, journal-friendly. LLM output never enters simulation state; intents (typed) do, prose does not.
- **Both surfaces:** engine hooks land in `WorldShard`/`PractitionerSession` as well as the CLI, so arena bots exercise retinue decay and relationship accrual (bots don't converse; they still accrue dismissal/summon moments). Keeps single-player and shared-world paths aligned, per repo convention.
- **Tests:** relationship accrual and stage transitions; personality-modulated thresholds; call-by-name epoch steering; dismissal moment recording; retinue stability decay and snapshot round-trip; intent classifier fallback on malformed output; thread predicate transitions. Target: every new public engine behavior has a focused test, consistent with the existing suite.
- **Model quality risk:** the evolving voice leans on small local models. Mitigations: concrete-fact packet injection (§4), authored register variants doing the tonal heavy lifting, per-stage authored fallbacks, and the existing validator. The design must read even with Ollama absent.

---

## 9. Phases

Each phase is releasable and independently playable. Version each; land 0.5.0 when the loop closes.

1. **0.4.28 — The Retinue.** BoundSpirit, persistence, tick decay, `dismiss` with manner, co-presence decay, snapshot migration. No LLM work. *Playable change: spirits stay.*
2. **0.4.29 — The Dead Speak.** `speak` command, spirit packets, knowledge assembly, spirit registers (stranger stage only). *Playable change: the Part II cave scene exists.*
3. **0.4.30 — The Dead Remember.** RelationshipLedger, moments, familiarity stages, per-stage registers, `call` by name, true-name giving, epoch steering. *Playable change: the tenth summoning sounds different from the first.*
4. **0.4.31 — Talk Matters.** Intent extraction wired into spirit and NPC chat; promises, revelations, rumor seeds. *Playable change: words have weight.*
5. **0.4.32 — The First Want.** Maacah/Devorah thread, thread-specific canon, authored beats. *Playable change: there is a reason to do any of this.*
6. **0.5.0 — The Proof.** Re-run Ridge of Elah against Codex Part XI's four criteria, Nate playing, with the Unscripted Moment Log. Tune, then tag.

## 10. Out of scope

Multiplayer/server, public API, Oracle Network, evidence chain, new regions, combat work, graphics, and the full canon density pass. All deferred until the proof says the core loop produces feeling.

## 11. Exit criteria

Codex XI's four, plus two specific to this milestone:

5. Re-summoning a known spirit feels like meeting someone again, not re-rolling a template. (Playtest judgment: Nate's.)
6. A tester can name, unprompted, one spirit they *like* and one they are *wary of* — and say why in terms of things that happened, not stats.

If 5 and 6 fail with all systems built, the problem is canon voice quality, and the next milestone is authored content, not code.
