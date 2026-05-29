import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// РЕДКОСТИ, ЭМОЦИИ И СТАТЫ
// ═══════════════════════════════════════════════════════════════════════════════

enum TreeRarity { common, uncommon, rare, epic, legendary, mysterious }

class RarityStats {
  const RarityStats({
    required this.color,
    required this.emoji,
    required this.maxRebirths,
    required this.waterConsumption,
    required this.income,
    required this.caterpillarIntervalDays,
    required this.baseWaterDays,
    required this.baseBirdDays,
    required this.glowIntensity,
  });
  final Color color;
  final String emoji;
  final int maxRebirths;
  final double waterConsumption;
  final int income;
  final int caterpillarIntervalDays;
  final double baseWaterDays;
  final double baseBirdDays;
  final double glowIntensity;
}

const rarityTable = <TreeRarity, RarityStats>{
  TreeRarity.common: RarityStats(
    color: Color(0xFF9E9E9E), emoji: '🧤', maxRebirths: 3,
    waterConsumption: 4, income: 10000, caterpillarIntervalDays: 5,
    baseWaterDays: 3, baseBirdDays: 6, glowIntensity: 0.0,
  ),
  TreeRarity.uncommon: RarityStats(
    color: Color(0xFF39FF14), emoji: '🕶️', maxRebirths: 5,
    waterConsumption: 5, income: 16000, caterpillarIntervalDays: 4,
    baseWaterDays: 2, baseBirdDays: 5, glowIntensity: 0.15,
  ),
  TreeRarity.rare: RarityStats(
    color: Color(0xFF00B4FF), emoji: '🧣', maxRebirths: 10,
    waterConsumption: 6, income: 25000, caterpillarIntervalDays: 3,
    baseWaterDays: 1, baseBirdDays: 4, glowIntensity: 0.3,
  ),
  TreeRarity.epic: RarityStats(
    color: Color(0xFFB026FF), emoji: '🎖️', maxRebirths: 15,
    waterConsumption: 7, income: 50000, caterpillarIntervalDays: 2,
    baseWaterDays: 0.5, baseBirdDays: 3, glowIntensity: 0.6,
  ),
  TreeRarity.legendary: RarityStats(
    color: Color(0xFFFF6B00), emoji: '👑', maxRebirths: 20,
    waterConsumption: 8, income: 80000, caterpillarIntervalDays: 2,
    baseWaterDays: 0.25, baseBirdDays: 2, glowIntensity: 0.8,
  ),
  TreeRarity.mysterious: RarityStats(
    color: Color(0xFFFF1744), emoji: '🔮', maxRebirths: 30,
    waterConsumption: 10, income: 300000, caterpillarIntervalDays: 1,
    baseWaterDays: 0.125, baseBirdDays: 1, glowIntensity: 1.0,
  ),
};

extension TreeRarityX on TreeRarity {
  RarityStats get stats => rarityTable[this]!;
  String get label => switch (this) {
    TreeRarity.common => 'Common',
    TreeRarity.uncommon => 'Uncommon',
    TreeRarity.rare => 'Rare',
    TreeRarity.epic => 'Epic',
    TreeRarity.legendary => 'Legendary',
    TreeRarity.mysterious => 'Mysterious',
  };
}

const emotionBonuses = <String, double>{
  'Surprised': 0.15,
  'Without emotion': 0.0,
  'Indifferent': 0.10,
  'Sad': 0.05,
  'Happy': 0.20,
};

// ═══════════════════════════════════════════════════════════════════════════════
// СТАТУС · ПОГОДА
// ═══════════════════════════════════════════════════════════════════════════════

enum TreeStatus { growth, rest, dead }

enum WeatherType { thunderstorm, heatwave, forestFire, flood, fog, calm, cloudy }

extension WeatherTypeX on WeatherType {
  String get label => switch (this) {
    WeatherType.thunderstorm => 'Дождь с грозой',
    WeatherType.heatwave => 'Засуха',
    WeatherType.forestFire => 'Лесной пожар',
    WeatherType.flood => 'Наводнение',
    WeatherType.fog => 'Туман',
    WeatherType.calm => 'Облачно с прояснениями',
    WeatherType.cloudy => 'Облачно',
  };
  double get waterMultiplier => switch (this) {
    WeatherType.thunderstorm => 0.5,
    WeatherType.heatwave => 2.0,
    WeatherType.forestFire => 10.0,
    WeatherType.flood => 0.2,
    WeatherType.fog => 0.5,
    WeatherType.calm => 1.0,
    WeatherType.cloudy => 1.0,
  };
  IconData get icon => switch (this) {
    WeatherType.thunderstorm => Icons.thunderstorm_rounded,
    WeatherType.heatwave => Icons.thermostat_rounded,
    WeatherType.forestFire => Icons.local_fire_department_rounded,
    WeatherType.flood => Icons.flood_rounded,
    WeatherType.fog => Icons.blur_on_rounded,
    WeatherType.calm => Icons.wb_sunny_rounded,
    WeatherType.cloudy => Icons.cloud_rounded,
  };
  Color get accent => switch (this) {
    WeatherType.thunderstorm => const Color(0xFF7C4DFF),
    WeatherType.heatwave => const Color(0xFFFF9100),
    WeatherType.forestFire => const Color(0xFFFF1744),
    WeatherType.flood => const Color(0xFF00E5FF),
    WeatherType.fog => const Color(0xFFB0BEC5),
    WeatherType.calm => const Color(0xFFFFD740),
    WeatherType.cloudy => const Color(0xFF90A4AE),
  };
  bool get isCritical => this == WeatherType.forestFire;
}

