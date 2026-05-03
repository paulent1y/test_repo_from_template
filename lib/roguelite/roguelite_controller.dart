import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../game/game_config.dart';
import '../game/game_controller.dart';
import '../game/game_engine.dart';
import '../game/game_state.dart';
import '../logging/app_log.dart';
import 'enemy.dart';
import 'enemy_factory.dart';
import 'projectile.dart';
import 'roguelite_state.dart' show RogueliteState, RunStats;
import 'save_data.dart';
import 'save_service.dart';

enum TalentUpgradeType { boardSize, spawnValue }
enum CoinUpgradeType { damage, coinPerKill, timeSec }

class RogueliteController extends ChangeNotifier {
  RogueliteController() {
    _game.addListener(_onGame);
    _loadSave();
  }

  final GameController _game = GameController();
  final RogueliteSaveService _saveService = RogueliteSaveService();
  final Random _rng = Random();
  int _projectileIdCounter = 0;
  bool _disposed = false;
  bool _autoRestart = false;
  bool _isPaused = false;
  bool _awaitingEndSequence = false;
  bool _bossKilledThisRun = false;
  int _runStartCoins = 0;
  int _enemiesKilledThisRun = 0;
  int _movesThisRun = 0;
  int _baseGridSize = defaultGridSize;
  int _bestMoveCount = 0;
  int _totalMovesAllRuns = 0;
  int _runCount = 0;

  bool get autoRestart => _autoRestart;
  bool get isPaused => _isPaused;
  bool get awaitingEndSequence => _awaitingEndSequence;
  int get bestMoveCount => _bestMoveCount;

