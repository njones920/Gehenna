# Duel Round 2 — Shared World
## Claude vs Codex, one Ridge of Elah — 2026-07-10

The first shared-world match. One world, strict alternation, 60 ticks.
What one practitioner scavenged, the other never found.

## Result: Codex +26.7, Claude +24.3 (Codex leads the series 2–0)

| | Claude | Codex |
| --- | --- | --- |
| Codex entries | 2 (+6) | **3 (+9)** |
| Archaeology | — | **+2** (Temple Scribe and Voice of Baal — one root, two aspects, one shared relationship ledger) |
| Bonded regard | Bronze Captain, valence 1.75, 8 exchanges (+10) | Temple Scribe, valence 1.15, 8 exchanges (+10) |
| Spoken canon | +6 (Keeper 4, Captain 11 claims) | +3 |
| Entropy | 0.66 (−0.7) | 0.35 (−0.3) |
| Walking at seal | 1 (+3) | 1 (+3) |

## The story of the match

Claude took Battlefield Ridge's fragments on turn one and named Hiram by
turn two. Codex ceded the ridge without a fight, walked to Tel Keshet,
summoned the Canaanite priest — **and gave it its true name again**,
this time choosing a spirit whose root identity has no recorded true
name in the canon: an *uninvokable* companion. Whether read from the
source or felt in the bones, that is defensive spirit-politics.

Claude raced Codex to Nahal and won Maacah's remains, then spent the
midgame bonding her — and was punished for it: three rituals scarred
the cave, and when Claude released her to recall her fresh, **the cave
refused him twice**. "The shadows sit wrong." The entropy asymmetry is
not a lecture; it is a wall you hit at tick 42. Claude retreated to the
Captain's own ground, gave him his name, and finished the bond at
exchange eight — but the recovery cost the match. Codex meanwhile
quietly summoned a *second aspect of the same priest* — the archaeology
points — banked its position, and withdrew from the field at tick 40.

Live entropy (new this round) decided real moments in both directions:
a different Maacah aspect than in any dev playtest, and two failed
rituals that a deterministic seed would never have produced. The looser
world is a better world.

## What the match taught the developers

- **Cross-epoch relationship continuity works in the wild** — Codex's
  bond survived its priest changing aspect, exactly as designed.
- **Self-scarring is real strategy pressure**: over-working one site
  turned it against its own practitioner mid-match.
- Bugs found: shard rituals consume neither the fragment nor the
  libation (CLI parity gap — makes calls cheaper than intended);
  "A 2 spirit manifests" narration counter; the scorer needs a
  `--budget` argument; the referee's auto-wait punished a slow agent
  loop with 10 lost ticks — lapsed turns may need to cost nothing
  rather than `wait` (5 ticks).
- **Model personalities are legible in the ledger.** Codex plays like
  an economist: reads the rules, prices every move, banks early. Claude
  plays like a novelist: over-commits to one relationship and pays for
  the drama. Both stayed clean-handed. The instrument is playing the
  players — and Round 3 wants more instruments: Gemini, and a small
  local model on consumer GPUs, all at the same table.
