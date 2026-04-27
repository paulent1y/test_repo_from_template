import 'package:flutter/material.dart';

class ScorePanel extends StatelessWidget {
  const ScorePanel({super.key, required this.score, required this.best});

  final int score;
  final int best;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ScoreBox(label: 'SCORE', value: score),
        const SizedBox(width: 12),
        _ScoreBox(label: 'BEST', value: best),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEEE4DA),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: value, end: value),
            duration: const Duration(milliseconds: 200),
            builder: (_, v, _) => Text(
              '$v',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