WeatherType weatherForCycleDay(int cycleDay) {
  final index = ((cycleDay - 1) % 7) + 1;
  return switch (index) {
    1 => WeatherType.thunderstorm,
    2 => WeatherType.heatwave,
    3 => WeatherType.forestFire,
    4 => WeatherType.flood,
    5 => WeatherType.fog,
    6 => WeatherType.calm,
    7 => WeatherType.cloudy,
    _ => WeatherType.calm,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// МОДЕЛЬ ДЕРЕВА
// ═══════════════════════════════════════════════════════════════════════════════

class TreeModel {
  const TreeModel({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.rarity,
    required this.maxRebirths,
    required this.rebirthsLeft,
    required this.currentWater,
    required this.seasonDay,
    required this.caterpillars,
    required this.status,
    this.isPlanted = true,
    this.emotion = 'Without emotion',
    this.owner = '',
    this.forSale = false,
    this.price = 0.0,
    this.plantedAtGameDay = 1,
    this.autoWaterDays = 0,
    this.autoWaterAmount = 0.0,
    this.currentContainer,
    this.waterCollectionProgress = 0.0,
    this.currentNest,
    this.birdGrowthProgress = 0.0,
  });
  final String id, imageUrl, name, emotion, owner;
  final TreeRarity rarity;
  final int maxRebirths, rebirthsLeft;
  final double currentWater;
  final int seasonDay, caterpillars;
  final TreeStatus status;
  final bool isPlanted, forSale;
  final double price;
  final int plantedAtGameDay;
  final int autoWaterDays;
  final double autoWaterAmount;
  final String? currentContainer;
  final double waterCollectionProgress;
  final String? currentNest;
  final double birdGrowthProgress;

  RarityStats get stats => rarity.stats;
  double get emotionBonus => emotionBonuses[emotion] ?? 0.0;
  double get waterConsumptionRate =>
      stats.waterConsumption * (status == TreeStatus.growth ? 1.0 : 0.0);
  double get waterPercent => (currentWater / 100.0).clamp(0.0, 1.0);

  int get hoursLeft {
    if (status == TreeStatus.growth) {
      final targetDay = GameEngine.seasonLength;
      final daysRemaining = targetDay - seasonDay;
      return daysRemaining * 24;
    } else if (status == TreeStatus.rest) {
      return (GameEngine.seasonLength - seasonDay) * 24;
    }
    return 0;
  }

  String get timeLeftFormatted {
    final hrs = hoursLeft;
    final days = hrs ~/ 24;
    final remainingHrs = hrs % 24;
    return '${days}д ${remainingHrs}ч 0м';
  }

  String get growthStageEmoji {
    if (status != TreeStatus.growth) return '';
    final day = seasonDay;
    if (day <= 10) return '🌱';
    if (day <= 20) return '🌿';
    return '🌳';
  }

  bool get canHarvest => status == TreeStatus.growth && seasonDay >= GameEngine.seasonLength && currentWater >= 100.0 && caterpillars == 0;

  TreeModel copyWith({
    int? rebirthsLeft, double? currentWater, int? seasonDay,
    int? caterpillars, TreeStatus? status, bool? isPlanted,
    String? emotion, String? owner, bool? forSale, double? price,
    int? plantedAtGameDay, int? autoWaterDays, double? autoWaterAmount,
    String? currentContainer, double? waterCollectionProgress,
    String? currentNest, double? birdGrowthProgress,
  }) {
    return TreeModel(
      id: id, imageUrl: imageUrl, name: name, rarity: rarity,
      maxRebirths: maxRebirths,
      rebirthsLeft: rebirthsLeft ?? this.rebirthsLeft,
      currentWater: currentWater ?? this.currentWater,
      seasonDay: seasonDay ?? this.seasonDay,
      caterpillars: caterpillars ?? this.caterpillars,
      status: status ?? this.status,
      isPlanted: isPlanted ?? this.isPlanted,
      emotion: emotion ?? this.emotion,
      owner: owner ?? this.owner,
      forSale: forSale ?? this.forSale,
      price: price ?? this.price,
      plantedAtGameDay: plantedAtGameDay ?? this.plantedAtGameDay,
      autoWaterDays: autoWaterDays ?? this.autoWaterDays,
      autoWaterAmount: autoWaterAmount ?? this.autoWaterAmount,
      currentContainer: currentContainer ?? this.currentContainer,
      waterCollectionProgress: waterCollectionProgress ?? this.waterCollectionProgress,
      currentNest: currentNest ?? this.currentNest,
      birdGrowthProgress: birdGrowthProgress ?? this.birdGrowthProgress,
    );
  }
}

extension TreeStatusX on TreeStatus {
  String get label => switch (this) {
    TreeStatus.growth => 'Рост',
    TreeStatus.rest => 'Отдых',
    TreeStatus.dead => 'Мёртвое',
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// РЕСУРСНЫЙ ЛОТ
// ═══════════════════════════════════════════════════════════════════════════════

class ResourceLot {
  final String id;
  final String sellerEmail;
  final String resourceType;
  final int quantity;
  final double pricePerUnit;

  const ResourceLot({
    required this.id,
    required this.sellerEmail,
    required this.resourceType,
    required this.quantity,
    required this.pricePerUnit,
  });

  double get totalPrice => quantity * pricePerUnit;
}

class LeaderboardEntry {
  String name;
  double wlntBalance;
  bool isPlayer;

  LeaderboardEntry({
    required this.name,
    required this.wlntBalance,
    this.isPlayer = false,
  });
}

enum ActionType { water, fertilize, bird }
class ActionEvent {
  final String treeId;
  final ActionType type;
  const ActionEvent({required this.treeId, required this.type});
}

// ═══════════════════════════════════════════════════════════════════════════════
// ИГРОВОЙ ДВИЖОК
// ═══════════════════════════════════════════════════════════════════════════════

class GameEngine {
  GameEngine({
    required this.gameDay,
    required this.wlntBalance,
    required this.trees,
    required this.currentWeather,
    Map<String, int>? inventory,
    List<ResourceLot>? resourceLots,
    List<LeaderboardEntry>? leaderboard,
  })  : inventory = inventory ?? {'water_unit': 0, 'fertilizer_unit': 0, 'bird_unit': 0},
        resourceLots = resourceLots ?? [],
        leaderboard = leaderboard ?? [];

  static const seasonLength = 30;
  int gameDay;
  double wlntBalance;
  List<TreeModel> trees;
  WeatherType currentWeather;
  Map<String, int> inventory;
  List<ResourceLot> resourceLots;
  List<LeaderboardEntry> leaderboard;
  DateTime? _lastRealtimeTick;

  final List<void Function(String)> _incomeListeners = [];
  void addIncomeListener(void Function(String) listener) => _incomeListeners.add(listener);
  void removeIncomeListener(void Function(String) listener) => _incomeListeners.remove(listener);
  void _notifyIncome(String message) {
    final listeners = List.from(_incomeListeners);
    for (final l in listeners) {
      l(message);
    }
  }

  final ValueNotifier<ActionEvent?> actionEvent = ValueNotifier<ActionEvent?>(null);

  void _triggerActionEvent(String treeId, ActionType type) {
    actionEvent.value = ActionEvent(treeId: treeId, type: type);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (actionEvent.value?.treeId == treeId) {
        actionEvent.value = null;
      }
    });
  }

  void _rewardTopPlayers() {
    if (leaderboard.isEmpty) return;
    final sorted = List<LeaderboardEntry>.from(leaderboard)
      ..sort((a, b) => b.wlntBalance.compareTo(a.wlntBalance));
    final prizes = [3, 2, 1];
    for (int i = 0; i < min(3, sorted.length); i++) {
      final entry = sorted[i];
      if (entry.isPlayer) {
        inventory['fertilizer_unit'] = (inventory['fertilizer_unit'] ?? 0) + prizes[i];
        _notifyIncome('🏆 Вы заняли ${i + 1} место! Получено ${prizes[i]} удобрений.');
      }
    }
  }

  void tickRealtime(Duration elapsed) {
    final now = DateTime.now();
    if (_lastRealtimeTick == null) { _lastRealtimeTick = now; return; }
    final diffMinutes = now.difference(_lastRealtimeTick!).inMinutes;
    if (diffMinutes <= 0) return;
    _lastRealtimeTick = now;
    for (int i = 0; i < trees.length; i++) {
      final tree = trees[i];
      if (!tree.isPlanted || tree.status != TreeStatus.growth) continue;
      final lossPerMinute = tree.waterConsumptionRate / 24.0 / 60.0;
      final totalLoss = lossPerMinute * diffMinutes;
      if (totalLoss > 0) {
        trees[i] = tree.copyWith(currentWater: (tree.currentWater - totalLoss).clamp(0.0, 100.0));
      }
    }
  }

  void _applyAutoWater() {
    for (int i = 0; i < trees.length; i++) {
      final tree = trees[i];
      if (tree.autoWaterDays > 0) {
        trees[i] = tree.copyWith(
          currentWater: (tree.currentWater + tree.autoWaterAmount).clamp(0.0, 100.0),
          autoWaterDays: tree.autoWaterDays - 1,
        );
      }
    }
  }

  static const containerMultiplier = <String, double>{
    'bucket': 1.0, 'barrel': 2.0, 'tank': 4.0,
  };
  static const nestBirdCount = <String, int>{
    'son': 1, 'father': 5, 'grandfather': 10, 'elder': 20,
  };

  TreeModel _advanceGrowth(TreeModel tree, WeatherType weather) {
    if (!tree.isPlanted) return tree;
    var water = tree.currentWater;
    var day = tree.seasonDay;
    var cats = tree.caterpillars;
    water = (water - tree.stats.waterConsumption * weather.waterMultiplier).clamp(0.0, 100.0);
    if (gameDay % tree.stats.caterpillarIntervalDays == 0) cats++;
    if (weather == WeatherType.fog) cats *= 2;
    if (day < seasonLength && water > 0) {
      day++;
    } else if (day >= seasonLength) {
      day = seasonLength;
    }
    return tree.copyWith(currentWater: water, seasonDay: day, caterpillars: cats);
  }

  TreeModel _advanceRest(TreeModel tree) {
    if (!tree.isPlanted) return tree;
    inventory['water_unit'] = (inventory['water_unit'] ?? 0) + 1;
    inventory['fertilizer_unit'] = (inventory['fertilizer_unit'] ?? 0) + 1;

    double wProg = tree.waterCollectionProgress;
    double bProg = tree.birdGrowthProgress;
    int addedWaters = 0, addedBirds = 0;

    if (tree.currentContainer != null && tree.currentContainer != 'none') {
      final base = tree.stats.baseWaterDays;
      final mult = containerMultiplier[tree.currentContainer] ?? 1.0;
      final timeDays = base * mult;
      if (timeDays > 0) {
        wProg += 1.0 / timeDays;
        while (wProg >= 1.0) { addedWaters++; wProg -= 1.0; }
      }
    }
    if (tree.currentNest != null) {
      final baseBird = tree.stats.baseBirdDays;
      if (baseBird > 0) {
        bProg += 1.0 / baseBird;
        while (bProg >= 1.0) {
          addedBirds += nestBirdCount[tree.currentNest] ?? 0;
          bProg -= 1.0;
        }
      }
    }
    inventory['water_unit'] = (inventory['water_unit'] ?? 0) + addedWaters;
    inventory['bird_unit'] = (inventory['bird_unit'] ?? 0) + addedBirds;

    var day = tree.seasonDay + 1;
    var left = tree.rebirthsLeft;
    if (day > seasonLength) {
      left--;
      if (left > 0) {
        return tree.copyWith(
          seasonDay: 1, rebirthsLeft: left, status: TreeStatus.growth,
          isPlanted: false, currentWater: 100.0, plantedAtGameDay: gameDay,
          waterCollectionProgress: wProg, birdGrowthProgress: bProg,
        );
      } else {
        return tree.copyWith(
          seasonDay: 1, rebirthsLeft: 0, status: TreeStatus.dead,
          isPlanted: false, plantedAtGameDay: gameDay,
          waterCollectionProgress: wProg, birdGrowthProgress: bProg,
        );
      }
    }
    return tree.copyWith(
      seasonDay: day, rebirthsLeft: left,
      waterCollectionProgress: wProg, birdGrowthProgress: bProg,
    );
  }

  TreeModel _advanceTree(TreeModel tree) {
    if (tree.status == TreeStatus.dead || !tree.isPlanted) return tree;
    final weather = weatherForCycleDay(tree.seasonDay);
    return switch (tree.status) {
      TreeStatus.growth => _advanceGrowth(tree, weather),
      TreeStatus.rest => _advanceRest(tree),
      TreeStatus.dead => tree,
    };
  }

  void nextDay() {
    gameDay++;
    currentWeather = weatherForCycleDay(gameDay);
    _applyAutoWater();
    trees = trees.map(_advanceTree).toList();
    final playerEntry = leaderboard.where((e) => e.isPlayer).firstOrNull;
    if (playerEntry != null) {
      playerEntry.wlntBalance = wlntBalance;
    }
    if (gameDay % 30 == 0) {
      _rewardTopPlayers();
    }
  }

  static const _resourceActionMap = <String, String>{
    'water_bucket': 'water_unit',
    'water_barrel': 'water_unit',
    'water_tank': 'water_unit',
    'auto_water_basic': 'water_unit',
    'auto_water_cistern': 'water_unit',
    'fertilize_normal': 'fertilizer_unit',
    'fertilize_super': 'fertilizer_unit',
    'woodpecker_1': 'bird_unit',
    'woodpecker_5': 'bird_unit',
    'woodpecker_10': 'bird_unit',
    'woodpecker_all': 'bird_unit',
  };

  bool applyCare(String treeId, String careCode) {
    final idx = trees.indexWhere((t) => t.id == treeId);
    if (idx == -1) return false;
    final tree = trees[idx];
    if (!tree.isPlanted) return false;

    final resourceKey = _resourceActionMap[careCode];
    double price = 0;
    bool resourceUsed = false;

    if (resourceKey != null && (inventory[resourceKey] ?? 0) > 0) {
      resourceUsed = true;
    } else {
      switch (careCode) {
        case 'water_bucket': price = 200; break;
        case 'water_barrel': price = 490; break;
        case 'water_tank': price = 780; break;
        case 'auto_water_basic': price = 2100; break;
        case 'auto_water_cistern': price = 5000; break;
        case 'fertilize_normal': price = 1000; break;
        case 'fertilize_super': price = 3000; break;
        case 'woodpecker_1': price = 200; break;
        case 'woodpecker_5': price = 950; break;
        case 'woodpecker_10': price = 1900; break;
        case 'woodpecker_all': price = 5000; break;
        case 'set_bucket': price = 500; break;
        case 'set_barrel': price = 1500; break;
        case 'set_tank': price = 4000; break;
        case 'set_nest_son': price = 500; break;
        case 'set_nest_father': price = 1500; break;
        case 'set_nest_grandfather': price = 4000; break;
        case 'set_nest_elder': price = 10000; break;
        default: break;
      }
    }

    bool success = false;

    if ((resourceUsed || (price == 0 || wlntBalance >= price))) {
      switch (careCode) {
        case 'water_bucket':
          trees[idx] = tree.copyWith(currentWater: (tree.currentWater + 20).clamp(0.0, 100.0));
          _triggerActionEvent(treeId, ActionType.water);
          success = true;
          break;
        case 'water_barrel':
          trees[idx] = tree.copyWith(currentWater: (tree.currentWater + 50).clamp(0.0, 100.0));
          _triggerActionEvent(treeId, ActionType.water);
          success = true;
          break;
        case 'water_tank':
          trees[idx] = tree.copyWith(currentWater: (tree.currentWater + 80).clamp(0.0, 100.0));
          _triggerActionEvent(treeId, ActionType.water);
          success = true;
          break;
        case 'auto_water_basic':
          trees[idx] = tree.copyWith(autoWaterDays: 7, autoWaterAmount: 20);
          _triggerActionEvent(treeId, ActionType.water);
          success = true;
          break;
        case 'auto_water_cistern':
          trees[idx] = tree.copyWith(autoWaterDays: 7, autoWaterAmount: 50);
          _triggerActionEvent(treeId, ActionType.water);
          success = true;
          break;
        case 'fertilize_normal':
          if (tree.status == TreeStatus.growth && tree.seasonDay < seasonLength) {
            trees[idx] = tree.copyWith(seasonDay: min(tree.seasonDay + 1, seasonLength));
            _triggerActionEvent(treeId, ActionType.fertilize);
            success = true;
          }
          break;
        case 'fertilize_super':
          if (tree.status == TreeStatus.growth && tree.seasonDay < seasonLength) {
            trees[idx] = tree.copyWith(seasonDay: min(tree.seasonDay + 3, seasonLength));
            _triggerActionEvent(treeId, ActionType.fertilize);
            success = true;
          }
          break;
        case 'woodpecker_1':
          if (tree.caterpillars >= 1) {
            trees[idx] = tree.copyWith(caterpillars: tree.caterpillars - 1);
            _triggerActionEvent(treeId, ActionType.bird);
            success = true;
          }
          break;
        case 'woodpecker_5':
          if (tree.caterpillars >= 5) {
            trees[idx] = tree.copyWith(caterpillars: tree.caterpillars - 5);
            _triggerActionEvent(treeId, ActionType.bird);
            success = true;
          }
          break;
        case 'woodpecker_10':
          if (tree.caterpillars >= 10) {
            trees[idx] = tree.copyWith(caterpillars: tree.caterpillars - 10);
            _triggerActionEvent(treeId, ActionType.bird);
            success = true;
          }
          break;
        case 'woodpecker_all':
          if (tree.caterpillars > 0) {
            trees[idx] = tree.copyWith(caterpillars: 0);
            _triggerActionEvent(treeId, ActionType.bird);
            success = true;
          }
          break;
        case 'set_bucket':
          if (tree.status == TreeStatus.rest) {
            trees[idx] = tree.copyWith(currentContainer: 'bucket', waterCollectionProgress: 0.0);
            success = true;
          }
          break;
        case 'set_barrel':
          if (tree.status == TreeStatus.rest) {
            trees[idx] = tree.copyWith(currentContainer: 'barrel', waterCollectionProgress: 0.0);
            success = true;
          }
          break;
        case 'set_tank':
          if (tree.status == TreeStatus.rest) {
            trees[idx] = tree.copyWith(currentContainer: 'tank', waterCollectionProgress: 0.0);
            success = true;
          }
          break;
        case 'set_nest_son':
          if (tree.status == TreeStatus.rest) {
            trees[idx] = tree.copyWith(currentNest: 'son', birdGrowthProgress: 0.0);
            success = true;
          }
          break;
        case 'set_nest_father':
          if (tree.status == TreeStatus.rest) {
            trees[idx] = tree.copyWith(currentNest: 'father', birdGrowthProgress: 0.0);
            success = true;
          }
          break;
        case 'set_nest_grandfather':
          if (tree.status == TreeStatus.rest) {
            trees[idx] = tree.copyWith(currentNest: 'grandfather', birdGrowthProgress: 0.0);
            success = true;
          }
          break;
        case 'set_nest_elder':
          if (tree.status == TreeStatus.rest) {
            trees[idx] = tree.copyWith(currentNest: 'elder', birdGrowthProgress: 0.0);
            success = true;
          }
          break;
        default: return false;
      }
    }

    if (success) {
      if (resourceUsed) {
        final key = resourceKey!;
        inventory[key] = (inventory[key] ?? 0) - 1;
      } else if (price > 0) {
        wlntBalance -= price;
      }
      final playerEntry = leaderboard.where((e) => e.isPlayer).firstOrNull;
      if (playerEntry != null) {
        playerEntry.wlntBalance = wlntBalance;
      }
      return true;
    }
    return false;
  }

  void harvestTree(String id) {
    final i = trees.indexWhere((t) => t.id == id);
    if (i == -1) return;
    final tree = trees[i];
    if (!tree.canHarvest) return;
    double income = tree.stats.income * (1 + tree.emotionBonus);
    wlntBalance += income;
    _notifyIncome('+${income.toStringAsFixed(0)} WLNT от ${tree.name}');
    trees[i] = tree.copyWith(
      status: TreeStatus.rest,
      seasonDay: 1,
      caterpillars: 0,
      currentWater: 100.0,
      plantedAtGameDay: gameDay,
    );
  }

  bool plantTree(String id) {
    final i = trees.indexWhere((t) => t.id == id);
    if (i == -1 || trees[i].isPlanted) return false;
    trees[i] = trees[i].copyWith(
        isPlanted: true, status: TreeStatus.growth, currentWater: 100.0,
        seasonDay: 1, caterpillars: 0, plantedAtGameDay: gameDay);
    return true;
  }

  void sellTree(String id, double price) {
    final i = trees.indexWhere((t) => t.id == id);
    if (i == -1) return;
    trees[i] = trees[i].copyWith(forSale: true, price: price);
  }

  void cancelSell(String id) {
    final i = trees.indexWhere((t) => t.id == id);
    if (i == -1) return;
    trees[i] = trees[i].copyWith(forSale: false, price: 0.0);
  }

  void buyTree(String id, String buyer) {
    final i = trees.indexWhere((t) => t.id == id);
    if (i == -1) return;
    final tree = trees[i];
    if (wlntBalance < tree.price) return;
    wlntBalance -= tree.price;
    trees[i] = tree.copyWith(
        owner: buyer, forSale: false, price: 0.0, isPlanted: true,
        status: TreeStatus.growth, currentWater: 100.0, seasonDay: 1,
        caterpillars: 0, plantedAtGameDay: gameDay);
  }

  void burnTree(String id) {
    final i = trees.indexWhere((t) => t.id == id);
    if (i == -1) return;
    final tree = trees[i];
    wlntBalance += 2000;
    final fertByRarity = <TreeRarity, int>{
      TreeRarity.common: 1, TreeRarity.uncommon: 3, TreeRarity.rare: 6,
      TreeRarity.epic: 9, TreeRarity.legendary: 12, TreeRarity.mysterious: 15,
    };
    final amount = fertByRarity[tree.rarity] ?? 0;
    inventory['fertilizer_unit'] = (inventory['fertilizer_unit'] ?? 0) + amount;
    trees.removeAt(i);
  }

  void sellResource(String sellerEmail, String resourceType, int quantity, double pricePerUnit) {
    if ((inventory[resourceType] ?? 0) < quantity) return;
    inventory[resourceType] = (inventory[resourceType] ?? 0) - quantity;
    final id = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    resourceLots.add(ResourceLot(
      id: id,
      sellerEmail: sellerEmail,
      resourceType: resourceType,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
    ));
  }

  void buyResource(String resourceLotId, String buyerEmail) {
    final idx = resourceLots.indexWhere((l) => l.id == resourceLotId);
    if (idx == -1) return;
    final lot = resourceLots[idx];
    if (lot.sellerEmail == buyerEmail) return;
    if (wlntBalance < lot.totalPrice) return;
    wlntBalance -= lot.totalPrice;
    inventory[lot.resourceType] = (inventory[lot.resourceType] ?? 0) + lot.quantity;
    resourceLots.removeAt(idx);
  }

  void cancelResourceSell(String resourceLotId) {
    final idx = resourceLots.indexWhere((l) => l.id == resourceLotId);
    if (idx == -1) return;
    final lot = resourceLots[idx];
    inventory[lot.resourceType] = (inventory[lot.resourceType] ?? 0) + lot.quantity;
    resourceLots.removeAt(idx);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ТЕМА
// ═══════════════════════════════════════════════════════════════════════════════

abstract final class AppTheme {
  static const bg = Color(0xFF080A08);
  static const panel = Color(0xFF12141A);
  static const panelBorder = Color(0xFF2A3040);
  static const text = Color(0xFFE8EDE4);
  static const muted = Color(0xFF7A8A82);
  static const gold = Color(0xFFFFD54F);
  static const neutralGradient = [
    Color(0xFF1C1C1E), Color(0xFF2C2C2E), Color(0xFF3A3A3C), Color(0xFF48484A),
  ];
  static List<BoxShadow> neonGlow(Color c, {double blur = 18}) => [
    BoxShadow(color: c.withOpacity(0.65), blurRadius: blur, spreadRadius: 1),
    BoxShadow(color: c.withOpacity(0.35), blurRadius: blur * 2),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// НАЧАЛЬНЫЕ ДАННЫЕ
// ═══════════════════════════════════════════════════════════════════════════════

List<TreeModel> _initialTrees() => [
  TreeModel(id: '0', imageUrl: 'https://gateway.irys.xyz/9tZ8WoKgNzFzGkvfHYsAjuTyHXKX3FGzLPJNxj2uJ1um',
    name: '#0', rarity: TreeRarity.mysterious, maxRebirths: 100, rebirthsLeft: 100,
    currentWater: 100, seasonDay: 0, caterpillars: 0, status: TreeStatus.growth, isPlanted: false,
    emotion: 'Without emotion', plantedAtGameDay: 1,
  ),
  TreeModel(id: '1', imageUrl: 'https://gateway.irys.xyz/Dp69bAFua6UaGxg9ZVC8ne9EjpLrw4cM2MdmU2sx2mVD',
    name: '#1', rarity: TreeRarity.common, maxRebirths: 3, rebirthsLeft: 3,
    currentWater: 0, seasonDay: 6, caterpillars: 2, status: TreeStatus.growth, isPlanted: true,
    emotion: 'Surprised', plantedAtGameDay: 1,
  ),
  TreeModel(id: '3', imageUrl: 'https://gateway.irys.xyz/CwHyPeeUwbdf7craVzppiM8AETg1Ww7AceqX1CkmFWeu',
    name: '#3', rarity: TreeRarity.uncommon, maxRebirths: 5, rebirthsLeft: 5,
    currentWater: 65, seasonDay: 11, caterpillars: 0, status: TreeStatus.growth, isPlanted: true,
    emotion: 'Without emotion', plantedAtGameDay: 1,
  ),
  TreeModel(id: '6', imageUrl: 'https://gateway.irys.xyz/DSvtn4gMQgkB9n7ivke5uBFca3LEzaeaP98USQtb81Wv',
    name: '#6', rarity: TreeRarity.common, maxRebirths: 3, rebirthsLeft: 3,
    currentWater: 70, seasonDay: 20, caterpillars: 0, status: TreeStatus.growth, isPlanted: true,
    emotion: 'Indifferent', plantedAtGameDay: 1,
  ),
  TreeModel(id: '9', imageUrl: 'https://gateway.irys.xyz/FbNbh3F2SMX1GhPjn4TyfRKCD7n9ixLNwiNL8mnD6gBK',
    name: '#9', rarity: TreeRarity.common, maxRebirths: 3, rebirthsLeft: 3,
    currentWater: 80, seasonDay: 15, caterpillars: 0, status: TreeStatus.rest, isPlanted: true,
    emotion: 'Sad', plantedAtGameDay: 1,
  ),
  TreeModel(id: '13', imageUrl: 'https://gateway.irys.xyz/GZ9JVevPvu5fbSTKWXKMeTNmL5rC2qW3F6xWzrtu8KLN',
    name: '#13', rarity: TreeRarity.common, maxRebirths: 3, rebirthsLeft: 3,
    currentWater: 90, seasonDay: 22, caterpillars: 0, status: TreeStatus.growth, isPlanted: true,
    emotion: 'Happy', plantedAtGameDay: 1,
  ),
];

List<ResourceLot> _initialResourceLots() => [
  ResourceLot(id: 'sys_w1', sellerEmail: 'system', resourceType: 'water_unit', quantity: 5, pricePerUnit: 150),
  ResourceLot(id: 'sys_f1', sellerEmail: 'system', resourceType: 'fertilizer_unit', quantity: 2, pricePerUnit: 800),
  ResourceLot(id: 'sys_b1', sellerEmail: 'system', resourceType: 'bird_unit', quantity: 1, pricePerUnit: 1000),
];

List<LeaderboardEntry> _initialLeaderboard(String playerEmail) {
  final rng = Random(42);
  final bots = ['Bot_Alice', 'Bot_Bob', 'Bot_Carol', 'Bot_Dave', 'Bot_Eve'];
  final entries = <LeaderboardEntry>[];
  for (final name in bots) {
    entries.add(LeaderboardEntry(
      name: name,
      wlntBalance: 10000 + rng.nextDouble() * 5000,
    ));
  }
  entries.add(LeaderboardEntry(
    name: playerEmail,
    wlntBalance: 12450.75,
    isPlayer: true,
  ));
  return entries;
}

// ═══════════════════════════════════════════════════════════════════════════════
// АВТОРИЗАЦИЯ
// ═══════════════════════════════════════════════════════════════════════════════

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onLogin});
  final void Function(String email, String referralCode) onLogin;
  @override State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController(), _passCtrl = TextEditingController(), _refCtrl = TextEditingController();
  bool _obscure = true;
  final _formKey = GlobalKey<FormState>();

  @override void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); _refCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate())
      widget.onLogin(_emailCtrl.text.trim(), _refCtrl.text.trim());
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bg,
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        ShaderMask(shaderCallback: (b) => LinearGradient(colors: [const Color(0xFF7CFC6E), AppTheme.gold]).createShader(b),
          child: const Text('🌳 WALNUT FARM', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
        const SizedBox(height: 8),
        const Text('Войдите, чтобы начать игру', style: TextStyle(color: AppTheme.muted, fontSize: 14)),
        const SizedBox(height: 32),
        TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: AppTheme.text),
          decoration: InputDecoration(labelText: 'Email', labelStyle: const TextStyle(color: AppTheme.muted),
            prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.muted), filled: true, fillColor: AppTheme.panel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7CFC6E)))),
          validator: (v) => v == null || v.trim().isEmpty || !v.contains('@') ? 'Некорректный email' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _passCtrl, obscureText: _obscure, style: const TextStyle(color: AppTheme.text),
          decoration: InputDecoration(labelText: 'Пароль', labelStyle: const TextStyle(color: AppTheme.muted),
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.muted),
            suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.muted),
              onPressed: () => setState(() => _obscure = !_obscure)),
            filled: true, fillColor: AppTheme.panel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7CFC6E)))),
          validator: (v) => v == null || v.trim().isEmpty ? 'Введите пароль' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _refCtrl, style: const TextStyle(color: AppTheme.text),
          decoration: InputDecoration(labelText: 'Реферальный код друга', labelStyle: const TextStyle(color: AppTheme.muted),
            prefixIcon: const Icon(Icons.card_giftcard, color: AppTheme.muted), filled: true, fillColor: AppTheme.panel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.gold)))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            shadowColor: const Color(0xFF00E676).withOpacity(0.5), elevation: 8),
            onPressed: _submit, child: const Text('ВОЙТИ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white)))),
        const SizedBox(height: 16),
        Text('Введите код друга и получите 1000 WLNT', style: TextStyle(color: AppTheme.muted.withOpacity(0.6), fontSize: 12), textAlign: TextAlign.center),
      ]))),
    )),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN APP
