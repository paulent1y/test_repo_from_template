import 'dart:math' show log;

import 'package:flutter/material.dart';

import 'enemy.dart';

const double kBossDisplaySize = 44.0;
const double _kMinDisplaySize = 16.0;
const double _kMinN = 2.0;

double enemyDisplaySize(int enemyMaxHp, int bossMaxHp) {
  if (enemyMaxHp >= bossMaxHp) return kBossDisplaySize;
  final bossN = log(bossMaxHp.toDouble()) / log(2);
  final enemyN =
      log(enemyMaxHp.clamp(2, bossMaxHp).toDouble()) / log(2);
  if (bossN <= _kMinN) return kBossDisplaySize;
  final ratio = ((enemyN - _kMinN) / (bossN - _kMinN)).clamp(0.0, 1.0);
  return _kMinDisplaySize +
      (kBossDisplaySize - _kMinDisplaySize) * ratio;
}

class EnemyWidget extends StatelessWidget {
  const EnemyWidget({
    super.key,
    required this.enemy,
    required this.bossMaxHp,
  });

  final Enemy enemy;
  final int bossMaxHp;

  @override
  Widget build(BuildContext context) {
    final size = enemy.isBoss
        ? kBossDisplaySize
        : enemyDisplaySize(enemy.maxHp, bossMaxHp);
    final hpFraction = enemy.hp / enemy.maxHp;
    final barColor = enemy.isBoss
        ? const Color(0xFFEDC22E)
        : enemy.pyramidRow == 1
            ? Colors.orange
            : Colors.redAccent;

    return Transform.translate(
      offset: enemy.jitter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: enemy.isBoss
                  ? const Color(0xFF3C3A32)
                  : const Color(0xFF8F7A66),
              borderRadius: BorderRadius.circular(6),
              border: enemy.isBoss
                  ? Border.all(color: const Color(0xFFEDC22E), width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '${enemy.hp}',
                style: TextStyle(
                  fontSize: (size * 0.28).clamp(8.0, 13.0),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),
          SizedBox(
            width: size,
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1.5),
              child: LinearProgressIndicator(
                value: hpFraction,
                backgroundColor: const Color(0xFFCDC1B4),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
