import 'dart:ui';

import 'package:flutter/material.dart';

import 'roguelite_state.dart';

class RogueliteRunEndOverlay extends StatelessWidget {
  const RogueliteRunEndOverlay({
    super.key,
    required this.stats,
    required this.autoRestart,
    required this.onRestart,
    required this.onToggleAutoRestart,
  });

  final RunStats stats;
  final bool autoRestart;
  final VoidCallback onRestart;
  final VoidCallback onToggleAutoRestart;

  String _formatTime(int ms) {
    final secs = ms ~/ 1000;
    final tenths = ms ~/ 100 % 10;
    return '${secs.toString().padLeft(2, '0')}.$tenths s';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(color: Colors.black.withAlpha(100)),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8EF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  stats.bossKilled ? '👑 Boss Defeated!' : 'Round Over',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF776E65),
                  ),
                ),
                const SizedBox(height: 16),
                _StatsGrid(stats: stats, formatTime: _formatTime),
                const SizedBox(height: 20),
                _BottomRow(
                  autoRestart: autoRestart,
                  onRestart: onRestart,
                  onToggleAutoRestart: onToggleAutoRestart,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.formatTime});

  final RunStats stats;
  final String Function(int) formatTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatTile(label: 'Time', value: formatTime(stats.roundTimeMs))),
            const SizedBox(width: 8),
            Expanded(child: _StatTile(label: 'Enemies', value: '${stats.enemiesKilled}')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _StatTile(label: 'Coins', value: '+${stats.coinsEarned} 🪙')),
            const SizedBox(width: 8),
            Expanded(child: _StatTile(label: 'Points', value: '+${stats.pointsEarned}')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _StatTile(label: 'Moves', value: '${stats.moveCount}')),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                label: 'ms / move',
                value: stats.moveCount > 0 ? '${stats.avgMsPerMove}' : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _StatTile(label: 'Best moves', value: '${stats.bestMovesSession}')),
            const SizedBox(width: 8),
            Expanded(child: _StatTile(label: 'Avg moves/run', value: '${stats.avgMovesSession}')),
          ],
        ),
        const SizedBox(height: 8),
        _StatTile(label: 'Best tile', value: '${stats.maxTileValue}', fullWidth: true),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEE4DA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9F9080),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF776E65),
            ),
          ),
        ],
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: inner) : inner;
  }
}

class _BottomRow extends StatelessWidget {
  const _BottomRow({
    required this.autoRestart,
    required this.onRestart,
    required this.onToggleAutoRestart,
  });

  final bool autoRestart;
  final VoidCallback onRestart;
  final VoidCallback onToggleAutoRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Auto-restart toggle
        GestureDetector(
          onTap: onToggleAutoRestart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: autoRestart,
                  onChanged: (_) => onToggleAutoRestart(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: const Color(0xFF43A047),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Auto-restart',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF776E65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Upgrades + Restart stacked
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                disabledBackgroundColor: const Color(0xFFBBB8B0),
                disabledForegroundColor: Colors.white70,
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              child: const Text('Upgrades'),
            ),
            const SizedBox(height: 6),
            FilledButton(
              onPressed: onRestart,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8F7A66),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay, size: 13),
                  SizedBox(width: 4),
                  Text('Restart'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
