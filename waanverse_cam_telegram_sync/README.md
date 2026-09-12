# Cam1 Telegram Sync — Reference Doc

## What this app does

Sits idle, long-polling Telegram for messages. When it sees a specific
trigger phrase (configurable) sent from your own chat, it scans the shared
recordings folder and sends every clip it hasn't sent before to that chat —
downscaled/re-encoded to fit Telegram's 50MB per-file limit.

This app **never records anything** and has **read-only** access to the
media folder — it's purely a delivery mechanism for clips that
**Cam1 Segment Recorder** (the other app) already saved.

## Data flow

```
You: send trigger phrase in Telegram
  --> this app's long-poll loop notices it
  --> scans /media/security_recordings for clips not in its own send-log
  --> for each new clip: ffmpeg transcode (shrink for Telegram) --> upload
  --> replies with a summary message when done
```

## Files in this app

- `config.yaml` — options exposed on the Configuration tab + their schema
- `Dockerfile` — base image, installs `ffmpeg`, `jq`, `curl`
- `run.sh` — all the actual logic

## Configuration tab options

| Option               | Meaning                                                              |
| -------------------- | -------------------------------------------------------------------- |
| `telegram_bot_token` | your bot's token, from @BotFather                                    |
| `telegram_chat_id`   | your chat ID — only messages from this chat are honored              |
| `trigger_message`    | the exact phrase (case-insensitive) that starts a sync, e.g. `/sync` |
| `preview_width`      | pixel width clips are scaled to before upload                        |

Changing values here only needs a **restart**. Adding/removing a field from
`config.yaml` itself needs the full uninstall → "Check for updates" →
reinstall cycle, same as the recorder app.

## How the main loop works (run.sh)

- Uses Telegram's `getUpdates` long-poll endpoint (`timeout=30`) — the
  request just sits open waiting for a new message instead of hammering the
  API, so this is cheap to run continuously.
- Tracks the last processed `update_id` in `/data/tg_offset` so a restart
  doesn't replay old messages.
- Ignores every message except ones that both (a) come from the configured
  `telegram_chat_id`, and (b) match `trigger_message` exactly,
  case-insensitive. Anything else typed in that chat is silently ignored.
- On a valid trigger, `sync_clips`:
    - Finds every `.mkv` under `/media/security_recordings` at least 1 minute
      old.
    - Skips anything already listed in `/data/telegram_sent.log`.
    - Transcodes each new one with `ffmpeg -nostdin ... -c:v libx264 -crf 28`,
      scaled to `preview_width`, output as `.mkv` (matches the source
      container, still small enough for the 50MB cap after re-encoding).
    - Uploads via `sendVideo`, logs the filename to the sent-log so it's never
      re-sent.
    - Sends a final `sendMessage` summary ("Sync complete: sent N new
      clip(s)").

## Things worth remembering later

- **`-nostdin` is required on the ffmpeg call.** Without it, ffmpeg
  inherits the pipe's stdin (from the `find | while read` construction) and
  can get truncated mid-encode by stray bytes in that pipe — this caused an
  earlier bug where clips were cut to ~16 seconds. Never remove this flag.
- **The re-encode step is the only CPU-heavy part of this whole camera
  setup.** The recorder app uses `-c copy` (near-free); this app actually
  decodes/re-encodes, which costs real CPU per clip. A backlog of many
  unsent clips at once (e.g. right after wiping `/data` via an uninstall)
  will transcode back-to-back and can spike CPU noticeably until it drains
  — that's expected, not a fault.
- **`/data/telegram_sent.log` is wiped by uninstalling this app** — but
  `/media/security_recordings` (owned by the host, not this app) is not.
  So a fresh install after an uninstall will treat every existing clip as
  "new" and re-send the whole backlog once, the first time the trigger
  fires.
- **Trigger matching is a plain string comparison**, not real Telegram
  bot-command parsing — `trigger_message` can be anything (`/sync`, `send
clips`, etc.), it just has to match exactly what you type, ignoring case.
- **Local apps live under the `local_apps` Samba share** (renamed from
  `addons` after the Feb 2026 Apps rebrand).

## Related app

**Cam1 Segment Recorder** — the app that actually records. Fully
independent of this one; it doesn't know or care whether this sync app
exists, is running, or has ever sent anything.

## Quick troubleshooting

| Symptom                                      | Check                                                                                                                                                 |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Trigger message does nothing                 | Confirm `telegram_chat_id` matches the chat you're messaging from, and the text matches `trigger_message` exactly (case doesn't matter, wording does) |
| Clips play but cut off early                 | Confirm the ffmpeg call still has `-nostdin` — this was a known bug if removed                                                                        |
| Nothing ever gets sent, no error             | Check the log for the actual `getUpdates` response — a bad `telegram_bot_token` fails silently into an empty response rather than a loud error        |
| Re-sends clips you thought were already sent | `/data/telegram_sent.log` was wiped by an uninstall — expected once, not a recurring bug                                                              |
