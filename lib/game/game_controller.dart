import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../logging/app_log.dart';
import 'game_config.dart';
import 'game_engine.dart';
import 'game_state.dart';

class GameController extends ChangeNotifier {
  GameController() {
    _init();
  }

  GameState _state = GameState.empty(defaultGridSize);
  final List<GameState> _undoStack = [];
  int _gridSize = defaultGridSize;
  Map<int, int> _bestScores = {};
  bool _disposed = false;

  // Slide animation duration — spawn fires after this delay.
  static const _slideDuration = Duration(milliseconds: 120);

  GameState get state => _state;
  int get gridSize => _gridSize;
  bool get canUndo => _undoStack.isNotEmpty;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _init() async {
    await _loadBestScores();
    final best = _bestScores[_gridSize] ?? 0;
    _state = GameEngine.spawn(GameState.empty(_gridSize, bestScore: best), count: 2);
    if (!_disposed) notifyListeners();
  }

  void newGame(int size) {
    _gridSize = size;
    _undoStack.clear();
    final best = _bestScores[size] ?? 0;
    _state = GameEngine.spawn(GameState.empty(size, bestScore: best), count: 2);
    appLog.info('game', 'game.new', ctx: {'size': size});
    notifyListeners();
  }

  Future<void> move(Direction dir) async {
    if (_state.status == GameStatus.lost) return;
    if (_state.status == GameStatus.won) return;

    final result = GameEngine.move(_state, dir);
    if (result == null) return;

    _pushUndo(_state);
    _state = result.state;

    appLog.info('game', 'game.move', ctx: {
      'dir': dir.name,
      'score': _state.score,
      'merged': result.merged,
    });

    if (_state.status == GameStatus.won) {
      appLog.info('game', 'game.won', ctx: {'score': _state.score});
    }

    _updateBestScore(_state.score);
    notifyListeners(); // Phase 1: tiles slide

    if (_state.status == GameStatus.playing) {
      await Future.delayed(_slideDuration);
      if (_disposed) return;

      _state = GameEngine.spawn(_state);

      if (!GameEngine.hasValidMoves(_state)) {
        _state = _state.copyWith(status: GameStatus.lost);
        appLog.info('game', 'game.over', ctx: {
          'score': _state.score,
          'size': _gridSize,
        });
      }

      notifyListeners(); // Phase 2: new tile pops in
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final scoreBefore = _state.score;
    _state = _undoStack.removeLast();
    appLog.info('game', 'game.undo', ctx: {
      'score_before': scoreBefore,
      'score_after': _state.score,
    });
    notifyListeners();
  }

  void continueAfterWin() {
    _state = _state.copyWith(status: GameStatus.continued);
    appLog.info('game', 'game.continued', ctx: {'score': _state.score});
    notifyListeners();
  }

  void _pushUndo(GameState s) {
    _undoStack.add(s);
    if (_undoStack.length > undoStackMax) _undoStack.removeAt(0);
  }

  void _updateBestScore(int score) {
    final current = _bestScores[_gridSize] ?? 0;
    if (score > current) {
      _bestScores[_gridSize] = score;
      _persistBestScores();
    }
  }

  Future<String> _scoresPath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/2048_scores.json';
  }

  Future<void> _loadBestScores() async {
    if (kIsWeb) return;
    try {
      final file = File(await _scoresPath());
      if (!file.existsSync()) return;
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _bestScores = raw.map((k, v) => MapEntry(int.parse(k), v as int));
    } catch (_) {}
  }

  Future<void> _persistBestScores() async {
    if (kIsWeb) return;
    try {
      final encoded =
          jsonEncode(_bestScores.map((k, v) => MapEntry(k.toString(), v)));
      await File(await _scoresPath()).writeAsString(encoded);
    } catch (_) {}
  }
}
