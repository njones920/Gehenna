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

### Changed

- Engine version is now `0.4.20`; Codex version is `3.0`.
- CLI splash now identifies the 420 Ridge of Elah build.
- `look`, `cast`, and NPC conversation advance local world time.
- Site trace fading and director event gating now use deterministic local scheduling instead of process randomness.

### Verified

- `swift test` passes with the current Swift Testing suite.
- `swift run gehenna` smoke-tested through the documented Hiram/Bronze Captain first ritual path.
