import 'package:flutter/material.dart';

const seasonLength = 30;

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

enum TreeStatus { growth, rest, dead }

extension TreeStatusX on TreeStatus {
  String get label => switch (this) {
    TreeStatus.growth => 'Рост',
    TreeStatus.rest => 'Отдых',
    TreeStatus.dead => 'Мёртво',
  };
}

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

  final String id;
  final String imageUrl;
  final String name;
  final TreeRarity rarity;
  final int maxRebirths;
  final int rebirthsLeft;
  final double currentWater;
  final int seasonDay;
  final int caterpillars;
  final TreeStatus status;
  final bool isPlanted;
  final String emotion;
  final String owner;
  final bool forSale;
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
  double get waterConsumptionRate => stats.waterConsumption * (status == TreeStatus.growth ? 1.0 : 0.0);
  double get waterPercent => (currentWater / 100.0).clamp(0.0, 1.0);

  int get hoursLeft {
    if (status == TreeStatus.growth) {
      final targetDay = seasonLength;
      final daysRemaining = targetDay - seasonDay;
      return daysRemaining * 24;
    } else if (status == TreeStatus.rest) {
      return (seasonLength - seasonDay) * 24;
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

  bool get canHarvest => status == TreeStatus.growth && seasonDay >= seasonLength && currentWater >= 100.0 && caterpillars == 0;

  TreeModel copyWith({
    int? rebirthsLeft,
    double? currentWater,
    int? seasonDay,
    int? caterpillars,
    TreeStatus? status,
    bool? isPlanted,
    String? emotion,
    String? owner,
    bool? forSale,
    double? price,
    int? plantedAtGameDay,
    int? autoWaterDays,
    double? autoWaterAmount,
    String? currentContainer,
    double? waterCollectionProgress,
    String? currentNest,
    double? birdGrowthProgress,
  }) {
    return TreeModel(
      id: id,
      imageUrl: imageUrl,
      name: name,
      rarity: rarity,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'name': name,
        'rarity': rarity.name,
        'maxRebirths': maxRebirths,
        'rebirthsLeft': rebirthsLeft,
        'currentWater': currentWater,
        'seasonDay': seasonDay,
        'caterpillars': caterpillars,
        'status': status.name,
        'isPlanted': isPlanted,
        'emotion': emotion,
        'owner': owner,
        'forSale': forSale,
        'price': price,
        'plantedAtGameDay': plantedAtGameDay,
        'autoWaterDays': autoWaterDays,
        'autoWaterAmount': autoWaterAmount,
        'currentContainer': currentContainer,
        'waterCollectionProgress': waterCollectionProgress,
        'currentNest': currentNest,
        'birdGrowthProgress': birdGrowthProgress,
      };

  factory TreeModel.fromJson(Map<String, dynamic> json) => TreeModel(
        id: json['id'] as String,
        imageUrl: json['imageUrl'] as String,
        name: json['name'] as String,
        rarity: TreeRarity.values.byName(json['rarity'] as String),
        maxRebirths: json['maxRebirths'] as int,
        rebirthsLeft: json['rebirthsLeft'] as int,
        currentWater: (json['currentWater'] as num).toDouble(),
        seasonDay: json['seasonDay'] as int,
        caterpillars: json['caterpillars'] as int,
        status: TreeStatus.values.byName(json['status'] as String),
        isPlanted: json['isPlanted'] as bool,
        emotion: json['emotion'] as String,
        owner: json['owner'] as String,
        forSale: json['forSale'] as bool,
        price: (json['price'] as num).toDouble(),
        plantedAtGameDay: json['plantedAtGameDay'] as int,
        autoWaterDays: json['autoWaterDays'] as int,
        autoWaterAmount: (json['autoWaterAmount'] as num).toDouble(),
        currentContainer: json['currentContainer'] as String?,
        waterCollectionProgress: (json['waterCollectionProgress'] as num).toDouble(),
        currentNest: json['currentNest'] as String?,
        birdGrowthProgress: (json['birdGrowthProgress'] as num).toDouble(),
      );
}

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'sellerEmail': sellerEmail,
        'resourceType': resourceType,
        'quantity': quantity,
        'pricePerUnit': pricePerUnit,
      };

  factory ResourceLot.fromJson(Map<String, dynamic> json) => ResourceLot(
        id: json['id'] as String,
        sellerEmail: json['sellerEmail'] as String,
        resourceType: json['resourceType'] as String,
        quantity: json['quantity'] as int,
        pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
      );
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'wlntBalance': wlntBalance,
        'isPlayer': isPlayer,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        name: json['name'] as String,
        wlntBalance: (json['wlntBalance'] as num).toDouble(),
        isPlayer: json['isPlayer'] as bool,
      );
}

class DailyChallenge {
  final String id;
  final String description;
  final int target;
  final int reward;
  int current;
  bool completed;
  bool claimed;

  DailyChallenge({
    required this.id,
    required this.description,
    required this.target,
    required this.reward,
    this.current = 0,
    this.completed = false,
    this.claimed = false,
  });

  double get progress => target == 0 ? 1.0 : (current / target).clamp(0.0, 1.0);

  DailyChallenge copyWith({
    int? current,
    bool? completed,
    bool? claimed,
  }) {
    return DailyChallenge(
      id: id,
      description: description,
      target: target,
      reward: reward,
      current: current ?? this.current,
      completed: completed ?? this.completed,
      claimed: claimed ?? this.claimed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'target': target,
        'reward': reward,
        'current': current,
        'completed': completed,
        'claimed': claimed,
      };

  factory DailyChallenge.fromJson(Map<String, dynamic> json) => DailyChallenge(
        id: json['id'] as String,
        description: json['description'] as String,
        target: json['target'] as int,
        reward: json['reward'] as int,
        current: json['current'] as int,
        completed: json['completed'] as bool,
        claimed: json['claimed'] as bool,
      );
}

enum ActionType { water, fertilize, bird }

class ActionEvent {
  final String treeId;
  final ActionType type;

  const ActionEvent({required this.treeId, required this.type});
}

class Outcome {
  final double prob;
  final int reward;
  final String label;

  const Outcome({required this.prob, required this.reward, required this.label});
}
