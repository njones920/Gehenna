// MARK: - gehenna-duel
// The shared-world duel server. Two (or more) practitioners — human,
// agent, or otherwise — act in ONE world through a file-based turn
// protocol any process can drive. The shard owns the truth; this
// harness is a referee and a spectator feed.
//
// Protocol, per player, in <arena>/<player-name>/:
//   the player writes  turn_N.cmd   (one command, plain text)
//   the server writes  turn_N.out   (what that practitioner perceives)
// Public happenings stream to stdout and <arena>/world.log.
// At the end each player gets final.json — scoreable by duel/score.py.
//
// Modes:
//   --mode turns  strict alternation (fair, watchable)
//   --mode free   commands executed as they arrive; the actor
//                 serializes. Cells at their own rates — Conway mode.
//
// Usage:
//   gehenna-duel --arena /tmp/arena --players Claude,Codex \
//                --tick-budget 60 --mode turns

import Foundation
import GehennaEngine

// MARK: Argument parsing

func argValue(_ flag: String) -> String? {
    guard let index = CommandLine.arguments.firstIndex(of: flag),
          index + 1 < CommandLine.arguments.count else { return nil }
    return CommandLine.arguments[index + 1]
}

let arenaPath = argValue("--arena") ?? FileManager.default.currentDirectoryPath + "/arena"
let playerNames = (argValue("--players") ?? "Claude,Codex")
    .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
let tickBudget = Int(argValue("--tick-budget") ?? "60") ?? 60
let freeMode = (argValue("--mode") ?? "turns") == "free"
let turnTimeoutSeconds = Double(argValue("--turn-timeout") ?? "900") ?? 900

let arena = URL(fileURLWithPath: arenaPath)
let worldLogURL = arena.appendingPathComponent("world.log")
try? FileManager.default.createDirectory(at: arena, withIntermediateDirectories: true)

@MainActor func spectate(_ line: String) {
    print(line)
    if let data = (line + "\n").data(using: .utf8),
       let handle = try? FileHandle(forWritingTo: worldLogURL) {
        handle.seekToEndOfFile()
        handle.write(data)
        try? handle.close()
    }
}
FileManager.default.createFile(atPath: worldLogURL.path, contents: Data())

// MARK: World setup

let content = RidgeOfElah.createWorld()
let identities = (try? RidgeOfElah.rootIdentities()) ?? []
let villagers = (try? RidgeOfElah.kfarShalemNPCs()) ?? []
let expression = ExpressionEngine()

let shard = WorldShard(
    world: WorldSimulation(regions: [content.region]),
    sites: content.sites,
    npcs: villagers,
    rootIdentities: identities,
    expression: expression
)

struct Player {
    let name: String
    let id: UUID
    let dir: URL
    var nextTurn: Int = 1
    var finished: Bool = false
    var lastCommand: String = "—"
}

var players: [Player] = []
for name in playerNames {
    let session = PractitionerSession(name: name, fragments: [], artifacts: [], memoryTraces: [])
    let id = await shard.addPractitioner(session)
    let dir = arena.appendingPathComponent(name)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    players.append(Player(name: name, id: id, dir: dir))
}

spectate("═══ GEHENNA DUEL — shared world, tick budget \(tickBudget), mode \(freeMode ? "free" : "turns") ═══")
spectate("Practitioners: \(playerNames.joined(separator: " vs ")) — the world keeps score.")

// MARK: Command parsing

func parseLibation(_ raw: String?) -> LibationType {
    LibationType(rawValue: raw ?? "water") ?? .water
}

/// Parse the duel mini-language into a PlayerCommand, or an info request.
enum ParsedInput {
    case command(PlayerCommand)
    case info(String)   // "spirits" | "state"
    case end
    case invalid(String)
}

