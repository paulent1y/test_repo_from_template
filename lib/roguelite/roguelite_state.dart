import 'enemy.dart';
import 'projectile.dart';

class RogueliteState {
  const RogueliteState({
    required this.coins,
    required this.talentPoints,
    required this.timeRemaining,
    required this.isRunning,
    required this.enemies,
    required this.projectiles,
    required this.bossMaxHp,
    this.showBossDefeated = false,
  });

  final int coins;
  final int talentPoints;
  final int timeRemaining;
  final bool isRunning;
  final List<Enemy> enemies;
  final List<Projectile> projectiles;
  final int bossMaxHp;
  final bool showBossDefeated;

  Enemy? get boss => enemies.where((e) => e.isBoss).firstOrNull;
  List<Enemy> get frontRow =>
      enemies.where((e) => !e.isBoss && e.pyramidRow == 2).toList();
  List<Enemy> get midRow =>
      enemies.where((e) => !e.isBoss && e.pyramidRow == 1).toList();

  RogueliteState copyWith({
    int? coins,
    int? talentPoints,
    int? timeRemaining,
    bool? isRunning,
    List<Enemy>? enemies,
    List<Projectile>? projectiles,
    int? bossMaxHp,
    bool? showBossDefeated,
  }) =>
      RogueliteState(
        coins: coins ?? this.coins,
        talentPoints: talentPoints ?? this.talentPoints,
        timeRemaining: timeRemaining ?? this.timeRemaining,
        isRunning: isRunning ?? this.isRunning,
        enemies: enemies ?? this.enemies,
        projectiles: projectiles ?? this.projectiles,
        bossMaxHp: bossMaxHp ?? this.bossMaxHp,
        showBossDefeated: showBossDefeated ?? this.showBossDefeated,
      );
}
