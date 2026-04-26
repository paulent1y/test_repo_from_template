# AppLog — Installation

## 1. Add dependency

`pubspec.yaml` under `dependencies`:

```yaml
path_provider: ^2.1.5
```

```bash
flutter pub get
```

## 2. Copy the logging module

```
lib/logging/
  log_config.dart
  log_observer.dart
  app_log.dart
```

## 3. Update main.dart

```dart
import 'package:flutter/material.dart';
import 'logging/app_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLog.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [appLog.observer],  // route tracking
      // ...
    );
  }
}
```

## 4. Verify

Run app. Console show:

```
[INFO] app/app.start {session: session-2026-04-26-100000}
```

Non-web: check `logs/` exists in application support directory.

## 5. API

```dart
// INFO and below — cid/ctx optional
appLog.info('save', 'save.begin', ctx: {'slot': 1});
appLog.debug('network', 'network.request');

// WARN and above — cid and ctx.reason required (compile-enforced)
appLog.warn(
  'auth', 'auth.failed',
  cid: 'auth-token-1',
  ctx: {'reason': 'token_expired'},
);
appLog.error(
  'save', 'save.failed',
  cid: 'save-user-3',
  ctx: {'reason': 'write_denied', 'slot': slot},
);
```

## 6. Custom config

```dart
await AppLog.init(
  config: const LogConfig(
    minConsoleLevel: LogLevel.warn,   // quieter console
    enableFocusSys: 'auth',           // dev: write auth events to focus.log too
  ),
);
```

## 7. Web

No config needed. File writes auto-skipped. Ring buffer available:

```dart
final recent = appLog.recentEntries(count: 100, minLevel: LogLevel.warn);
for (final e in recent) debugPrint(e.json);
```

## 8. go_router

```dart
final _router = GoRouter(
  observers: [appLog.observer],
  routes: [...],
);
```

## 9. New Claude Code session

Tell Claude: *"Read docs/LOGGING_GUIDE.md and save the bootstrap memories."*

See `docs/LOGGING_GUIDE.md` for full schema, vocabulary, Claude debugging workflow.