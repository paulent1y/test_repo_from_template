import 'package:flutter/painting.dart';

class Projectile {
  const Projectile({
    required this.id,
    required this.damage,
    required this.originCell,
    required this.targetEnemyId,
    required this.color,
  });

  final int id;
  final int damage;
  final ({int row, int col}) originCell;
  final int targetEnemyId;
  final Color color;
}
