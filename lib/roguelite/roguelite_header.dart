import 'package:flutter/material.dart';

import '../debug/wireframe_wrapper.dart';
import 'roguelite_layout.dart';

const _cStat  = Color(0xFF00BCD4);
const _cTimer = Color(0xFFFF5252);

class RogueliteHeader extends StatelessWidget {
  const RogueliteHeader({
    super.key,
    required this.talentPoints,
    required this.timeRemainingMs,
    required this.coins,
    required this.isUrgent,
    required this.isPaused,
    required this.onPauseToggle,
  });

  final int talentPoints;
  final int timeRemainingMs;
  final int coins;
  final bool isUrgent;
  final bool isPaused;
  final VoidCallback onPauseToggle;

  String _formatTime() {
    final secs = timeRemainingMs ~/ 1000;
    final tenths = timeRemainingMs ~/ 100 % 10;
    return '${secs.toString().padLeft(2, '0')}.$tenths';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RogueliteLayout.headerPadH,
        vertical: RogueliteLayout.headerPadV,
      ),
      color: const Color(0xFFBBADA0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          WireframeWrapper(
            label: 'stat-row',
            color: _cStat,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 3),
                Text(
                  '$talentPoints',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF776E65),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7),
                  child: Text(
                    '|',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9F9080),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const Text('🪙', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 3),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF776E65),
                  ),
                ),
              ],
            ),
          ),
          WireframeWrapper(
            label: 'timer',
            color: _cTimer,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isUrgent ? Colors.redAccent : const Color(0xFF776E65),
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: isUrgent ? Colors.redAccent : const Color(0xFF776E65),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onPauseToggle,
                  child: Icon(
                    isPaused ? Icons.play_arrow : Icons.pause,
                    size: 16,
                    color: isUrgent ? Colors.redAccent : const Color(0xFF776E65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
