#!/usr/bin/env python3
"""GEHENNA duel spectator — watch a shared-world match from any terminal.

Usage:  python3 watch.py <arena-dir> [--interval 1.0]

Reads <arena>/status.json (the server's heartbeat) and <arena>/world.log
(the public record) and repaints. Ctrl-C to stop watching; the match
does not care whether it is observed.
"""
import argparse, json, sys, time
from pathlib import Path

RESET, DIM, BOLD = "\033[0m", "\033[2m", "\033[1m"
PLAYER_COLORS = ["\033[36m", "\033[35m", "\033[33m", "\033[32m"]  # cyan, magenta, yellow, green
EVENT, OMEN = "\033[37m", "\033[33m"

FLAME = ["▁", "▂", "▄", "▆", "█"]


def flame_bar(stability):
    """A spirit's presence as a five-lamp row."""
    lit = max(0, min(5, round(stability * 5)))
    return "\033[33m" + FLAME[4] * lit + DIM + "▁" * (5 - lit) + RESET


def color_for(name, names):
    try:
        return PLAYER_COLORS[names.index(name) % len(PLAYER_COLORS)]
    except ValueError:
        return RESET


def render(arena):
    status_path = arena / "status.json"
    log_path = arena / "world.log"

    sys.stdout.write("\033[2J\033[H")
    if not status_path.exists():
        print(f"{DIM}Waiting for the world to begin... ({status_path}){RESET}")
        return

    try:
        status = json.loads(status_path.read_text())
    except (json.JSONDecodeError, OSError):
        return  # mid-write; catch it next repaint

    tick, budget = status.get("tick", 0), status.get("budget", 0)
    names = [p["name"] for p in status.get("players", [])]
    filled = int((tick / budget) * 30) if budget else 0
    bar = "▓" * min(30, filled) + DIM + "░" * max(0, 30 - filled) + RESET

    print(f"{BOLD}╔═ G E H E N N A ═ the world keeps score ═╗{RESET}")
    print(f"  tick {BOLD}{tick}{RESET}/{budget}  {bar}  mode: {status.get('mode', '?')}\n")

    for player in status.get("players", []):
        c = color_for(player["name"], names)
        state = f"{DIM}(withdrawn){RESET}" if player.get("finished") else ""
        print(f" {c}{BOLD}◈ {player['name']}{RESET} ─ {player.get('site', '?')} {state}")
        spirits = player.get("spirits", [])
        if spirits:
            for spirit in spirits:
                print(f"    walking: {spirit['name']}  {flame_bar(spirit.get('stability', 0))}"
                      f"  {DIM}{spirit.get('disposition', '')}, {spirit.get('exchanges', 0)} exchanges{RESET}")
        else:
            print(f"    {DIM}no one walks with them{RESET}")
        print(f"    {DIM}codex {player.get('codexEntries', 0)} · fragments {player.get('fragments', 0)}"
              f" · libations {player.get('libations', 0)} · taboos {player.get('taboos', 0)}"
              f" · entropy {player.get('entropy', 0):.2f}{RESET}")
        print(f"    {c}› {player.get('lastCommand', '—')[:76]}{RESET}\n")

    print(f"{BOLD}── the record ──{RESET}")
    if log_path.exists():
        lines = log_path.read_text().splitlines()[-14:]
        for line in lines:
            c = EVENT
            for name in names:
                if f"[{name}]" in line:
                    c = color_for(name, names)
            if "◇" in line:
                c = OMEN
            print(f" {c}{line[:110]}{RESET}")
    sys.stdout.flush()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("arena", nargs="?", default="arena")
    ap.add_argument("--interval", type=float, default=1.0)
    args = ap.parse_args()
    arena = Path(args.arena)
    try:
        while True:
            render(arena)
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print(RESET + "\nYou stop watching. The world continues without you.")


if __name__ == "__main__":
    main()
