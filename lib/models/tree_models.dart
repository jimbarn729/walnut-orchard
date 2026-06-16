import 'package:flutter/material.dart';

enum TreeRarity { common, rare, epic, legendary }

extension TreeRarityExt on TreeRarity {
  String get label => ['Обычная', 'Редкая', 'Эпическая', 'Легендарная'][index];
  Color get color => [
        const Color(0xFF9E9E9E),
        const Color(0xFF4CAF50),
        const Color(0xFF9C27B0),
        const Color(0xFFFFD740),
      ][index];
}

enum TreeStatus { growth, rest, dead }

extension TreeStatusExt on TreeStatus {
  String get label => ['Рост', 'Отдых', 'Погибло'][index];
}

enum ActionType { water, fertilize, bird }

enum WeatherType { calm, cloudy, thunderstorm, heatwave, forestFire, flood, fog }

extension WeatherTypeExt on WeatherType {
  IconData get icon {
    switch (this) {
      case WeatherType.calm:
        return Icons.wb_sunny;
      case WeatherType.cloudy:
        return Icons.cloud;
      case WeatherType.thunderstorm:
        return Icons.flash_on;
      case WeatherType.heatwave:
        return Icons.wb_sunny;
      case WeatherType.forestFire:
        return Icons.local_fire_department;
      case WeatherType.flood:
        return Icons.water;
      case WeatherType.fog:
        return Icons.foggy;
    }
  }

  String get label {
    switch (this) {
      case WeatherType.calm:
        return 'Ясно';
      case WeatherType.cloudy:
        return 'Облачно';
      case WeatherType.thunderstorm:
        return 'Гроза';
      case WeatherType.heatwave:
        return 'Жара';
      case WeatherType.forestFire:
        return 'Пожар';
      case WeatherType.flood:
        return 'Наводнение';
      case WeatherType.fog:
        return 'Туман';
    }
  }

  Color get accent {
    switch (this) {
      case WeatherType.calm:
        return Colors.amber;
      case WeatherType.cloudy:
        return Colors.grey;
      case WeatherType.thunderstorm:
        return Colors.purple;
      case WeatherType.heatwave:
        return Colors.orange;
      case WeatherType.forestFire:
        return Colors.red;
      case WeatherType.flood:
        return Colors.cyan;
      case WeatherType.fog:
        return Colors.blueGrey;
    }
  }

  bool get isCritical => this == WeatherType.forestFire || this == WeatherType.flood || this == WeatherType.heatwave;
}

class TreeStats {
  final String emoji;
  final Color color;
  final double income;
  final double glowIntensity;

  const TreeStats({
    required this.emoji,
    required this.color,
    required this.income,
    required this.glowIntensity,
  });
}

class TreeModel {
  final String id;
  final String name;
  final String imageUrl;
  final TreeRarity rarity;
  TreeStatus status;
  int seasonDay;
  double currentWater;
  int caterpillars;
  int rebirthsLeft;
  final int maxRebirths;
  double price;
  bool forSale;
  bool isPlanted;
  String owner;
  String emotion;
  double emotionBonus;
  String timeLeftFormatted;
  bool canHarvest;
  int autoWaterDays;
  double autoWaterAmount;
  String? currentContainer;
  double waterCollectionProgress;
  String? currentNest;
  double birdGrowthProgress;
  final TreeStats stats;

  TreeModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rarity,
    required this.status,
    required this.seasonDay,
    required this.currentWater,
    required this.caterpillars,
    required this.rebirthsLeft,
    required this.maxRebirths,
    required this.price,
    required this.forSale,
    required this.isPlanted,
    required this.owner,
    required this.emotion,
    required this.emotionBonus,
    required this.timeLeftFormatted,
    required this.canHarvest,
    required this.autoWaterDays,
    required this.autoWaterAmount,
    this.currentContainer,
    required this.waterCollectionProgress,
    this.currentNest,
    required this.birdGrowthProgress,
    required this.stats,
  });

  double get waterPercent => (currentWater / 100).clamp(0.0, 1.0);

  String get growthStageEmoji {
    if (status != TreeStatus.growth) return '';
    final progress = seasonDay / 14;
    if (progress < 0.33) return '🌱';
    if (progress < 0.66) return '🌿';
    return '🌳';
  }
}

class DailyChallenge {
  final String id;
  final String description;
  final int target;
  int current;
  bool completed;
  bool claimed;
  final double reward;

  DailyChallenge({
    required this.id,
    required this.description,
    required this.target,
    required this.current,
    required this.completed,
    required this.claimed,
    required this.reward,
  });

  double get progress => target == 0 ? 0.0 : current / target;
}

class LeaderboardEntry {
  final String name;
  final double wlntBalance;
  final bool isPlayer;

  LeaderboardEntry({
    required this.name,
    required this.wlntBalance,
    required this.isPlayer,
  });
}

class ResourceLot {
  final String id;
  final String resourceType;
  final int quantity;
  final double pricePerUnit;
  final String sellerEmail;

  ResourceLot({
    required this.id,
    required this.resourceType,
    required this.quantity,
    required this.pricePerUnit,
    required this.sellerEmail,
  });
}

class ActionEvent {
  final String treeId;
  final ActionType type;

  const ActionEvent({required this.treeId, required this.type});
}
