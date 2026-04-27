import 'dart:math';
import 'dart:ui';

import 'enemy.dart';

class EnemyFactory {
  static int _idCounter = 0;
  static int _newId() => ++_idCounter;

  static List<Enemy> initialPyramid(Random rng, {required int bossMaxHp}) {
    final bossN = (log(bossMaxHp.toDouble()) / log(2)).round(); // 8 for 256
    final maxEnemyN = (bossN - 1).clamp(2, 99);

    final enemies = <Enemy>[];
    // Front row (pyramidRow=2): 4 enemies, n in [2, min(4, maxEnemyN)]
    for (var col = 0; col < 4; col++) {
      final n = (2 + rng.nextInt(3)).clamp(2, maxEnemyN); // 2,3,4 capped
      enemies.add(_make(rng, n: n, isBoss: false, row: 2, col: col));
    }
    // Mid row (pyramidRow=1): 3 enemies, n in [4, min(6, maxEnemyN)]
    for (var col = 0; col < 3; col++) {
      final base = 4.clamp(2, maxEnemyN);
      final spread = (min(6, maxEnemyN) - base).clamp(0, 99);
      final n = base + (spread > 0 ? rng.nextInt(spread + 1) : 0);
      enemies.add(_make(rng, n: n, isBoss: false, row: 1, col: col));
    }
    // Boss (pyramidRow=0)
    enemies.add(_make(rng, n: bossN, isBoss: true, row: 0, col: 0));
    return enemies;
  }

  static Enemy spawnBoss(Random rng, int bossMaxHp) {
    final n = (log(bossMaxHp.toDouble()) / log(2)).round();
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
      Offset(rng.nextDouble() * 10 - 5, rng.nextDouble() * 10 - 5);
}
