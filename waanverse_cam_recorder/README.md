# Cam1 Segment Recorder — Reference Doc

## What this app does

Continuously pulls the living room camera's feed (relayed through go2rtc) and
records it into 10-minute `.mkv` segments, aligned to clock boundaries
(`:00`, `:10`, `:20`...). Recording only happens when a single Home Assistant
template sensor says it should.

This app does **not** handle Telegram uploads — that's a separate app,
**Cam1 Telegram Sync**, which only reads from the same media folder and never
touches recording.

## Data flow

```
Camera --> go2rtc (LAN relay, rtsp://<HA-IP>:8554/living_room)
        --> this app's ffmpeg (-c copy, no re-encoding)
        --> /media/security_recordings/cam1_YYYYMMDD_HHMMSS.mkv
```

`-c copy` means ffmpeg just repackages the existing compressed stream — no
decode/re-encode — so this app's CPU/resource footprint is essentially free,
even running 24/7.

## Files in this app

- `config.yaml` — options exposed on the Configuration tab + their schema
- `Dockerfile` — base image, installs `ffmpeg`, `jq`, `curl`
- `run.sh` — all the actual logic

## Configuration tab options

| Option                 | Meaning                                              |
| ---------------------- | ---------------------------------------------------- |
| `camera_rtsp_url`      | go2rtc's local relay URL for this camera             |
| `should_record_entity` | the HA entity this app polls to decide record on/off |
| `retention_days`       | local clips older than this are auto-deleted         |

Changing these values only needs a **restart**. Changing `config.yaml`'s
`options`/`schema` structure itself (adding/removing a field) needs a full
**uninstall → "Check for updates" → reinstall** cycle, not just a rebuild —
Supervisor has been finicky about picking up schema changes otherwise.

## The recording gate

The app doesn't contain any privacy/home/motion logic itself anymore — it
just polls **one** entity, by default:

```
binary_sensor.should_record_living_room
```

That sensor is defined in Home Assistant's own `templates.yaml`, not in this
app, and encodes the actual decision rules:

1. **Privacy switch is on** (`switch.camera_privacy_mode`) → hard stop,
   nothing else matters.
2. **Otherwise, if home** (`person.<you>` = `home`) → follow the manual
   button only (`input_boolean.living_room_recording`), motion is ignored.
3. **Otherwise (away)** → follow the motion sensor only
   (`binary_sensor.living_room_motion`), with a 2-minute grace period after
   motion stops before actually cutting off — button is ignored in this
   branch.

Keeping this logic in HA (not bash) means changing the rules is a
`templates.yaml` edit + reload, not an app rebuild.

## How the main loop works (run.sh)

- Polls `should_record_entity` every 5 seconds via Supervisor's proxied
  Core API (`http://supervisor/core/api/states/<entity>`).
- `gate = "on"` → `start_ffmpeg` (no-op if already running).
- `gate = "off"` → `stop_ffmpeg` (sends `SIGTERM`, lets ffmpeg close the
  current segment cleanly rather than corrupting it).
- `gate = "unknown"` (API hiccup, entity missing) → deliberately does
  nothing that iteration, so a transient read failure doesn't cause
  flapping.
- **Self-healing:** every loop iteration also checks if ffmpeg died on its
  own while it was supposed to be running, and restarts it if so —
  independent of whatever the gate says.
- **Connection timeout:** uses `-timeout 5000000` (5s), _not_ `-reconnect*`
  flags — those are HTTP-protocol-only options and error out
  (`Option reconnect not found`) on an `rtsp://` input. The outer loop's
  restart-on-exit is what actually provides reconnection for RTSP.
- A background hourly loop deletes `.mkv` files older than `retention_days`.

## Things worth remembering later

- **Why `.mkv` and not `.mp4`:** Matroska tolerates abrupt cuts and
  timestamp irregularities from the camera far better than mp4, which needs
  a cleanly finalized moov atom.
- **First segment after any (re)start is a short "partial" clip** — this is
  expected. `-segment_atclocktime 1` intentionally cuts a short first
  segment to sync up with the next `/10` boundary, then every segment after
  that is a full 10 minutes.
- **If the camera's own hardware privacy mode kills its stream** (rather
  than this being a purely virtual switch), you'll see a couple of
  reconnect-attempt log lines right before the gate catches up and shuts
  things down cleanly — harmless, not a fault.

## Related app

**Cam1 Telegram Sync** — separate app, `read_only` access to the same media
folder. Sits idle long-polling Telegram for a message; when one arrives from
your chat, it sends every clip not already in its own send-log, transcoded
down small enough for Telegram's 50MB limit. Has its own bot token / chat ID
in its own Configuration tab — doesn't share any config with this app.

## Quick troubleshooting

| Symptom                         | Check                                                                                                       |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Recording never starts          | Developer Tools → States → `should_record_living_room` — what's it actually reading?                        |
| That sensor shows `unavailable` | One of the entity IDs inside the template doesn't exist / was renamed                                       |
| High CPU from this app          | Shouldn't happen — `-c copy` is nearly free. If seen, double check no stray transcode got added to `run.sh` |
