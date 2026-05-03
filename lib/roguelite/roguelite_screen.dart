import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../debug/wireframe_wrapper.dart';
import '../game/game_state.dart';
import '../ui/control_bar.dart';
import '../ui/game_board.dart';
import 'roguelite_layout.dart';
import 'boss_defeated_overlay.dart';
import 'damage_popup_widget.dart';
import 'enemy_pyramid_widget.dart';
import 'enemy_widget.dart' show enemyDisplaySize;
import 'projectile.dart';
import 'projectile_widget.dart';
import 'roguelite_controller.dart' show RogueliteController, TalentUpgradeType, CoinUpgradeType;
import 'roguelite_header.dart';
import 'roguelite_run_end_overlay.dart';

// Wireframe color palette per layer
const _cHeader   = Color(0xFF2196F3); // blue
const _cPyramid  = Color(0xFFFF9800); // orange
const _cBoard    = Color(0xFF4CAF50); // green
const _cControls = Color(0xFF9C27B0); // purple
const _cExpanded = Color(0xFF00BCD4); // cyan
const _cTabs     = Color(0xFFFFEB3B); // yellow

enum _Tab { talents, coins, battle }

class RogueliteScreen extends StatefulWidget {
  const RogueliteScreen({super.key, required this.controller});
  final RogueliteController controller;

  @override
  State<RogueliteScreen> createState() => _RogueliteScreenState();
}

