import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../debug/wireframe_wrapper.dart';
import '../game/game_state.dart';
import '../ui/control_bar.dart';
import '../ui/game_board.dart';
import 'boss_defeated_overlay.dart';
import 'damage_popup_widget.dart';
import 'enemy_pyramid_widget.dart';
import 'enemy_widget.dart' show enemyDisplaySize;
import 'projectile.dart';
import 'projectile_widget.dart';
import 'roguelite_controller.dart';
import 'roguelite_header.dart';
import 'roguelite_state.dart';
import 'upgrades_tab.dart';
import 'talents_tab.dart';

// Wireframe color palette per layer
const _cHeader   = Color(0xFF2196F3); // blue
const _cPyramid  = Color(0xFFFF9800); // orange
const _cBoard    = Color(0xFF4CAF50); // green
const _cControls = Color(0xFF9C27B0); // purple
const _cExpanded = Color(0xFF00BCD4); // cyan

class RogueliteScreen extends StatefulWidget {
  const RogueliteScreen({super.key, required this.controller});
  final RogueliteController controller;

  @override
  State<RogueliteScreen> createState() => _RogueliteScreenState();
}

class _RogueliteScreenState extends State<RogueliteScreen> {
  RogueliteController get _ctrl => widget.controller;
  final FocusNode _focusNode = FocusNode();
  int _tabIndex = 0;

  final GlobalKey _boardKey = GlobalKey();
  final Map<int, GlobalKey> _enemyKeys = {};
  double _boardSize = 300.0;

  int _popupCounter = 0;
  final List<({int id, Offset pos, int damage, Color color})> _popups = [];

