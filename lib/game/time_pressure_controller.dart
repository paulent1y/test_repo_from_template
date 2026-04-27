import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../logging/app_log.dart';
import 'game_config.dart';
import 'game_controller.dart';
import 'game_state.dart';

class TimePressureRecord {
  const TimePressureRecord({required this.total, required this.max});
  final int total;
  final int max;
}

enum TimerPhase { idle, running, ended }

class TimePressureController extends ChangeNotifier {
  TimePressureController() {
    _game.addListener(_onGame);
    _loadRecords();
  }

  final GameController _game = GameController();
  int _selectedDuration = timePressureDurations[1];
  int _remaining = timePressureDurations[1];
  TimerPhase _phase = TimerPhase.idle;
  Timer? _timer;
  Map<String, TimePressureRecord> _records = {};

  GameState get gameState => _game.state;
  int get gridSize => _game.gridSize;
  bool get canUndo => _game.canUndo;
  int get selectedDuration => _selectedDuration;
  int get remaining => _remaining;
  TimerPhase get phase => _phase;

  TimePressureRecord? recordFor(int duration) =>
      _records['${_game.gridSize}-$duration'];

  void selectDuration(int seconds) {
    if (_phase == TimerPhase.running) return;
    _selectedDuration = seconds;
    _remaining = seconds;
    notifyListeners();
  }

  void selectGridSize(int size) {
    if (_phase == TimerPhase.running) return;
    _game.newGame(size);
  }

  void stop() {
    if (_phase != TimerPhase.running) return;
    _timer?.cancel();
    _timer = null;
    _phase = TimerPhase.idle;
    _remaining = _selectedDuration;
    appLog.info('time', 'time.stop', ctx: {'grid': _game.gridSize});
    notifyListeners();
  }

  void start() {
    _timer?.cancel();
    _game.newGame(_game.gridSize);
    _remaining = _selectedDuration;
    _phase = TimerPhase.running;
    appLog.info('time', 'time.start',
        ctx: {'duration': _selectedDuration, 'grid': _game.gridSize});
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _remaining--;
      if (_remaining <= 0) {
        _remaining = 0;
        _end();
      } else {
        notifyListeners();
      }
    });
    notifyListeners();
  }

  Future<void> move(Direction dir) async {
    if (_phase != TimerPhase.running) return;
    if (_game.state.status == GameStatus.won) _game.continueAfterWin();
    await _game.move(dir);
  }

  void undo() {
    if (_phase != TimerPhase.running) return;
    _game.undo();
  }

  void _end() {
    _timer?.cancel();
    _timer = null;
    _phase = TimerPhase.ended;

    final tiles = _game.state.tiles;
    final total = tiles.fold(0, (s, t) => s + t.value);
    final max = tiles.isEmpty
        ? 0
        : tiles.map((t) => t.value).reduce((a, b) => a > b ? a : b);

    final key = '${_game.gridSize}-$_selectedDuration';
    final existing = _records[key];
    if (existing == null || total > existing.total) {
      _records[key] = TimePressureRecord(total: total, max: max);
      _persistRecords();
    }

    appLog.info('time', 'time.end', ctx: {
      'duration': _selectedDuration,
      'grid': _game.gridSize,
      'total': total,
      'max': max,
    });

    notifyListeners();
  }

  void _onGame() => notifyListeners();

  Future<String> _recordsPath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/2048_time_records.json';
  }

  Future<void> _loadRecords() async {
    if (kIsWeb) return;
    try {
      final file = File(await _recordsPath());
      if (!file.existsSync()) return;
      final raw =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _records = raw.map((k, v) {
        final m = v as Map<String, dynamic>;
        return MapEntry(
            k,
            TimePressureRecord(
                total: m['total'] as int, max: m['max'] as int));
      });
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistRecords() async {
    if (kIsWeb) return;
    try {
      final encoded = jsonEncode(
        _records
            .map((k, v) => MapEntry(k, {'total': v.total, 'max': v.max})),
      );
      await File(await _recordsPath()).writeAsString(encoded);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _game.removeListener(_onGame);
    _game.dispose();
    super.dispose();
  }
}
