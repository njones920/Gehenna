# Canon Data Roadmap

GEHENNA is not meant to be powered by generic fantasy lore.

The reference canon should become a structured historical dataset for the Iron
Age and Late Bronze Age southern Levant: people, places, burial practices,
ritual technologies, polities, languages, cultic institutions, artifacts,
social roles, trade routes, conflicts, taboos, and underworld concepts.

The current `0.4.22` build is a playable engine seed. Its Ridge of Elah content is a
small vertical slice, not the final canon density.

## Current State

The current canon content includes:

- Five Ridge of Elah sites.
- Starter fragments, artifacts, memory traces, and libations.
- Six named NPCs in Kfar Shalem.
- A small set of root identities and epoch manifestations.
- A compact tag dictionary that can drive ritual resolution and Codex entries.

This is enough to prove the mechanics. It is not enough to make the world feel
like a deep historical simulation.

## Target Canon Shape

The reference canon needs structured data in several layers:

- **Geography**: regions, roads, wadis, caves, tells, villages, shrines, fields,
  borders, burial zones, and contested corridors.
- **Polities and factions**: highland villages, coastal city-states, temple
  households, kin groups, smiths, traders, priests, soldiers, elders, and
  outcasts.
- **Material culture**: bones, pottery, weapons, seals, amulets, cult stands,
  vessels, textiles, tools, inscriptions, and burial goods.
- **Mortuary practice**: primary burial, secondary burial, cave burial, ossuary
  handling, cremation edge cases, ancestor rites, feasts, contagion rules, and
  taboo contexts.
- **Name and language data**: personal names, patronymics, theophoric elements,
  partial inscriptions, language/register hints, and scribal conventions.
- **Cult and cosmology**: Sheol, Rephaim, ancestor veneration, divine silence,
  forbidden necromancy, ritual purity, offerings, authority tokens, and
  region-specific taboos.
- **Historical pressure**: drought, raids, tribute, trade, succession disputes,
  migration, plague, war bands, social collapse, and regional recovery.
- **Source references**: every canon element should eventually carry provenance
  metadata: source type, confidence, period, region, and notes.

## Engine Implications

The tag dictionary is the most important content artifact. A thin tag dictionary
produces generic ghosts. A dense, historically grounded tag dictionary produces
specific people.

Future work should move hard-coded Ridge content toward a compiled canon bundle:

```text
canon/
  regions/
  sites/
  factions/
  artifacts/
  fragments/
  names/
  mortuary_practices/
  ritual_inputs/
  root_identities/
  source_notes/
```

The engine should treat that bundle as authoritative data. The event journal
records what happened; the canon bundle defines what can exist.

## Near-Term Work

1. Define stable canon IDs for sites, fragments, artifacts, NPCs, and root
   identities.
2. Extract Ridge of Elah content from Swift factories into typed canon files.
3. Add provenance fields to canon records.
4. Expand the tag dictionary with historically grounded social roles, death
   contexts, object types, polities, cultic roles, and names.
5. Add validation so missing provenance is visible during canon compilation.
6. Teach the arena to report which historical/canon tags drove major outcomes.

The `0.4.22` build should invite people to clone and play. The next canon milestone
should invite historians, archaeologists, and lore-focused agents to make the
world deeper without weakening the simulation.
