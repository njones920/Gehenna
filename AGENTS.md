# GEHENNA Agent Instructions

This repo contains the early Swift implementation of GEHENNA, based on the Codex design documents in the repo root.

## Source Of Truth

- `GEHENNA_CODEX v3.md` is the current authoritative design reference.
- `GEHENNA_DESIGN_HISTORY.md` reconciles Codex Two and v3 for implementation context.
- `docs/CANON_DATA_ROADMAP.md` records the historical data gap and the intended canon expansion path.
- `docs/DEPLOYMENT.md` records the SwiftPM/Linux/server deployment direction.
- `docs/archive/GEHENNA_CODEX_TWO.txt` is superseded historical context. Do not use it as implementation authority.
- The current implementation is an engine/CLI prototype, not the full vertical slice.

## Project Direction

GEHENNA is not a conventional fantasy RPG and should not drift toward one. Preserve these commitments:

- Rituals are compiled configurations, not spells.
- Power comes through spirits and relationships, not player stat growth.
- The practitioner is physically vulnerable; mastery is understanding.
- Consequence is content. The world must remember.
- No karma meter, no alignment meter, no visible stat sheet in the final player-facing experience.
- Spirits and NPCs should become specific people, not generic content categories.
- Canon/lore data should be historically grounded and structured; avoid generic fantasy filler.
- The CLI is a serious prototype interface, not just a debug shell.

The near-term priority is world autonomy: the world should act around the practitioner instead of only responding to commands.

## Architecture Preferences

Prefer small, testable steps that move toward:

- Event journal as the source of truth for consequential actions.
- Fine-grained world heartbeat for presence, scheduling, and interruptions.
- Slower consequence rhythms for decay, rumor propagation, faction movement, and regional recovery.
- Immediate cascade handling for shocks: mutations, taboo violations, Veil tears, threshold crossings, faction panic, Sovereign events.
- Site-local persistent state: scarring, local suspicion, active traces, recent events, and witness state.
- Region/site ownership boundaries suitable for future actors or shards.
- Deterministic ritual resolution with replayable inputs, pre-state, seed/envelope, result, and post-effects.
- Expression Layer that renders state but never decides simulation truth.
- SwiftPM portability across macOS development and Linux server targets. Keep Apple-only APIs out of the engine.

Do not rush to graphics, combat, or conventional MMO avatar mechanics before the CLI proves grammar, consequence, and world autonomy.

## Coding Guidelines

- Keep changes aligned with existing Swift package structure.
- Add tests for engine behavior, especially anything touching resolution, world state, event cascades, persistence, or Codex behavior.
- Keep player-facing output diegetic. Debug-only numbers are acceptable only when clearly marked or isolated from final interface paths.
- Prefer typed models and deterministic reducers over ad hoc string logic.
- Preserve reproducibility. If randomness affects a result, the seed or entropy envelope should be recordable.
- Avoid broad rewrites unless an existing abstraction blocks the next milestone.

## Collaboration Notes

- Read `GEHENNA_DEV_MEMORY.md` before making substantial changes.
- Read `GEHENNA_DESIGN_HISTORY.md` when changing product direction, architecture, or anything that interprets the Codex.
- If you introduce a major architectural decision, update `GEHENNA_DEV_MEMORY.md` with the decision, rationale, and next implications.
- If you add a new long-term invariant, update this file.
- Leave the repo in a state where another agent can continue without guessing your intent.