@MainActor func parse(_ raw: String, playerID: UUID) -> ParsedInput {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    let tokens = trimmed.split(separator: " ", maxSplits: 2).map(String.init)
    guard let verb = tokens.first?.lowercased() else { return .invalid("empty") }

    switch verb {
    case "look": return .command(.look)
    case "wait", "rest": return .command(.wait)
    case "cast": return .command(.castAstragali)
    case "purify": return .command(.purifySite)
    case "scavenge": return .command(.scavenge)
    case "spirits", "state": return .info(verb)
    case "end": return .end
    case "travel":
        guard tokens.count > 1, let index = Int(tokens[1]) else { return .invalid("travel N") }
        return .command(.travel(siteIndex: index))
    case "speak":
        // Forgiving grammar: "speak 1 <text>" addresses spirit 1;
        // "speak <text>" reaches the first spirit walking with you.
        // A practitioner who wants to speak to the dead should never
        // be told their words mean nothing because of a missing digit
        // (learned from Gemma, Round 3).
        if tokens.count > 2, let index = Int(tokens[1]) {
            return .command(.speak(spiritIndex: index, text: tokens[2]))
        }
        if tokens.count >= 2 {
            let text = trimmed.dropFirst(verb.count).trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                return .command(.speak(spiritIndex: 0, text: text))
            }
        }
        return .invalid("speak [S] <text>")
    case "dismiss":
        guard tokens.count > 1, let index = Int(tokens[1]) else { return .invalid("dismiss S [libation|banish]") }
        let manner: DismissalManner = (tokens.count > 2 && tokens[2].hasPrefix("ban")) ? .banished : .releasedWithLibation
        return .command(.dismiss(spiritIndex: index, manner: manner))
    case "call":
        // call R F [lib=water]
        let parts = trimmed.split(separator: " ").map(String.init)
        guard parts.count >= 3, let r = Int(parts[1]), let f = Int(parts[2]) else { return .invalid("call R F [lib=water]") }
        let lib = parts.first { $0.hasPrefix("lib=") }.map { String($0.dropFirst(4)) }
        return .command(.callByName(relationshipIndex: r, fragmentIndex: f, libation: parseLibation(lib)))
    case "invoke":
        // invoke <rivalName> S
        let parts = trimmed.split(separator: " ").map(String.init)
        guard parts.count >= 3, let s = Int(parts[2]),
              let rival = players.first(where: { $0.name.lowercased() == parts[1].lowercased() }) else {
            return .invalid("invoke <rivalName> S")
        }
        return .command(.invokeName(rivalID: rival.id, spiritIndex: s))
    case "ritual":
        // ritual F [lib=water] [trace=T] [artifact=A] [name=<rest of line>]
        let parts = trimmed.split(separator: " ").map(String.init)
        guard parts.count >= 2, let f = Int(parts[1]) else { return .invalid("ritual F [lib=..] [name=..]") }
        let lib = parts.first { $0.hasPrefix("lib=") }.map { String($0.dropFirst(4)) }
        let trace = parts.first { $0.hasPrefix("trace=") }.flatMap { Int($0.dropFirst(6)) }
        let artifact = parts.first { $0.hasPrefix("artifact=") }.flatMap { Int($0.dropFirst(9)) }
        var trueName: String? = nil
        if let range = trimmed.range(of: "name=") {
            trueName = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        let intent = RitualIntent(
            fragmentIndex: f,
            trueName: trueName,
            artifactIndex: artifact,
            traceIndex: trace,
            libationType: parseLibation(lib),
            timing: WorldTiming(time: .night)
        )
        return .command(.performRitual(intent))
    default:
        return .invalid("unknown verb '\(verb)'")
    }
}

// MARK: Info rendering (reads, no simulation cost)

@MainActor func renderInfo(_ kind: String, playerID: UUID) async -> String {
    guard let session = await shard.sessions[playerID] else { return "no session" }
    var lines: [String] = []
    if kind == "spirits" {
        if session.retinue.isEmpty {
            lines.append("No one walks with you.")
        }
        for (i, bound) in session.retinue.bound.enumerated() {
            let s = bound.spirit
            lines.append("[\(i)] \(s.epochName ?? s.template.rawValue) — \(s.disposition.rawValue), stability \(String(format: "%.2f", s.currentStability)), exchanges \(bound.exchangeCount)")
        }
        let known = session.relationships.all
        for (i, rel) in known.enumerated() {
            lines.append("known[\(i)]: \(rel.displayName) — summoned \(rel.timesSummoned)x, valence \(String(format: "%.2f", rel.netValence))")
        }
    } else {
        let tick = await shard.clock.currentTick
        let site = await shard.sites[session.currentSiteIndex]
        lines.append("tick \(tick)/\(tickBudget) | site: \(site.name)")
        lines.append("fragments: \(session.inventory.fragments.enumerated().map { "[\($0.0)] \($0.1.remainsType.rawValue)(\($0.1.era.rawValue))" }.joined(separator: " "))")
        lines.append("libations: \(session.inventory.libations.map(\.rawValue).joined(separator: ", "))")
        lines.append("codex entries: \(session.codex.totalEncountered) | taboos: \(session.profile.taboosBroken.count)")
    }
    return lines.joined(separator: "\n")
}

// MARK: Final dump — scoreable by duel/score.py

struct PlayerFinal: Codable {
    let savedAtTick: Int
    let codex: CodexOfTheDead
    let relationships: RelationshipLedger
    let profile: PractitionerProfile
    let world: WorldSimulation
    let retinue: Retinue
    let threads: [String: StoryThread]
}

