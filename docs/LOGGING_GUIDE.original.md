# AppLog — Logging Guide

> **Claude Code:** Read this file first when starting a session. Then read `summary.log`, `errors.log`, `session.log` in that order. Stop when you have enough context.

---

## Files

| File | Purpose | When to read |
|------|---------|-------------|
| `summary.log` | Digest: systems with errors, CID index, line counts, fingerprint index | Always first |
| `errors.log` | All WARN+ events, JSON lines | When summary shows errors |
| `session.log` | All events, JSON lines. Can be large. | By cid/fp/evt grep, not in full |
| `focus.log` | One subsystem only. Dev tool, opt-in. | Optional |

**Log files location (non-web):**

| Platform | Path |
|----------|------|
| Android / iOS | `getApplicationSupportDirectory()/logs/` |
| Windows | `%APPDATA%\<AppName>\logs\` |
| macOS | `~/Library/Application Support/<AppName>/logs/` |
| Linux | `~/.local/share/<AppName>/logs/` |
| Web | No files. Ring buffer only — `appLog.recentEntries()` |

---

## Event Schema

One JSON object per line (NDJSON). No pretty-printing.

```json
{
  "ts":    "2026-04-26T10:00:00.000Z",
  "lvl":   "ERROR",
  "sys":   "auth",
  "evt":   "auth.failed",
  "cid":   "auth-token-3",
  "sid":   "session-2026-04-26-100000",
  "src":   "auth_service.dart:42",
  "fp":    "a3f9c1",
  "route": "/login",
  "ctx":   { "reason": "token_expired", "user": "user_01" }
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `ts` | always | UTC ISO-8601 with milliseconds |
| `lvl` | always | TRACE DEBUG INFO WARN ERROR FATAL |
| `sys` | always | Subsystem: auth, save, network, ui, etc. |
| `evt` | always | Stable dot-namespaced code: `sys.verb_noun` |
| `cid` | WARN+ | Correlation ID: `sys-noun-counter` |
| `sid` | always | Session ID for this process launch |
| `src` | debug builds | Caller `file.dart:line` |
| `fp` | always | 6-char FNV-1a hex of `evt\|src\|ctx.reason` — dedup key |
| `route` | always | Current Navigator route, e.g. `/home` |
| `ctx` | varies | `ctx.reason` required (stable code) on WARN+ |

---

## Severity

| Level | Rank | Use for |
|-------|------|---------|
| TRACE | 0 | Hot-path internals, verbose iteration data |
| DEBUG | 1 | Dev-time state dumps |
| INFO | 2 | Normal lifecycle events |
| WARN | 3 | Recoverable anomaly, unexpected-but-handled |
| ERROR | 4 | Feature failure, user-visible degradation |
| FATAL | 5 | Unrecoverable, app must restart |

---

## Callsite API

```dart
// INFO and below — cid and ctx are optional
appLog.info('save', 'save.begin', ctx: {'slot': 1});
appLog.debug('network', 'network.request', ctx: {'url': endpoint});

// WARN and above — cid and ctx are REQUIRED (compile-enforced)
appLog.warn(
  'auth', 'auth.failed',
  cid: 'auth-token-3',
  ctx: {'reason': 'token_expired', 'user': userId},
);
appLog.error(
  'save', 'save.failed',
  cid: 'save-user-2',
  ctx: {'reason': 'write_denied', 'slot': slot},
);
```

`warn`, `error`, and `fatal` use Dart required named parameters — the compiler rejects calls without `cid` and `ctx`. The debug-mode assert then validates their content.

---

## Correlation IDs

Format: `sys-noun-counter` — lowercase, at least three hyphen-separated segments.

```
auth-token-3
save-user-2
network-api-7
state-cart-1
```

Rules:
- One `cid` per operation, not per sub-step.
- Increment the counter for each new operation of the same type within a session.
- Pass the same `cid` to all events in the correlated flow.

```dart
const cid = 'save-user-1';
appLog.info('save', 'save.begin', cid: cid, ctx: {'slot': slot});
try {
  await performSave(slot);
  appLog.info('save', 'save.success', cid: cid, ctx: {'slot': slot});
} catch (e) {
  appLog.error('save', 'save.failed',
    cid: cid,
    ctx: {'reason': 'write_denied', 'slot': slot, 'error': e.toString()},
  );
}
```

---

## ctx.reason Vocabulary

Must be a stable code — not a `toString()` of an exception, not prose.

| Code | Use case |
|------|----------|
| `token_expired` | Auth token no longer valid |
| `permission_denied` | OS or server denied access |
| `write_denied` | File or database write rejected |
| `network_timeout` | HTTP or socket timeout |
| `network_error` | HTTP non-2xx or socket error |
| `parse_failed` | JSON or data deserialization error |
| `invalid_state` | State machine transition rejected |
| `not_found` | Resource missing |
| `quota_exceeded` | Rate limit or storage full |
| `user_cancelled` | Explicit user cancel |

Add project-specific codes to this table as you introduce them.

---

## Event Vocabulary

```
app.start           app.shutdown        app.background      app.foreground
route.changed
save.begin          save.success        save.failed
load.begin          load.success        load.failed
auth.begin          auth.success        auth.failed         auth.logout
network.request     network.success     network.failed      network.timeout
ui.button_tapped    ui.dialog_opened    ui.dialog_closed
state.invalid_transition
resource.load_failed
```

Rules:
- Never encode variable values in the event name. `auth.failed` correct. `auth.failed_for_user_01` not.
- Before adding a new code, check if an existing one fits.
- Add new codes to this table when you introduce them.

---

## Fingerprint (`fp`)

`fp` is a 6-char hex string — FNV-1a 32-bit hash of `evt|src|ctx.reason`.

- Same `fp` across sessions means the same event, same callsite, same reason.
- Use `fp` to identify repeated failures without reading duplicate lines.
- The Fingerprint Index in `summary.log` shows first-seen timestamp for each fp.

```bash
grep -c '"fp":"a3f9c1"' errors.log
```

---

## Automatic Lifecycle Events

These are emitted without any callsite code:

| Event | Trigger |
|-------|---------|
| `app.start` | `AppLog.init()` completes |
| `route.changed` | Navigator push/pop/replace |
| `app.background` | `AppLifecycleState.paused` |
| `app.foreground` | `AppLifecycleState.resumed` |
| `app.shutdown` | `AppLifecycleState.detached` |

`summary.log` is flushed automatically on `app.background` and `app.shutdown`. On `ERROR` or `FATAL` events it is also flushed immediately.

---

## Focus Mode (Dev Only)

To route one subsystem to `focus.log` while debugging:

```dart
await AppLog.init(
  config: const LogConfig(enableFocusSys: 'auth'),
);
```

Remove `enableFocusSys` before committing. The other log files continue normally.

---

## Web Platform

File I/O is skipped on web (`kIsWeb` guard in `_LogWriters`). The in-memory ring buffer works on all platforms. Access it from a debug overlay or DevTools:

```dart
final recent = appLog.recentEntries(count: 100, minLevel: LogLevel.warn);
for (final e in recent) debugPrint(e.json);
```

---

## Claude Code Workflow

### Read order

1. `summary.log` — always first. Check **Systems with Errors** and **File Line Counts**.
2. If line counts are small, read `errors.log` in full.
3. If line counts are large, use `fp` or `cid` from summary to grep targeted slices.
4. Read `session.log` only for a specific flow (`cid` grep) or if chronological reconstruction is needed.

Never open `session.log` without checking summary first. Never read all files by default.

### Grep patterns

```bash
# All events for one correlation ID
grep '"cid":"save-user-2"' session.log

# All events for a subsystem
grep '"sys":"auth"' errors.log

# How many times did this fingerprint fire?
grep -c '"fp":"a3f9c1"' errors.log

# All ERROR and FATAL
grep '"lvl":"ERROR"\|"lvl":"FATAL"' session.log

# Events on a specific route
grep '"route":"/checkout"' session.log

# Specific event type
grep '"evt":"auth.failed"' session.log
```

### Correlating a failure

1. Find the `ERROR` in `errors.log`. Note `cid` and `fp`.
2. Grep `session.log` for the `cid` — shows the full operation timeline.
3. Check `fp` in **Fingerprint Index** of `summary.log` — `first_seen` tells you if this is new or recurring.
4. Check `ctx.reason` against the vocabulary table above.

---

## Bootstrap Memory Instructions

When you read this file in a new session on this project, save the following entries to memory immediately.

---

### Memory 1 — project: AppLog file locations

`summary.log` is always read first. It contains: systems_with_errors, CID index, file line counts, fingerprint dedup index. Non-web log files are at `getApplicationSupportDirectory()/logs/` (Windows: `%APPDATA%\<app>\logs\`). Web: ring buffer only via `appLog.recentEntries()`.

---

### Memory 2 — project: AppLog event schema

JSON lines: `{ts, lvl, sys, evt, cid, sid, src, fp, route, ctx}`. `fp` = 6-char FNV-1a hex of `evt|src|ctx.reason` — dedup key. `route` = current Navigator route. `cid` format: `sys-noun-counter` (e.g. `auth-token-3`).

---

### Memory 3 — feedback: WARN+ contracts are compile-enforced

`warn`/`error`/`fatal` in AppLog require `cid` and `ctx` as Dart required named parameters. The compiler rejects missing arguments. Debug-mode assert validates `isValidCid(cid)` and `ctx['reason']` presence. `ctx.reason` must be a stable code (e.g. `write_denied`), never prose or exception.toString().

---

### Memory 4 — project: AppLog singleton init

`AppLog.init()` is awaited in `main()` before `runApp()`. Top-level `appLog` getter is the callsite accessor. `appLog.observer` must be registered in `MaterialApp(navigatorObservers:)` for route tracking.

---

### Memory 5 — feedback: grep strategy for AppLog logs

Search order: `fp` (repeated error dedup) → `cid` (full flow trace) → `evt` (event type scan) → `sys` (subsystem filter). Never grep for prose — all searchable values are in structured fields. Check `summary.log` line counts before deciding whether to read full files or tail.

---

### Memory 6 — project: AppLog 3-file structure

`lib/logging/log_config.dart` — LogLevel enum, LogConfig, fingerprint, session ID. Pure Dart, no Flutter imports.
`lib/logging/log_observer.dart` — LogObserver (NavigatorObserver), callback-based, no AppLog import.
`lib/logging/app_log.dart` — AppLog singleton, `_LogWriters` and `_LogSummary` as file-private classes, `appLog` top-level getter.

---

### Memory 7 — feedback: what must be logged in Flutter apps

Always: `app.start/shutdown/background/foreground`, route changes (auto), save/load lifecycle, auth flows, network request outcomes, user actions with state consequences, resource/signal failures.
Never: frame callbacks, position updates, repeated logs for unchanged state, full object dumps.
Rule: if removing the log line wouldn't reduce ability to answer "what happened, where, why" — remove it.

---

### Memory 8 — project: AppLog web and ring buffer

`_LogWriters` is a no-op on web (`kIsWeb` guard). Ring buffer (default 500 entries, configurable via `LogConfig.ringBufferSize`) is always active on all platforms. `appLog.recentEntries(count, minLevel)` reads it. `AppLog.resetForTesting()` resets the singleton for unit tests.
