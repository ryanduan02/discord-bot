# discord-bot

This is a small macOS utility that reads today's events from the Appple Calendar and posts a plain-text summary to a Discord channel via a webhook.

**Components**
- `calendar.swift`: a Swift CLI that queries macOS Calendar (EventKit) for today's events and emits compact JSON.
- `discord.py`: a Python script that runs the Swift producer, formats events for human-readable output (Eastern Time), and posts to a Discord webhook.
- `env/discord_hook.env`: environment file used by `discord.py` to load `DISCORD_WEBHOOK_URL`.
- `build/calendar`: the compiled Swift producer binary (not checked in). The Python script expects this binary at `build/calendar`.

**Requirements**
- macOS (uses EventKit for Calendar access).
- Swift toolchain (to compile `calendar.swift` with EventKit).
- Python 3.10+ (the code uses modern typing and `zoneinfo`).
- Python packages: `requests`, `python-dotenv`.

Quick Python dependency install:

```bash
python3 -m pip install --user requests python-dotenv
```

**Build the Swift producer**
1. Ensure you have the Swift toolchain installed (Xcode or Swift from swift.org).
2. From the repository root run:

```bash
mkdir -p build
swiftc -O -o build/calendar calendar.swift -framework EventKit
chmod +x build/calendar
```

Notes:
- The Swift binary uses EventKit and will prompt (via the system) for Calendar access the first time it runs. Grant Calendar permission in System Settings > Privacy & Security > Calendars if prompted.

**Configure the webhook**
- Add your Discord webhook URL to `env/discord_hook.env` like:

```env
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/your_webhook_id/your_webhook_token"
```

The Python script (`discord.py`) loads that file automatically using `python-dotenv`.

**Run manually**
1. Build `build/calendar` (see above).
2. Make sure `env/discord_hook.env` contains a valid webhook URL.
3. Run:

```bash
python3 discord.py
```

On success you will see a console message such as `Posted. HTTP 204` (or 200). If the webhook fails the script exits with a non-zero status and prints the response.

**Scheduling**
You can run the script on a schedule (e.g., daily) using `cron` or `launchd`.

Example `cron` (run every weekday at 08:00):

```cron
0 8 * * 1-5 /usr/bin/env python3 /path/to/discord-bot/discord.py
```

For macOS-native scheduling prefer a `launchd` plist that runs the script at the desired time. Remember that whichever process runs the Swift binary will need Calendar permission.

**Permissions & Troubleshooting**
- If you see errors about calendar access, open System Settings > Privacy & Security > Calendars and enable access for the app that runs the binary (Terminal, Python, or the binary itself depending on how you run it).
- If `discord.py` prints `Missing DISCORD_WEBHOOK_URL`, verify `env/discord_hook.env` exists and contains `DISCORD_WEBHOOK_URL`.
- If the Swift build fails, ensure Xcode/Swift toolchain is installed and you passed `-framework EventKit` when compiling.
- If webhook posts return non-2xx, inspect the HTTP response printed by the script for Discord error details.

**Development notes**
- `calendar.swift` emits JSON of the form:

```json
{"date":"YYYY-MM-DD","events":[{"title":"...","start":"ISO8601","end":"ISO8601","allDay":false,"location":"..."}, ...]}
```

- `discord.py` runs `build/calendar`, parses the JSON, converts times to America/New_York, and posts a simple text summary to the webhook.

**License**
This project is licensed under the Apache License 2.0 (see `LICENSE`).

**Next steps / suggestions**
- Add a `requirements.txt` or `pyproject.toml` for reproducible Python installs.
- Add a `Makefile` or simple `scripts/` folder with a `build` and `install` task to simplify building and scheduling.

If you'd like, I can add a `requirements.txt`, a `Makefile` with the `swiftc` build command, and a sample `launchd` plist for macOS scheduling.
# discord-bot
