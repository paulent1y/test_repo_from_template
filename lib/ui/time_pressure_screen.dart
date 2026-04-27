import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_config.dart';
import '../game/game_state.dart';
import '../game/time_pressure_controller.dart';
import 'control_bar.dart';
import 'game_board.dart';

class TimePressureScreen extends StatefulWidget {
  const TimePressureScreen({super.key, required this.controller});
  final TimePressureController controller;

  @override
  State<TimePressureScreen> createState() => _TimePressureScreenState();
}

class _TimePressureScreenState extends State<TimePressureScreen> {
  TimePressureController get _ctrl => widget.controller;
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
              final phase = _ctrl.phase;
              return Column(
                children: [
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 220,
                          child: _DurationPanel(ctrl: _ctrl),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _TimerDisplay(ctrl: _ctrl)),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GestureDetector(
                      onPanEnd: phase == TimerPhase.running ? _onPanEnd : null,
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final boardSize = min(box.maxWidth, box.maxHeight)
                                .clamp(180.0, 520.0);
                            return SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: GameBoard(
                                state: _ctrl.gameState,
                                boardSize: boardSize,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ControlBar(
                    gridSize: _ctrl.gridSize,
                    canUndo: _ctrl.canUndo && phase == TimerPhase.running,
                    onUndo: _ctrl.undo,
                    onSizeChanged: _ctrl.selectGridSize,
                    gridSizeEnabled: phase == TimerPhase.idle,
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

class _DurationPanel extends StatelessWidget {
  const _DurationPanel({required this.ctrl});
  final TimePressureController ctrl;

  @override
  Widget build(BuildContext context) {
    final phase = ctrl.phase;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...timePressureDurations
            .map((d) => _DurationRow(ctrl: ctrl, duration: d)),
        const SizedBox(height: 10),
        if (phase == TimerPhase.running)
          FilledButton(
            onPressed: ctrl.stop,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('STOP'),
          )
        else
          FilledButton(
            onPressed: ctrl.start,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8F7A66),
            ),
            child: const Text('START'),
          ),
      ],
    );
  }
}

class _DurationRow extends StatelessWidget {
  const _DurationRow({required this.ctrl, required this.duration});
  final TimePressureController ctrl;
  final int duration;

  @override
  Widget build(BuildContext context) {
    final selected = ctrl.selectedDuration == duration;
    final isRunning = ctrl.phase == TimerPhase.running;
    final record = ctrl.recordFor(duration);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: OutlinedButton(
              onPressed: isRunning ? null : () => ctrl.selectDuration(duration),
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    selected ? const Color(0xFF8F7A66) : Colors.transparent,
                foregroundColor:
                    selected ? Colors.white : const Color(0xFF776E65),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF8F7A66)
                      : const Color(0xFFBBADA0),
                ),
              ),
              child: Text(
                '${duration}s',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: record != null
                ? Row(
                    children: [
                      _RecordChip(
                        label: 'SUM',
                        value: record.total,
                        bg: const Color(0xFFBBADA0),
                        fg: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      _RecordChip(
                        label: 'MAX',
                        value: record.max,
                        bg: tileColor(record.max),
                        fg: record.max <= 4
                            ? const Color(0xFF776E65)
                            : Colors.white,
                      ),
                    ],
                  )
                : const Text(
                    '—',
                    style: TextStyle(fontSize: 12, color: Color(0xFFBBADA0)),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecordChip extends StatelessWidget {
  const _RecordChip({
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });

  final String label;
  final int value;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: fg.withAlpha(180),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({required this.ctrl});
  final TimePressureController ctrl;

  @override
  Widget build(BuildContext context) {
    final remaining = ctrl.remaining;
    final phase = ctrl.phase;
    final urgent = phase == TimerPhase.running && remaining <= 5;
    final timerColor =
        urgent ? Colors.redAccent : const Color(0xFF776E65);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          remaining.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.w900,
            color: timerColor,
            letterSpacing: -2,
          ),
        ),
        if (phase == TimerPhase.ended)
          const Text(
            "Time's up!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF776E65),
            ),
          ),
        if (phase == TimerPhase.idle)
          const Text(
            'Press START',
            style: TextStyle(fontSize: 13, color: Color(0xFFBBADA0)),
          ),
      ],
    );
  }
}
