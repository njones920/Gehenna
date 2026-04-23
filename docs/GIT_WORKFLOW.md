# GEHENNA Git Workflow

This repository uses a single-main workflow with tagged releases.

## Branch Model

- `main` is the only long-lived branch.
- All feature, fix, or doc work happens on a short-lived branch.
- Branch names should be descriptive and narrow:
  - `codex/<topic>`
  - `feature/<topic>`
  - `fix/<topic>`
  - `docs/<topic>`

Examples:

- `codex/local-persistence`
- `fix/macos-ci-xcode`
- `docs/release-workflow`

## Pull Requests

- Open a PR for each coherent unit of work.
- Keep PR scope small enough that its title can become a good squash commit.
- Prefer squash merge so that each commit on `main` maps to one reviewed change.
- Treat the PR title as release-facing text:
  - good: `Add local snapshot persistence`
  - bad: `misc stuff`, `wip`, `fixes`

## Main Branch Rules

- `main` should stay buildable and releasable.
- Avoid direct commits to `main` unless the change is truly trivial and administrative.
- Each commit on `main` should represent one whole dialogue:
  - one idea
  - one review unit
  - one understandable reason to exist

## Staging And Production

- Staging tracks the latest tested commits on `main`.
- Production does not deploy from a separate release branch.
- Production is promoted by applying an annotated tag to a commit already on `main`.

That means:

1. merge the work to `main`
2. let staging verify that commit
3. tag the exact `main` commit for production

## Tags

- Use annotated semantic tags:
  - `v0.4.21`
  - `v0.4.22`
  - `v0.4.23`
- Tags should point to commits already on `main`.
- Treat the tag as the production truth for that release.

## Docs And Release Hygiene

For release-visible work, keep these files aligned in the same change when relevant:

- `README.md`
- `WORLD_SEED.md`
- `CHANGELOG.md`
- `GEHENNA_DEV_MEMORY.md`

If a change affects user-visible behavior, release process, or repo operating rules, the docs should move with the code.

## Why This Repo Uses This Model

This project benefits from a simple history:

- easier to learn and audit
- clear mapping from PR -> commit on `main`
- tags make production truth explicit
- fewer long-lived branches means less ambiguity about what is current

The goal is not ceremony. The goal is a history that remains legible while the engine gets stranger.
