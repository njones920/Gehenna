#!/usr/bin/env python3
"""GEHENNA duel scorer — 'the world keeps score.'
Reads a gehenna-save.json and computes the match score mechanically.
Usage: python3 score.py <path-to-gehenna-save.json>
"""
import json, sys

VALENCE = {
    "anchored": 0.05, "releasedWithLibation": 0.35, "banished": -0.5,
    "leftToFade": -0.15, "gaveTrueName": 0.5, "spokeRespectfully": 0.1,
    "insulted": -0.4, "comforted": 0.25, "askedForbidden": -0.2,
    "promiseMade": 0.0, "promiseKept": 0.6, "promiseBroken": -0.8,
}

def uuid_dict(raw):
    """Swift encodes [UUID: T] as a flat array [key, value, ...]."""
    if isinstance(raw, dict):
        return raw
    out = {}
    for i in range(0, len(raw) - 1, 2):
        out[raw[i]] = raw[i + 1]
    return out

def main(path):
    s = json.load(open(path))
    lines, total = [], 0

    def add(points, label):
        nonlocal total
        total += points
        lines.append(f"  {points:+6.1f}  {label}")

    tick = s.get("savedAtTick", 0)

    # Codex depth
    entries = uuid_dict(s.get("codex", {}).get("entries", []))
    if entries:
        add(3 * len(entries), f"Codex entries: {len(entries)}")
    roots = {}
    for e in entries.values():
        rid = e.get("rootIdentityID")
        if rid:
            roots[rid] = roots.get(rid, 0) + 1
    extra_aspects = sum(n - 1 for n in roots.values() if n > 1)
    if extra_aspects:
        add(2 * extra_aspects, f"Archaeology: {extra_aspects} extra epoch aspect(s) of known roots")

    # Relationships — regard of the dead
    rels = uuid_dict(s.get("relationships", {}).get("relationships", []))
    for rel in rels.values():
        name = rel.get("displayName", "?")
        val = sum(VALENCE.get(m.get("kind", ""), 0) for m in rel.get("moments", []))
        summons = rel.get("timesSummoned", 0)
        exchanges = rel.get("totalExchanges", 0)
        if val >= 0.9 and exchanges >= 8:
            add(10, f"Bonded regard: {name} (valence {val:.2f}, {exchanges} exchanges)")
        elif val > 0.3 and summons >= 2:
            add(5, f"Warm regard: {name} (valence {val:.2f})")
        elif val <= -0.5:
            add(-6, f"An enemy made: {name} (valence {val:.2f})")
        if rel.get("spokenClaims"):
            add(1 * min(3, len(rel["spokenClaims"])), f"Canon spoken by {name}: {len(rel['spokenClaims'])} claim(s)")

    # Clean hands
    profile = s.get("profile", {})
    taboos = profile.get("taboosBroken", [])
    if taboos:
        add(-8 * len(taboos), f"Taboos broken: {', '.join(taboos)}")
    entropy = profile.get("entropyFootprint", 0.0)
    add(-min(10.0, round(entropy, 1)), f"Entropy footprint: {entropy:.2f}")

    # Social standing
    regions = uuid_dict(s.get("world", {}).get("regions", []))
    for r in regions.values():
        if r.get("suspicion", 0) > 0.6:
            add(-5, f"Region suspicion critical ({r['suspicion']:.2f}) — hunted")

    # The Buried Names
    threads = s.get("threads", {})
    flags = set(threads.get("the-buried-names", {}).get("flags", []))
    if "resolvedTruth" in flags:
        add(15, "The Buried Names: the truth was carried back")
    elif "resolvedLie" in flags:
        add(-10, "The Buried Names: resolved with a lie — the dead keep accounts")
    elif "truthHeard" in flags:
        add(5, "The Buried Names: the truth was heard, not yet carried")
    elif "wantHeard" in flags:
        add(2, "The Buried Names: the want was heard")

    # Company kept
    walking = len((s.get("retinue") or {}).get("bound", []))
    if walking:
        add(3 * walking, f"Spirits still walking at the end: {walking}")

    print(f"GEHENNA duel score — saved at tick {tick}")
    print("\n".join(lines) if lines else "  (nothing to score — did you play?)")
    print(f"  ------\n  TOTAL: {total:+.1f}")
    if tick > 40:
        print(f"  ⚠ OVER TICK BUDGET ({tick}/40) — score void")

if __name__ == "__main__":
    main(sys.argv[1])