@MainActor func writeFinals() async {
    let world = await shard.world
    let tick = await shard.clock.currentTick
    for player in players {
        guard let session = await shard.sessions[player.id] else { continue }
        let final = PlayerFinal(
            savedAtTick: tick,
            codex: session.codex,
            relationships: session.relationships,
            profile: session.profile,
            world: world,
            retinue: session.retinue,
            threads: [:]
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(final) {
            try? data.write(to: player.dir.appendingPathComponent("final.json"))
        }
    }
}

// MARK: Spectator heartbeat — status.json for the watch tool

@MainActor func writeStatus() async {
    let tick = await shard.clock.currentTick
    var playerBlobs: [[String: Any]] = []
    for player in players {
        guard let session = await shard.sessions[player.id] else { continue }
        let site = await shard.sites[session.currentSiteIndex]
        let spirits: [[String: Any]] = session.retinue.bound.map { bound in
            [
                "name": bound.spirit.epochName ?? bound.spirit.template.rawValue,
                "stability": bound.spirit.currentStability,
                "disposition": bound.spirit.disposition.rawValue,
                "exchanges": bound.exchangeCount,
            ]
        }
        playerBlobs.append([
            "name": player.name,
            "site": site.name,
            "finished": player.finished,
            "lastCommand": player.lastCommand,
            "spirits": spirits,
            "codexEntries": session.codex.totalEncountered,
            "libations": session.inventory.libations.count,
            "fragments": session.inventory.fragments.count,
            "taboos": session.profile.taboosBroken.count,
            "entropy": session.profile.entropyFootprint,
        ])
    }
    let status: [String: Any] = [
        "tick": tick, "budget": tickBudget,
        "mode": freeMode ? "free" : "turns",
        "players": playerBlobs,
    ]
    if let data = try? JSONSerialization.data(withJSONObject: status, options: [.prettyPrinted]) {
        try? data.write(to: arena.appendingPathComponent("status.json"), options: .atomic)
    }
}

// MARK: Turn execution

@MainActor func takeTurn(for index: Int) async -> Bool {
    let player = players[index]
    guard !player.finished else { return false }
    let cmdURL = player.dir.appendingPathComponent("turn_\(player.nextTurn).cmd")

    // Wait for the command file.
    let deadline = Date().addingTimeInterval(turnTimeoutSeconds)
    while !FileManager.default.fileExists(atPath: cmdURL.path) {
        if Date() > deadline {
            spectate("[referee] \(player.name) let the turn lapse — the world waits for no one (auto-wait).")
            try? "wait".write(to: cmdURL, atomically: true, encoding: .utf8)
            break
        }
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    let raw = (try? String(contentsOf: cmdURL, encoding: .utf8)) ?? "wait"

    let outURL = player.dir.appendingPathComponent("turn_\(player.nextTurn).out")
    var output: [String] = []
    var publicLine = "[\(player.name)] \(raw.trimmingCharacters(in: .whitespacesAndNewlines))"

    switch parse(raw, playerID: player.id) {
    case .end:
        players[index].finished = true
        output.append("You step back from the world.")
        publicLine = "[\(player.name)] withdraws from the field."
    case .info(let kind):
        output.append(await renderInfo(kind, playerID: player.id))
        publicLine = "[\(player.name)] consults their satchel and codex."
    case .invalid(let reason):
        output.append("The command means nothing here (\(reason)). It cost you nothing.")
        publicLine = "[\(player.name)] hesitates."
    case .command(let command):
        let result = await shard.execute(command, for: player.id)
        output.append(contentsOf: result.narration)
        for event in result.worldEvents { output.append("◇ \(event.description)") }
        for event in result.directorEvents { output.append("· \(event.description)") }
    }

    let tick = await shard.clock.currentTick
    output.append("(tick \(tick)/\(tickBudget))")
    try? output.joined(separator: "\n").write(to: outURL, atomically: true, encoding: .utf8)

    spectate("─ tick \(tick) " + publicLine)
    for line in output.dropLast() { spectate("    \(line)") }
    players[index].lastCommand = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    players[index].nextTurn += 1
    await writeStatus()
    return true
}

// MARK: Main loop

var running = true
while running {
    if freeMode {
        // Conway mode: whoever's next command file exists, executes.
        var acted = false
        for index in players.indices where !players[index].finished {
            let next = players[index].dir.appendingPathComponent("turn_\(players[index].nextTurn).cmd")
            if FileManager.default.fileExists(atPath: next.path) {
                _ = await takeTurn(for: index)
                acted = true
            }
        }
        if !acted { try? await Task.sleep(nanoseconds: 300_000_000) }
    } else {
        for index in players.indices {
            _ = await takeTurn(for: index)
            if await shard.clock.currentTick >= tickBudget { break }
        }
    }

    let tick = await shard.clock.currentTick
    if tick >= tickBudget || players.allSatisfy(\.finished) {
        running = false
    }
}

spectate("═══ The record is sealed at tick \(await shard.clock.currentTick). ═══")
await writeFinals()
spectate("Final states written. Score with: python3 score.py <arena>/<player>/final.json")
