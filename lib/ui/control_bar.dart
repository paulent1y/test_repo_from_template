import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  const ControlBar({
    super.key,
    required this.gridSize,
    required this.canUndo,
    required this.onNewGame,
    required this.onUndo,
    required this.onSizeChanged,
  });

  final int gridSize;
  final bool canUndo;
  final void Function(int) onNewGame;
  final VoidCallback onUndo;
  final void Function(int) onSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 3, label: Text('3×3')),
            ButtonSegment(value: 4, label: Text('4×4')),
            ButtonSegment(value: 5, label: Text('5×5')),
            ButtonSegment(value: 6, label: Text('6×6')),
          ],
          selected: {gridSize},
          onSelectionChanged: (s) => onSizeChanged(s.first),
          style: ButtonStyle(
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () => onNewGame(gridSize),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8F7A66),
              ),
              child: const Text('New Game'),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: canUndo ? onUndo : null,
              child: const Text('Undo'),
            ),
          ],
        ),
      ],
    );
  }
}
