import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  const ControlBar({
    super.key,
    required this.gridSize,
    required this.canUndo,
    this.onNewGame,
    required this.onUndo,
    required this.onSizeChanged,
    this.gridSizeEnabled = true,
  });

  final int gridSize;
  final bool canUndo;
  final void Function(int)? onNewGame;
  final VoidCallback onUndo;
  final void Function(int) onSizeChanged;
  final bool gridSizeEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 3, label: Text('3×3')),
            ButtonSegment(value: 4, label: Text('4×4')),
            ButtonSegment(value: 5, label: Text('5×5')),
            ButtonSegment(value: 6, label: Text('6×6')),
          ],
          selected: {gridSize},
          onSelectionChanged:
              gridSizeEnabled ? (s) => onSizeChanged(s.first) : null,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (onNewGame != null) ...[
              FilledButton(
                onPressed: () => onNewGame!(gridSize),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8F7A66),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                child: const Text('New Game', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 10),
            ],
            FilledButton.tonal(
              onPressed: canUndo ? onUndo : null,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              child: const Text('Undo', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }
}
