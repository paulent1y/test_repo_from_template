# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Claude Flutter Template

## Stack

- Flutter SDK: `^3.11.5` (Dart)
- flame: `^1.37.0`
- path_provider: `^2.1.5`
- cupertino_icons: `^1.0.8`
- flutter_lints: `^6.0.0`

## Folder Structure

```
lib/
  logging/
    log_config.dart     — LogLevel enum, LogConfig, fingerprint, session ID
    log_observer.dart   — NavigatorObserver (callback-based, no AppLog dep)
    app_log.dart        — AppLog singleton, _LogWriters, _LogSummary
  main.dart
docs/
  LOGGING_GUIDE.md      — full schema, vocabulary, Claude debug workflow
  INSTALL.md            — quick setup for projects cloned from this template
MCP_SETUP.md            — Dart and Flame MCP server setup instructions
```

Platforms scaffolded: Android, iOS, Web, Windows, macOS, Linux.

## Logging Architecture

`AppLog` is a singleton `WidgetsBindingObserver`. Call `AppLog.init()` before `runApp()` and wire `appLog.observer` into `MaterialApp.navigatorObservers` — route tracking won't work otherwise.

**Write pipeline per event:**
1. In-memory ring buffer (default 500 entries) — all platforms including web.
2. `session.log` — all events ≥ `minFileLevel` (default TRACE). Soft-rotates at 50k lines.
3. `errors.log` — WARN+ only. Soft-rotates at 10k lines.
4. `focus.log` — single-sys filter, only when `LogConfig.enableFocusSys` is set (dev use).
5. `summary.log` — auto-flushed on every ERROR+ event and on app lifecycle pause/detach. Read this first when debugging.

File I/O is disabled on web (`kIsWeb`); ring buffer still works. All file writes are chained through a single `Future _chain` to prevent concurrent write races.

**Fingerprint** (`fp` field): FNV-1a 32-bit hash of `evt|src|reason`, first 6 hex chars. Used to deduplicate repeated WARN+ events in `summary.log`.

**`cid` validation regex:** `^[a-z][a-z0-9]*(?:-[a-z0-9]+){2,}$` — minimum three hyphen-separated segments (e.g. `auth-token-1`).

**`LogConfig` customization** — pass to `AppLog.init(config: ...)`:
- `minConsoleLevel` — what prints to console (default DEBUG)
- `minFileLevel` — what writes to session.log (default TRACE)
- `enableFocusSys` — sys name to isolate into focus.log
- `enableSrc` — capture caller file:line via StackTrace (default: `kDebugMode` only)

**Testing:** call `AppLog.resetForTesting()` in `setUp`/`tearDown` to reset the singleton between tests.

## Run Commands

```bash
flutter run                        # picks first available device
flutter run -d windows             # Windows desktop
flutter run -d chrome              # web
flutter run -d <device-id>         # specific device — run `flutter devices` to list
flutter analyze                    # linter check — run before finishing any task
flutter test                       # unit/widget tests
```

## Logger — AppLog

`lib/logging/app_log.dart`. Top-level accessor: `appLog`.

```dart
// INFO and below — cid and ctx optional
appLog.info('save', 'save.begin', ctx: {'slot': 1});
appLog.debug('network', 'network.request');

// WARN and above — cid and ctx REQUIRED (compile-enforced)
appLog.warn('auth', 'auth.failed',
  cid: 'auth-token-1',
  ctx: {'reason': 'token_expired'},
);
appLog.error('save', 'save.failed',
  cid: 'save-user-3',
  ctx: {'reason': 'write_denied', 'slot': slot},
);
```

`cid` format: `sys-noun-counter` (e.g. `auth-token-3`).  
`ctx.reason` must be stable code — never prose or exception.toString().  
See `docs/LOGGING_GUIDE.md` for full vocabulary and Claude debug workflow.

**Never use `print()` or `debugPrint()` in application code.**

## MCP Servers

| Server | Scope   | Status        | Notes                        |
|--------|---------|---------------|------------------------------|
| dart   | project | auto (SDK)    | Dart SDK 3.9+ required       |
| flame  | user    | manual setup  | see MCP_SETUP.md             |

Project-level config: `.claude/settings.json`.

## Conventions

- One component per file.
- Flutter widgets for UI.
- Flame for game objects (if game project).
- Log every user action with state consequences, all auth/save/load flows, network outcomes.
- Never log frame callbacks, position updates, repeated unchanged state.

## Development Insights Log

Append to `claude_insights.md` in repo root when noticing anything surprising:
- **Tooling**: Flutter/Dart CLI quirks, MCP issues, analyzer edge cases
- **Workflow**: ordering problems, steps worth automating
- **Flutter/Dart gotchas**: platform-conditional behavior, plugin issues, widget lifecycle surprises
- **Instruction gaps**: cases where this CLAUDE.md gave wrong or incomplete guidance

## Build State Checklist

- [x] Flutter project scaffolded (all platforms)
- [x] Flame engine added (`^1.37.0`)
- [x] AppLog logging system (`lib/logging/`)
- [x] Dart MCP server configured (project-level)
- [x] Flame MCP server registered (user-level, see MCP_SETUP.md)
- [x] Caveman plugin installed (user-level)
- [x] 2048 game — engine, controller, UI complete (working as of 2026-04-27)