import 'package:flutter/material.dart';

/// Displays caterpillars on a tree with animated crawling effect.
class CaterpillarBadge extends StatefulWidget {
  const CaterpillarBadge({super.key, required this.count, this.compact = false});
  final int count;
  final bool compact;

  @override
  State<CaterpillarBadge> createState() => _CaterpillarBadgeState();
}

class _CaterpillarBadgeState extends State<CaterpillarBadge> with TickerProviderStateMixin {
  late AnimationController _crawl;
  late AnimationController _appear;

  @override
  void initState() {
    super.initState();
    _crawl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _appear = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  }

  @override
  void dispose() {
    _crawl.dispose();
    _appear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();

    if (widget.compact) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: _appear, curve: Curves.elasticOut),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.green.shade900.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade400.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _crawl,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(sin(_crawl.value * 2 * 3.14159) * 2, 0),
                    child: const Text('🐛', style: TextStyle(fontSize: 14)),
                  );
                },
              ),
              const SizedBox(width: 3),
              Text(
                '×${widget.count}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.green.shade300,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ScaleTransition(
      scale: CurvedAnimation(parent: _appear, curve: Curves.elasticOut),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.shade900.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade400.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _crawl,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(sin(_crawl.value * 2 * 3.14159) * 3, cos(_crawl.value * 2 * 3.14159) * 1.5),
                  child: const Text('🐛', style: TextStyle(fontSize: 18)),
                );
              },
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Гусеницы', style: TextStyle(fontSize: 11, color: Colors.white70)),
                Text(
                  '${widget.count} шт',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.green.shade300,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