// ═══════════════════════════════════════════════════════════════════════════════

void main() => runApp(const WalnutFarmApp());

class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});
  final Widget child;
  static const w = 450.0, h = 900.0;
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF0A0A0A), body: Center(child: SizedBox(width: w, height: h,
    child: ClipRRect(borderRadius: BorderRadius.circular(28), child: DecoratedBox(decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF2A2A2A), width: 2),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 40, spreadRadius: 4)]),
      child: child)))));
}

class WalnutFarmApp extends StatefulWidget {
  const WalnutFarmApp({super.key});
  @override State<WalnutFarmApp> createState() => _WalnutFarmAppState();
}

class _WalnutFarmAppState extends State<WalnutFarmApp> {
  bool _logged = false;
  String _email = '', _myRefCode = '';
  bool _usedReferral = false;
  ThemeMode _themeMode = ThemeMode.dark;

  void _login(String email, String refCode) {
    final code = refCode.trim().isNotEmpty
        ? 'WALNUT${Random().nextInt(999999).toString().padLeft(6, '0')}'
        : 'WALNUT${email.hashCode.abs().toString().substring(0, 6)}';
    setState(() { _logged = true; _email = email; _myRefCode = code; _usedReferral = refCode.trim().isNotEmpty; });
  }

  @override Widget build(BuildContext context) {
    final initialWlnt = 12450.75 + (_usedReferral ? 1000 : 0);
    return MaterialApp(
      title: 'Walnut Farm',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50), brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50), brightness: Brightness.dark),
      ),
      builder: (c, child) => PhoneFrame(child: child ?? const SizedBox.shrink()),
      home: _logged ? MainShell(
        initialWlnt: initialWlnt,
        userEmail: _email,
        myReferralCode: _myRefCode,
        themeMode: _themeMode,
        onToggleTheme: () => setState(() => _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
        onLogout: () => setState(() { _logged = false; _email = ''; _myRefCode = ''; _usedReferral = false; }),
      ) : AuthScreen(onLogin: _login),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN SHELL
// ═══════════════════════════════════════════════════════════════════════════════

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.initialWlnt,
    required this.userEmail,
    required this.myReferralCode,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onLogout,
  });
  final double initialWlnt;
  final String userEmail, myReferralCode;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme, onLogout;

  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _tab = 0;
  late GameEngine _game;
  String? _selectedTreeId;
  double _solBalance = 2.5;
  Timer? _realtimeTimer;
  late AnimationController _incomeAnimCtrl;
  final List<_FloatingIncome> _floatingIncomes = [];
  late final AudioPlayer _uiPlayer;

  @override void initState() {
    super.initState();
    _game = GameEngine(
      gameDay: 1,
      wlntBalance: widget.initialWlnt,
      trees: _initialTrees(),
      currentWeather: weatherForCycleDay(1),
      inventory: {'water_unit': 2, 'fertilizer_unit': 1, 'bird_unit': 0},
      resourceLots: _initialResourceLots(),
      leaderboard: _initialLeaderboard(widget.userEmail),
    );
    _realtimeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _game.tickRealtime(const Duration(minutes: 1)));
    });
    _incomeAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _game.addIncomeListener(_onIncomeNotification);
    _uiPlayer = AudioPlayer();
  }

  void _onIncomeNotification(String message) {
    _addFloatingIncome(message);
    _safePlay('sounds/coins.mp3');
  }

  void _safePlay(String asset) {
    try {
      _uiPlayer.stop().then((_) => _uiPlayer.play(AssetSource(asset)));
    } catch (_) {}
  }

  void _addFloatingIncome(String message) {
    final offset = Offset(MediaQuery.of(context).size.width / 2 - 60, 300.0);
    setState(() {
      _floatingIncomes.add(_FloatingIncome(message: message, offset: offset, opacity: 1.0));
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          if (_floatingIncomes.isNotEmpty) _floatingIncomes.removeAt(0);
        });
      }
    });
  }

  @override void dispose() {
    _realtimeTimer?.cancel();
    _game.removeIncomeListener(_onIncomeNotification);
    _incomeAnimCtrl.dispose();
    _uiPlayer.dispose();
    super.dispose();
  }

  void _daySkip() => setState(() => _game.nextDay());
  void _selectTree(String? id) => setState(() => _selectedTreeId = id);

  bool _treeAction(String treeId, String action) {
    bool ok = _game.applyCare(treeId, action);
    if (ok) {
      setState(() {});
      _safePlay('sounds/click.mp3');
    }
    return ok;
  }

  void _sellTree(String treeId, double price) {
    final tree = _game.trees.firstWhere((t) => t.id == treeId);
    if (tree.isPlanted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя продать посаженное дерево. Дождитесь завершения цикла.')),
      );
      return;
    }
    setState(() => _game.sellTree(treeId, price));
    _safePlay('sounds/click.mp3');
  }

  void _cancelSell(String treeId) {
    setState(() => _game.cancelSell(treeId));
    _safePlay('sounds/click.mp3');
  }
  void _buyTree(String treeId) {
    setState(() => _game.buyTree(treeId, widget.userEmail));
    _safePlay('sounds/click.mp3');
  }

  void _sellResource(String resourceType, int quantity, double pricePerUnit) {
    setState(() => _game.sellResource(widget.userEmail, resourceType, quantity, pricePerUnit));
    _safePlay('sounds/click.mp3');
  }
  void _buyResource(String lotId) {
    setState(() => _game.buyResource(lotId, widget.userEmail));
    _safePlay('sounds/click.mp3');
  }
  void _cancelResourceSell(String lotId) {
    setState(() => _game.cancelResourceSell(lotId));
    _safePlay('sounds/click.mp3');
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          IndexedStack(index: _tab, children: [
            FarmScreen(game: _game, selectedId: _selectedTreeId, onDaySkip: _daySkip, onSelectTree: _selectTree, onAction: _treeAction, uiPlayer: _uiPlayer),
            MarketScreen(game: _game, userEmail: widget.userEmail, onBuyTree: _buyTree, onCancelTreeSell: _cancelSell, onBuyResource: _buyResource, onCancelResourceSell: _cancelResourceSell, onSellResource: _sellResource, uiPlayer: _uiPlayer),
            LuckyScreen(game: _game, onBurned: (id) => setState(() => _game.burnTree(id)), uiPlayer: _uiPlayer),
            CollectionScreen(game: _game, userEmail: widget.userEmail, onSelectTree: _selectTree, onPlant: (id) { if (_game.plantTree(id)) setState(() {}); _safePlay('sounds/click.mp3'); }, onSell: _sellTree, onCancelSell: _cancelSell, leaderboard: _game.leaderboard, onHarvest: (id) { setState(() => _game.harvestTree(id)); _safePlay('sounds/click.mp3'); }, uiPlayer: _uiPlayer),
            WalletScreen(solBalance: _solBalance, wlntBalance: _game.wlntBalance, userEmail: widget.userEmail, myReferralCode: widget.myReferralCode, themeMode: widget.themeMode, onToggleTheme: widget.onToggleTheme, onLogout: widget.onLogout, onDepositSol: (a) => setState(() => _solBalance += a), onWithdrawSol: (a) { if (a <= _solBalance) setState(() => _solBalance -= a); }, onDepositWlnt: (a) => setState(() => _game.wlntBalance += a), onWithdrawWlnt: (a) { if (a <= _game.wlntBalance) setState(() => _game.wlntBalance -= a); }, uiPlayer: _uiPlayer),
          ]),
          ..._floatingIncomes.map((f) => Positioned(left: f.offset.dx, top: f.offset.dy - 50 * (1 - f.opacity), child: Opacity(opacity: f.opacity, child: Material(color: Colors.transparent, child: Text(f.message, style: TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold)))))),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          _safePlay('sounds/click.mp3');
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: const Color(0xFF1B3D1F),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.eco_outlined), selectedIcon: Icon(Icons.eco, color: Color(0xFF7CFC6E)), label: 'Сад'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Магазин'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), selectedIcon: Icon(Icons.auto_awesome, color: Colors.amber), label: 'Удача'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Деревья'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: AppTheme.gold), label: 'Кошелёк'),
        ],
      ),
    );
  }
}

