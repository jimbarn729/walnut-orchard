import 'dart:math';
import 'package:flutter/material.dart';

import '../models/game_models.dart';

/// Animated weather overlay that renders particle effects on top of the farm screen.
class WeatherEffects extends StatefulWidget {
  const WeatherEffects({super.key, required this.weather, required this.child});
  final WeatherType weather;
  final Widget child;

  @override
  State<WeatherEffects> createState() => _WeatherEffectsState();
}

class _WeatherEffectsState extends State<WeatherEffects> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _rng = Random();

  // Lightning flash
  double _flashOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _particles = _generateParticles(widget.weather);
    _controller.addListener(_tick);
  }

  @override
  void didUpdateWidget(covariant WeatherEffects oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weather != widget.weather) {
      _particles = _generateParticles(widget.weather);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  List<_Particle> _generateParticles(WeatherType w) {
    switch (w) {
      case WeatherType.calm:
      case WeatherType.cloudy:
        return [];
      case WeatherType.thunderstorm:
        return List.generate(80, (_) => _rainDrop(_rng, heavy: true));
      case WeatherType.flood:
        return List.generate(60, (_) => _rainDrop(_rng, heavy: true))
          ..addAll(List.generate(8, (_) => _wave(_rng)));
      case WeatherType.fog:
        return List.generate(20, (_) => _fogPatch(_rng));
      case WeatherType.heatwave:
        return List.generate(15, (_) => _heatShimmer(_rng));
      case WeatherType.forestFire:
        return List.generate(50, (_) => _ember(_rng))
          ..addAll(List.generate(10, (_) => _smokePatch(_rng)));
    }
  }

  void _tick() {
    for (final p in _particles) {
      p.update(_rng);
    }
    // Random lightning for thunderstorm
    if (widget.weather == WeatherType.thunderstorm && _rng.nextDouble() < 0.008) {
      setState(() => _flashOpacity = 0.7);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _flashOpacity = 0.0);
      });
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Background tint per weather
        Positioned.fill(child: _weatherTint(widget.weather)),
        // Particle canvas
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _ParticlePainter(_particles))),
          ),
        // Lightning flash overlay
        if (widget.weather == WeatherType.thunderstorm)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _flashOpacity,
                duration: const Duration(milliseconds: 100),
                child: Container(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _weatherTint(WeatherType w) {
    Color color;
    switch (w) {
      case WeatherType.calm:
        color = Colors.amber.withOpacity(0.04);
        break;
      case WeatherType.cloudy:
        color = Colors.blueGrey.withOpacity(0.08);
        break;
      case WeatherType.thunderstorm:
        color = Colors.indigo.withOpacity(0.15);
        break;
      case WeatherType.flood:
        color = Colors.blue.withOpacity(0.12);
        break;
      case WeatherType.fog:
        color = Colors.grey.withOpacity(0.25);
        break;
      case WeatherType.heatwave:
        color = Colors.deepOrange.withOpacity(0.08);
        break;
      case WeatherType.forestFire:
        color = Colors.red.withOpacity(0.12);
        break;
    }
    return IgnorePointer(child: Container(color: color));
  }
}

// ---------------------------------------------------------------------------
// Particles
// ---------------------------------------------------------------------------

class _Particle {
  double x, y, vx, vy, size, opacity;
  Color color;
  _ParticleType type;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.color,
    required this.type,
  });

  void update(Random rng) {
    x += vx;
    y += vy;
    switch (type) {
      case _ParticleType.rain:
        if (y > 1.05) { y = -0.05; x = rng.nextDouble(); }
        break;
      case _ParticleType.wave:
        x += sin(y * 10) * 0.003;
        if (x > 1.15) { x = -0.15; }
        break;
      case _ParticleType.fog:
        opacity = (opacity + (rng.nextDouble() - 0.5) * 0.02).clamp(0.05, 0.3);
        if (x > 1.3) { x = -0.3; }
        break;
      case _ParticleType.heatShimmer:
        y += sin(x * 20) * 0.001;
        if (y < -0.1) { y = 1.1; }
        break;
      case _ParticleType.ember:
        opacity = (opacity - 0.005).clamp(0.0, 1.0);
        size *= 0.995;
        if (opacity <= 0 || size < 0.5) {
          x = rng.nextDouble(); y = 1.05; opacity = 1.0; size = rng.nextDouble() * 3 + 1;
        }
        break;
      case _ParticleType.smoke:
        size += 0.3;
        opacity = (opacity - 0.003).clamp(0.0, 1.0);
        if (opacity <= 0) {
          x = rng.nextDouble() * 0.6 + 0.2; y = 0.95 + rng.nextDouble() * 0.05;
          size = rng.nextDouble() * 20 + 10; opacity = 0.3;
        }
        break;
    }
  }
}

