import 'package:flutter/material.dart';

class DamagePopupWidget extends StatefulWidget {
  const DamagePopupWidget({
    super.key,
    required this.damage,
    required this.position,
    required this.color,
    required this.onComplete,
  });

  final int damage;
  final Offset position;
  final Color color;
  final VoidCallback onComplete;

  @override
  State<DamagePopupWidget> createState() => _DamagePopupWidgetState();
}

class _DamagePopupWidgetState extends State<DamagePopupWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _opacity;
  late final Animation<double> _rise;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ac, curve: const Interval(0.4, 1.0)));
    _rise = Tween<double>(begin: 0.0, end: -36.0)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _ac.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onComplete();
      }
    });
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, _) => Positioned(
        left: widget.position.dx - 16,
        top: widget.position.dy + _rise.value - 12,
        child: Opacity(
          opacity: _opacity.value,
          child: Text(
            '-${widget.damage}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: widget.color,
              shadows: const [
                Shadow(blurRadius: 4, color: Colors.black45),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
