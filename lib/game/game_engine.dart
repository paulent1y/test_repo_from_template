import 'dart:math';

import 'game_config.dart';
import 'game_state.dart';

class MergeEvent {
  const MergeEvent({required this.row, required this.col, required this.value});
  final int row;
  final int col;
  final int value;
}

class MoveResult {
  const MoveResult({
    required this.state,
    required this.merged,
    required this.mergeEvents,
  });
  final GameState state;
  final int merged;
  final List<MergeEvent> mergeEvents;
}

class GameEngine {
  static final Random _rng = Random();
  static int _idCounter = 0;
  static int _newId() => ++_idCounter;

  /// Slide + merge tiles in [dir]. Returns null if nothing moved.
  /// Does NOT spawn a new tile — caller does that separately.
  static MoveResult? move(GameState state, Direction dir) {
    final size = state.size;

    // Build lookup: (row, col) → TileData
    final lookup = <(int, int), TileData>{};
    for (final t in state.tiles) {
      lookup[(t.row, t.col)] = t;
    }

    final newTiles = <TileData>[];
    final mergeEvents = <MergeEvent>[];
    var totalScore = 0;
    var totalMerges = 0;

    for (var lane = 0; lane < size; lane++) {
      // Collect non-empty tiles, ordered from leading edge of direction
      final inLane = <TileData>[];
      for (var pos = 0; pos < size; pos++) {
        final (r, c) = _toRC(dir, lane, pos, size);
        final t = lookup[(r, c)];
        if (t != null) inLane.add(t);
      }

      var outPos = 0;
      var i = 0;
      while (i < inLane.length) {
        final (nr, nc) = _toRC(dir, lane, outPos, size);
        if (i + 1 < inLane.length && inLane[i].value == inLane[i + 1].value) {
          final val = inLane[i].value * 2;
          totalScore += val;
          totalMerges++;
          mergeEvents.add(MergeEvent(row: nr, col: nc, value: val));
          newTiles.add(TileData(id: _newId(), value: val, row: nr, col: nc));
          i += 2;
        } else {
          newTiles.add(inLane[i].copyWith(row: nr, col: nc));
          i++;
        }
        outPos++;
      }
    }

    if (_sameGrid(state.tiles, newTiles, state.size)) return null;

    final newScore = state.score + totalScore;
    final newBest = max(state.bestScore, newScore);

    GameStatus newStatus = state.status;
    if (state.status == GameStatus.playing && _hasWon(newTiles)) {
      newStatus = GameStatus.won;
    }

    return MoveResult(
      state: state.copyWith(
        tiles: newTiles,
        score: newScore,
        bestScore: newBest,
        status: newStatus,
      ),
      merged: totalMerges,
      mergeEvents: mergeEvents,
    );
  }

  /// Spawn [count] new tiles at random empty cells.
  /// [spawnValues] must have at least one element; index 0 = common (90%),
  /// index 1 = rare (10%). Pass upgraded lists for roguelite talent effects.
  static GameState spawn(
    GameState state, {
    int count = 1,
    List<int> spawnValues = defaultSpawnValues,
  }) {
    final grid = state.grid;
    final empties = <(int, int)>[];
    for (var r = 0; r < state.size; r++) {
      for (var c = 0; c < state.size; c++) {
        if (grid[r][c] == 0) empties.add((r, c));
      }
    }
    if (empties.isEmpty) return state;
    empties.shuffle(_rng);
    final common = spawnValues[0];
    final rare = spawnValues.length > 1 ? spawnValues[1] : spawnValues[0];
    final newTiles = List<TileData>.from(state.tiles);
    for (var i = 0; i < count && i < empties.length; i++) {
      final (r, c) = empties[i];
      newTiles.add(TileData(
        id: _newId(),
        value: _rng.nextDouble() < 0.9 ? common : rare,
        row: r,
        col: c,
      ));
    }
    return state.copyWith(tiles: newTiles);
  }

  static bool hasValidMoves(GameState state) {
    final g = state.grid;
    final s = state.size;
    for (var r = 0; r < s; r++) {
      for (var c = 0; c < s; c++) {
        if (g[r][c] == 0) return true;
        if (c + 1 < s && g[r][c] == g[r][c + 1]) return true;
        if (r + 1 < s && g[r][c] == g[r + 1][c]) return true;
      }
    }
    return false;
  }

  static (int, int) _toRC(Direction dir, int lane, int pos, int size) =>
      switch (dir) {
        Direction.left => (lane, pos),
        Direction.right => (lane, size - 1 - pos),
        Direction.up => (pos, lane),
        Direction.down => (size - 1 - pos, lane),
      };

  static bool _hasWon(List<TileData> tiles) =>
      tiles.any((t) => t.value >= winTile);

  static bool _sameGrid(List<TileData> a, List<TileData> b, int size) {
    if (a.length != b.length) return false;
    final ag = <(int, int), int>{for (final t in a) (t.row, t.col): t.value};
    final bg = <(int, int), int>{for (final t in b) (t.row, t.col): t.value};
    if (ag.length != bg.length) return false;
    for (final e in ag.entries) {
      if (bg[e.key] != e.value) return false;
    }
    return true;
  }
}
