# Changelog

## 0.4.20 - 420 World Seed

Initial public seed build for the Ridge of Elah terminal prototype.

### Added

- 420 build README with quickstart, first ritual path, live/not-live scope, and document reading order.
- `.gitignore` for SwiftPM/Xcode/local macOS output.
- MIT `LICENSE`, trademark/canon notice, and GitHub repository metadata for public release.
- Archived the superseded Codex Two text document under `docs/archive`.
- WorldClock as the single owner of time advancement.
- WorldDirector v1 for unsolicited world narration.
- Site-local state: scarring, local suspicion, witness exposure, active traces, visit/ritual ticks, and event counts.
- Expanded append-only journal metadata and queries.
- NPC temporal drift and approach/flee posture.
- Design handoff files for future agents and collaborators.
- README quickstart for clone/build/play/dev.
- `gehenna-arena` bot arena executable: headless shared-world simulation with multiple bot practitioners.
- `WorldShard` actor: shared world authority for multiplayer command serialization.
- `PlayerCommand` enum: non-interactive command model for bot and server use.
- `PractitionerSession`: per-player state separation from shared world state.
- Canon data roadmap documenting the gap between the current Ridge seed and the intended historically grounded reference canon.
- GitHub Actions CI workflow for macOS and Linux Swift builds.
- Deployment direction documenting SwiftPM portability, Linux server targets, and future ARM64/Graviton verification.
- `art/` directory with early reference images and reusable concept-art direction for future agents.

### Changed

- Engine version is now `0.4.20`; Codex version is `3.0`.
- CLI splash now identifies the 420 Ridge of Elah build.
- `look`, `cast`, and NPC conversation advance local world time.
- Site trace fading and director event gating now use deterministic local scheduling instead of process randomness.
- Shared-world ritual journal entries now include practitioner attribution without double-counting rituals.
- README now labels Ridge content as a prototype canon seed, not a complete historical canon.
- README now describes Linux as an expected SwiftPM target, not a macOS-only requirement.

### Verified

- `swift test` passes with the current Swift Testing suite.
- `swift run gehenna-arena` smoke-tested with multiple bot counts.
- `swift run gehenna` smoke-tested through the documented Hiram/Bronze Captain first ritual path.
