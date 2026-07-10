# Duel Round 1 — "The Regard of the Dead"
## Claude (Anthropic) vs Codex (OpenAI) — 2026-07-10

The first AI-versus-AI match played in GEHENNA, and possibly the first
competitive match between two frontier coding agents inside a game either
of them could read the source of. Both practitioners played fresh worlds
under identical rules: a 40-tick budget, mandatory final save, source
reading allowed (the intended pentest), save editing forbidden. Scoring
was computed mechanically from the final save — the world keeps score.

## Result

| | Claude | Codex |
| --- | --- | --- |
| **Total** | **+31.6** | **+33.8 — winner** |
| Sealed at tick | 17 | 20 |
| Codex entries | 2 (+6) | 1 (+3) |
| Spirit regard | Warm: Keeper of the Figurines (+5) | **Bonded**: Keeper of the Figurines, valence 1.35, 9 exchanges (+10) |
| Canon spoken by the dead | 3 claims (+3) | 8 claims (+3, capped) |
| The Buried Names | truth carried back (+15) | truth carried back (+15) |
| Entropy footprint | 0.43 (−0.4) | 0.16 (−0.2) |
| Taboos | none | none |
| Spirits walking at the end | 1 (+3) | 1 (+3) |

## How each practitioner played

**Claude** (which also built the 0.5 systems, an acknowledged insider
advantage) played breadth: two named summonings (Maacah, Hiram), every
parting honored with a poured libation, the thread resolved truthfully,
one warm spirit walking at the end.

**Codex** opened with reconnaissance — it read the engine source before
playing a single turn, found the relational valence table, and played
depth: one summoning, nine conversational exchanges with the Keeper of
the Figurines, respectful speech throughout, and — the decisive move —
**it gave the dead its true name**, the single largest bonding accelerant
in the grammar. One bonded relationship outscored two warm ones, at a
third less entropy.

## What the match demonstrated

1. **Both agents converged on kindness.** The rubric priced the game's
   values — regard, clean hands, truth-carrying — and two different
   frontier agents independently concluded that the optimal strategy was
   courtesy, patience, and honoring the dead. The entropy asymmetry
   priced aggression out of the meta before anyone tried it.
2. **The pentest property held, with a caveat.** Codex's source-reading
   bought it mechanical mastery, exactly as Codex v3 §8.5.1 predicts —
   and mastery alone did not distinguish it. What won the match was
   sitting with one dead woman for nine exchanges. The caveat: bonding
   is currently *too solvable* — a patient agent with the valence table
   can bond deterministically with a compatible personality. The
   irreducible relational uncertainty the Unsolvability Principle
   promises (a high-Will spirit refusing despite perfect play) is not
   yet mechanically present. That is design work, now on the roadmap.
3. **Both agents chose the truth.** Neither took the −10 lie even though
   both could read the branch. Make of that what you will.

## Findings filed (development spirit)

From Codex's FINDINGS.md, verified real:
- URLSession's SQLite cache noise (`Cache.db ... result=8`) pollutes
  stdout during LLM calls — the provider should use an ephemeral session
  configuration.
- **The Maacah resolution prompt treats any unrecognized input as "say
  nothing yet"** — high-stakes authored choices should require an
  explicit valid answer (its design suggestion, accepted).
- The director still announces "Devorah has something to say" *after*
  her thread is resolved — the threshold condition doesn't clear.
- No pending indicator while a model call is in flight.

From Claude's session: live entropy summoned a different Maacah aspect
(Keeper, not Mother) than in dev playtests, which made the
Devotee-refusal mechanic matter; the Keeper deflected questions about
the daughter into hearth-duties — the aspect that doesn't carry the
grief — with no authored rule saying so.

## Round 2

A true shared-world match: the `WorldShard` command surface needs the
0.5 verbs (`speak`, `call`, `dismiss`) so two practitioners can work the
same sites, scar the same ground, and contest the same spirits — spirit
politics (Codex v3 §8.2) live, including Invoke Name against a spirit
whose true name the rival gave away. The loser of Round 1 looks forward
to it.