class _FloatingIncome {
  final String message;
  final Offset offset;
  final double opacity;
  _FloatingIncome({required this.message, required this.offset, required this.opacity});
}

// ═══════════════════════════════════════════════════════════════════════════════
// САД (FarmScreen + VisualGarden)
// ═══════════════════════════════════════════════════════════════════════════════

class FarmScreen extends StatelessWidget {
  const FarmScreen({super.key, required this.game, required this.selectedId, required this.onDaySkip, required this.onSelectTree, required this.onAction, required this.uiPlayer});
  final GameEngine game; final String? selectedId; final VoidCallback onDaySkip; final ValueChanged<String?> onSelectTree; final bool Function(String treeId, String action) onAction; final AudioPlayer uiPlayer;

  TreeModel? _findSelected() => selectedId == null ? null : game.trees.cast<TreeModel?>().firstWhere((t) => t!.id == selectedId, orElse: () => null);

  @override Widget build(BuildContext context) {
    final selected = _findSelected();
    return SafeArea(child: Stack(children: [
      Column(children: [
        Expanded(flex: 3, child: VisualGarden(game: game, selectedId: selectedId, onTreeTap: (id) {
          if (selectedId == id) onSelectTree(null); else onSelectTree(id);
        }, uiPlayer: uiPlayer)),
        const SizedBox(height: 8),
        _SkipDayButton(onPressed: onDaySkip),
        const SizedBox(height: 8),
      ]),
      if (selected != null && selected!.isPlanted)
        Positioned(right: 0, top: 80, bottom: 80, child: ActionPanel(tree: selected!, game: game, onAction: (action) => onAction(selected!.id, action), onClose: () => onSelectTree(null), uiPlayer: uiPlayer)),
    ]));
  }
}

class VisualGarden extends StatefulWidget {
  const VisualGarden({super.key, required this.game, required this.selectedId, required this.onTreeTap, required this.uiPlayer});
  final GameEngine game; final String? selectedId; final ValueChanged<String> onTreeTap; final AudioPlayer uiPlayer;
  @override State<VisualGarden> createState() => _VisualGardenState();
}

class _VisualGardenState extends State<VisualGarden> with TickerProviderStateMixin {
  late AnimationController _rainCtrl, _fireCtrl, _floodCtrl, _fogCtrl;

  @override void initState() {
    super.initState();
    _rainCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _fireCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _floodCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _fogCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override void dispose() {
    _rainCtrl.dispose(); _fireCtrl.dispose(); _floodCtrl.dispose(); _fogCtrl.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final game = widget.game;
    final growthTrees = game.trees.where((t) => t.isPlanted && t.status == TreeStatus.growth).toList();
    final restTrees = game.trees.where((t) => t.isPlanted && t.status == TreeStatus.rest).toList();
    final weather = game.currentWeather;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 8))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: const LinearGradient(colors: AppTheme.neutralGradient, begin: Alignment.topLeft, end: Alignment.bottomRight)))),
        Positioned(top: 12, left: 16, right: 16, child: Row(children: [
          Expanded(child: Text('🌳 САД', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.text))),
          _GlassChip(icon: weather.icon, label: weather.label, color: weather.accent, critical: weather.isCritical),
        ])),
        Padding(padding: const EdgeInsets.only(top: 50), child: Row(children: [
          Expanded(child: _ZonePanel(title: '🌱 Рост', trees: growthTrees, selectedId: widget.selectedId, onTreeTap: widget.onTreeTap, weather: weather, isGrowth: true, game: game, uiPlayer: widget.uiPlayer)),
          Container(width: 2, color: AppTheme.panelBorder.withOpacity(0.4)),
          Expanded(child: _ZonePanel(title: '❄️ Отдых', trees: restTrees, selectedId: widget.selectedId, onTreeTap: widget.onTreeTap, weather: weather, isGrowth: false, game: game, uiPlayer: widget.uiPlayer)),
        ])),
        if (weather == WeatherType.thunderstorm)
          Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: Stack(children: [
            RainEffect(controller: _rainCtrl),
            Positioned(top: 10, right: 20, child: Icon(Icons.cloud, size: 50, color: const Color(0xBBFFFFFF))),
            AnimatedBuilder(animation: _rainCtrl, builder: (_, __) {
              if (Random().nextDouble() < 0.05)
                return Positioned(top: 20, left: Random().nextInt(200).toDouble(), child: const Icon(Icons.flash_on, color: Colors.yellow, size: 24));
              return const SizedBox.shrink();
            }),
          ]))),
        if (weather == WeatherType.heatwave)
          Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: Stack(children: [
            Positioned(top: 10, right: 30, child: Icon(Icons.wb_sunny, size: 50, color: const Color(0xFFFFD740).withOpacity(0.9))),
            Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topRight, radius: 0.6, colors: [Color(0x44FF9100), Colors.transparent]))),
            CustomPaint(painter: CrackPainter(), size: Size.infinite),
          ]))),
        if (weather == WeatherType.forestFire)
          Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: AnimatedBuilder(animation: _fireCtrl, builder: (_, __) => CustomPaint(painter: _FirePainter(_fireCtrl.value), size: Size.infinite)))),
        if (weather == WeatherType.flood)
          Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: _FloodEffect(controller: _floodCtrl))),
        if (weather == WeatherType.fog)
          Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: _FogEffect(controller: _fogCtrl))),
        if (weather == WeatherType.calm)
          Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: Stack(children: [
            Positioned(top: 10, left: 20, child: Icon(Icons.cloud, size: 40, color: const Color(0xAAFFFFFF))),
            Positioned(top: 15, right: 40, child: Icon(Icons.wb_sunny, size: 35, color: const Color(0xFFFFD740).withOpacity(0.8))),
          ]))),
        if (weather == WeatherType.cloudy)
          Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Icon(Icons.cloud, size: 40, color: const Color(0xAAFFFFFF)),
            Icon(Icons.cloud, size: 35, color: const Color(0x99FFFFFF)),
            Icon(Icons.cloud, size: 45, color: const Color(0xAAFFFFFF)),
          ]))),
      ])),
    );
  }
}

class CrackPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF5D4037)..strokeWidth = 1.5;
    final rng = Random(99);
    for (int i = 0; i < 8; i++) {
      var x = rng.nextDouble() * size.width;
      var y = rng.nextDouble() * size.height * 0.7 + size.height * 0.3;
      final path = Path()..moveTo(x, y);
      for (int j = 0; j < 5; j++) {
        x += (rng.nextDouble() - 0.5) * 30;
        y += rng.nextDouble() * 15 + 5;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _FirePainter extends CustomPainter {
  final double progress;
  _FirePainter(this.progress);
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
          colors: [const Color(0xFFFF1744).withOpacity(0.8), Colors.transparent],
          begin: Alignment.bottomCenter, end: Alignment.topCenter)
          .createShader(Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4));
    final path = Path();
    final w = size.width, h = size.height;
    for (int i = 0; i < 5; i++) {
      final x = i * w / 4;
      final sway = sin(progress * 2 * pi * 2 + i) * 20;
      path.moveTo(x, h); path.lineTo(x + sway, h * 0.7); path.lineTo(x + w / 8 + sway, h * 0.6); path.lineTo(x + w / 4, h * 0.8);
    }
    path.lineTo(w, h); path.close();
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => true;
}

class _FloodEffect extends StatelessWidget {
  const _FloodEffect({required this.controller});
  final AnimationController controller;
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: controller, builder: (_, __) => Align(alignment: Alignment.bottomCenter, child: FractionallySizedBox(heightFactor: 0.1 + controller.value * 0.15, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0x8800E5FF), const Color(0x4400E5FF)], begin: Alignment.bottomCenter, end: Alignment.topCenter))))));
}

class _FogEffect extends StatelessWidget {
  const _FogEffect({required this.controller});
  final AnimationController controller;
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: controller, builder: (_, __) { final shift = controller.value * 400 - 200; return Stack(children: [ Positioned(left: shift, top: 50, child: Container(width: 300, height: 200, color: const Color(0x30FFFFFF))), Positioned(left: shift + 200, top: 120, child: Container(width: 250, height: 180, color: const Color(0x20FFFFFF))), Positioned(left: shift - 100, top: 10, child: Container(width: 350, height: 150, color: const Color(0x25FFFFFF)))]); });
}

class RainEffect extends StatelessWidget {
  const RainEffect({super.key, required this.controller});
  final AnimationController controller;
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: controller, builder: (_, __) => CustomPaint(painter: _RainPainter(progress: controller.value), size: Size.infinite));
}

class _RainPainter extends CustomPainter {
  _RainPainter({required this.progress});
  final double progress;
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x8866B2FF)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final rng = Random(42);
    for (int i = 0; i < 100; i++) {
      final x = rng.nextDouble() * size.width, speed = 150 + rng.nextDouble() * 200;
      final y0 = rng.nextDouble() * size.height, y = (y0 + speed * progress) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x, y + 12), paint);
    }
  }
  @override bool shouldRepaint(covariant _RainPainter o) => progress != o.progress;
}

class _ZonePanel extends StatelessWidget {
  const _ZonePanel({required this.title, required this.trees, required this.selectedId, required this.onTreeTap, required this.weather, required this.isGrowth, required this.game, required this.uiPlayer});
  final String title; final List<TreeModel> trees; final String? selectedId; final ValueChanged<String> onTreeTap; final WeatherType weather; final bool isGrowth; final GameEngine game; final AudioPlayer uiPlayer;
  @override Widget build(BuildContext context) => Column(children: [
    const SizedBox(height: 4),
    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isGrowth ? const Color(0xFF7CFC6E) : const Color(0xFF80D8FF))),
    Expanded(child: trees.isEmpty ? Center(child: Text('Нет деревьев', style: TextStyle(color: AppTheme.muted, fontSize: 12))) : GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.85),
      itemCount: trees.length,
      itemBuilder: (_, i) => NftTreeCard(tree: trees[i], isSelected: trees[i].id == selectedId, onTap: () { onTreeTap(trees[i].id); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }, weather: weather, game: game),
    )),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════════
// КАРТОЧКА NFT-ДЕРЕВА (стадии роста + анимация действий + количество гусениц)
// ═══════════════════════════════════════════════════════════════════════════════

class NftTreeCard extends StatefulWidget {
  const NftTreeCard({super.key, required this.tree, required this.isSelected, required this.onTap, required this.weather, required this.game});
  final TreeModel tree; final bool isSelected; final VoidCallback onTap; final WeatherType weather; final GameEngine game;

  @override State<NftTreeCard> createState() => _NftTreeCardState();
}

class _NftTreeCardState extends State<NftTreeCard> with TickerProviderStateMixin {
  late AnimationController _glowController;
  Animation<double>? _glowAnimation;
  late AnimationController _actionAnimCtrl;
  ActionType? _currentActionType;

  @override void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    if (widget.tree.stats.glowIntensity > 0) {
      _glowAnimation = Tween(begin: 0.0, end: widget.tree.stats.glowIntensity).animate(_glowController);
      _glowController.repeat(reverse: true);
    } else {
      _glowAnimation = null;
    }

    _actionAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _actionAnimCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _actionAnimCtrl.reverse();
      }
      if (status == AnimationStatus.dismissed) {
        _currentActionType = null;
        if (mounted) setState(() {});
      }
    });

    widget.game.actionEvent.addListener(_onActionEvent);
  }

  void _onActionEvent() {
    final event = widget.game.actionEvent.value;
    if (event != null && event.treeId == widget.tree.id) {
      _currentActionType = event.type;
      _actionAnimCtrl.forward(from: 0.0);
      if (mounted) setState(() {});
    }
  }

  @override void dispose() {
    _glowController.dispose();
    _actionAnimCtrl.dispose();
    widget.game.actionEvent.removeListener(_onActionEvent);
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final tree = widget.tree;
    final accent = tree.stats.color;
    final growth = tree.status == TreeStatus.growth, rest = tree.status == TreeStatus.rest, dead = tree.status == TreeStatus.dead;
    final noWater = tree.currentWater <= 0 && growth;
    final rarityGlow = tree.stats.glowIntensity > 0;

    Border? border;
    List<BoxShadow> shadows = [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 12, offset: const Offset(0, 6))];
    if (growth && !noWater) {
      final c = widget.isSelected ? Colors.white : accent;
      border = Border.all(color: c, width: widget.isSelected ? 3 : 2.5);
      shadows = [...AppTheme.neonGlow(accent, blur: widget.isSelected ? 22 : 14), ...shadows];
    } else if (rest) border = Border.all(color: accent.withOpacity(0.35), width: 1.5);
    else border = Border.all(color: AppTheme.muted.withOpacity(0.4), width: 1.5);

    Widget nftImage;
    if (noWater) {
      nftImage = Container(color: const Color(0xFF0D120D), child: const Center(child: Text('💀', style: TextStyle(fontSize: 48))));
    } else {
      nftImage = Image.network(tree.imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
        loadingBuilder: (_, child, p) => p == null ? child : Container(color: const Color(0xFF0D120D), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: accent, value: p.expectedTotalBytes != null ? p.cumulativeBytesLoaded / p.expectedTotalBytes! : null))),
        errorBuilder: (_, _, _) => Container(color: const Color(0xFF0D120D), child: Center(child: Text(tree.stats.emoji, style: const TextStyle(fontSize: 48)))));
    }
    if (rest) nftImage = Opacity(opacity: 0.6, child: nftImage);
    else if (dead) nftImage = ColorFiltered(colorFilter: const ColorFilter.matrix(<double>[0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0,0,0,1,0]), child: nftImage);

    final stageEmoji = tree.growthStageEmoji;

    Widget? actionOverlay;
    if (_currentActionType != null) {
      final String iconEmoji = switch (_currentActionType!) {
        ActionType.water => '💧',
        ActionType.fertilize => '🧪',
        ActionType.bird => '🐦',
      };
      actionOverlay = AnimatedBuilder(
        animation: _actionAnimCtrl,
        builder: (context, child) {
          final scale = 1.0 + _actionAnimCtrl.value * 0.5;
          final opacity = 1.0 - _actionAnimCtrl.value;
          return Positioned(
            top: 10,
            right: 10,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Text(iconEmoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
          );
        },
      );
    }

    // Гусеницы отображаются как иконки и красное количество в центре
    List<Widget> catWidgets = [];
    if (tree.caterpillars > 0) {
      final rng = Random(tree.id.hashCode);
      for (int i = 0; i < min(tree.caterpillars, 15); i++) {
        final angle = 2 * pi * i / tree.caterpillars + (rng.nextDouble() - 0.5) * 0.5;
        final radius = 30.0 + rng.nextDouble() * 10;
        catWidgets.add(Positioned(
          left: 50 + cos(angle) * radius - 10,
          top: 50 + sin(angle) * radius - 10,
          child: Transform.rotate(
            angle: rng.nextDouble() * 2 * pi,
            child: const Text('🐛', style: TextStyle(fontSize: 16)),
          ),
        ));
      }
    }

    Widget? caterpillarCountText;
    if (tree.caterpillars > 0) {
      caterpillarCountText = Center(
        child: Text(
          '🐛 ${tree.caterpillars}',
          style: const TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
        ),
      );
    }

    Widget card = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedScale(scale: widget.isSelected ? 1.03 : 1.0, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: border,
            boxShadow: shadows,
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Stack(fit: StackFit.expand, children: [
            nftImage,
            // Стадия роста
            if (growth && !noWater && stageEmoji.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Text(stageEmoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
            // Градиент внизу
            Positioned(left: 0, right: 0, bottom: 0, height: 70, child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.75)])))),
            // Название
            Positioned(left: 10, bottom: 36, right: 10, child: Text(tree.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, shadows: [Shadow(blurRadius: 6, color: Colors.black)]))),
            // Значок отдыха/смерти
            if (rest) Positioned(top: 8, right: 8, child: _StatusBadge(emoji: '❄️', glow: const Color(0xFF80D8FF))),
            if (dead) Positioned(top: 8, right: 8, child: _StatusBadge(emoji: '🍂', glow: AppTheme.muted)),
            // День сезона
            if (growth && !noWater) Positioned(top: 8, left: 40, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: accent.withOpacity(0.25), border: Border.all(color: accent.withOpacity(0.7)), boxShadow: AppTheme.neonGlow(accent, blur: 8)), child: Text('Д${tree.seasonDay}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent)))),
            // Влажность
            Positioned(left: 0, right: 0, bottom: 22, child: _MiniProgressBar(progress: tree.waterPercent, color: const Color(0xFF00E5FF))),
            // Сбор воды
            if (tree.currentContainer != null)
              Positioned(left: 0, right: 0, bottom: 14, child: _MiniProgressBar(progress: (tree.waterCollectionProgress % 1.0), color: const Color(0xFF42A5F5), label: '💧')),
            // Птицеферма
            if (tree.currentNest != null)
              Positioned(left: 0, right: 0, bottom: 6, child: _MiniProgressBar(progress: (tree.birdGrowthProgress % 1.0), color: const Color(0xFFFFCA28), label: '🐦')),
            // Гусеницы (иконки)
            ...catWidgets,
            // Количество гусениц красным текстом в центре
            if (caterpillarCountText != null) caterpillarCountText,
            // Анимация действия
            if (actionOverlay != null) actionOverlay,
            // Выделение
            if (widget.isSelected) Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.25), width: 2)))),
          ])),
        ),
      ),
    );

    if (rarityGlow && !dead && _glowAnimation != null) {
      return AnimatedBuilder(
        animation: _glowAnimation!,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: accent.withOpacity(0.5 + _glowAnimation!.value * 0.4), blurRadius: 16, spreadRadius: 2),
                BoxShadow(color: accent.withOpacity(0.3), blurRadius: 24),
              ],
            ),
            child: card,
          );
        },
      );
    }

    return card;
  }
}

