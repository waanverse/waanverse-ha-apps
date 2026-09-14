# Changelog — Waanverse Telegram Sync

All notable changes to this app are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/), versioning follows
[Semantic Versioning](../VERSIONING.md) — currently `0.x.y` (initial
development).

## [0.0.2] - Unreleased

### Added

- Immediate acknowledgment message sent back the moment the trigger
  phrase is received, before clips are transcoded/uploaded — so a long
  sync no longer looks like nothing happened.

## [0.0.1]

### Added

- Initial release: long-polls Telegram (`getUpdates`) for messages from
  a configured chat, and on an exact match against a configurable
  `trigger_message`, sends every clip not already logged as sent from
  the shared, read-only recordings folder.
- Clips are transcoded down (scaled, re-encoded) to fit Telegram's 50MB
  per-file limit before upload.
- Configurable via `config.yaml` (`telegram_bot_token`,
  `telegram_chat_id`, `trigger_message`, `preview_width`).
- `translations/en.yaml` with names/descriptions for each Configuration
  tab field.
- `icon.png` / `logo.png` branding assets.
