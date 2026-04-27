import 'package:flutter/material.dart';

import 'projectile.dart';

class ProjectileWidget extends StatefulWidget {
  const ProjectileWidget({
    super.key,
    required this.projectile,
    required this.originGlobal,
    required this.targetGlobal,
    required this.onHit,
    required this.onComplete,
  });

  final Projectile projectile;
  final Offset originGlobal;
  final Offset targetGlobal;
  final VoidCallback onHit;
  final VoidCallback onComplete;

  @override
  State<ProjectileWidget> createState() => _ProjectileWidgetState();
}

class _ProjectileWidgetState extends State<ProjectileWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<Offset> _pos;
  bool _hitFired = false;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pos = Tween<Offset>(
      begin: widget.originGlobal,
      end: widget.targetGlobal,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeIn));

    _ac.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete();
    });
    _ac.addListener(() {
      if (!_hitFired && _ac.value >= 0.85) {
        _hitFired = true;
        widget.onHit();
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
      animation: _pos,
      builder: (_, _) => Positioned(
        left: _pos.value.dx - 8,
        top: _pos.value.dy - 8,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: widget.projectile.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.projectile.color.withAlpha(180),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
