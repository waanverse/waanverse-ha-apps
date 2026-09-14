# Catalog

Single source of truth for what's in this repository. Update this file as
part of every release — see [VERSIONING.md](./VERSIONING.md).

| App                     | Slug                      | Version | Description                                                                         |
| ----------------------- | ------------------------- | ------- | ----------------------------------------------------------------------------------- |
| Waanverse Cam Recorder  | `waanverse_cam_recorder`  | 0.0.1   | Records a go2rtc camera feed into 10-minute clips, gated by a Home Assistant entity |
| Waanverse Telegram Sync | `waanverse_telegram_sync` | 0.0.2   | Sends recorded clips to Telegram on request, triggered by a configurable phrase     |

Both apps are at `0.0.1` — early/initial development, per
[VERSIONING.md](./VERSIONING.md). Config options and entity contracts may
still change without a major-version bump until either app graduates to
`1.0.0`.

Each app's full details, configuration options, and troubleshooting notes
live in its own `README.md`. Version-by-version history lives in each
app's own `CHANGELOG.md`.

## Adding a new app to this repo

1. Create `<slug>/` at the repo root with `config.yaml`, `Dockerfile`,
   `run.sh`, `README.md`, `CHANGELOG.md`, and (if it has config options)
   `translations/en.yaml`.
2. Start it at `0.0.1`.
3. Add a row to the table above.
4. Follow [VERSIONING.md](./VERSIONING.md) from the app's first commit
   onward.
