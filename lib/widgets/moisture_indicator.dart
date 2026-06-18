import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animated moisture bar with gradient (green→yellow→red) and pulse at critical levels.
class MoistureIndicator extends StatefulWidget {
  const MoistureIndicator({super.key, required this.value, this.height = 18});
  final double value; // 0..100
  final double height;

  @override
  State<MoistureIndicator> createState() => _MoistureIndicatorState();
}

class _MoistureIndicatorState extends State<MoistureIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value.clamp(0.0, 100.0);
    final isCritical = v < 15;
    final isEmpty = v == 0;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final pulseScale = isCritical ? 1.0 + _pulse.value * 0.03 : 1.0;
        return Transform.scale(scale: pulseScale, alignment: Alignment.centerLeft, child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isEmpty ? Icons.water_drop_outlined : Icons.water_drop,
                size: 14,
                color: isEmpty ? Colors.red.shade400 : AppTheme.gold,
              ),
              const SizedBox(width: 4),
              Text(
                '${v.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isEmpty ? Colors.red.shade400 : AppTheme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: widget.height,
              child: Stack(
                children: [
                  // Background
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.panelBorder,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Fill
                  FractionallySizedBox(
                    widthFactor: v / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _gradientColors(v),
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isCritical
                            ? [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 6)]
                            : null,
                      ),
                    ),
                  ),
                  // Shimmer
                  if (v > 0)
                    FractionallySizedBox(
                      widthFactor: v / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white.withOpacity(0.15), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _gradientColors(double v) {
    if (v < 20) return [Colors.red.shade700, Colors.red.shade400, Colors.red.shade300];
    if (v < 50) return [Colors.orange.shade700, Colors.amber.shade500, Colors.yellow.shade400];
    return [Colors.green.shade700, Colors.green.shade400, Colors.green.shade300];
  }
}

/// Compact version for tree cards
class MoistureBarCompact extends StatelessWidget {
  const MoistureBarCompact({super.key, required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 100.0);
    Color barColor;
    if (v < 20) {
      barColor = Colors.red.shade400;
    } else if (v < 50) {
      barColor = Colors.amber.shade400;
    } else {
      barColor = Colors.green.shade400;
    }

    return Row(
      children: [
        Icon(
          v == 0 ? Icons.water_drop_outlined : Icons.water_drop,
          size: 12,
          color: barColor,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v / 100,
              minHeight: 6,
              backgroundColor: AppTheme.panelBorder,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text('${v.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: barColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
