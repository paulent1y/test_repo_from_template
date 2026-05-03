import 'enemy.dart';
import 'projectile.dart';

class RunStats {
  const RunStats({
    required this.roundTimeMs,
    required this.enemiesKilled,
    required this.coinsEarned,
    required this.pointsEarned,
    required this.maxTileValue,
    required this.moveCount,
    required this.bestMovesSession,
    required this.avgMovesSession,
    this.bossKilled = false,
  });

  final int roundTimeMs;
  final int enemiesKilled;
  final int coinsEarned;
  final int pointsEarned;
  final int maxTileValue;
  final int moveCount;
  final int bestMovesSession;
  final int avgMovesSession;
  final bool bossKilled;

  int get avgMsPerMove => moveCount > 0 ? roundTimeMs ~/ moveCount : 0;
}

class RogueliteState {
  const RogueliteState({
    required this.coins,
    required this.talentPoints,
    required this.timeRemainingMs,
    required this.isRunning,
    required this.enemies,
    required this.projectiles,
    required this.bossMaxHp,
    this.showBossDefeated = false,
    this.showRunEnd = false,
    this.lastRunStats,
    // Talent upgrades (one-time)
    this.boardSizeUpgraded = false,
    this.spawnValueUpgraded = false,
    // Coin upgrades (stackable)
    this.bonusDamage = 0,
    this.bonusCoinPerKill = 0,
    this.bonusTimeSec = 0,
  });

  final int coins;
  final int talentPoints;
  final int timeRemainingMs;
  final bool isRunning;
  final List<Enemy> enemies;
  final List<Projectile> projectiles;
  final int bossMaxHp;
  final bool showBossDefeated;
  final bool showRunEnd;
  final RunStats? lastRunStats;

  final bool boardSizeUpgraded;
  final bool spawnValueUpgraded;
  final int bonusDamage;
  final int bonusCoinPerKill;
  final int bonusTimeSec;

  Enemy? get boss => enemies.where((e) => e.isBoss).firstOrNull;
  List<Enemy> get frontRow =>
      enemies.where((e) => !e.isBoss && e.pyramidRow == 3).toList();
  List<Enemy> get midRow =>
      enemies.where((e) => !e.isBoss && e.pyramidRow == 2).toList();

  RogueliteState copyWith({
    int? coins,
    int? talentPoints,
    int? timeRemainingMs,
    bool? isRunning,
    List<Enemy>? enemies,
    List<Projectile>? projectiles,
    int? bossMaxHp,
    bool? showBossDefeated,
    bool? showRunEnd,
    RunStats? lastRunStats,
    bool? boardSizeUpgraded,
    bool? spawnValueUpgraded,
    int? bonusDamage,
    int? bonusCoinPerKill,
    int? bonusTimeSec,
  }) =>
      RogueliteState(
        coins: coins ?? this.coins,
        talentPoints: talentPoints ?? this.talentPoints,
        timeRemainingMs: timeRemainingMs ?? this.timeRemainingMs,
        isRunning: isRunning ?? this.isRunning,
        enemies: enemies ?? this.enemies,
        projectiles: projectiles ?? this.projectiles,
        bossMaxHp: bossMaxHp ?? this.bossMaxHp,
        showBossDefeated: showBossDefeated ?? this.showBossDefeated,
        showRunEnd: showRunEnd ?? this.showRunEnd,
        lastRunStats: lastRunStats ?? this.lastRunStats,
        boardSizeUpgraded: boardSizeUpgraded ?? this.boardSizeUpgraded,
        spawnValueUpgraded: spawnValueUpgraded ?? this.spawnValueUpgraded,
        bonusDamage: bonusDamage ?? this.bonusDamage,
        bonusCoinPerKill: bonusCoinPerKill ?? this.bonusCoinPerKill,
        bonusTimeSec: bonusTimeSec ?? this.bonusTimeSec,
      );
}
