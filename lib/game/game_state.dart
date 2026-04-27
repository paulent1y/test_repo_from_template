enum GameStatus { playing, won, continued, lost }

enum Direction { up, down, left, right }

class TileData {
  const TileData({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
  });

  final int id;
  final int value;
  final int row;
  final int col;

  TileData copyWith({int? id, int? value, int? row, int? col}) => TileData(
        id: id ?? this.id,
        value: value ?? this.value,
        row: row ?? this.row,
        col: col ?? this.col,
      );
}

class GameState {
  const GameState({
    required this.tiles,
    required this.score,
    required this.bestScore,
    required this.status,
    required this.size,
  });

  factory GameState.empty(int size, {int bestScore = 0}) => GameState(
        tiles: const [],
        score: 0,
        bestScore: bestScore,
        status: GameStatus.playing,
        size: size,
      );

  final List<TileData> tiles;
  final int score;
  final int bestScore;
  final GameStatus status;
  final int size;

  List<List<int>> get grid {
    final g = List.generate(size, (_) => List.filled(size, 0));
    for (final t in tiles) {
      g[t.row][t.col] = t.value;
    }
    return g;
  }

  GameState copyWith({
    List<TileData>? tiles,
    int? score,
    int? bestScore,
    GameStatus? status,
    int? size,
  }) =>
      GameState(
        tiles: tiles ?? this.tiles,
        score: score ?? this.score,
        bestScore: bestScore ?? this.bestScore,
        status: status ?? this.status,
        size: size ?? this.size,
      );
}
