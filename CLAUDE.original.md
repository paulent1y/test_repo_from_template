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
`ctx.reason` must be a stable code — never prose or exception.toString().  
See `docs/LOGGING_GUIDE.md` for the full vocabulary and Claude debug workflow.

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
- Flame for game objects (if this project is a game).
- Log every user action with state consequences, all auth/save/load flows, network outcomes.
- Never log frame callbacks, position updates, or repeated unchanged state.

## Development Insights Log

Append to `claude_insights.md` in repo root during a session when you notice anything surprising:
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
- [ ] App-specific feature work (fill in when cloned)
