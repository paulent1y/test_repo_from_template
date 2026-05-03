## 2026-04-27 — 2048 two-phase move pattern
<category: Flutter/Dart gotcha>
`notifyListeners()` called twice per move: once after slide (so slide animation runs), then after 120ms delay when new tile spawns. A single notify loses the slide animation — tiles just jump. Keep both notifies separated by `Future.delayed(_slideDuration)`.
<recommendation: Never collapse the two notifyListeners calls into one in game_controller.dart>

## 2026-04-27 — Best scores keyed by grid size
<category: Workflow>
`_bestScores` is `Map<int, int>` (gridSize → score), JSON-encoded with string keys. On load, keys parsed back via `int.parse(k)`. Web skips all file I/O (kIsWeb guard in both load and persist).
<recommendation: When adding new persistence, follow same kIsWeb guard pattern>

## 2026-04-27 — ValueKey collisions in shared Stack
<category: Flutter/Dart gotcha>
Projectile widgets and damage popup widgets both used `ValueKey<int>` with IDs starting at 1, placed as siblings in the same Stack. Flutter threw "Duplicate keys found" when a projectile id=1 and popup id=1 coexisted. Fixed by using a record key `ValueKey(('pop', id))` for popups — different type, can't collide with `ValueKey<int>`.
<recommendation: When multiple widget series share a Stack, namespace their keys with record types or string prefixes>

## 2026-04-27 — ConstrainedBox maxHeight vs SizedBox for flexible containers
<category: Flutter/Dart gotcha>
Using `SizedBox(height: 110)` for the enemy pyramid caused RenderFlex overflow on some screens. Replacing with `ConstrainedBox(maxHeight: 110)` allows the container to shrink when space is tight. Even better: wrap in `Flexible`/`Expanded` and let the Column distribute space — the pyramid now uses `Expanded` so it fills whatever is left above the board.
<recommendation: Prefer ConstrainedBox(maxHeight) or Flexible/Expanded over fixed SizedBox for containers that should yield space>

## 2026-04-27 — ADB IP changes between sessions
<category: Tooling>
Device IP for wireless ADB changes between Wi-Fi reconnects (e.g. 192.168.18.153 → 100.77.240.39). Run `flutter devices` to get current IP before each `flutter run -d <ip>` session. No workaround — just check first.
<recommendation: Always run flutter devices at session start rather than reusing a saved IP>

## 2026-04-27 — Fat APK vs split-per-abi
<category: Workflow>
Default `flutter build apk --release` produces a fat APK (~40MB) bundling all ABIs. `--split-per-abi` generates 3 APKs (~12-15MB each). For sideloading to a specific device, use the arm64 split. Also: `flame` and `cupertino_icons` are in pubspec but never imported — safe to remove, cleans dependency graph.
<recommendation: Use --split-per-abi for all release builds; remove unused pubspec deps>
