import 'package:flutter/material.dart';

import 'enemy.dart';

const double kEnemySize = 40.0;
const double kBossSize = 52.0;

class EnemyWidget extends StatelessWidget {
  const EnemyWidget({super.key, required this.enemy});
  final Enemy enemy;

  @override
  Widget build(BuildContext context) {
    final size = enemy.isBoss ? kBossSize : kEnemySize;
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
              borderRadius: BorderRadius.circular(8),
              border: enemy.isBoss
                  ? Border.all(color: const Color(0xFFEDC22E), width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '${enemy.hp}',
                style: TextStyle(
                  fontSize: enemy.isBoss ? 13 : 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: size,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: hpFraction,
                backgroundColor: const Color(0xFFCDC1B4),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