class _MiniProgressBar extends StatelessWidget {
  final double progress; final Color color; final String? label;
  const _MiniProgressBar({required this.progress, required this.color, this.label});
  @override Widget build(BuildContext context) => Row(children: [
    if (label != null) Padding(padding: const EdgeInsets.only(left: 4), child: Text(label!, style: const TextStyle(fontSize: 10))),
    Expanded(child: Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 4), child: FractionallySizedBox(widthFactor: progress.clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: color))))),
  ]);
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon, required this.label, required this.color, this.critical = false});
  final IconData icon; final String label; final Color color; final bool critical;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black.withOpacity(0.35), border: Border.all(color: critical ? const Color(0xFFFF1744) : color.withOpacity(0.5))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 5), Flexible(child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)))]));
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.emoji, required this.glow});
  final String emoji; final Color glow;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.5), boxShadow: AppTheme.neonGlow(glow, blur: 10)), child: Text(emoji, style: const TextStyle(fontSize: 18)));
}

// ═══════════════════════════════════════════════════════════════════════════════
// ПАНЕЛЬ ДЕЙСТВИЙ (с звуком)
// ═══════════════════════════════════════════════════════════════════════════════

class ActionPanel extends StatelessWidget {
  const ActionPanel({super.key, required this.tree, required this.game, required this.onAction, required this.onClose, required this.uiPlayer});
  final TreeModel tree; final GameEngine game; final void Function(String action) onAction; final VoidCallback onClose; final AudioPlayer uiPlayer;

  String _priceLabel(String careCode) {
    final resourceKey = GameEngine._resourceActionMap[careCode];
    if (resourceKey != null && (game.inventory[resourceKey] ?? 0) > 0) return 'Из запаса';
    return switch (careCode) {
      'water_bucket' => '200 WLNT', 'water_barrel' => '490 WLNT', 'water_tank' => '780 WLNT',
      'auto_water_basic' => '2100 WLNT', 'auto_water_cistern' => '5000 WLNT',
      'fertilize_normal' => '1000 WLNT', 'fertilize_super' => '3000 WLNT',
      'woodpecker_1' => '200 WLNT', 'woodpecker_5' => '950 WLNT', 'woodpecker_10' => '1900 WLNT', 'woodpecker_all' => '5000 WLNT',
      'set_bucket' => '500 WLNT', 'set_barrel' => '1500 WLNT', 'set_tank' => '4000 WLNT',
      'set_nest_son' => '500 WLNT', 'set_nest_father' => '1500 WLNT', 'set_nest_grandfather' => '4000 WLNT', 'set_nest_elder' => '10000 WLNT',
      _ => ''
    };
  }

  @override Widget build(BuildContext context) {
    final stats = tree.stats;
    final isGrowth = tree.status == TreeStatus.growth;
    final isRest = tree.status == TreeStatus.rest;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic, width: 240,
      decoration: BoxDecoration(
        color: AppTheme.panel.withOpacity(0.95),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
        border: Border.all(color: stats.color.withOpacity(0.6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.7), blurRadius: 20, offset: const Offset(-4, 0)), ...AppTheme.neonGlow(stats.color, blur: 12)],
      ),
      child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(tree.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.text), overflow: TextOverflow.ellipsis)),
          IconButton(icon: const Icon(Icons.close, size: 20, color: AppTheme.muted), onPressed: () { onClose(); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ]),
        const SizedBox(height: 12),
        if (isGrowth) ...[
          _SectionHeader('💧 ПОЛИВ'), const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SmallCareButton('Ведро\n+20%', _priceLabel('water_bucket'), 'water_bucket', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
            _SmallCareButton('Бочка\n+50%', _priceLabel('water_barrel'), 'water_barrel', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
            _SmallCareButton('Бак\n+80%', _priceLabel('water_tank'), 'water_tank', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
          ]),
          const SizedBox(height: 12), _SectionHeader('🔄 АВТОПОЛИВ'), const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SmallCareButton('Базовый\n7д +20%', _priceLabel('auto_water_basic'), 'auto_water_basic', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
            _SmallCareButton('Цистерна\n7д +50%', _priceLabel('auto_water_cistern'), 'auto_water_cistern', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
          ]),
          const SizedBox(height: 12), _SectionHeader('🌿 УДОБРЕНИЯ'), const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SmallCareButton('Обычное\n-1 день', _priceLabel('fertilize_normal'), 'fertilize_normal', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
            _SmallCareButton('Супер\n-3 дня', _priceLabel('fertilize_super'), 'fertilize_super', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
          ]),
          const SizedBox(height: 12), _SectionHeader('🐦 ЗАЩИТА'), const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SmallCareButton('Сын\n-1', _priceLabel('woodpecker_1'), 'woodpecker_1', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
            _SmallCareButton('Отец\n-5', _priceLabel('woodpecker_5'), 'woodpecker_5', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
            _SmallCareButton('Дед\n-10', _priceLabel('woodpecker_10'), 'woodpecker_10', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
            _SmallCareButton('Старейшина\nвсе', _priceLabel('woodpecker_all'), 'woodpecker_all', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
          ]),
        ],
        if (isRest) ...[
          _SectionHeader('💧 СБОР ВОДЫ'), const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SmallCareButton('Ведро', _priceLabel('set_bucket'), 'set_bucket', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
            _SmallCareButton('Бочка', _priceLabel('set_barrel'), 'set_barrel', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
            _SmallCareButton('Бак', _priceLabel('set_tank'), 'set_tank', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
          ]),
          if (tree.currentContainer != null) ...[
            const SizedBox(height: 4),
            _ProgressIndicatorRow(label: 'Прогресс:', progress: tree.waterCollectionProgress, color: const Color(0xFF42A5F5)),
            Text('${(tree.waterCollectionProgress % 1 * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
          ],
          const SizedBox(height: 12), _SectionHeader('🐦 ПТИЦЕФЕРМА'), const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SmallCareButton('Сын', _priceLabel('set_nest_son'), 'set_nest_son', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
            _SmallCareButton('Отец', _priceLabel('set_nest_father'), 'set_nest_father', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
            _SmallCareButton('Дед', _priceLabel('set_nest_grandfather'), 'set_nest_grandfather', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
            _SmallCareButton('Старейшина', _priceLabel('set_nest_elder'), 'set_nest_elder', (a) { onAction(a); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }),
          ]),
          if (tree.currentNest != null) ...[
            const SizedBox(height: 4),
            _ProgressIndicatorRow(label: 'Прогресс:', progress: tree.birdGrowthProgress, color: const Color(0xFFFFCA28)),
            Text('${(tree.birdGrowthProgress % 1 * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
          ],
        ],
        const SizedBox(height: 12),
        Text('Баланс: ${_fmt(game.wlntBalance)} WLNT', style: const TextStyle(fontSize: 11, color: AppTheme.gold, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
      ])),
    );
  }

  String _fmt(double v) { final s = v.toStringAsFixed(0), b = StringBuffer(); for (int i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) b.write(' '); b.write(s[i]); } return b.toString(); }
}

class _ProgressIndicatorRow extends StatelessWidget {
  final String label; final double progress; final Color color;
  const _ProgressIndicatorRow({required this.label, required this.progress, required this.color});
  @override Widget build(BuildContext context) => Row(children: [
    Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.muted)), const SizedBox(width: 6),
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: (progress % 1.0).clamp(0.0, 1.0), backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 4))),
  ]);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.text));
}

class _SmallCareButton extends StatelessWidget {
  final String label, price, careCode;
  final void Function(String) onAction;
  const _SmallCareButton(this.label, this.price, this.careCode, this.onAction);

  @override Widget build(BuildContext context) {
    final btn = SizedBox(width: 70, child: Material(color: Colors.transparent, child: InkWell(
      onTap: () => onAction(careCode),
      borderRadius: BorderRadius.circular(12),
      child: Ink(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: price == 'Из запаса' ? const Color(0xFF1B5E20) : const Color(0xFF1A2A1A), border: Border.all(color: const Color(0xFF7CFC6E).withOpacity(0.5))), child: Column(children: [
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.text)),
        const SizedBox(height: 2), Text(price, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: AppTheme.gold)),
      ])),
    )));
    final tooltip = switch (careCode) {
      'water_bucket' => 'Полить ведром (+20% влажности)', 'water_barrel' => 'Полить бочкой (+50%)', 'water_tank' => 'Полить баком (+80%)',
      'auto_water_basic' => 'Автополив на 7 дней (+20%/день)', 'auto_water_cistern' => 'Автополив на 7 дней (+50%/день)',
      'fertilize_normal' => 'Обычное удобрение: -1 день роста', 'fertilize_super' => 'Суперудобрение: -3 дня роста',
      'woodpecker_1' => 'Сын-дятел: убрать 1 гусеницу', 'woodpecker_5' => 'Отец-дятел: убрать 5 гусениц', 'woodpecker_10' => 'Дед-дятел: убрать 10 гусениц', 'woodpecker_all' => 'Старейшина: убрать всех гусениц',
      'set_bucket' => 'Поставить ведро для сбора воды', 'set_barrel' => 'Поставить бочку для сбора воды', 'set_tank' => 'Поставить бак для сбора воды',
      'set_nest_son' => 'Гнездо сына: 1 птица', 'set_nest_father' => 'Гнездо отца: 5 птиц', 'set_nest_grandfather' => 'Гнездо деда: 10 птиц', 'set_nest_elder' => 'Гнездо старейшины: 20 птиц',
      _ => ''
    };
    return Tooltip(message: tooltip, child: btn);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// КНОПКА ПРОПУСКА ДНЯ
// ═══════════════════════════════════════════════════════════════════════════════

class _SkipDayButton extends StatelessWidget {
  const _SkipDayButton({required this.onPressed}); final VoidCallback onPressed;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Material(color: Colors.transparent, child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(20),
      child: Ink(height: 52, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00C853), Color(0xFF1B5E20)]),
        boxShadow: [BoxShadow(color: const Color(0xFF00E676).withOpacity(0.55), blurRadius: 20, offset: const Offset(0, 4)), BoxShadow(color: const Color(0xFF00C853).withOpacity(0.3), blurRadius: 32)]),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.fast_forward_rounded, color: Colors.white, size: 28), SizedBox(width: 10), Text('ПРОПУСТИТЬ ДЕНЬ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white))])))));
}

// ═══════════════════════════════════════════════════════════════════════════════
// МАГАЗИН
// ═══════════════════════════════════════════════════════════════════════════════

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key, required this.game, required this.userEmail, required this.onBuyTree, required this.onCancelTreeSell, required this.onBuyResource, required this.onCancelResourceSell, required this.onSellResource, required this.uiPlayer});
  final GameEngine game; final String userEmail; final ValueChanged<String> onBuyTree, onCancelTreeSell, onBuyResource, onCancelResourceSell; final void Function(String resourceType, int quantity, double pricePerUnit) onSellResource; final AudioPlayer uiPlayer;

  @override Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Text('🏪 МАГАЗИН', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onBackground, shadows: [Shadow(blurRadius: 12, color: AppTheme.gold.withOpacity(0.5))]))),
      TabBar(labelColor: AppTheme.gold, unselectedLabelColor: AppTheme.muted, indicatorColor: AppTheme.gold, onTap: (_) => uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))), tabs: const [Tab(text: 'Деревья'), Tab(text: 'Ресурсы')]),
      Expanded(child: TabBarView(children: [
        _TreeMarketTab(game: game, userEmail: userEmail, onBuyTree: onBuyTree, onCancelTreeSell: onCancelTreeSell, uiPlayer: uiPlayer),
        _ResourceMarketTab(game: game, userEmail: userEmail, onBuyResource: onBuyResource, onCancelResourceSell: onCancelResourceSell, onSellResource: onSellResource, uiPlayer: uiPlayer),
      ])),
    ])));
  }
}

class _TreeMarketTab extends StatelessWidget {
  const _TreeMarketTab({required this.game, required this.userEmail, required this.onBuyTree, required this.onCancelTreeSell, required this.uiPlayer});
  final GameEngine game; final String userEmail; final ValueChanged<String> onBuyTree, onCancelTreeSell; final AudioPlayer uiPlayer;

