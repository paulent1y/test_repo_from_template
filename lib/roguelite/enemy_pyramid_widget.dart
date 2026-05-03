import 'package:flutter/material.dart';

import '../debug/wireframe_wrapper.dart';
import 'enemy.dart';
import 'enemy_widget.dart';
import 'roguelite_layout.dart';

const _cBossRow = Color(0xFFFFD600);
const _cRow1    = Color(0xFFFF9800);
const _cRow2    = Color(0xFFFF7043);
const _cRow3    = Color(0xFFFF5722);

class EnemyPyramidWidget extends StatelessWidget {
  const EnemyPyramidWidget({
    super.key,
    required this.enemies,
    required this.enemyKeys,
    required this.bossMaxHp,
  });

  final List<Enemy> enemies;
  final Map<int, GlobalKey> enemyKeys;
  final int bossMaxHp;

  @override
  Widget build(BuildContext context) {
    final alive = enemies.where((e) => !e.isDead).toList();
    final boss = alive.where((e) => e.isBoss).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _bossRow(boss),
        Expanded(child: _enemyRow(alive, row: 1, label: 'row-1', color: _cRow1, hPad: RogueliteLayout.pyramidMidHPad)),
        Expanded(child: _enemyRow(alive, row: 2, label: 'row-2', color: _cRow2, hPad: RogueliteLayout.pyramidFrontHPad)),
        Expanded(child: _enemyRow(alive, row: 3, label: 'row-3', color: _cRow3, hPad: RogueliteLayout.pyramidDenseHPad)),
      ],
    );
  }

  Widget _bossRow(Enemy? boss) {
    return WireframeWrapper(
      label: 'row-boss',
      color: _cBossRow,
      child: SizedBox(
        height: RogueliteLayout.pyramidRowHeight,
        child: boss != null
            ? Center(
                child: EnemyWidget(
                  key: enemyKeys.putIfAbsent(boss.id, GlobalKey.new),
                  enemy: boss,
                  bossMaxHp: bossMaxHp,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _enemyRow(
    List<Enemy> alive, {
    required int row,
    required String label,
    required Color color,
    required double hPad,
  }) {
    final rowEnemies = alive.where((e) => !e.isBoss && e.pyramidRow == row).toList();
    return WireframeWrapper(
      label: label,
      color: color,
      child: rowEnemies.isEmpty
          ? const SizedBox.shrink()
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: rowEnemies.map((e) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: EnemyWidget(
                    key: enemyKeys.putIfAbsent(e.id, GlobalKey.new),
                    enemy: e,
                    bossMaxHp: bossMaxHp,
                  ),
                );
              }).toList(),
            ),
    );
  }
}