enum _ParticleType { rain, wave, fog, heatShimmer, ember, smoke }

_Particle _rainDrop(Random rng, {bool heavy = false}) => _Particle(
  x: rng.nextDouble(), y: -rng.nextDouble() * 0.3,
  vx: heavy ? -0.003 : -0.001, vy: heavy ? 0.035 : 0.02,
  size: heavy ? 2.0 : 1.5,
  opacity: heavy ? 0.7 : 0.4,
  color: heavy ? Colors.lightBlueAccent : Colors.blue.shade200,
  type: _ParticleType.rain,
);

_Particle _wave(Random rng) => _Particle(
  x: -0.15, y: 0.75 + rng.nextDouble() * 0.2,
  vx: 0.006, vy: 0.0,
  size: rng.nextDouble() * 30 + 20,
  opacity: 0.2,
  color: Colors.blue.shade700,
  type: _ParticleType.wave,
);

_Particle _fogPatch(Random rng) => _Particle(
  x: rng.nextDouble(), y: rng.nextDouble(),
  vx: 0.002 + rng.nextDouble() * 0.003, vy: (rng.nextDouble() - 0.5) * 0.001,
  size: rng.nextDouble() * 80 + 40,
  opacity: rng.nextDouble() * 0.15 + 0.05,
  color: Colors.grey.shade400,
  type: _ParticleType.fog,
);

_Particle _heatShimmer(Random rng) => _Particle(
  x: rng.nextDouble(), y: rng.nextDouble(),
  vx: 0.0, vy: -0.003,
  size: rng.nextDouble() * 40 + 20,
  opacity: 0.08,
  color: Colors.orange.shade300,
  type: _ParticleType.heatShimmer,
);

_Particle _ember(Random rng) => _Particle(
  x: rng.nextDouble(), y: 1.0 + rng.nextDouble() * 0.1,
  vx: (rng.nextDouble() - 0.5) * 0.005, vy: -0.015 - rng.nextDouble() * 0.01,
  size: rng.nextDouble() * 3 + 1,
  opacity: 1.0,
  color: rng.nextDouble() > 0.5 ? Colors.orange : Colors.redAccent,
  type: _ParticleType.ember,
);

_Particle _smokePatch(Random rng) => _Particle(
  x: rng.nextDouble() * 0.6 + 0.2, y: 0.95 + rng.nextDouble() * 0.05,
  vx: (rng.nextDouble() - 0.5) * 0.002, vy: -0.005,
  size: rng.nextDouble() * 20 + 10,
  opacity: 0.25,
  color: Colors.grey.shade700,
  type: _ParticleType.smoke,
);

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles);
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dx = p.x * size.width;
      final dy = p.y * size.height;
      final paint = Paint()..color = p.color.withOpacity(p.opacity);

      switch (p.type) {
        case _ParticleType.rain:
          canvas.drawLine(
            Offset(dx, dy),
            Offset(dx + p.vx * size.width * 0.5, dy + p.vy * size.height * 0.5),
            paint..strokeWidth = p.size,
          );
          break;
        case _ParticleType.wave:
          final rect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(dx, dy), width: p.size * 2, height: p.size * 0.4),
            Radius.circular(p.size * 0.2),
          );
          canvas.drawRRect(rect, paint);
          break;
        case _ParticleType.fog:
        case _ParticleType.smoke:
          canvas.drawCircle(Offset(dx, dy), p.size / 2, paint);
          break;
        case _ParticleType.heatShimmer:
          canvas.drawOval(
            Rect.fromCenter(center: Offset(dx, dy), width: p.size, height: p.size * 0.3),
            paint,
          );
          break;
        case _ParticleType.ember:
          canvas.drawCircle(Offset(dx, dy), p.size / 2, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
