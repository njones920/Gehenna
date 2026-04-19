# Deployment Direction

GEHENNA is intended to stay SwiftPM-first and server-portable.

The engine should build and run as the same Swift package across:

- local macOS development
- Linux hobby instances
- Linux x86_64 servers
- Linux ARM64 servers
- future production-class ARM64 infrastructure such as AWS Graviton

The current code uses SwiftPM and Foundation only. That is intentional. New
dependencies should preserve Linux compatibility unless there is a clear reason
to isolate them in a platform-specific target.

## Current Verification

Currently verified locally:

- macOS build
- macOS test suite
- macOS `gehenna` CLI
- macOS `gehenna-arena` bot simulation

Configured but not yet proven until the first public GitHub run:

- Linux Swift 6 CI using the official Swift container

Not yet verified:

- Linux ARM64
- AWS Graviton
- long-running server processes
- persistence under restart
- networked multiplayer

Do not claim Graviton or ARM64 production support until the project has a real
CI/deployment path that proves it.

## Platform Principles

- Keep the authoritative simulation in portable Swift.
- Keep platform-specific UI/client code out of `GehennaEngine`.
- Prefer SwiftPM targets over app-project coupling.
- Treat macOS as a development platform, not the only runtime.
- Treat Linux as the default server target.
- Treat ARM64 as a first-class architecture target.
- Keep deterministic simulation logic independent of wall-clock time,
  filesystem layout, locale, and platform-specific randomness.

## Future Server Shape

The production direction is a server-authoritative world:

```text
client or bot intent
  -> network/API adapter
  -> shard actor
  -> deterministic reducer
  -> event journal
  -> persistent state projection
  -> interest-filtered notifications
```

The current `WorldShard` actor and `PlayerCommand` model are the first local
version of that shape. A future TCP/MUD server or HTTP/WebSocket API should
wrap the shard rather than duplicating command logic.

## Graviton Notes

AWS Graviton is a natural production target for the project because the engine
is compiled Swift, the simulation is CPU-sensitive, and Apple Silicon local
development already normalizes ARM64 workflows.

That said, Graviton should be treated as an intended target, not a verified
target, until the repo has:

1. A Linux ARM64 build path.
2. A repeatable deployment script or container image.
3. A persistence backend.
4. A long-running shard process.
5. Smoke tests that run on the deployed host.

The goal is not to lock the project to one cloud. The goal is to keep the
engine portable enough that hobbyists can run small worlds while larger
operators can run much larger, persistent canon instances.
