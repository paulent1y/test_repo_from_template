import '../game/game_config.dart';

class RogueliteSaveData {
  const RogueliteSaveData({
    this.coins = 0,
    this.talentPoints = 0,
    this.bossMaxHp = 16,
    this.boardSizeUpgraded = false,
    this.spawnValueUpgraded = false,
    this.bonusDamage = 0,
    this.bonusCoinPerKill = 0,
    this.bonusTimeSec = 0,
    this.baseGridSize = defaultGridSize,
  });

  final int coins;
  final int talentPoints;
  final int bossMaxHp;
  final bool boardSizeUpgraded;
  final bool spawnValueUpgraded;
  final int bonusDamage;
  final int bonusCoinPerKill;
  final int bonusTimeSec;
  final int baseGridSize;

  factory RogueliteSaveData.fromJson(Map<String, dynamic> json) =>
      RogueliteSaveData(
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        talentPoints: (json['talentPoints'] as num?)?.toInt() ?? 0,
        bossMaxHp: (json['bossMaxHp'] as num?)?.toInt() ?? 16,
        boardSizeUpgraded: json['boardSizeUpgraded'] as bool? ?? false,
        spawnValueUpgraded: json['spawnValueUpgraded'] as bool? ?? false,
        bonusDamage: (json['bonusDamage'] as num?)?.toInt() ?? 0,
        bonusCoinPerKill: (json['bonusCoinPerKill'] as num?)?.toInt() ?? 0,
        bonusTimeSec: (json['bonusTimeSec'] as num?)?.toInt() ?? 0,
        baseGridSize:
            (json['baseGridSize'] as num?)?.toInt() ?? defaultGridSize,
      );

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'talentPoints': talentPoints,
        'bossMaxHp': bossMaxHp,
        'boardSizeUpgraded': boardSizeUpgraded,
        'spawnValueUpgraded': spawnValueUpgraded,
        'bonusDamage': bonusDamage,
        'bonusCoinPerKill': bonusCoinPerKill,
        'bonusTimeSec': bonusTimeSec,
        'baseGridSize': baseGridSize,
      };
}
