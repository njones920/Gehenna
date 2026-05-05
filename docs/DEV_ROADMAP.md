# GEHENNA: Deep Audit & Development Roadmap

*Audit performed by the Codex CLI sub-agent against `GEHENNA_CODEX v3.md` and `AGENTS.md`.*

## Verdict

The recent changes are directionally true to GEHENNA. CLI modularization supports the "serious prototype interface" goal, and moving NPCs/root identities into JSON via `DataLoader` is exactly the first move toward the Codex's structured-canon model. 

However, the implementation is still a scaffold, not yet a proper canon pipeline, and a few details cut against the project's core principles: silent data fallbacks, force unwraps, repeated global reloads, visible debug numbers, and thin NPC interaction output.

> [!TIP]
> The short version: the project is not drifting into generic fantasy RPG territory, but it is at risk of treating "structured data" as "JSON files" instead of as validated historical canon.

---

## 1. What Aligns Well

- **Structured Canon:** The data direction matches the Codex. v3 says canon files should be structured, typed, and validated. `npcs.json` and `identities.json` are a reasonable first extraction from Swift factories.
- **NPC Interiority:** The NPC content is especially on-mission. `NPCInteriority` and the JSON records give named people interior voices, wounds, wants, private truths, and thresholds, which supports "NPCs should become specific people, not generic content categories" from `AGENTS.md`. 
- **CLI Modularity:** The CLI split is healthy structurally. Moving commands out of a large `main.swift` makes the terminal prototype easier to manage, matching the repo instruction to keep changes aligned with small, testable steps.

---

## 2. Main Risks & Deviations

> [!WARNING]
> **Loader failure degrades the world instead of failing compilation.**
> `DataLoader` catches errors, prints warnings, and returns empty arrays. A missing canon bundle should be a **hard canon failure** in most engine contexts, not a playable world with no NPCs.

> [!WARNING]
> **Engine code prints to stdout.**
> Warning prints currently live in engine content code. The engine should return errors or diagnostics; the CLI Expression Layer decides how to render them.

> [!CAUTION]
> **Convenience accessors force unwrap canon lookups.**
> Hardcoded accessors (`abiGad()`, etc.) reload the bundle and force unwrap matches. This is brittle. If a canonical name changes, the engine crashes instead of surfacing a canon validation error.

- **Ritual resolution ignores session-loaded identities:** Ritual execution reloads `RidgeOfElah.rootIdentities()` instead of using the session's loaded identities.
- **CLI output violates "No Visible Numbers":** Several final-facing commands expose raw counts, percentages, and tier raw values. The Codex states: *"The player reads the world, not a stat sheet."*
- **Village interaction is mechanically thin:** The richer response helpers are not used in `VillageCommands`, leaving interactions feeling command-response.

---

## 3. Development Roadmap

To bring the current scaffold into full compliance with the Codex vision, focus on these sequential steps:

### Phase 1: Canon Pipeline Hardening
1. **Promote `CanonDataLoader` into `CanonBundle`.**
   Create a typed `CanonBundle` containing `npcs`, `rootIdentities`, and later sites/fragments. Load once at startup. Pass that bundle through `GameSession`, `WorldShard`, and arena setup.
2. **Add `CanonValidator`.**
   Start narrow: ensure unique UUIDs, required fields, and enum compatibility. Validate that every epoch trigger tag appears somewhere in the world.
3. **Make canon load failure explicit.**
   Engine APIs should throw or return diagnostics. CLI should render: *"The canon bundle is broken; the world cannot be entered."* 

### Phase 2: Data Migration
4. **Finish the JSON migration in layers.**
   Next extraction order (matching `CANON_DATA_ROADMAP.md`):
   - Sites with stable IDs.
   - Fragments/artifacts/memory traces attached to sites.
   - Tag dictionary records.
   - Source/provenance notes.
   - Voice registers and sensory palette.

### Phase 3: Expression & World Autonomy
5. **Make CLI modularization behavioral.**
   Introduce a small command router type so `GameSession.run()` stops being a central switchboard.
6. **Restore diegetic output.**
   Hide raw numbers behind a `debug` mode. Replace visible values with descriptions in profiles, inventory, rituals, and journals.
7. **Make Kfar Shalem matter.**
   Wire the dialogue responses (`npcGreeting`, `friendlyResponse`, etc.) into `villageMenu`. Add journal entries for meaningful conversations and use thresholds to trigger unsolicited director events.

### Phase 4: Validation
8. **Add tests around the new structure.**
   - Bundled JSON decodes successfully.
   - Ritual resolution uses session-provided identities.
   - Malformed canon fixtures fail validation.
   - Village conversations successfully mutate NPC state and advance world time.
