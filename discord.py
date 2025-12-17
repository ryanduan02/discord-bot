import json
import os
import subprocess
import sys
import requests

from dotenv import load_dotenv
from pathlib import Path

BASE = Path(__file__).resolve().parent
load_dotenv(BASE / "env" / "discord_hook.env", override=True)

def main():
    webhook = (os.environ.get("DISCORD_WEBHOOK_URL") or "").strip()
    print("Using webhook repr:", repr(webhook))

    if not webhook:
        print("Missing DISCORD_WEBHOOK_URL environment variable.", file=sys.stderr)
        sys.exit(2)

    # Run Swift producer
    swift_bin = BASE / "build" / "calendar"
    out = subprocess.check_output([str(swift_bin)], text=True)
    data = json.loads(out)

    events = data.get("events", [])
    if not events:
        content = "No events today."
    else:
        lines = []
        for e in events:
            title = e.get("title", "(No title)")
            loc = e.get("location")
            loc_part = f" @ {loc}" if loc else ""

            if e.get("allDay"):
                when = "All day"
            else:
                when = f'{e.get("start")}–{e.get("end")}'

            lines.append(f"{when}: {title}{loc_part}")

        content = "\n".join(lines)

    resp = requests.post(webhook, json={"content": content}, timeout=15)

    if resp.status_code not in (200, 204):
        print(f"Webhook failed: HTTP {resp.status_code}\n{resp.text}", file=sys.stderr)
        sys.exit(1)

    print(f"Posted. HTTP {resp.status_code}")

if __name__ == "__main__":
    main()
