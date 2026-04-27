import 'dart:math';
import 'dart:ui';

import 'enemy.dart';

class EnemyFactory {
  static int _idCounter = 0;
  static int _newId() => ++_idCounter;

  static List<Enemy> initialPyramid(Random rng) {
    final enemies = <Enemy>[];
    // Front row (pyramidRow=2): 4 enemies, n in [2,4]
    for (var col = 0; col < 4; col++) {
      final n = 2 + rng.nextInt(3); // 2,3,4
      enemies.add(_make(rng, n: n, isBoss: false, row: 2, col: col));
    }
    // Mid row (pyramidRow=1): 3 enemies, n in [4,6]
    for (var col = 0; col < 3; col++) {
      final n = 4 + rng.nextInt(3); // 4,5,6
      enemies.add(_make(rng, n: n, isBoss: false, row: 1, col: col));
    }
    // Boss (pyramidRow=0)
    enemies.add(_make(rng, n: 8, isBoss: true, row: 0, col: 0));
    return enemies;
  }

  static List<Enemy> spawnBackRow(Random rng, int difficulty) {
    final enemies = <Enemy>[];
    // New back row at pyramidRow=1 (mid), 3 enemies, difficulty bumps n range
    final base = 4 + difficulty.clamp(0, 4);
    for (var col = 0; col < 3; col++) {
      final n = base + rng.nextInt(3);
      enemies.add(_make(rng, n: n, isBoss: false, row: 1, col: col));
    }
    return enemies;
  }

  static Enemy spawnBoss(Random rng, int bossMaxHp) {
    final n = (log(bossMaxHp) / log(2)).round();
    return Enemy(
      id: _newId(),
      hp: bossMaxHp,
      maxHp: bossMaxHp,
      coinReward: n,
      isBoss: true,
      pyramidRow: 0,
      pyramidCol: 0,
      jitter: _jitter(rng),
    );
  }

  static Enemy _make(
    Random rng, {
    required int n,
    required bool isBoss,
    required int row,
    required int col,
  }) {
    final hp = 1 << n; // 2^n
    return Enemy(
      id: _newId(),
      hp: hp,
      maxHp: hp,
      coinReward: n,
      isBoss: isBoss,
      pyramidRow: row,
      pyramidCol: col,
      jitter: _jitter(rng),
    );
  }

  static Offset _jitter(Random rng) =>
      Offset(rng.nextDouble() * 20 - 10, rng.nextDouble() * 20 - 10);
}