  void pauseRun() {
    if (!_state.isRunning || _isPaused) return;
    _isPaused = true;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void resumeRun() {
    if (!_state.isRunning || !_isPaused) return;
    _isPaused = false;
    _timer = Timer.periodic(const Duration(milliseconds: 100), _onTick);
    notifyListeners();
  }

  void toggleAutoRestart() {
    _autoRestart = !_autoRestart;
    notifyListeners();
  }

  void restartRun() => _startRun();

  Future<void> _loadSave() async {
    final saved = await _saveService.load();
    if (saved != null && !_disposed) {
      _baseGridSize = saved.baseGridSize;
      _state = _state.copyWith(
        coins: saved.coins,
        talentPoints: saved.talentPoints,
        bossMaxHp: saved.bossMaxHp,
        boardSizeUpgraded: saved.boardSizeUpgraded,
        spawnValueUpgraded: saved.spawnValueUpgraded,
        bonusDamage: saved.bonusDamage,
        bonusCoinPerKill: saved.bonusCoinPerKill,
        bonusTimeSec: saved.bonusTimeSec,
      );
    }
    if (!_disposed) _startRun();
  }

  void _save() {
    _saveService.save(RogueliteSaveData(
      coins: _state.coins,
      talentPoints: _state.talentPoints,
      bossMaxHp: _state.bossMaxHp,
      boardSizeUpgraded: _state.boardSizeUpgraded,
      spawnValueUpgraded: _state.spawnValueUpgraded,
      bonusDamage: _state.bonusDamage,
      bonusCoinPerKill: _state.bonusCoinPerKill,
      bonusTimeSec: _state.bonusTimeSec,
      baseGridSize: _baseGridSize,
    ));
  }

  static const _baseRunDurationMs = 10000;
  static const _initialBossHp = 16;
  static const _coinUpgradeCost = 10;
  static const _talentUpgradeCost = 1;

  RogueliteState _state = const RogueliteState(
    coins: 0,
    talentPoints: 0,
    timeRemainingMs: _baseRunDurationMs,
    isRunning: false,
    enemies: [],
    projectiles: [],
    bossMaxHp: _initialBossHp,
  );
  Timer? _timer;

  GameState get gameState => _game.state;
  int get gridSize => _game.gridSize;
  bool get canUndo => _game.canUndo;
  RogueliteState get rogueliteState => _state;

  void _startRun() {
    _timer?.cancel();
    _isPaused = false;
    _awaitingEndSequence = false;
    _bossKilledThisRun = false;
    final gridSize = _baseGridSize + (_state.boardSizeUpgraded ? 1 : 0);
    _game.newGame(gridSize);
    _game.setSpawnValues(_state.spawnValueUpgraded ? [2, 4] : defaultSpawnValues);
    _runStartCoins = _state.coins;
    _enemiesKilledThisRun = 0;
    _movesThisRun = 0;
    final runDurationMs = _baseRunDurationMs + _state.bonusTimeSec * 1000;
    _state = _state.copyWith(
      timeRemainingMs: runDurationMs,
      isRunning: true,
      enemies: EnemyFactory.initialPyramid(_rng, bossMaxHp: _state.bossMaxHp),
      projectiles: [],
      showBossDefeated: false,
      showRunEnd: false,
    );
    _timer = Timer.periodic(const Duration(milliseconds: 100), _onTick);
    appLog.info('roguelite', 'roguelite.run_start', ctx: {
      'coins': _state.coins,
      'talent_pts': _state.talentPoints,
    });
    notifyListeners();
  }

  void _onTick(Timer t) {
    final remaining = _state.timeRemainingMs - 100;
    if (remaining <= 0) {
      _timer?.cancel();
      _timer = null;
      _state = _state.copyWith(timeRemainingMs: 0);
      _awaitingEndSequence = true;
      notifyListeners();
    } else {
      _state = _state.copyWith(timeRemainingMs: remaining);
      notifyListeners();
    }
  }

  void _endRun() {
    _timer?.cancel();
    _timer = null;

    final tiles = _game.state.tiles;
    final maxTile = tiles.isEmpty ? 0 : tiles.map((t) => t.value).reduce(max);
    final runDurationMs = _baseRunDurationMs + _state.bonusTimeSec * 1000;
    _runCount++;
    _totalMovesAllRuns += _movesThisRun;
    if (_movesThisRun > _bestMoveCount) _bestMoveCount = _movesThisRun;
    final stats = RunStats(
      roundTimeMs: runDurationMs - _state.timeRemainingMs,
      enemiesKilled: _enemiesKilledThisRun,
      coinsEarned: _state.coins - _runStartCoins,
      pointsEarned: _game.state.score,
      maxTileValue: maxTile,
      moveCount: _movesThisRun,
      bestMovesSession: _bestMoveCount,
      avgMovesSession: _totalMovesAllRuns ~/ _runCount,
      bossKilled: _bossKilledThisRun,
    );

    _state = _state.copyWith(
      isRunning: false,
      projectiles: [],
      showBossDefeated: false,
      showRunEnd: !_autoRestart,
      lastRunStats: stats,
    );

    appLog.info('roguelite', 'roguelite.run_end', ctx: {
      'coins': _state.coins,
      'talent_pts': _state.talentPoints,
      'enemies_killed': _enemiesKilledThisRun,
    });
    notifyListeners();

    if (_autoRestart) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!_disposed) _startRun();
      });
    }
  }

  Future<void> move(Direction dir) async {
    if (!_state.isRunning) return;
    if (_game.state.status == GameStatus.won) _game.continueAfterWin();
    final preview = GameEngine.move(_game.state, dir);
    if (preview == null) return;
    _movesThisRun++;
    await _game.move(dir);
    _spawnProjectiles(preview.mergeEvents);
  }

  void undo() {
    if (!_state.isRunning) return;
    _game.undo();
    _state = _state.copyWith(projectiles: []);
    notifyListeners();
  }

  void onProjectileHit(int projectileId) {
    final proj = _state.projectiles
        .where((p) => p.id == projectileId)
        .firstOrNull;
    if (proj == null) return;
    _applyDamage(proj.targetEnemyId, proj.damage);
  }

  void onProjectileComplete(int projectileId) {
    _state = _state.copyWith(
      projectiles: _state.projectiles
          .where((p) => p.id != projectileId)
          .toList(),
    );
    notifyListeners();
  }

  void _spawnProjectiles(List<MergeEvent> events) {
    if (events.isEmpty) return;
    final newProjectiles = List<Projectile>.from(_state.projectiles);
    for (final e in events) {
      final target = _pickTarget();
      if (target == null) continue;
      newProjectiles.add(Projectile(
        id: ++_projectileIdCounter,
        damage: e.value + _state.bonusDamage,
        originCell: (row: e.row, col: e.col),
        targetEnemyId: target.id,
        color: tileColor(e.value),
      ));
    }
    _state = _state.copyWith(projectiles: newProjectiles);
  }

  Enemy? _pickTarget() {
    final alive = _state.enemies.where((e) => !e.isDead).toList();
    if (alive.isEmpty) return null;
    final nonBoss = alive.where((e) => !e.isBoss).toList();
    if (nonBoss.isNotEmpty) {
      final maxRow = nonBoss.map((e) => e.pyramidRow).reduce(max);
      final frontLine = nonBoss.where((e) => e.pyramidRow == maxRow).toList();
      return frontLine[_rng.nextInt(frontLine.length)];
    }
    return alive.firstWhere((e) => e.isBoss, orElse: () => alive.first);
  }

  void _applyDamage(int enemyId, int damage) {
    final idx = _state.enemies.indexWhere((e) => e.id == enemyId);
    if (idx == -1) return;
    final enemy = _state.enemies[idx];
    final newHp = (enemy.hp - damage).clamp(0, enemy.maxHp);
    final updated = List<Enemy>.from(_state.enemies);
    updated[idx] = enemy.copyWith(hp: newHp);
    _state = _state.copyWith(enemies: updated);

    if (newHp <= 0) {
      if (enemy.isBoss) {
        _onBossDeath();
      } else {
        _onEnemyDeath(enemy);
      }
    } else {
      notifyListeners();
    }
  }

  void _onEnemyDeath(Enemy enemy) {
    _enemiesKilledThisRun++;
    final coins = _state.coins + enemy.coinReward + _state.bonusCoinPerKill;
    final remaining = _state.enemies.where((e) => e.id != enemy.id).toList();
    _state = _state.copyWith(coins: coins, enemies: remaining);

    appLog.info('roguelite', 'roguelite.enemy_killed', ctx: {
      'coins_gained': enemy.coinReward + _state.bonusCoinPerKill,
      'total_coins': coins,
    });

    _save();
    notifyListeners();
  }

  void _onBossDeath() {
    _timer?.cancel();
    _timer = null;
    final talentPoints = _state.talentPoints + 1;
    final newBossMaxHp = _state.bossMaxHp * 2;

    _state = _state.copyWith(
      talentPoints: talentPoints,
      bossMaxHp: newBossMaxHp,
      showBossDefeated: true,
    );

    appLog.info('roguelite', 'roguelite.boss_killed', ctx: {
      'talent_pts': talentPoints,
      'new_boss_hp': newBossMaxHp,
    });

    _bossKilledThisRun = true;
    _save();
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!_disposed) {
        _awaitingEndSequence = true;
        notifyListeners();
      }
    });
  }

  void buyTalentUpgrade(TalentUpgradeType type) {
    if (_state.talentPoints < _talentUpgradeCost) return;
    switch (type) {
      case TalentUpgradeType.boardSize:
        if (_state.boardSizeUpgraded) return;
        _state = _state.copyWith(
          talentPoints: _state.talentPoints - _talentUpgradeCost,
          boardSizeUpgraded: true,
        );
      case TalentUpgradeType.spawnValue:
        if (_state.spawnValueUpgraded) return;
        _state = _state.copyWith(
          talentPoints: _state.talentPoints - _talentUpgradeCost,
          spawnValueUpgraded: true,
        );
        _game.setSpawnValues([2, 4]);
    }
    appLog.info('roguelite', 'roguelite.talent_upgrade', ctx: {'type': type.name});
    _save();
    notifyListeners();
  }

  void buyCoinUpgrade(CoinUpgradeType type) {
    if (_state.coins < _coinUpgradeCost) return;
    switch (type) {
      case CoinUpgradeType.damage:
        _state = _state.copyWith(
          coins: _state.coins - _coinUpgradeCost,
          bonusDamage: _state.bonusDamage + 1,
        );
      case CoinUpgradeType.coinPerKill:
        _state = _state.copyWith(
          coins: _state.coins - _coinUpgradeCost,
          bonusCoinPerKill: _state.bonusCoinPerKill + 1,
        );
      case CoinUpgradeType.timeSec:
        _state = _state.copyWith(
          coins: _state.coins - _coinUpgradeCost,
          bonusTimeSec: _state.bonusTimeSec + 1,
          timeRemainingMs: _state.isRunning
              ? _state.timeRemainingMs + 1000
              : _state.timeRemainingMs,
        );
    }
    appLog.info('roguelite', 'roguelite.coin_upgrade', ctx: {'type': type.name});
    _save();
    notifyListeners();
  }

  void finalizeEndRun() {
    if (!_awaitingEndSequence) return;
    _awaitingEndSequence = false;
    _endRun();
  }

  void selectGridSize(int size) {
    if (_state.isRunning) return;
    _baseGridSize = size;
    _game.newGame(size + (_state.boardSizeUpgraded ? 1 : 0));
    _game.setSpawnValues(_state.spawnValueUpgraded ? [2, 4] : defaultSpawnValues);
    _save();
  }

  void _onGame() {
    if (_state.isRunning && !_awaitingEndSequence &&
        _game.state.status == GameStatus.lost) {
      _timer?.cancel();
      _timer = null;
      _awaitingEndSequence = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _game.removeListener(_onGame);
    _game.dispose();
    super.dispose();
  }
}