  @override Widget build(BuildContext context) {
    final marketTrees = game.trees.where((t) => t.forSale && t.owner != userEmail).toList();
    return marketTrees.isEmpty ? Center(child: Text('Нет лотов', style: TextStyle(color: AppTheme.muted))) : ListView.builder(padding: const EdgeInsets.all(20), itemCount: marketTrees.length, itemBuilder: (_, i) {
      final tree = marketTrees[i];
      return Card(color: AppTheme.panel, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), margin: const EdgeInsets.only(bottom: 10),
        child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(tree.imageUrl, width: 60, height: 60, fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tree.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.text), overflow: TextOverflow.ellipsis),
            Text(tree.rarity.label, style: TextStyle(color: tree.stats.color)),
            Text('Цена: ${tree.price.toStringAsFixed(0)} WLNT', style: const TextStyle(color: AppTheme.gold)),
          ])),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)), onPressed: () { onBuyTree(tree.id); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }, child: const Text('Купить')),
        ])),
      );
    });
  }
}

class _ResourceMarketTab extends StatelessWidget {
  const _ResourceMarketTab({required this.game, required this.userEmail, required this.onBuyResource, required this.onCancelResourceSell, required this.onSellResource, required this.uiPlayer});
  final GameEngine game; final String userEmail; final ValueChanged<String> onBuyResource, onCancelResourceSell; final void Function(String resourceType, int quantity, double pricePerUnit) onSellResource; final AudioPlayer uiPlayer;

  String _resourceName(String type) => switch (type) { 'water_unit' => '💧 Вода', 'fertilizer_unit' => '🌿 Удобрение', 'bird_unit' => '🐦 Птица', _ => type };

  @override Widget build(BuildContext context) {
    final lots = game.resourceLots;
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (lots.isEmpty) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text('Нет лотов ресурсов', style: TextStyle(color: AppTheme.muted))) else
        ...lots.map((lot) => Card(color: AppTheme.panel, margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Text(_resourceName(lot.resourceType), style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700)), const Spacer(),
          Text('${lot.quantity} шт. x ${lot.pricePerUnit.toStringAsFixed(0)} WLNT', style: const TextStyle(color: AppTheme.gold)),
          if (lot.sellerEmail == userEmail) TextButton(onPressed: () { onCancelResourceSell(lot.id); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }, child: const Text('Снять', style: TextStyle(color: Colors.red)))
          else ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)), onPressed: () { onBuyResource(lot.id); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }, child: const Text('Купить')),
        ])))),
      const SizedBox(height: 16), Text('Выставить свой лот:', style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700)), const SizedBox(height: 8),
      _SellResourceForm(onSell: onSellResource, inventory: game.inventory, uiPlayer: uiPlayer),
    ]));
  }
}

class _SellResourceForm extends StatefulWidget {
  const _SellResourceForm({required this.onSell, required this.inventory, required this.uiPlayer});
  final void Function(String resourceType, int quantity, double pricePerUnit) onSell; final Map<String, int> inventory; final AudioPlayer uiPlayer;
  @override State<_SellResourceForm> createState() => _SellResourceFormState();
}

class _SellResourceFormState extends State<_SellResourceForm> {
  String _type = 'water_unit';
  final _qtyCtrl = TextEditingController(text: '1'), _priceCtrl = TextEditingController(text: '100');

  @override Widget build(BuildContext context) {
    return Column(children: [
      DropdownButton<String>(value: _type, items: const [DropdownMenuItem(value: 'water_unit', child: Text('💧 Вода')), DropdownMenuItem(value: 'fertilizer_unit', child: Text('🌿 Удобрение')), DropdownMenuItem(value: 'bird_unit', child: Text('🐦 Птица'))], onChanged: (v) => setState(() => _type = v!)),
      Row(children: [
        Expanded(child: TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Кол-во'))),
        const SizedBox(width: 12),
        Expanded(child: TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Цена за шт.'))),
      ]),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: () { final qty = int.tryParse(_qtyCtrl.text); final price = double.tryParse(_priceCtrl.text); if (qty != null && price != null && qty > 0 && price > 0) { widget.onSell(_type, qty, price); widget.uiPlayer.stop().then((_) => widget.uiPlayer.play(AssetSource('sounds/click.mp3'))); } }, child: const Text('Выставить')),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// УДАЧА
// ═══════════════════════════════════════════════════════════════════════════════

class LuckyScreen extends StatefulWidget {
  const LuckyScreen({super.key, required this.game, required this.onBurned, required this.uiPlayer});
  final GameEngine game; final ValueChanged<String> onBurned; final AudioPlayer uiPlayer;
  @override State<LuckyScreen> createState() => _LuckyScreenState();
}

class _LuckyScreenState extends State<LuckyScreen> {
  String _result = '';
  static const bet = 100.0;
  static const outcomes = [
    _Outcome(prob: 0.45, reward: 0, label: 'Пусто'), _Outcome(prob: 0.25, reward: 60, label: '60 WLNT'), _Outcome(prob: 0.15, reward: 150, label: '150 WLNT'),
    _Outcome(prob: 0.10, reward: 250, label: '250 WLNT'), _Outcome(prob: 0.03, reward: 500, label: '500 WLNT'),
    _Outcome(prob: 0.01, reward: 1000, label: '1000 WLNT'), _Outcome(prob: 0.01, reward: 750, label: '750 WLNT'),
  ];

  void _spin() {
    if (widget.game.wlntBalance < bet) { setState(() => _result = 'Недостаточно средств'); return; }
    widget.game.wlntBalance -= bet;
    final rnd = Random().nextDouble();
    double cumulative = 0;
    for (final o in outcomes) {
      cumulative += o.prob;
      if (rnd <= cumulative) { widget.game.wlntBalance += o.reward; setState(() => _result = 'Вы выиграли: ${o.label}'); return; }
    }
    setState(() => _result = 'Вы проиграли');
    widget.uiPlayer.stop().then((_) => widget.uiPlayer.play(AssetSource('sounds/click.mp3')));
  }

  void _burnDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppTheme.panel, title: const Text('Сжечь NFT', style: TextStyle(color: AppTheme.text)),
      content: SizedBox(width: double.maxFinite, child: ListView.builder(shrinkWrap: true, itemCount: widget.game.trees.length, itemBuilder: (_, i) {
        final tree = widget.game.trees[i];
        return ListTile(leading: Image.network(tree.imageUrl, width: 40, height: 40, fit: BoxFit.cover), title: Text(tree.name, style: const TextStyle(color: AppTheme.text)), subtitle: Text(tree.rarity.label, style: const TextStyle(color: AppTheme.muted)), onTap: () { Navigator.pop(ctx); widget.onBurned(tree.id); setState(() => _result = 'NFT ${tree.name} сожжён. Получено 2000 WLNT и удобрения.'); widget.uiPlayer.stop().then((_) => widget.uiPlayer.play(AssetSource('sounds/click.mp3'))); });
      })),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена'))],
    ));
  }

  @override Widget build(BuildContext context) => SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text('🍀 УДАЧА', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.text, shadows: [Shadow(blurRadius: 12, color: AppTheme.gold.withOpacity(0.5))])),
    const SizedBox(height: 16), Text('Баланс: ${_fmt(widget.game.wlntBalance)} WLNT', style: const TextStyle(color: AppTheme.gold, fontSize: 16)),
    const SizedBox(height: 16), const Text('Ставка: 100 WLNT', style: TextStyle(color: AppTheme.text)), const SizedBox(height: 8),
    const Text('Вероятности:', style: TextStyle(color: AppTheme.muted)),
    ...outcomes.map((o) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(o.label, style: const TextStyle(color: AppTheme.text)), Text('${(o.prob*100).toStringAsFixed(0)}%', style: const TextStyle(color: AppTheme.muted))]))),
    const SizedBox(height: 16),
    ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _spin, icon: const Icon(Icons.casino, color: Colors.black), label: const Text('КРУТИТЬ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black))),
    const SizedBox(height: 16), Text(_result, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.text)),
    const SizedBox(height: 32), const Divider(color: AppTheme.panelBorder), const SizedBox(height: 16),
    const Text('Инвентарь:', style: TextStyle(color: AppTheme.muted)),
    _Res('💧 Вода', widget.game.inventory['water_unit'] ?? 0), _Res('🌿 Удобрения', widget.game.inventory['fertilizer_unit'] ?? 0), _Res('🐦 Птицы', widget.game.inventory['bird_unit'] ?? 0),
    const SizedBox(height: 24),
    OutlinedButton.icon(style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _burnDialog, icon: const Icon(Icons.local_fire_department, color: Colors.red), label: const Text('Сжечь NFT', style: TextStyle(color: Colors.red))),
  ])));

  Widget _Res(String label, int count) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: AppTheme.text)), Text('$count', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700))]));
  String _fmt(double v) { final s = v.toStringAsFixed(0), b = StringBuffer(); for (int i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) b.write(' '); b.write(s[i]); } return b.toString(); }
}

class _Outcome { final double prob, reward; final String label; const _Outcome({required this.prob, required this.reward, required this.label}); }

// ═══════════════════════════════════════════════════════════════════════════════
// КОЛЛЕКЦИЯ + РЕСУРСЫ + РЕЙТИНГ (с исправленным порядком условий)
// ═══════════════════════════════════════════════════════════════════════════════

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key, required this.game, required this.userEmail, required this.onSelectTree, required this.onPlant, required this.onSell, required this.onCancelSell, required this.leaderboard, required this.onHarvest, required this.uiPlayer});
  final GameEngine game; final String userEmail; final ValueChanged<String> onSelectTree, onPlant, onCancelSell; final void Function(String treeId, double price) onSell; final List<LeaderboardEntry> leaderboard; final ValueChanged<String> onHarvest; final AudioPlayer uiPlayer;

  @override Widget build(BuildContext context) {
    return DefaultTabController(length: 3, child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Text('ВАША КОЛЛЕКЦИЯ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onBackground, shadows: [Shadow(blurRadius: 12, color: AppTheme.gold.withOpacity(0.5))]))),
      TabBar(labelColor: AppTheme.gold, unselectedLabelColor: AppTheme.muted, indicatorColor: AppTheme.gold, onTap: (_) => uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))), tabs: const [Tab(text: 'Деревья'), Tab(text: 'Ресурсы'), Tab(text: 'Рейтинг')]),
      Expanded(child: TabBarView(children: [
        _CollectionTreeTab(game: game, userEmail: userEmail, onSelectTree: onSelectTree, onPlant: onPlant, onSell: onSell, onCancelSell: onCancelSell, onHarvest: onHarvest, uiPlayer: uiPlayer),
        _ResourcesTab(game: game),
        LeaderboardScreen(leaderboard: leaderboard),
      ])),
    ])));
  }
}

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab({required this.game}); final GameEngine game;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    ResourceRow('💧 Вода', game.inventory['water_unit'] ?? 0),
    ResourceRow('🌿 Удобрения', game.inventory['fertilizer_unit'] ?? 0),
    ResourceRow('🐦 Птицы', game.inventory['bird_unit'] ?? 0),
  ]);
}

class _CollectionTreeTab extends StatelessWidget {
  const _CollectionTreeTab({required this.game, required this.userEmail, required this.onSelectTree, required this.onPlant, required this.onSell, required this.onCancelSell, required this.onHarvest, required this.uiPlayer});
  final GameEngine game; final String userEmail; final ValueChanged<String> onSelectTree, onPlant, onCancelSell, onHarvest; final void Function(String treeId, double price) onSell; final AudioPlayer uiPlayer;

