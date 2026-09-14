# Versioning Policy

All apps in this repository follow [Semantic Versioning](https://semver.org/)
— `MAJOR.MINOR.PATCH`.

## Starting point: 0.0.1

Every app here currently starts at `0.0.1`. Under semver, a `0.x.y`
version means _initial development — anything may still change, the
config/behavior isn't considered stable yet._ That's an accurate
description of where these apps actually are right now, so there's no
reason to pretend otherwise with a `1.0.0`.

## While at 0.x.y

- **PATCH** (`0.0.x`) — bug fixes, small internal tweaks, no change to
  config options or behavior.
- **MINOR** (`0.x.0`) — anything bigger: a new feature, a new config
  option, or a change that _would_ be a breaking change once this hits
  `1.0.0` (a renamed/removed option, a changed entity contract). Per
  semver's own rule for major version zero, MINOR absorbs what MAJOR
  normally means while you're still here.
- **MAJOR** stays `0` for the whole time an app is in this phase.

## Graduating to 1.0.0

Move an app to `1.0.0` once its config/behavior is stable enough that
you're not expecting to rename entities or options again on a whim — e.g.
once you're relying on it day-to-day without surprises, or if you ever
publish this repo for other people to install. After that point, normal
`MAJOR.MINOR.PATCH` rules apply:

- **MAJOR** — requires existing installs to take action (renamed/removed
  required option, changed entity/file contract, removed feature).
- **MINOR** — new, backward-compatible capability.
- **PATCH** — bug fix or internal change with no effect on the app's
  external contract.

## When to actually bump (applies at any stage)

Bump the `version:` in `config.yaml` for **any** change to that app's
`run.sh`, `Dockerfile`, or `config.yaml` — including small fixes. Home
Assistant's Supervisor only knows to offer an update when the version
number changes, so a fix that ships without a bump will silently never
reach an existing install.

Cosmetic/doc-only changes within an app folder (README wording,
translation text, icon/logo swaps) don't strictly require a bump to
function, but bump anyway (PATCH is fine) if you want existing installs
to actually receive the update.

Pure repo-level changes (this file, the root `README.md`, `.gitignore`)
never need an app version bump — they're not part of what gets installed.

## Process for each release

1. Make the change.
2. Update the app's `CHANGELOG.md` — add an entry under a new version
   heading, dated.
3. Bump `version:` in that app's `config.yaml` to match.
4. Update `CATALOG.md` at the repo root to reflect the new version.
5. Commit with a message referencing the version, e.g.
   `waanverse_cam_recorder: 0.0.1 -> 0.0.2 — fix reconnect flag`.
6. Push. Existing installs will see "Update available" next time they
   check the App Store.
