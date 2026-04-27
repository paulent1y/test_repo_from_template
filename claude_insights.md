## 2026-04-27 — 2048 two-phase move pattern
<category: Flutter/Dart gotcha>
`notifyListeners()` called twice per move: once after slide (so slide animation runs), then after 120ms delay when new tile spawns. A single notify loses the slide animation — tiles just jump. Keep both notifies separated by `Future.delayed(_slideDuration)`.
<recommendation: Never collapse the two notifyListeners calls into one in game_controller.dart>

## 2026-04-27 — Best scores keyed by grid size
<category: Workflow>
`_bestScores` is `Map<int, int>` (gridSize → score), JSON-encoded with string keys. On load, keys parsed back via `int.parse(k)`. Web skips all file I/O (kIsWeb guard in both load and persist).
<recommendation: When adding new persistence, follow same kIsWeb guard pattern>
