# Study Nook

macOS app: a Pomodoro timer in the MacBook notch ("island"). Swift package, SwiftUI + Canvas, everything is drawn in code.

## Models (fixed for this project, do not change)

- Plans, architecture, design decisions: **Opus 5.5** (`opusplan` runs Opus in plan mode).
- Writing code: **Sonnet 5.5** (what `opusplan` uses outside plan mode).
- Questions about Game of Thrones (story, looks, places, ships, armies): the **`got-lore`** agent, which runs on **Haiku 5.5, medium effort**.
- Do not switch models, aliases or effort levels in this project unless the user explicitly asks. The settings live in `.claude/settings.json`.

## Commands

- Build and run: `Scripts/build-app.sh --run` (`STUDYNOOK_FAST=1` for a short cycle).
- Tests: `swift test`.
- Render every scene to PNG without screen recording permission: `STUDYNOOK_SNAPSHOT=<dir> build/StudyNook.app/Contents/MacOS/StudyNook`.

## Rules

- The app must stay light on battery: cap frame rates, no animation when the island is collapsed, cache static layers.
