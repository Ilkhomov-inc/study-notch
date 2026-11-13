# Study Nook

macOS app: a Pomodoro timer in the MacBook notch ("island"). Swift package, SwiftUI + Canvas, everything is drawn in code.

## Models (fixed for this project, do not change)

- **For now: Opus 5.5 for everything**: plans, code, and Game of Thrones lore questions (the `got-lore` agent too). The user asked for this on 2026-11-14.
- Before that the split was: Opus 5.5 for plans, Sonnet 5.5 for code (`opusplan`), Haiku 5.5 medium effort for the `got-lore` agent. To go back, set `"model": "opusplan"` in `.claude/settings.json` and `model: haiku` + `effort: medium` in `.claude/agents/got-lore.md`, but only if the user asks.
- Do not switch models, aliases or effort levels in this project unless the user explicitly asks. The settings live in `.claude/settings.json`.

## Commands

- Build and run: `Scripts/build-app.sh --run` (`STUDYNOOK_FAST=1` for a short cycle).
- Tests: `swift test`.
- Render every scene to PNG without screen recording permission: `STUDYNOOK_SNAPSHOT=<dir> build/StudyNook.app/Contents/MacOS/StudyNook` (`STUDYNOOK_ONLY=<prefix>` limits it).

## Rules

- The app must stay light on battery: cap frame rates, no animation when the island is collapsed, cache static layers.
- During the timer the scenes show only the road (army marches, ships sail, dragons fly). All action (fire, battles, fallen dragons) plays during the rest.
