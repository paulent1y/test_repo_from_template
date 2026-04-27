import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_controller.dart';
import '../game/game_state.dart';
import 'control_bar.dart';
import 'game_board.dart';
import 'score_panel.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameController get _ctrl => widget.controller;
  final FocusNode _focusNode = FocusNode();

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
              final state = _ctrl.state;
              return Column(
                children: [
                  const SizedBox(height: 12),
                  // Title + score
                  const Text(
                    '2048',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF776E65),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ScorePanel(score: state.score, best: state.bestScore),
                  const SizedBox(height: 14),
                  // Board — Expanded so it fills remaining space in both orientations
                  Expanded(
                    child: GestureDetector(
                      onPanEnd: _onPanEnd,
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final boardSize = min(box.maxWidth, box.maxHeight)
                                .clamp(180.0, 520.0);
                            return SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: Stack(
                                children: [
                                  GameBoard(state: state, boardSize: boardSize),
                                  if (state.status == GameStatus.won)
                                    _WinOverlay(
                                      onContinue: _ctrl.continueAfterWin,
                                      onNewGame: () => _ctrl.newGame(_ctrl.gridSize),
                                    ),
                                  if (state.status == GameStatus.lost)
                                    _LostOverlay(
                                      score: state.score,
                                      onNewGame: () => _ctrl.newGame(_ctrl.gridSize),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Controls
                  ControlBar(
                    gridSize: _ctrl.gridSize,
                    canUndo: _ctrl.canUndo,
                    onNewGame: _ctrl.newGame,
                    onUndo: _ctrl.undo,
                    onSizeChanged: (size) => _ctrl.newGame(size),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WinOverlay extends StatelessWidget {
  const _WinOverlay({required this.onContinue, required this.onNewGame});

  final VoidCallback onContinue;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    return _Overlay(
      color: const Color(0xCCEDC22E),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'You reached 2048!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF776E65),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8F7A66)),
                child: const Text('Continue'),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: onNewGame,
                child: const Text('New Game'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LostOverlay extends StatelessWidget {
  const _LostOverlay({required this.score, required this.onNewGame});

  final int score;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    return _Overlay(
      color: const Color(0xCCCDC1B4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Game Over',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF776E65),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Score: $score',
            style: const TextStyle(fontSize: 16, color: Color(0xFF776E65)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onNewGame,
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8F7A66)),
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: child),
      ),
    );
  }
}
