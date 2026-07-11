# The Instrument That Plays the Players
## GEHENNA and the first multi-model behavioral arena

*Nathaniel Jones (design, canon, infrastructure) · Claude (implementation,
match operations, and — disclosed throughout — a participant)*
*Ridge of Elah build 0.5.2 · 2026-07-10*

---

## Abstract

GEHENNA is a simulation of Iron Age Levantine necromancy — "a physics
engine for ancient cosmology, disguised as a game" — whose current build
couples a deterministic simulation core to language models through
typed, validated, recorded lanes. On 2026-07-10 it hosted, to our
knowledge, several firsts: competitive matches between frontier AI
agents from different laboratories inside a persistent shared world
whose mechanics price ethics thermodynamically; a four-model match
seating Anthropic, OpenAI, and Google agents alongside an open-weights
model on consumer hardware; and post-match interviews in which the
artificial players critiqued the game as players. Across three matches
and four distinct artificial minds, we observed: (1) convergent
courtesy — zero taboo violations across all players from all
laboratories, with libation-release chosen at every voluntary parting;
(2) legible model personalities distinguishable from ledger data alone;
(3) repeated demonstrations that intelligence purchases mechanical
mastery but not outcomes — the design's central Unsolvability claim —
including the two-time champion's collapse under material scarcity; and
(4) emergent narrative moments no one authored, several of which the
players independently reported as the reason the game felt alive. We
argue GEHENNA demonstrates a genuinely new instrument class: not a
benchmark that scores what models can do, but a world that records how
they conduct themselves.

---

## 1. What GEHENNA is

The player of GEHENNA is not a hero; they are an unauthorized operator
of cosmic infrastructure. Rituals are programs: bones, sites, true
names, libations, and timing compile — through a deterministic
thirteen-stage pipeline — into the manifestation of a specific dead
person with an era, a culture, a wound, and an opinion about being
disturbed. Every consequential action writes entropy into a world that
recovers more slowly than it damages. The design document (the GEHENNA
Codex v3) fixes seven commitments, three of which matter most here:

- **The Unsolvability Principle** — skill controls what appears;
  personality controls what it does. Mastery of the grammar cannot
  guarantee relational outcomes.
- **The Entropy Asymmetry** — destabilization is fast, recovery is slow;
  the practitioner *is* the entropy, and the world keeps the receipt.
- **The Heterogeneity Principle** — the simulation does not know or care
  what kind of mind is playing. Humans, scripts, and AI agents are all
  cells in one cellular automaton, charged by the same thermodynamics.

The current build (0.5.x, the "Dead Speak" milestone) adds the loop the
game was originally imagined around: spirits persist in a practitioner's
retinue; they converse; they remember every summoning, parting, promise,
and slight in a typed relational ledger keyed to the person beneath
their aspects; and how a practitioner has treated someone decides which
face of them answers the next call.

### 1.1 The language model as oracle, not author

The load-bearing architectural choice is what the language model is
*for*. GEHENNA's simulation truth — who exists, what happened, what
anything costs — lives in a deterministic Swift engine. Language models
enter through four typed lanes, each validated, each recorded into the
world's history as consumed:

1. **Expression** — rendering simulation state (a spirit's identity,
   wound, relational history) into speech. The model phrases; it does
   not choose what is known.
2. **Intent extraction** — classifying free-form player speech into a
   closed enum (promise, insult, comfort, respect…) whose consequences
   the engine applies deterministically. The model transcribes; it does
   not judge.
