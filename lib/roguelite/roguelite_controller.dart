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
import 'roguelite_state.dart';

class RogueliteController extends ChangeNotifier {
  RogueliteController() {
    _game.addListener(_onGame);
    _startRun();
  }

  final GameController _game = GameController();
  final Random _rng = Random();
  int _projectileIdCounter = 0;
  int _waveCount = 0;
  bool _disposed = false;

  static const _runDuration = 30;
  static const _initialBossHp = 256;

  RogueliteState _state = RogueliteState(
    coins: 0,
    talentPoints: 0,
    timeRemaining: _runDuration,
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
    _waveCount = 0;
    _game.newGame(_game.gridSize);
    _state = _state.copyWith(
      timeRemaining: _runDuration,
      isRunning: true,
      enemies: EnemyFactory.initialPyramid(_rng),
      projectiles: [],
      showBossDefeated: false,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    appLog.info('roguelite', 'roguelite.run_start', ctx: {
      'coins': _state.coins,
      'talent_pts': _state.talentPoints,
    });
    notifyListeners();
  }

  void _onTick(Timer t) {
    final remaining = _state.timeRemaining - 1;
    if (remaining <= 0) {
      _state = _state.copyWith(timeRemaining: 0);
      _endRun();
    } else {
      _state = _state.copyWith(timeRemaining: remaining);
      notifyListeners();
    }
  }

  void _endRun() {
    _timer?.cancel();
    _timer = null;
    _state = _state.copyWith(isRunning: false, projectiles: []);
    appLog.info('roguelite', 'roguelite.run_end', ctx: {
      'coins': _state.coins,
      'talent_pts': _state.talentPoints,
    });
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!_disposed) _startRun();
    });
  }

  Future<void> move(Direction dir) async {
    if (!_state.isRunning) return;
    if (_game.state.status == GameStatus.won) _game.continueAfterWin();
    // Preview first (pure, no side effects) to capture merge events
    final preview = GameEngine.move(_game.state, dir);
    if (preview == null) return;
    await _game.move(dir);
    _spawnProjectiles(preview.mergeEvents);
    // notifyListeners called by _onGame forwarding from _game
  }

  void undo() {
    if (!_state.isRunning) return;
    _game.undo();
    // Cancel in-flight projectiles for the undone move
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
        damage: e.value,
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
    final front = alive.where((e) => !e.isBoss && e.pyramidRow == 2).toList();
    if (front.isNotEmpty) {
      front.sort((a, b) => a.pyramidCol.compareTo(b.pyramidCol));
      return front.first;
    }
    final mid = alive.where((e) => !e.isBoss && e.pyramidRow == 1).toList();
    if (mid.isNotEmpty) {
      mid.sort((a, b) => a.pyramidCol.compareTo(b.pyramidCol));
      return mid.first;
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
    final coins = _state.coins + enemy.coinReward;
    final remaining = _state.enemies.where((e) => e.id != enemy.id).toList();
    _state = _state.copyWith(coins: coins, enemies: remaining);

    appLog.info('roguelite', 'roguelite.enemy_killed', ctx: {
      'coins_gained': enemy.coinReward,
      'total_coins': coins,
    });

    // Front row cleared → shift mid to front, spawn new back row
    if (_state.frontRow.isEmpty && _state.midRow.isNotEmpty) {
      _waveCount++;
      final advanced = _state.enemies.map((e) {
        if (!e.isBoss && e.pyramidRow == 1) return e.copyWith(pyramidRow: 2);
        return e;
      }).toList();
      final newBack = EnemyFactory.spawnBackRow(_rng, _waveCount);
      _state = _state.copyWith(enemies: [...advanced, ...newBack]);
      appLog.info('roguelite', 'roguelite.wave_advance',
          ctx: {'wave': _waveCount});
    }
    notifyListeners();
  }

  void _onBossDeath() {
    final talentPoints = _state.talentPoints + 1;
    final newBossMaxHp = _state.bossMaxHp * 2;
    final newBoss = EnemyFactory.spawnBoss(_rng, newBossMaxHp);
    final enemiesWithoutBoss =
        _state.enemies.where((e) => !e.isBoss).toList();

    _state = _state.copyWith(
      talentPoints: talentPoints,
      bossMaxHp: newBossMaxHp,
      enemies: [...enemiesWithoutBoss, newBoss],
      showBossDefeated: true,
    );

    appLog.info('roguelite', 'roguelite.boss_killed', ctx: {
      'talent_pts': talentPoints,
      'new_boss_hp': newBossMaxHp,
    });

    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!_disposed) {
        _state = _state.copyWith(showBossDefeated: false);
        notifyListeners();
      }
    });
  }

  void selectGridSize(int size) {
    if (_state.isRunning) return;
    _game.newGame(size);
  }

  void _onGame() => notifyListeners();

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _game.removeListener(_onGame);
    _game.dispose();
    super.dispose();
  }
}
