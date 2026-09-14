# Changelog — Waanverse Cam Recorder

All notable changes to this app are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/), versioning follows
[Semantic Versioning](../VERSIONING.md) — currently `0.x.y` (initial
development).

## [0.0.1] - Unreleased

### Added

- Initial release: go2rtc relay + standalone ffmpeg segmenter, recording
  10-minute clock-aligned `.mkv` clips via `-c copy` (no transcoding).
- Recording gated by a single Home Assistant template sensor
  (`should_record_entity`), polled every 5 seconds — decision logic
  (privacy switch, manual toggle) lives in Home Assistant's own
  `templates.yaml`, not in this app.
- Self-healing: restarts ffmpeg automatically if it exits unexpectedly
  while it should be recording.
- Configurable via `config.yaml` (`camera_rtsp_url`,
  `should_record_entity`, `retention_days`) — no hardcoded values.
- `translations/en.yaml` with names/descriptions for each Configuration
  tab field.
- `icon.png` / `logo.png` branding assets.