class _RogueliteScreenState extends State<RogueliteScreen>
    with TickerProviderStateMixin {
  RogueliteController get _ctrl => widget.controller;
  final FocusNode _focusNode = FocusNode();

  _Tab _selectedTab = _Tab.battle;

  final GlobalKey _boardKey = GlobalKey();
  final Map<int, GlobalKey> _enemyKeys = {};
  double _boardSize = 300.0;

  int _popupCounter = 0;
  final List<({int id, Offset pos, int damage, Color color})> _popups = [];

  late final AnimationController _flashCtrl;
  late final AnimationController _boardFadeCtrl;
  bool? _prevIsRunning;
  bool? _prevAwaitingEnd;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _boardFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _boardFadeCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.controller.finalizeEndRun();
      }
    });
    widget.controller.addListener(_onCtrlUpdate);
  }

  void _onCtrlUpdate() {
    final rs = widget.controller.rogueliteState;
    final awaitingEnd = widget.controller.awaitingEndSequence;

    if (awaitingEnd && _prevAwaitingEnd != true) {
      _boardFadeCtrl.forward(from: 0);
    }
    if (rs.isRunning && _prevIsRunning != true) {
      _boardFadeCtrl.reverse();
      _flashCtrl.forward(from: 0);
    }
    _prevAwaitingEnd = awaitingEnd;
    _prevIsRunning = rs.isRunning;
  }

  void _onTabChanged(_Tab tab) {
    if (tab == _Tab.battle) {
      _ctrl.resumeRun();
    } else {
      _ctrl.pauseRun();
    }
    setState(() => _selectedTab = tab);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCtrlUpdate);
    _flashCtrl.dispose();
    _boardFadeCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    Direction? dir;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      dir = Direction.left;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      dir = Direction.right;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.keyW) {
      dir = Direction.up;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.keyS) {
      dir = Direction.down;
    } else if (event.logicalKey == LogicalKeyboardKey.keyZ &&
        HardwareKeyboard.instance.isControlPressed) {
      _ctrl.undo();
      return;
    }
    if (dir != null) _ctrl.move(dir);
  }

  void _onPanEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond;
    const threshold = 150.0;
    if (v.dx.abs() > v.dy.abs()) {
      if (v.dx > threshold) _ctrl.move(Direction.right);
      if (v.dx < -threshold) _ctrl.move(Direction.left);
    } else {
      if (v.dy > threshold) _ctrl.move(Direction.down);
      if (v.dy < -threshold) _ctrl.move(Direction.up);
    }
  }

  Offset _boardCellCenter(int row, int col) {
    const gap = RogueliteLayout.boardCellGap;
    final n = _ctrl.gridSize;
    final tileSize = (_boardSize - gap * (n + 1)) / n;
    return Offset(
      gap + col * (tileSize + gap) + tileSize / 2,
      gap + row * (tileSize + gap) + tileSize / 2,
    );
  }

  Offset? _boardCellGlobal(int row, int col) {
    final ctx = _boardKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(_boardCellCenter(row, col));
  }

  Offset? _enemyGlobal(int enemyId, double size) {
    final key = _enemyKeys[enemyId];
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset(size / 2, size / 2));
  }

  void _onProjectileHit(Projectile p) {
    _ctrl.onProjectileHit(p.id);
    final enemy = _ctrl.rogueliteState.enemies
        .where((e) => e.id == p.targetEnemyId)
        .firstOrNull;
    if (enemy == null) return;
    final eSize = enemyDisplaySize(enemy.maxHp, _ctrl.rogueliteState.bossMaxHp);
    final pos = _enemyGlobal(p.targetEnemyId, eSize);
    if (pos == null) return;
    final id = ++_popupCounter;
    setState(() {
      _popups.add((id: id, pos: pos, damage: p.damage, color: p.color));
    });
  }

  void _onProjectileComplete(Projectile p) {
    _ctrl.onProjectileComplete(p.id);
  }

  void _onPopupComplete(int id) {
    setState(() => _popups.removeWhere((p) => p.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      body: SafeArea(
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: ListenableBuilder(
            listenable: _ctrl,
            builder: (context, _) {
              final rs = _ctrl.rogueliteState;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = constraints.maxHeight;
                  final headerH = screenHeight * RogueliteLayout.zoneHeaderPercent / 100;
                  final enemiesH = screenHeight * RogueliteLayout.zoneEnemiesPercent / 100;
                  final boardH = screenHeight * RogueliteLayout.zoneBoardPercent / 100;
                  final controlsH = screenHeight * RogueliteLayout.zoneControlsPercent / 100;
                  final tabsH = screenHeight * RogueliteLayout.zoneTabsPercent / 100;
                  return Stack(
                    children: [
                      Column(
                        children: [
                          WireframeWrapper(
                            label: 'header ${RogueliteLayout.zoneHeaderPercent.toStringAsFixed(0)}%',
                            color: _cHeader,
                            child: SizedBox(
                              height: headerH,
                              child: RogueliteHeader(
                                talentPoints: rs.talentPoints,
                                timeRemainingMs: rs.timeRemainingMs,
                                coins: rs.coins,
                                isUrgent: rs.timeRemainingMs <= 5000 && rs.isRunning,
                                isPaused: _ctrl.isPaused,
                                onPauseToggle: () => _ctrl.isPaused
                                    ? _ctrl.resumeRun()
                                    : _ctrl.pauseRun(),
                              ),
                            ),
                          ),
                          WireframeWrapper(
                            label: 'enemies ${RogueliteLayout.zoneEnemiesPercent.toStringAsFixed(0)}%',
                            color: _cPyramid,
                            child: SizedBox(
                              height: enemiesH,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: RogueliteLayout.pyramidPadV,
                                ),
                                child: EnemyPyramidWidget(
                                  enemies: rs.enemies,
                                  enemyKeys: _enemyKeys,
                                  bossMaxHp: rs.bossMaxHp,
                                ),
                              ),
                            ),
                          ),
                          WireframeWrapper(
                            label: 'board-area ${RogueliteLayout.zoneBoardPercent.toStringAsFixed(0)}%',
                            color: _cExpanded,
                            child: SizedBox(
                              height: boardH,
                              child: _selectedTab == _Tab.battle
                                  ? Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: RogueliteLayout.boardAreaPadV,
                                      ),
                                      child: Center(
                                        child: LayoutBuilder(
                                          builder: (context, box) {
                                            final boardSize = min(box.maxWidth, box.maxHeight);
                                            _boardSize = boardSize;
                                            return WireframeWrapper(
                                              label: 'board',
                                              color: _cBoard,
                                              child: AnimatedBuilder(
                                                animation: Listenable.merge([_flashCtrl, _boardFadeCtrl]),
                                                builder: (context, child) {
                                                  final flashT = _flashCtrl.value;
                                                  final fadeT  = _boardFadeCtrl.value;
                                                  final flashOpacity = (1 - flashT) * 0.45;
                                                  return Stack(
                                                    children: [
                                                      child!,
                                                      if (flashOpacity > 0.01)
                                                        Positioned.fill(
                                                          child: IgnorePointer(
                                                            child: DecoratedBox(
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFF4CAF50).withValues(alpha: flashOpacity),
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      if (fadeT > 0.01)
                                                        Positioned.fill(
                                                          child: IgnorePointer(
                                                            child: DecoratedBox(
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFFBBADA0).withValues(alpha: fadeT),
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  );
                                                },
                                                child: GestureDetector(
                                                  onPanEnd: rs.isRunning ? _onPanEnd : null,
                                                  child: SizedBox(
                                                    key: _boardKey,
                                                    width: boardSize,
                                                    height: boardSize,
                                                    child: GameBoard(
                                                      state: _ctrl.gameState,
                                                      boardSize: boardSize,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                  : _buildUpgradePanel(_selectedTab),
                            ),
                          ),
                          WireframeWrapper(
                            label: 'controls ${RogueliteLayout.zoneControlsPercent.toStringAsFixed(0)}%',
                            color: _cControls,
                            child: SizedBox(
                              height: controlsH,
                              child: ControlBar(
                                gridSize: _ctrl.gridSize,
                                canUndo: _ctrl.canUndo && rs.isRunning,
                                onUndo: _ctrl.undo,
                                onSizeChanged: _ctrl.selectGridSize,
                                gridSizeEnabled: !rs.isRunning,
                                showWireframeToggle: true,
                                onRestart: _ctrl.restartRun,
                                onAutoRestartToggle: _ctrl.toggleAutoRestart,
                                autoRestart: _ctrl.autoRestart,
                              ),
                            ),
                          ),
                          WireframeWrapper(
                            label: 'tabs ${RogueliteLayout.zoneTabsPercent.toStringAsFixed(0)}%',
                            color: _cTabs,
                            child: SizedBox(
                              height: tabsH,
                              child: _buildTabBar(),
                            ),
                          ),
                        ],
                      ),
                      Positioned.fill(
                        child: Stack(
                          children: [
                            for (final p in rs.projectiles) _buildProjectile(p),
                            for (final pop in _popups)
                              DamagePopupWidget(
                                key: ValueKey(('pop', pop.id)),
                                damage: pop.damage,
                                position: pop.pos,
                                color: pop.color,
                                onComplete: () => _onPopupComplete(pop.id),
                              ),
                          ],
                        ),
                      ),
                      if (rs.showBossDefeated) const BossDefeatedOverlay(),
                      if (rs.showRunEnd && rs.lastRunStats != null)
                        Positioned.fill(
                          child: RogueliteRunEndOverlay(
                            stats: rs.lastRunStats!,
                            autoRestart: _ctrl.autoRestart,
                            onRestart: _ctrl.restartRun,
                            onToggleAutoRestart: _ctrl.toggleAutoRestart,
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    const tabs = [
      (_Tab.talents, 'Talents'),
      (_Tab.coins,   'Coins'),
      (_Tab.battle,  'Battle'),
    ];
    return Row(
      children: tabs.map((entry) {
        final (tab, label) = entry;
        final active = _selectedTab == tab;
        return Expanded(
          child: GestureDetector(
            onTap: () => _onTabChanged(tab),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFEDC53F)
                    : const Color(0xFFFAF8EF),
                border: Border(
                  top: BorderSide(
                    color: active
                        ? const Color(0xFFBBA52A)
                        : const Color(0xFFD4C5A0),
                    width: active ? 2.0 : 1.0,
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active
                      ? const Color(0xFF5A3E00)
                      : const Color(0xFF8C7B5A),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUpgradePanel(_Tab tab) {
    final rs = _ctrl.rogueliteState;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: tab == _Tab.talents
          ? Column(
              children: [
                _upgradeCard(
                  title: 'Bigger Board',
                  desc: '+1 grid size (applies next run)',
                  costLabel: '1 talent',
                  level: rs.boardSizeUpgraded ? 1 : 0,
                  maxLevel: 1,
                  canAfford: rs.talentPoints >= 1,
                  onBuy: () => _ctrl.buyTalentUpgrade(TalentUpgradeType.boardSize),
                ),
                const SizedBox(height: 6),
                _upgradeCard(
                  title: 'Better Start',
                  desc: 'Tiles spawn as 2 & 4 instead of 1 & 2',
                  costLabel: '1 talent',
                  level: rs.spawnValueUpgraded ? 1 : 0,
                  maxLevel: 1,
                  canAfford: rs.talentPoints >= 1,
                  onBuy: () => _ctrl.buyTalentUpgrade(TalentUpgradeType.spawnValue),
                ),
              ],
            )
          : Column(
              children: [
                _upgradeCard(
                  title: '+1 Damage',
                  desc: 'Each merge deals +1 extra damage',
                  costLabel: '10 coins',
                  level: rs.bonusDamage,
                  maxLevel: null,
                  canAfford: rs.coins >= 10,
                  onBuy: () => _ctrl.buyCoinUpgrade(CoinUpgradeType.damage),
                ),
                const SizedBox(height: 6),
                _upgradeCard(
                  title: '+1 Coin/Kill',
                  desc: 'Each kill drops one extra coin',
                  costLabel: '10 coins',
                  level: rs.bonusCoinPerKill,
                  maxLevel: null,
                  canAfford: rs.coins >= 10,
                  onBuy: () => _ctrl.buyCoinUpgrade(CoinUpgradeType.coinPerKill),
                ),
                const SizedBox(height: 6),
                _upgradeCard(
                  title: '+1 Second',
                  desc: 'Run timer +1s (also adds 1s mid-run)',
                  costLabel: '10 coins',
                  level: rs.bonusTimeSec,
                  maxLevel: null,
                  canAfford: rs.coins >= 10,
                  onBuy: () => _ctrl.buyCoinUpgrade(CoinUpgradeType.timeSec),
                ),
              ],
            ),
    );
  }

  Widget _upgradeCard({
    required String title,
    required String desc,
    required String costLabel,
    required int level,
    required int? maxLevel,
    required bool canAfford,
    required VoidCallback onBuy,
  }) {
    final maxed = maxLevel != null && level >= maxLevel;
    return Container(
      decoration: BoxDecoration(
        color: maxed ? const Color(0xFFE8E0D0) : const Color(0xFFEDE0C8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: maxed ? const Color(0xFFBBADA0) : const Color(0xFF8C7B5A),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF3C3A32),
                      ),
                    ),
                    if (level > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDC53F),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'lv $level',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A3E00),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF776E65)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (maxed)
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18)
          else
            FilledButton(
              onPressed: canAfford ? onBuy : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEDC53F),
                foregroundColor: const Color(0xFF5A3E00),
                disabledBackgroundColor: const Color(0xFFD4C5A0),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(costLabel),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectile(Projectile p) {
    final origin = _boardCellGlobal(p.originCell.row, p.originCell.col);
    final enemy = _ctrl.rogueliteState.enemies
        .where((e) => e.id == p.targetEnemyId)
        .firstOrNull;
    if (origin == null || enemy == null) return const SizedBox.shrink();
    final eSize = enemyDisplaySize(enemy.maxHp, _ctrl.rogueliteState.bossMaxHp);
    final target = _enemyGlobal(p.targetEnemyId, eSize);
    if (target == null) return const SizedBox.shrink();

    return ProjectileWidget(
      key: ValueKey(p.id),
      projectile: p,
      originGlobal: origin,
      targetGlobal: target,
      onHit: () => _onProjectileHit(p),
      onComplete: () => _onProjectileComplete(p),
    );
  }
}

