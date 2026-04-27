import 'package:flutter/material.dart';

import 'enemy.dart';
import 'enemy_widget.dart';

class EnemyPyramidWidget extends StatelessWidget {
  const EnemyPyramidWidget({
    super.key,
    required this.enemies,
    required this.enemyKeys,
  });

  final List<Enemy> enemies;
  final Map<int, GlobalKey> enemyKeys;

  @override
  Widget build(BuildContext context) {
    final alive = enemies.where((e) => !e.isDead).toList();
    final boss = alive.where((e) => e.isBoss).firstOrNull;
    final mid = alive.where((e) => !e.isBoss && e.pyramidRow == 1).toList();
    final front = alive.where((e) => !e.isBoss && e.pyramidRow == 2).toList();

    return SizedBox(
      height: 148,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Boss row
          if (boss != null)
            KeyedSubtree(
              key: enemyKeys.putIfAbsent(boss.id, GlobalKey.new),
              child: EnemyWidget(enemy: boss),
            )
          else
            const SizedBox(height: kBossSize + 6),
          const SizedBox(height: 6),
          // Mid row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: mid.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: KeyedSubtree(
                  key: enemyKeys.putIfAbsent(e.id, GlobalKey.new),
                  child: EnemyWidget(enemy: e),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          // Front row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: front.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: KeyedSubtree(
                  key: enemyKeys.putIfAbsent(e.id, GlobalKey.new),
                  child: EnemyWidget(enemy: e),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