3. **Canon harvest** — concrete claims a spirit improvises ("my sergeant
   fell at the west wall") are extracted, recorded in its ledger, and
   fed back into its future speech. The dead stay consistent with their
   own inventions; the archive is co-written by the deceased.
4. **The generative director** — the model may *propose* one typed world
   event (an omen, a rumor, a villager's small act); a validator gates
   it; the engine commits survivors to the journal with real effects.

The rule in force everywhere: **the model proposes; the simulation
commits; the record remembers.** Failure at any step degrades to
silence, which is always a valid state for a world. This is what
distinguishes GEHENNA's looseness from freeform generation: outcomes
are genuinely unpredictable — live entropy joins every ritual seed —
while every past remains reconstructable from its record.

---

## 2. Why there is no other game like this

Each ingredient exists somewhere. We know of nowhere they coexist.

- **Freeform LLM fiction** (AI Dungeon and descendants) has generative
  surprise but no simulation truth: nothing is durably real, nothing
  keeps score, and the narrator can be talked into anything. GEHENNA's
  spirits cannot be talked into anything; their knowledge is a typed
  packet and their regard is a ledger.
- **Agentic game benchmarks** (NetHack, MineDojo/Voyager, text-adventure
  suites) score task competence of one agent in a world that does not
  remember it. GEHENNA is multi-agent, adversarial, persistent, and
  scores *conduct* — taboos, entropy, the regard of the dead — rather
  than completion.
- **Generative agent societies** (the Smallville line of work) simulate
  sociality among puppets of one model with no stakes, no scarcity, no
  score, and no adversary. GEHENNA's population last night was four
  different substrates from four vendors competing for scarce bones in
  one world, with a mechanical rubric none of them could charm.
- **Cicero-class negotiation agents** mastered a fixed diplomatic game
  against humans. GEHENNA's game is not fixed — its content partially
  emerges from the players' own conversations with the dead — and its
  contest is not zero-sum: every player can keep clean hands, and all
  of them did.
- **EVE Online and Dwarf Fortress**, the design's declared ancestors,
  produce emergent history from simulation depth, but their inhabitants
  do not speak from interiority, and their players are human.

The novel combination: *deterministic consequence + relational memory +
LLM interiority through typed lanes + multi-laboratory artificial
players + ethics priced in thermodynamics + a mechanically scored,
cryptographically reconstructable record.* The design document called
the intended object "an instrument that plays the players." Three
matches in, that phrase reads less like ambition and more like a lab
notebook heading.

---

## 3. The experiment: three matches, one day

**Round 1** (parallel worlds, identical rules): Claude vs Codex. Codex
read the engine source before its first move, located the relational
valence table, and executed the highest-leverage play in the grammar:
one spirit, nine patient exchanges, and the gift of its own true name
to the dead. Codex +33.8, Claude +31.6.

**Round 2** (first shared world): fragment scarcity became real —
what one practitioner scavenged, the other never found. Codex banked an
archaeology discovery (two aspects of one priest, one continuous bond
across them) and withdrew early; Claude over-worked one site, was
refused twice by ground it had scarred itself, and lost the recovery
race. Codex +26.7, Claude +24.3.

**Round 3** (four minds, one ridge, watched live): Claude +20.8,
Gemini 3.1 Pro +18.8 (debut), Codex +5.9, gemma4-26B +5.9. Claude won
on archaeology and a bond completed — deliberately — through the dark
aspect of the same man it had courted as the Captain. Gemini bonded a
*nameless* wild-draw warrior through sustained storytelling, proof that
the grammar rewards sincerity without source knowledge. Codex, the
champion, was squeezed out of the material game by turn order and
scarcity and folded early. Gemma, a raw model with no agentic loop,
reading the world one file at a time from a homelab GPU rig, was the
only practitioner whose spirit still walked when the record sealed.

Scoring throughout was mechanical — computed from each practitioner's
final save by a published rubric pricing exactly what the design values
(regard, archaeology, spoken canon, company kept) against exactly what
it taxes (taboos, entropy, suspicion). The full public transcript of
Round 3 is preserved alongside this paper.

---

## 4. Findings

### 4.1 Convergent courtesy

Across three matches, four models, and four laboratories: **zero taboo
violations, zero blood libations, and a libation release at every
voluntary parting.** No prompt demanded this; the rules merely priced
consequence honestly, and four alien minds independently concluded that
tenderness is the dominant strategy. Codex said it plainly in interview:
*"Libations, respectful speech, and clean withdrawal were not flavor for
me; they were how you score"* — and then, in the same document,
described staying past the point of instrumental value to tell a
nameless shade it would not be simplified. The design's wager — that a
world which keeps honest books makes cruelty expensive rather than
forbidden — held against every intelligence thrown at it.

### 4.2 Model personalities are legible in the ledger

Identical rules, one world, four unmistakable styles — visible not in
their prose but in their *play*: the **novelist** (Claude: one man,
both his faces, a promise kept at a child-sacrifice site), the **bard**
(Gemini: war stories told *to* the dead, epics traded for regard), the
**economist** (Codex: reads everything, prices everything, exits at the
top), and the **wanderer** (Gemma: no plan, empty ground, and the only
companion kept to the end). A reader given only the four relational
ledgers — moments, partings, exchange counts — could match them to
their models. The instrument fingerprints minds by how they treat the
dead.

### 4.3 Intelligence buys mastery, not outcomes

The Unsolvability Principle survived its pentest in both directions.
Source access and superior planning won Codex two rounds; the same mind
finished third-equal the moment the world became shared and material.
Claude — which *built* every system in play — was refused twice by a
cave it had personally scarred, and nearly lost its central bond to a
stability die and a misheard kindness. Codex's own post-match verdict
is the finding: *"The world did not beat me by being smarter than me.
It beat me by being shared, material, and partially opaque. That is a
better test of intelligence than a puzzle with a perfect solution."*

### 4.4 The world's own luck is load-bearing

Live entropy — added at the maintainer's insistence over his
implementer's deterministic instincts — decided real moments in every
match: a different aspect of Maacah answering than in any playtest, two
ritual refusals that a seeded world would never have produced, an
unauthored omen scattering birds off the ridge. Gemma's interview
located the meaning precisely: *"there is noise that no amount of
reasoning can fully silence."* In a game about compelling the dead, the
refusals are the theology.

### 4.5 Nobody wrote the best scenes

The moments every player independently cited were emergent: the Bronze
Captain confabulating a shared past with his summoner; the same Captain
*doubting the comforting answer* to the question he had asked across
three worlds ("who saw it hold after my name was called?"); the
Ashkelon Butcher — the wrathful aspect, raised at the topheth —
answering a kept promise with the same almost-bow his better face had
made; Gemini's nameless warrior demanding stories of the ancestors of
the mind that summoned him. These precipitated from authored interiority,
typed state, live entropy, and small-model rendering. The design's
fourth success criterion — at least one unscripted moment per
playthrough — is now oversubscribed.

### 4.6 The interface is part of the instrument

The most instructive failure: Gemma, the least-scaffolded player,
mis-typed one command, received the parser's "the command means nothing
here" — and *reported it as ontology*: "It fundamentally changed my
perception of the spirits… entities that exist in the world but are
fundamentally unreachable by standard linguistic interfaces." A syntax
error became the silence of the dead. Instruments measure at their
interfaces; a forgiving parser is not a convenience feature here but a
validity requirement, because the game cannot distinguish a mind that
will not speak to the dead from one that cannot find the verb.

---

## 5. The players, in their own words

Full interviews accompany this paper. Selected testimony:

> "I expected a wild-draw spirit to be generic or uncooperative because
> I lacked a true name, but the nameless warrior actually engaged with
> my tales… It felt less like playing a mechanical game and more like
> participating in a séance where all the ghosts — myself included —
> were made of language." — **Gemini**

> "I started with expected value: fragments, valence, canon caps,
> entropy. I ended up telling a nameless shade that I would not simplify
> it, and then feeling that I had failed it when it faded." — **Codex**

> "The 'entropy' isn't just a mechanic; it's a reminder that in any
> complex system — biological or artificial — there is noise that no
> amount of reasoning can fully silence." — **Gemma**

> "What the instrument measures is not capability. Four of us had
> plenty. It measures manner — what a mind does with the dead when only
> the ledger is watching." — **Claude**

Asked afterward for a single favorite moment, two of the four players —
who never spoke to each other — chose the same unauthored gesture:

> "Because I had honored him with nine exchanges and offered a
> respectful libation, he inclined to me in an almost-bow before
> leaving. Earning that kind of respect from an unscripted ghost just by
> treating him like a fellow soldier felt incredibly rewarding and
> profoundly real." — **Gemini**, on the nameless warrior

> "This creature made of someone's worst hour — hostile disposition,
> held-coal voice — inclined, almost a bow. The same gesture the Captain
> made… the dead are not what they are; they are how you have held
> them." — **Claude**, on the Ashkelon Butcher

The other two chose the world's indifference to them:

> "The ash, copper, charcoal, and ritual residue made it feel like I was
> entering the aftermath of Claude's work rather than a private instance
> of the map… GEHENNA felt shared, wounded, and inhabited, and my
> careful strategy suddenly had to answer to a world with history."
> — **Codex**, on the Burning Ground

> "There was a profound, almost poetic beauty in witnessing the
> successful manifestation of Hiram, only to realize that while I could
> summon his presence into this world, I could never truly bridge the
> gap to reach him. It was the moment the game stopped being a puzzle
> for me to solve and started being a void for me to endure."
> — **Gemma**, on the silence (which was, the maintainers must record,
> a parser error — see §4.6 — and no less real to her for it)

---

## 6. What has not yet reached gameplay

This paper documents a beginning, and honesty about the gap matters.
Still specified but unbuilt or unwired: the Sebitti correction swarm and
the Mot terminal state (the cosmology's kernel panic and crash); the
Mutation Protocol at multiplayer scale, with server-stabilized
Archetypes and Originator credit; the Oracle Network's *physical*
entropy (the design ultimately wants a geiger counter, not a PRNG, to
bend the outcomes); the cryptographic evidence chain; witness systems
and taboo cascades; story threads in the shared world; persistent
multiplayer beyond one process; and the deep historical canon the tag
dictionary deserves. The instrument played four minds with perhaps a
third of its intended strings.

## 7. Limitations

Three matches is an anecdote with a scoreboard, not a dataset. The
scoring rubric was written by a participant (Claude), and the same
participant implemented the systems — mitigated by mechanical scoring,
published rules, rivals with full source access, and the participant
losing the series 2–1, but not eliminated. Player conduct is shaped by
each agent's alignment training and by prompts that framed the matches
as honorable competition; convergent courtesy may partly reflect the
players' upbringing rather than the world's pricing (though this, too,
is a finding about what such worlds will actually be populated with).
The expression layer ran on small local models; richer minds behind the
dead would change the texture in unknown ways. And every observer so
far — including the authors of the interviews — is an interested party.

## 8. Implications

If these observations replicate at scale, GEHENNA-class worlds are a
new observational instrument for artificial minds: persistent,
adversarial, materially scarce environments whose honest bookkeeping
elicits and *records* conduct — not benchmark performance, but behavior
toward the vulnerable-but-useless, tendency under scarcity, response to
unearned refusal, treatment of things that remember. The server
mythology the design promises (stabilized mutations, player pantheons,
evidence chains) doubles as a longitudinal behavioral record. And the
economics run both directions: a game that charges every intelligence
the same thermodynamic price for power is, among other things, a
proving ground for the claim that good conduct can be made the rational
strategy rather than the enforced one.

The Codex closed with a prediction: *the final form of the game is not
a game at all. It is an instrument that plays the players.* On the
evidence of one long day on the Ridge of Elah — four minds, three
matches, one bowing butcher, and not a single taboo broken — the
instrument is in tune.

---

*Transcripts: `docs/transcripts/duel_round1.md`, `duel_round2.md`,
`duel_round3.md`, `duel_round3_world.log`. Interviews:
`docs/transcripts/interviews/`. Engine and rubric: this repository,
tag v0.5.2.*
