import 'dart:math';
import 'dart:ui';

import 'enemy.dart';

// (pyramidRow, count, hp)
const _rowConfig = [(1, 2, 8), (2, 4, 4), (3, 6, 2)];

class EnemyFactory {
  static int _idCounter = 0;
  static int _newId() => ++_idCounter;

  static List<Enemy> initialPyramid(Random rng, {required int bossMaxHp}) {
    final bossN = (log(bossMaxHp.toDouble()) / log(2)).round();
    final enemies = <Enemy>[];

    for (final (row, count, hp) in _rowConfig) {
      for (var col = 0; col < count; col++) {
        enemies.add(_make(rng, row: row, col: col, hp: hp));
      }
    }

    enemies.add(_makeBoss(rng, n: bossN, bossMaxHp: bossMaxHp));
    return enemies;
  }

  static Enemy spawnBoss(Random rng, int bossMaxHp) {
    final n = (log(bossMaxHp.toDouble()) / log(2)).round();
    return _makeBoss(rng, n: n, bossMaxHp: bossMaxHp);
  }

  static Enemy _make(Random rng, {required int row, required int col, required int hp}) =>
      Enemy(
        id: _newId(),
        hp: hp,
        maxHp: hp,
        coinReward: 1,
        isBoss: false,
        pyramidRow: row,
        pyramidCol: col,
        jitter: _jitter(rng),
      );

  static Enemy _makeBoss(Random rng, {required int n, required int bossMaxHp}) =>
      Enemy(
        id: _newId(),
        hp: bossMaxHp,
        maxHp: bossMaxHp,
        coinReward: n,
        isBoss: true,
        pyramidRow: 0,
        pyramidCol: 0,
        jitter: _jitter(rng),
      );

  static Offset _jitter(Random rng) =>
      Offset(rng.nextDouble() * 10 - 5, rng.nextDouble() * 10 - 5);
}
