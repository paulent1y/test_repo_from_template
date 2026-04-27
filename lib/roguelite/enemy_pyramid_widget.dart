import 'package:flutter/material.dart';

import 'enemy.dart';
import 'enemy_widget.dart';

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
    final mid = alive.where((e) => !e.isBoss && e.pyramidRow == 1).toList();
    final front = alive.where((e) => !e.isBoss && e.pyramidRow == 2).toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 110),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Boss row
          if (boss != null)
            EnemyWidget(
              key: enemyKeys.putIfAbsent(boss.id, GlobalKey.new),
              enemy: boss,
              bossMaxHp: bossMaxHp,
            )
          else
            const SizedBox(height: kBossDisplaySize + 4),
          const SizedBox(height: 4),
          // Mid row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: mid.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: EnemyWidget(
                  key: enemyKeys.putIfAbsent(e.id, GlobalKey.new),
                  enemy: e,
                  bossMaxHp: bossMaxHp,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          // Front row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: front.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: EnemyWidget(
                  key: enemyKeys.putIfAbsent(e.id, GlobalKey.new),
                  enemy: e,
                  bossMaxHp: bossMaxHp,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
