import 'dart:math';
import 'package:flutter/material.dart';

/// Overlay that plays a burst of particles for resource actions (water, fertilizer, bird).
class ActionParticles extends StatefulWidget {
  const ActionParticles({super.key, required this.action, required this.onComplete});
  final ActionParticleType action;
  final VoidCallback onComplete;

  @override
  State<ActionParticles> createState() => _ActionParticlesState();
}

enum ActionParticleType { water, fertilizer, bird, harvest }

class _ActionParticlesState extends State<ActionParticles> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_ActionParticle> _particles;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..addListener(_tick)
      ..forward().then((_) => widget.onComplete());
    _particles = _generate();
  }

  List<_ActionParticle> _generate() {
    switch (widget.action) {
      case ActionParticleType.water:
        return List.generate(20, (_) => _ActionParticle(
          x: 0.5, y: 0.5,
          vx: (_rng.nextDouble() - 0.5) * 0.04,
          vy: _rng.nextDouble() * 0.03 + 0.01,
          size: _rng.nextDouble() * 6 + 3,
          color: Colors.blue.shade400,
          icon: '💧',
          useIcon: _rng.nextDouble() > 0.6,
          life: 1.0,
          decay: 0.015 + _rng.nextDouble() * 0.01,
        ));
      case ActionParticleType.fertilizer:
        return List.generate(15, (_) => _ActionParticle(
          x: 0.5, y: 0.5,
          vx: (_rng.nextDouble() - 0.5) * 0.03,
          vy: -_rng.nextDouble() * 0.02 - 0.005,
          size: _rng.nextDouble() * 5 + 2,
          color: Colors.brown.shade400,
          icon: '✨',
          useIcon: _rng.nextDouble() > 0.5,
          life: 1.0,
          decay: 0.012 + _rng.nextDouble() * 0.008,
        ));
      case ActionParticleType.bird:
        return List.generate(8, (_) => _ActionParticle(
          x: _rng.nextDouble() * 0.6 + 0.2,
          y: _rng.nextDouble() * 0.3 + 0.2,
          vx: (_rng.nextDouble() - 0.5) * 0.02,
          vy: -0.02 - _rng.nextDouble() * 0.01,
          size: 20,
          color: Colors.white,
          icon: '🪶',
          useIcon: true,
          life: 1.0,
          decay: 0.01 + _rng.nextDouble() * 0.005,
        ));
      case ActionParticleType.harvest:
        return List.generate(25, (_) => _ActionParticle(
          x: 0.5, y: 0.5,
          vx: (_rng.nextDouble() - 0.5) * 0.05,
          vy: -_rng.nextDouble() * 0.04 - 0.01,
          size: _rng.nextDouble() * 8 + 4,
          color: Colors.amber.shade400,
          icon: '🪙',
          useIcon: _rng.nextDouble() > 0.4,
          life: 1.0,
          decay: 0.008 + _rng.nextDouble() * 0.006,
        ));
    }
  }

  void _tick() {
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.life -= p.decay;
      if (widget.action == ActionParticleType.water) {
        p.vy += 0.001; // gravity for water drops
      }
    }
    _particles.removeWhere((p) => p.life <= 0);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ActionParticlePainter(_particles),
        size: Size.infinite,
      ),
    );
  }
}

class _ActionParticle {
  double x, y, vx, vy, size, life, decay;
  Color color;
  String icon;
  bool useIcon;

  _ActionParticle({
    required this.x, required this.y, required this.vx, required this.vy,
    required this.size, required this.color, required this.icon,
    required this.useIcon, required this.life, required this.decay,
  });
}

class _ActionParticlePainter extends CustomPainter {
  _ActionParticlePainter(this.particles);
  final List<_ActionParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final p in particles) {
      final dx = p.x * size.width;
      final dy = p.y * size.height;
      if (p.useIcon) {
        tp.text = TextSpan(
          text: p.icon,
          style: TextStyle(fontSize: p.size, color: p.color.withOpacity(p.life)),
        );
        tp.layout();
        tp.paint(canvas, Offset(dx - tp.width / 2, dy - tp.height / 2));
      } else {
        final paint = Paint()..color = p.color.withOpacity(p.life * 0.8);
        canvas.drawCircle(Offset(dx, dy), p.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget that shows an action particle burst at the center, auto-removes after animation.
class ActionBurst extends StatefulWidget {
  const ActionBurst({super.key, required this.action, required this.onDone});
  final ActionParticleType action;
  final VoidCallback onDone;

  static void show(BuildContext context, ActionParticleType action, {VoidCallback? onDone}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ActionBurst(
        action: action,
        onDone: () { entry.remove(); onDone?.call(); },
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<ActionBurst> createState() => _ActionBurstState();
}

class _ActionBurstState extends State<ActionBurst> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ActionParticles(
        action: widget.action,
        onComplete: widget.onDone,
      ),
    );
  }
}