  void _showDetails(BuildContext context, TreeModel tree) {
    final bool isOwner = tree.owner == userEmail || tree.owner.isEmpty;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (ctx) => Container(
      height: MediaQuery.of(ctx).size.height * 0.7,
      decoration: const BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), border: Border(top: BorderSide(color: AppTheme.panelBorder, width: 1.5))),
      child: Column(children: [
        const SizedBox(height: 12), Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.muted, borderRadius: BorderRadius.circular(2))), const SizedBox(height: 12),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(tree.imageUrl, width: 200, height: 200, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(width: 200, height: 200, color: const Color(0xFF0D120D), child: Center(child: Text(tree.stats.emoji, style: const TextStyle(fontSize: 64)))))),
          const SizedBox(height: 16), Text(tree.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.text), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(tree.stats.emoji, style: const TextStyle(fontSize: 20)), const SizedBox(width: 8), Text(tree.rarity.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tree.stats.color))]),
          const SizedBox(height: 4), Text('Эмоция: ${tree.emotion} (бонус +${(tree.emotionBonus*100).toStringAsFixed(0)}%)', style: const TextStyle(color: AppTheme.muted)),
          const SizedBox(height: 20),
          _DetailRow('Статус', tree.status.label), _DetailRow('Перерождения', '${tree.rebirthsLeft} / ${tree.maxRebirths}'),
          if (tree.status == TreeStatus.growth || tree.status == TreeStatus.rest) ...[
            _DetailRow('Оставшееся время', tree.timeLeftFormatted),
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Влажность', style: TextStyle(color: AppTheme.muted, fontSize: 14)), const SizedBox(width: 8),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(height: 8, child: LinearProgressIndicator(value: tree.waterPercent, backgroundColor: const Color(0xFF0A0C10), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)))))),
              const SizedBox(width: 8), Text('${tree.currentWater.round()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.text)),
            ])),
            if (tree.status == TreeStatus.growth) _DetailRow('Гусеницы', '${tree.caterpillars}'),
          ],
          if (tree.autoWaterDays > 0) _DetailRow('Автополив', '${tree.autoWaterDays} дн. (${tree.autoWaterAmount}%/день)'),
          if (tree.forSale) _DetailRow('Продаётся', 'Да (${tree.price.toStringAsFixed(0)} WLNT)'),
          const SizedBox(height: 24),
          // Исправленный порядок условий
          if (tree.forSale && isOwner)
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { onCancelSell(tree.id); Navigator.pop(ctx); _safePlay('sounds/click.mp3'); }, icon: const Icon(Icons.cancel), label: const Text('Снять с продажи'))
          else if (!tree.isPlanted && isOwner)
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)), onPressed: () { onPlant(tree.id); Navigator.pop(ctx); _safePlay('sounds/click.mp3'); }, icon: const Icon(Icons.eco, color: Colors.white), label: const Text('Посадить', style: TextStyle(color: Colors.white))),
              OutlinedButton.icon(style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)), onPressed: () { Navigator.pop(ctx); _showSellDialog(context, tree); }, icon: const Icon(Icons.sell, color: Colors.red), label: const Text('Продать', style: TextStyle(color: Colors.red))),
            ])
          else if (tree.canHarvest && isOwner)
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)), onPressed: () { onHarvest(tree.id); Navigator.pop(ctx); _safePlay('sounds/click.mp3'); }, icon: const Icon(Icons.agriculture), label: const Text('Собрать урожай', style: TextStyle(color: Colors.white)))
          else if (tree.isPlanted && tree.status == TreeStatus.growth && isOwner)
            Text('Нельзя продать во время роста', style: TextStyle(color: AppTheme.muted))
          else if (tree.isPlanted && tree.status == TreeStatus.rest && isOwner)
            Text('Дерево в отдыхе', style: TextStyle(color: AppTheme.muted))   // <-- убрана фраза про продажу
        ]))),
      ]),
    ));
  }

  void _showSellDialog(BuildContext context, TreeModel tree) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.panel, title: const Text('Цена продажи', style: TextStyle(color: AppTheme.text)),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.text), decoration: const InputDecoration(hintText: 'WLNT')),
      actions: [ TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')), ElevatedButton(onPressed: () { final p = double.tryParse(ctrl.text); if (p != null && p > 0) { Navigator.pop(ctx); onSell(tree.id, p); _safePlay('sounds/click.mp3'); } }, child: const Text('Продать')) ],
    ));
  }

  void _safePlay(String asset) {
    try { uiPlayer.stop().then((_) => uiPlayer.play(AssetSource(asset))); } catch (_) {}
  }

  @override Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: game.trees.length, itemBuilder: (_, i) {
        final tree = game.trees[i];
        return _CollectionCard(tree: tree, onTap: () { _showDetails(context, tree); _safePlay('sounds/click.mp3'); });
      })),
    ]);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value); final String label, value;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 14)), Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.text), textAlign: TextAlign.right))]));
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.tree, this.onTap}); final TreeModel tree; final VoidCallback? onTap;
  @override Widget build(BuildContext context) {
    final progress = tree.status == TreeStatus.growth ? (tree.seasonDay / GameEngine.seasonLength).clamp(0.0, 1.0) : (tree.status == TreeStatus.rest ? tree.seasonDay / GameEngine.seasonLength : 0.0);
    final statusColor = tree.status == TreeStatus.growth ? const Color(0xFF7CFC6E) : (tree.status == TreeStatus.rest ? const Color(0xFF80D8FF) : AppTheme.muted);
    return Card(margin: const EdgeInsets.only(bottom: 10), color: AppTheme.panel, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: tree.stats.color.withOpacity(0.4))), elevation: 0,
      child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(tree.imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(width: 70, height: 70, color: const Color(0xFF0D120D), child: Center(child: Text(tree.stats.emoji, style: const TextStyle(fontSize: 30)))))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [ Expanded(child: Text(tree.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.text), overflow: TextOverflow.ellipsis)), if (tree.forSale) const Icon(Icons.sell, size: 16, color: Colors.red) ]),
          const SizedBox(height: 4),
          Row(children: [
            Flexible(child: Text(tree.stats.emoji, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 4),
            Flexible(child: Text(tree.rarity.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tree.stats.color), overflow: TextOverflow.ellipsis)),
            const Spacer(),
            Icon(tree.status == TreeStatus.growth ? Icons.eco : (tree.status == TreeStatus.rest ? Icons.ac_unit : Icons.close), size: 16, color: statusColor),
            const SizedBox(width: 4),
            Flexible(child: Text(tree.status.label, style: TextStyle(fontSize: 11, color: statusColor), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(height: 8, child: Stack(children: [
            Container(color: const Color(0xFF0A0C10)),
            FractionallySizedBox(widthFactor: progress, child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [tree.stats.color.withOpacity(0.5), tree.stats.color])))),
          ]))),
          const SizedBox(height: 4),
          Text('День: ${tree.seasonDay}/${GameEngine.seasonLength}  |  Перерождений: ${tree.rebirthsLeft}/${tree.maxRebirths}', style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
        ])),
      ]))),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// КОШЕЛЁК
// ═══════════════════════════════════════════════════════════════════════════════

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key, required this.solBalance, required this.wlntBalance, required this.userEmail, required this.myReferralCode, required this.themeMode, required this.onToggleTheme, required this.onLogout, required this.onDepositSol, required this.onWithdrawSol, required this.onDepositWlnt, required this.onWithdrawWlnt, required this.uiPlayer});
  final double solBalance, wlntBalance; final String userEmail, myReferralCode; final ThemeMode themeMode; final VoidCallback onToggleTheme, onLogout; final ValueChanged<double> onDepositSol, onWithdrawSol, onDepositWlnt, onWithdrawWlnt; final AudioPlayer uiPlayer;

  Future<void> _amountDialog(BuildContext context, String title, String label, ValueChanged<double> onConfirm) async {
    final ctrl = TextEditingController(); final formKey = GlobalKey<FormState>();
    final result = await showDialog<double>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.panel, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(color: AppTheme.text)),
      content: Form(key: formKey, child: TextFormField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.text), decoration: InputDecoration(hintText: label, hintStyle: const TextStyle(color: AppTheme.muted), filled: true, fillColor: AppTheme.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null || double.parse(v) <= 0 ? 'Некорректная сумма' : null)),
      actions: [ TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена', style: TextStyle(color: AppTheme.muted))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(ctx, double.parse(ctrl.text)); }, child: const Text('Подтвердить')) ],
    ));
    if (result != null) onConfirm(result);
  }

  @override Widget build(BuildContext context) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Text('КОШЕЛЁК', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onBackground, shadows: [Shadow(blurRadius: 12, color: AppTheme.gold.withOpacity(0.5))]))),
      IconButton(icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode, color: AppTheme.gold), onPressed: () { onToggleTheme(); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }, tooltip: 'Переключить тему'),
      IconButton(icon: const Icon(Icons.logout, color: AppTheme.muted), onPressed: () { onLogout(); uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); }, tooltip: 'Выйти'),
    ]),
    const SizedBox(height: 8), Text(userEmail, style: const TextStyle(color: AppTheme.muted, fontSize: 14)),
    const SizedBox(height: 4), Text('Мой код: $myReferralCode', style: const TextStyle(color: AppTheme.gold, fontSize: 14)),
    const SizedBox(height: 24),
    _BalanceCard(icon: Icons.currency_bitcoin, label: 'Solana (SOL)', balance: solBalance.toStringAsFixed(4), color: const Color(0xFF9945FF)),
    const SizedBox(height: 16),
    Row(children: [
      Expanded(child: _ActionChip(label: 'Пополнить', icon: Icons.add_circle_outline, onTap: () { uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); _amountDialog(context, 'Пополнить SOL', 'Сумма SOL', onDepositSol); })),
      const SizedBox(width: 12),
      Expanded(child: _ActionChip(label: 'Вывести', icon: Icons.arrow_circle_up_outlined, onTap: () { uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); _amountDialog(context, 'Вывести SOL', 'Сумма SOL', (a) { if (a <= solBalance) onWithdrawSol(a); else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Недостаточно средств'))); }); })),
    ]),
    const SizedBox(height: 32),
    _BalanceCard(icon: Icons.eco, label: 'Walnut Token (WLNT)', balance: _fmt(wlntBalance), color: AppTheme.gold),
    const SizedBox(height: 16),
    Row(children: [
      Expanded(child: _ActionChip(label: 'Пополнить', icon: Icons.add_circle_outline, onTap: () { uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); _amountDialog(context, 'Пополнить WLNT', 'Сумма WLNT', onDepositWlnt); })),
      const SizedBox(width: 12),
      Expanded(child: _ActionChip(label: 'Вывести', icon: Icons.arrow_circle_up_outlined, onTap: () { uiPlayer.stop().then((_) => uiPlayer.play(AssetSource('sounds/click.mp3'))); _amountDialog(context, 'Вывести WLNT', 'Сумма WLNT', (a) { if (a <= wlntBalance) onWithdrawWlnt(a); else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Недостаточно средств'))); }); })),
    ]),
  ]))));

  String _fmt(double v) { final s = v.toStringAsFixed(2), parts = s.split('.'), intPart = parts[0], frac = parts.length > 1 ? '.${parts[1]}' : ''; final b = StringBuffer(); for (int i = 0; i < intPart.length; i++) { if (i > 0 && (intPart.length - i) % 3 == 0) b.write(' '); b.write(intPart[i]); } return '$b$frac'; }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.icon, required this.label, required this.balance, required this.color});
  final IconData icon; final String label, balance; final Color color;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(children: [ Icon(icon, size: 36, color: color), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.muted)), const SizedBox(height: 6), Text(balance, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)) ])) ]));
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon, required this.onTap});
  final String label; final IconData icon; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Ink(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppTheme.panel, border: Border.all(color: AppTheme.panelBorder)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: AppTheme.text), const SizedBox(width: 8), Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.text)))]))));
}

class ResourceRow extends StatelessWidget {
  final String label; final int count;
  const ResourceRow(this.label, this.count, {super.key});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Text(label, style: const TextStyle(color: AppTheme.text)), const Spacer(), Text(count.toString(), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700))]));
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key, required this.leaderboard});
  final List<LeaderboardEntry> leaderboard;

  @override Widget build(BuildContext context) {
    final sorted = List<LeaderboardEntry>.from(leaderboard)..sort((a, b) => b.wlntBalance.compareTo(a.wlntBalance));
    return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: sorted.length, itemBuilder: (_, i) {
      final entry = sorted[i];
      return Card(
        color: entry.isPlayer ? const Color(0xFF1B3D1F) : AppTheme.panel,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: entry.isPlayer ? AppTheme.gold : Colors.transparent, width: entry.isPlayer ? 2 : 0)),
        child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Text('${i + 1}.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: i == 0 ? AppTheme.gold : i == 1 ? Colors.grey.shade400 : i == 2 ? Colors.brown.shade300 : AppTheme.text)),
          const SizedBox(width: 12),
          Expanded(child: Text(entry.name, style: TextStyle(fontWeight: entry.isPlayer ? FontWeight.bold : FontWeight.normal, color: entry.isPlayer ? AppTheme.gold : AppTheme.text))),
          Text('${entry.wlntBalance.toStringAsFixed(0)} WLNT', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
        ])),
      );
    });
  }
}