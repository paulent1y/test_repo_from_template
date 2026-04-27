import 'dart:ui';

class Enemy {
  Enemy({
    required this.id,
    required this.hp,
    required this.maxHp,
    required this.coinReward,
    required this.isBoss,
    required this.pyramidRow,
    required this.pyramidCol,
    required this.jitter,
  });

  final int id;
  int hp;
  final int maxHp;
  final int coinReward;
  final bool isBoss;
  final int pyramidRow;
  final int pyramidCol;
  final Offset jitter;

  bool get isDead => hp <= 0;

  Enemy copyWith({
    int? hp,
    int? maxHp,
    int? pyramidRow,
    int? pyramidCol,
  }) =>
      Enemy(
        id: id,
        hp: hp ?? this.hp,
        maxHp: maxHp ?? this.maxHp,
        coinReward: coinReward,
        isBoss: isBoss,
        pyramidRow: pyramidRow ?? this.pyramidRow,
        pyramidCol: pyramidCol ?? this.pyramidCol,
        jitter: jitter,
      );
}
