import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';

/// Compact weather status bar that shows current weather, its effects, and day info.
class WeatherStatusBar extends StatelessWidget {
  const WeatherStatusBar({super.key, required this.game});
  final GameEngine game;

  @override
  Widget build(BuildContext context) {
    final w = game.currentWeather;
    final season = game.currentSeason;
    final seasonLabel = season == SeasonType.growth ? '🌱 Сезон роста' : '❄️ Сезон отдыха';
    final seasonProgress = game.seasonProgress;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weather row
          Row(
            children: [
              Text(w.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.text)),
                    Text(
                      _weatherEffect(w),
                      style: TextStyle(fontSize: 11, color: _weatherEffectColor(w)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _weatherBadge(w),
            ],
          ),
          const SizedBox(height: 6),
          // Season + day progress
          Row(
            children: [
              Text(seasonLabel, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: seasonProgress,
                    minHeight: 4,
                    backgroundColor: AppTheme.panelBorder,
                    valueColor: AlwaysStoppedAnimation(
                      season == SeasonType.growth ? Colors.green.shade400 : Colors.blue.shade300,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('День ${game.dayInSeason}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
            ],
          ),
        ],
      ),
    );
  }

  String _weatherEffect(WeatherType w) {
    switch (w) {
      case WeatherType.calm:
        return 'Всё в норме';
      case WeatherType.cloudy:
        return 'Влажность восстанавливается +50%';
      case WeatherType.thunderstorm:
        return 'Гусеницы ×2 • Влажность +50%';
      case WeatherType.flood:
        return '⚠️ Гусеницы ×4 • Влажность 100%';
      case WeatherType.fog:
        return 'Всё в норме';
      case WeatherType.heatwave:
        return '⚠️ Расход воды ×2 • Нет гусениц';
      case WeatherType.forestFire:
        return '🔥 Расход воды ×10 • Нет гусениц';
    }
  }

  Color _weatherEffectColor(WeatherType w) {
    switch (w) {
      case WeatherType.calm:
      case WeatherType.cloudy:
      case WeatherType.fog:
        return Colors.green.shade300;
      case WeatherType.thunderstorm:
        return Colors.amber.shade400;
      case WeatherType.flood:
      case WeatherType.forestFire:
        return Colors.red.shade400;
      case WeatherType.heatwave:
        return Colors.orange.shade400;
    }
  }

  Widget _weatherBadge(WeatherType w) {
    Color bg;
    Color border;
    switch (w) {
      case WeatherType.calm:
      case WeatherType.fog:
        bg = Colors.green.shade900;
        border = Colors.green.shade400;
        break;
      case WeatherType.cloudy:
        bg = Colors.blueGrey.shade900;
        border = Colors.blueGrey.shade400;
        break;
      case WeatherType.thunderstorm:
        bg = Colors.indigo.shade900;
        border = Colors.indigo.shade400;
        break;
      case WeatherType.flood:
      case WeatherType.forestFire:
        bg = Colors.red.shade900;
        border = Colors.red.shade400;
        break;
      case WeatherType.heatwave:
        bg = Colors.orange.shade900;
        border = Colors.orange.shade400;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border.withOpacity(0.5)),
      ),
      child: Text(
        w.emoji,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
