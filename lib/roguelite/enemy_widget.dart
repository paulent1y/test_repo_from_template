import 'dart:math' show log;

import 'package:flutter/material.dart';

import '../debug/wireframe_wrapper.dart';
import 'enemy.dart';
import 'roguelite_layout.dart';

const _cBox    = Color(0xFFFFB300); // amber
const _cHpBar  = Color(0xFFE64A19); // deep-orange

// Kept for external callers that reference kBossDisplaySize directly.
const double kBossDisplaySize = RogueliteLayout.enemyBossSize;

const double _kMinN = 2.0;

double enemyDisplaySize(int enemyMaxHp, int bossMaxHp) {
  if (enemyMaxHp >= bossMaxHp) return RogueliteLayout.enemyBossSize;
  final bossN = log(bossMaxHp.toDouble()) / log(2);
  final enemyN = log(enemyMaxHp.clamp(2, bossMaxHp).toDouble()) / log(2);
  if (bossN <= _kMinN) return RogueliteLayout.enemyBossSize;
  final ratio = ((enemyN - _kMinN) / (bossN - _kMinN)).clamp(0.0, 1.0);
  return RogueliteLayout.enemyMinSize +
      (RogueliteLayout.enemyBossSize - RogueliteLayout.enemyMinSize) * ratio;
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
          WireframeWrapper(
            label: 'box',
            color: _cBox,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: enemy.isBoss
                    ? const Color(0xFF3C3A32)
                    : const Color(0xFF8F7A66),
                borderRadius: BorderRadius.circular(RogueliteLayout.enemyRadius),
                border: enemy.isBoss
                    ? Border.all(
                        color: const Color(0xFFEDC22E),
                        width: RogueliteLayout.enemyBossBoderWidth,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  '${enemy.hp}',
                  style: TextStyle(
                    fontSize: (size * RogueliteLayout.enemyTextScale)
                        .clamp(RogueliteLayout.enemyTextMin, RogueliteLayout.enemyTextMax),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: RogueliteLayout.enemyHpBarGap),
          WireframeWrapper(
            label: 'hp',
            color: _cHpBar,
            child: SizedBox(
              width: size,
              height: RogueliteLayout.enemyHpBarHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  RogueliteLayout.enemyHpBarHeight / 2,
                ),
                child: LinearProgressIndicator(
                  value: hpFraction,
                  backgroundColor: const Color(0xFFCDC1B4),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: RogueliteLayout.enemyHpBarHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
