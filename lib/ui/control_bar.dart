import 'package:flutter/material.dart';

import '../debug/wireframe_wrapper.dart';
import '../roguelite/roguelite_layout.dart';

const _cSegmented = Color(0xFF9C27B0); // purple
const _cButton = Color(0xFFFF6F00);  // deep orange

class ControlBar extends StatelessWidget {
  const ControlBar({
    super.key,
    required this.gridSize,
    required this.canUndo,
    required this.onUndo,
    required this.onSizeChanged,
    this.gridSizeEnabled = true,
    this.showWireframeToggle = false,
    this.onNewGame,
    this.onRestart,
    this.onAutoRestartToggle,
    this.autoRestart = false,
  });

  final int gridSize;
  final bool canUndo;
  final VoidCallback onUndo;
  final void Function(int) onSizeChanged;
  final bool gridSizeEnabled;
  final bool showWireframeToggle;
  final void Function(int)? onNewGame;
  final VoidCallback? onRestart;
  final VoidCallback? onAutoRestartToggle;
  final bool autoRestart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: RogueliteLayout.controlBarPadH,
        vertical: RogueliteLayout.controlBarPadV,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showWireframeToggle)
            WireframeWrapper(
              label: 'wireframe-btn',
              color: _cSegmented,
              child: ValueListenableBuilder<bool>(
                valueListenable: wireframeEnabled,
                builder: (_, enabled, _) => _SmallIconBtn(
                  icon: enabled ? Icons.grid_on : Icons.grid_off,
                  active: enabled,
                  activeColor: const Color(0xFF2196F3),
                  onPressed: () => wireframeEnabled.value = !wireframeEnabled.value,
                ),
              ),
            ),
          WireframeWrapper(
            label: 'grid-selector',
            color: _cSegmented,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
                ButtonSegment(value: 5, label: Text('5')),
              ],
              selected: {gridSize},
              onSelectionChanged:
                  gridSizeEnabled ? (s) => onSizeChanged(s.first) : null,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: WidgetStateProperty.all(
                  const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: RogueliteLayout.segmentedButtonFontSize,
                  ),
                ),
                padding: WidgetStateProperty.all(
                  EdgeInsets.symmetric(
                    horizontal: RogueliteLayout.segmentedButtonPadH,
                    vertical: 0,
                  ),
                ),
              ),
            ),
          ),
          if (onNewGame != null)
            WireframeWrapper(
              label: 'new-btn',
              color: _cButton,
              child: FilledButton(
                onPressed: () => onNewGame!(gridSize),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8F7A66),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.symmetric(
                    horizontal: RogueliteLayout.filledButtonPadH,
                    vertical: RogueliteLayout.filledButtonPadV,
                  ),
                ),
                child: Text(
                  'New',
                  style: TextStyle(fontSize: RogueliteLayout.filledButtonFontSize),
                ),
              ),
            ),
          if (onRestart != null)
            WireframeWrapper(
              label: 'restart-btn',
              color: _cButton,
              child: _SmallIconBtn(
                icon: Icons.replay,
                active: false,
                activeColor: const Color(0xFF8F7A66),
                inactiveColor: const Color(0xFF8F7A66),
                onPressed: onRestart,
              ),
            ),
          if (onAutoRestartToggle != null)
            WireframeWrapper(
              label: 'auto-restart-btn',
              color: _cButton,
              child: _SmallIconBtn(
                icon: Icons.loop,
                active: autoRestart,
                activeColor: const Color(0xFF43A047),
                onPressed: onAutoRestartToggle,
              ),
            ),
          WireframeWrapper(
            label: 'undo-btn',
            color: _cButton,
            child: FilledButton.tonal(
              onPressed: canUndo ? onUndo : null,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.symmetric(
                  horizontal: RogueliteLayout.filledButtonPadH,
                  vertical: RogueliteLayout.filledButtonPadV,
                ),
              ),
              child: Text(
                'Undo',
                style: TextStyle(
                  fontSize: RogueliteLayout.filledButtonFontSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallIconBtn extends StatelessWidget {
  const _SmallIconBtn({
    required this.icon,
    required this.active,
    required this.activeColor,
    this.inactiveColor = const Color(0xFF8F7A66),
    this.onPressed,
  });

  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        style: IconButton.styleFrom(
          backgroundColor: active ? activeColor : inactiveColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
