import 'dart:math' show pi;

import 'package:flutter/material.dart';

final wireframeEnabled = ValueNotifier<bool>(false);

/// Wraps [child] with a colored border + dimension labels when wireframe
/// mode is active. Uses CustomPaint foreground so it never affects layout.
class WireframeWrapper extends StatelessWidget {
  const WireframeWrapper({
    super.key,
    required this.child,
    required this.label,
    this.color = const Color(0xFF2196F3),
  });

  final Widget child;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: wireframeEnabled,
      builder: (_, enabled, _) {
        if (!enabled) return child;
        return CustomPaint(
          foregroundPainter: _WireframePainter(label: label, color: color),
          child: child,
        );
      },
    );
  }
}

class _WireframePainter extends CustomPainter {
  _WireframePainter({required this.label, required this.color});

  final String label;
  final Color color;

  static final Map<Color, Paint> _borderCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = _borderCache.putIfAbsent(
      color,
      () => Paint()
        ..color = color.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.drawRect(Offset.zero & size, borderPaint);

    final w = size.width;
    final h = size.height;

    // Width label — centered on top edge
    _label(canvas, '${w.round()}', Offset(w / 2, 7), color);

    // Height label — centered on right edge, rotated
    canvas.save();
    canvas.translate(w - 7, h / 2);
    canvas.rotate(-pi / 2);
    _label(canvas, '${h.round()}', Offset.zero, color);
    canvas.restore();

    // Component name — top-left corner
    _label(canvas, label, const Offset(4, 4), color,
        align: TextAlign.left, anchor: Alignment.topLeft);
  }

  void _label(
    Canvas canvas,
    String text,
    Offset position,
    Color color, {
    TextAlign align = TextAlign.center,
    Alignment anchor = Alignment.center,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();

    final w = tp.width + 3;
    final h = tp.height + 2;
    final dx = position.dx - w * (anchor.x + 1) / 2;
    final dy = position.dy - h * (anchor.y + 1) / 2;

    final bg = Paint()..color = Colors.black.withAlpha(160);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(dx, dy, w, h), const Radius.circular(2)),
      bg,
    );
    tp.paint(canvas, Offset(dx + 1.5, dy + 1));
  }

  @override
  bool shouldRepaint(_WireframePainter old) =>
      old.label != label || old.color != color;
}
