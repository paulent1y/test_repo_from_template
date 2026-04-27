import 'package:flutter/material.dart';

class RogueliteHeader extends StatelessWidget {
  const RogueliteHeader({
    super.key,
    required this.talentPoints,
    required this.timeRemaining,
    required this.coins,
    required this.isUrgent,
  });

  final int talentPoints;
  final int timeRemaining;
  final int coins;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFBBADA0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatChip(label: 'TALENTS', value: '$talentPoints', icon: '⭐'),
          _TimerChip(seconds: timeRemaining, urgent: isUrgent),
          _StatChip(label: 'COINS', value: '$coins', icon: '🪙'),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEE4DA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF776E65),
                  letterSpacing: 0.5,
                ),
              ),
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
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.seconds, required this.urgent});

  final int seconds;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: urgent ? Colors.redAccent : const Color(0xFF3C3A32),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${seconds.toString().padLeft(2, '0')}s',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -1,
        ),
      ),
    );
  }
}
