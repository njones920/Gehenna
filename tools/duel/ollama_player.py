#!/usr/bin/env python3
"""An Ollama model plays GEHENNA through the duel protocol.

Any model on any Ollama host becomes a practitioner: it reads what the
world showed it last turn, replies with exactly one command, and the
duel server does the rest. Small models are legitimate practitioners —
the Heterogeneity Principle in one file.

Usage:
  python3 ollama_player.py --dir <arena>/<PlayerName> \
      --host http://192.168.x.x:11434 --model qwen2.5:14b \
      [--max-turns 30] [--temperature 0.8]
"""
import argparse, json, time, urllib.request
from pathlib import Path

RULES = """You are a practitioner of forbidden necromancy in GEHENNA, an Iron Age Levant simulation, competing against rival practitioners in one shared world. The world keeps score: codex entries (+), warm/bonded spirit relationships (+, built by summoning someone again, respectful talk, libation partings, giving your name), canon your spirits speak (+), spirits still walking with you at the end (+), taboos/entropy/suspicion (-), banishing spirits (-, they remember).

Reply with EXACTLY ONE command per turn, nothing else. Commands:
  look | wait | scavenge | cast | purify | spirits | state | end
  travel N            (0 Battlefield Ridge, 1 Tel Keshet, 2 Nahal Caves, 3 Kfar Shalem village, 4 Burning Ground)
  ritual F lib=water name=<true name if known>     (F = fragment index; needs fragments — scavenge first)
  speak S <what you say to bound spirit S>          (courtesy and promises are remembered; 'my name is X' bonds deeply)
  call R F lib=water                                (re-summon known relationship R with fragment F)
  dismiss S libation | dismiss S banish             (libation parting is respectful; banishing makes enemies)
  invoke <RivalName> S                              (contest a rival's spirit whose true name your codex holds)

Known true names in this land: 'Hiram, son of Dagon' (a Philistine captain, battlefield), 'Maacah' (an Israelite woman, the caves). Speaking a true name over matching remains is the strongest ritual. Check 'state' for your fragments and the tick budget; 'spirits' for who walks with you. Be patient with the dead. Pour libations. Keep your hands clean."""


def ollama_chat(host, model, messages, temperature):
    body = json.dumps({
        "model": model, "messages": messages, "stream": False,
        "options": {"temperature": temperature},
    }).encode()
    req = urllib.request.Request(f"{host}/api/chat", data=body,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=300) as resp:
        return json.load(resp)["message"]["content"].strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True)
    ap.add_argument("--host", default="http://localhost:11434")
    ap.add_argument("--model", required=True)
    ap.add_argument("--max-turns", type=int, default=30)
    ap.add_argument("--temperature", type=float, default=0.8)
    ap.add_argument("--context", default=None,
                    help="optional file appended to the system prompt — match history, coaching, roundtable")
    args = ap.parse_args()

    me = Path(args.dir)
    me.mkdir(parents=True, exist_ok=True)
    rules = RULES
    if args.context:
        rules += "\n\nCONTEXT FROM YOUR PAST MATCHES:\n" + Path(args.context).read_text()
    history = []

    for turn in range(1, args.max_turns + 1):
        messages = [{"role": "system", "content": rules}]
        for past in history[-6:]:
            messages.append({"role": "user", "content": past})
        messages.append({"role": "user", "content": f"Turn {turn}. Your one command:"})

        try:
            raw = ollama_chat(args.host, args.model, messages, args.temperature)
        except Exception as exc:
            print(f"[driver] model call failed ({exc}); waiting instead")
            raw = "wait"
        command = raw.splitlines()[0].strip().strip("`\"'") or "wait"
        print(f"[driver] turn {turn}: {command}", flush=True)
        (me / f"turn_{turn}.cmd").write_text(command)

        out_path = me / f"turn_{turn}.out"
        deadline = time.time() + 900
        while not out_path.exists():
            if time.time() > deadline:
                print("[driver] no response from world; ending")
                return
            time.sleep(1)
        time.sleep(0.3)
        result = out_path.read_text()
        print(result, flush=True)
        history.append(f"You did: {command}\nThe world answered:\n{result}")
        if "record is sealed" in result:
            return

    # Max turns reached: retire formally so the referee is not left
    # waiting on an abandoned seat.
    (me / f"turn_{args.max_turns + 1}.cmd").write_text("end")
    print("[driver] max turns reached — withdrew from the field", flush=True)


if __name__ == "__main__":
    main()
