# Waanverse Home Assistant Apps

Home Assistant apps built and maintained by **Waanverse Labs**, for our own
smart home and shared here for anyone who finds them useful. This repository
is where we publish the apps we build around home automation.

## Apps in this repository

| App | What it does |
|---|---|
| **Waanverse Cam Recorder** | Records a go2rtc camera feed into 10-minute clips, gated by a Home Assistant entity (e.g. a template sensor combining privacy mode, home/away state, and motion) |
| **Waanverse Cam Telegram Sync** | Sends recorded clips to Telegram on request, triggered by a configurable phrase — read-only access to the recordings, no recording logic of its own |

Each app is self-contained and can be installed independently — you don't
need both. Full details, configuration options, and troubleshooting notes
live in each app's own `README.md`.

## Installation

1. In Home Assistant, go to **Settings → Apps → App Store**.
2. Open the **⋮ menu (top right) → Repositories**.
3. Add this repository's URL:
   ```
   https://github.com/waanverse/waanverse-ha-apps
   ```
4. Refresh the store — both apps will appear under **Waanverse Home
   Assistant Apps**.
5. Install, configure via each app's **Configuration** tab, then start.


## Design principles we follow across these apps

- **No secrets in the repo.** Camera URLs, entity IDs, and bot tokens are
  always exposed as configurable options (`options`/`schema` in
  `config.yaml`), never hardcoded — so the same source works for anyone's
  instance without editing code.
- **Do one thing per app.** Recording and Telegram delivery are separate
  apps on purpose, each independently installable, configurable, and
  restartable, so a change to one never risks the other.
- **Push decision logic into Home Assistant where possible.** Where an app
  needs to react to conditions like presence or motion, we prefer a Home
  Assistant template entity the app simply polls, rather than duplicating
  that logic in bash — it's easier to inspect, debug, and change from the
  HA UI directly.

## Status

These apps are actively developed and used on our own Home Assistant
instance. Currently built locally on install (Supervisor builds the image
from source on your device) rather than distributed as pre-built container
images — we'll move to published images via GitHub Actions once the apps
are more established.

## Contributing / issues

This is currently a small, actively-iterated internal project. If you're
using these apps and run into something, feel free to open an issue on the
relevant app.

## License

MIT — see [LICENSE](./LICENSE).