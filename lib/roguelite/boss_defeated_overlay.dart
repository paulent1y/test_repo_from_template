import 'package:flutter/material.dart';

class BossDefeatedOverlay extends StatefulWidget {
  const BossDefeatedOverlay({super.key});

  @override
  State<BossDefeatedOverlay> createState() => _BossDefeatedOverlayState();
}

class _BossDefeatedOverlayState extends State<BossDefeatedOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.5, end: 1.1)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 18),
      TweenSequenceItem(
          tween: Tween(begin: 1.1, end: 1.0), weight: 55),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.0), weight: 27),
    ]).animate(_ac);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 18),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 27),
    ]).animate(_ac);
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ac,
          builder: (_, _) => Opacity(
            opacity: _opacity.value,
            child: Center(
              child: ScaleTransition(
                scale: _scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xCC3C3A32),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFEDC22E), width: 2),
                  ),
                  child: const Text(
                    'BOSS DEFEATED',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFEDC22E),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
