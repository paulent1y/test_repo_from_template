import 'package:flutter/material.dart';

import '../game/game_config.dart';

class TileWidget extends StatefulWidget {
  const TileWidget({super.key, required this.value, required this.tileSize});

  final int value;
  final double tileSize;

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ac, curve: Curves.easeOutBack),
    );
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    final fontSize =
        widget.tileSize * (v >= 1000 ? 0.28 : v >= 100 ? 0.33 : 0.42);
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.tileSize,
        height: widget.tileSize,
        decoration: BoxDecoration(
          color: tileColor(v),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            '$v',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: tileForeground(v),
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