  @override
  void dispose() {
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
    const gap = 8.0;
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
      floatingActionButton: _WireframeToggleFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      body: SafeArea(
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: ListenableBuilder(
            listenable: _ctrl,
            builder: (context, _) {
              final rs = _ctrl.rogueliteState;
              return Column(
                children: [
                  WireframeWrapper(
                    label: 'header',
                    color: _cHeader,
                    child: RogueliteHeader(
                      talentPoints: rs.talentPoints,
                      timeRemaining: rs.timeRemaining,
                      coins: rs.coins,
                      isUrgent: rs.timeRemaining <= 5 && rs.isRunning,
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _tabIndex,
                      children: [
                        _BattleView(
                          ctrl: _ctrl,
                          rs: rs,
                          boardKey: _boardKey,
                          enemyKeys: _enemyKeys,
                          popups: _popups,
                          onPanEnd: rs.isRunning ? _onPanEnd : null,
                          onBoardSized: (s) => _boardSize = s,
                          onProjectileHit: _onProjectileHit,
                          onProjectileComplete: _onProjectileComplete,
                          onPopupComplete: _onPopupComplete,
                          boardCellGlobal: _boardCellGlobal,
                          enemyGlobal: _enemyGlobal,
                        ),
                        const UpgradesTab(),
                        const TalentsTab(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: WireframeWrapper(
        label: 'bottom-nav',
        color: _cControls,
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (i) => setState(() => _tabIndex = i),
          backgroundColor: const Color(0xFFBBADA0),
          selectedItemColor: const Color(0xFF3C3A32),
          unselectedItemColor: const Color(0xFF776E65),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.sports_martial_arts), label: 'Battle'),
            BottomNavigationBarItem(
                icon: Icon(Icons.upgrade), label: 'Upgrades'),
            BottomNavigationBarItem(
                icon: Icon(Icons.star), label: 'Talents'),
          ],
        ),
      ),
    );
  }
}

class _WireframeToggleFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: wireframeEnabled,
      builder: (_, enabled, _) => FloatingActionButton.small(
        onPressed: () => wireframeEnabled.value = !wireframeEnabled.value,
        backgroundColor:
            enabled ? const Color(0xFF2196F3) : const Color(0xFF8F7A66),
        tooltip: 'Toggle wireframe',
        child: Icon(
          enabled ? Icons.grid_on : Icons.grid_off,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _BattleView extends StatelessWidget {
  const _BattleView({
    required this.ctrl,
    required this.rs,
    required this.boardKey,
    required this.enemyKeys,
    required this.popups,
    required this.onPanEnd,
    required this.onBoardSized,
    required this.onProjectileHit,
    required this.onProjectileComplete,
    required this.onPopupComplete,
    required this.boardCellGlobal,
    required this.enemyGlobal,
  });

  final RogueliteController ctrl;
  final RogueliteState rs;
  final GlobalKey boardKey;
  final Map<int, GlobalKey> enemyKeys;
  final List<({int id, Offset pos, int damage, Color color})> popups;
  final void Function(DragEndDetails)? onPanEnd;
  final void Function(double) onBoardSized;
  final void Function(Projectile) onProjectileHit;
  final void Function(Projectile) onProjectileComplete;
  final void Function(int) onPopupComplete;
  final Offset? Function(int row, int col) boardCellGlobal;
  final Offset? Function(int enemyId, double size) enemyGlobal;

  @override
  Widget build(BuildContext context) {
    return WireframeWrapper(
      label: 'battle-tab',
      color: _cExpanded,
      child: Stack(
        children: [
          Column(
            children: [
              WireframeWrapper(
                label: 'pyramid 110dp',
                color: _cPyramid,
                child: EnemyPyramidWidget(
                  enemies: rs.enemies,
                  enemyKeys: enemyKeys,
                  bossMaxHp: rs.bossMaxHp,
                ),
              ),
              Expanded(
                child: WireframeWrapper(
                  label: 'board-area',
                  color: _cExpanded,
                  child: GestureDetector(
                    onPanEnd: onPanEnd,
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final boardSize = min(box.maxWidth, box.maxHeight)
                              .clamp(120.0, 240.0);
                          onBoardSized(boardSize);
                          return WireframeWrapper(
                            label: 'board ${boardSize.round()}²',
                            color: _cBoard,
                            child: SizedBox(
                              key: boardKey,
                              width: boardSize,
                              height: boardSize,
                              child: GameBoard(
                                state: ctrl.gameState,
                                boardSize: boardSize,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              WireframeWrapper(
                label: 'controls',
                color: _cControls,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ControlBar(
                    gridSize: ctrl.gridSize,
                    canUndo: ctrl.canUndo && rs.isRunning,
                    onUndo: ctrl.undo,
                    onSizeChanged: ctrl.selectGridSize,
                    gridSizeEnabled: !rs.isRunning,
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: Stack(
              children: [
                for (final p in rs.projectiles) _buildProjectile(p),
                for (final pop in popups)
                  DamagePopupWidget(
                    key: ValueKey(pop.id),
                    damage: pop.damage,
                    position: pop.pos,
                    color: pop.color,
                    onComplete: () => onPopupComplete(pop.id),
                  ),
              ],
            ),
          ),
          if (rs.showBossDefeated) const BossDefeatedOverlay(),
        ],
      ),
    );
  }

  Widget _buildProjectile(Projectile p) {
    final origin = boardCellGlobal(p.originCell.row, p.originCell.col);
    final enemy =
        rs.enemies.where((e) => e.id == p.targetEnemyId).firstOrNull;
    if (origin == null || enemy == null) return const SizedBox.shrink();
    final eSize = enemyDisplaySize(enemy.maxHp, rs.bossMaxHp);
    final target = enemyGlobal(p.targetEnemyId, eSize);
    if (target == null) return const SizedBox.shrink();

    return ProjectileWidget(
      key: ValueKey(p.id),
      projectile: p,
      originGlobal: origin,
      targetGlobal: target,
      onHit: () => onProjectileHit(p),
      onComplete: () => onProjectileComplete(p),
    );
  }
}
