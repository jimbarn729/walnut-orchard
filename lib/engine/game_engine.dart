import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_models.dart';

const resourceActionMap = <String, String>{
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

class GameEngine {
  static const solToWlntRate = 1000.0;

  GameEngine({
    required this.gameDay,
    required this.wlntBalance,
    required this.solBalance,
    required this.trees,
    required this.currentWeather,
    Map<String, int>? inventory,
    List<ResourceLot>? resourceLots,
    List<LeaderboardEntry>? leaderboard,
    List<DailyChallenge>? dailyChallenges,
  })  : inventory = inventory ?? {'water_unit': 0, 'fertilizer_unit': 0, 'bird_unit': 0},
        resourceLots = resourceLots ?? [],
        leaderboard = leaderboard ?? [],
        dailyChallenges = dailyChallenges ?? [];


  static const seasonLength = 30;
  int gameDay;
  double wlntBalance;
  double solBalance;
  List<TreeModel> trees;
  WeatherType currentWeather;
  Map<String, int> inventory;
  List<ResourceLot> resourceLots;
  List<LeaderboardEntry> leaderboard;
  List<DailyChallenge> dailyChallenges;
  DateTime? lastRealtimeTick;

  final List<void Function(String)> _incomeListeners = [];
  void addIncomeListener(void Function(String) listener) => _incomeListeners.add(listener);
  void removeIncomeListener(void Function(String) listener) => _incomeListeners.remove(listener);

  void _notifyIncome(String message) {
    final listeners = List<void Function(String)>.from(_incomeListeners);
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
    if (lastRealtimeTick == null) {
      lastRealtimeTick = now;
      return;
    }
    final diffMinutes = now.difference(lastRealtimeTick!).inMinutes;
    if (diffMinutes > 0) {
      lastRealtimeTick = now;
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
    'bucket': 1.0,
    'barrel': 2.0,
    'tank': 4.0,
  };
  static const nestBirdCount = <String, int>{
    'son': 1,
    'father': 5,
    'grandfather': 10,
    'elder': 20,
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
        while (wProg >= 1.0) {
          addedWaters++;
          wProg -= 1.0;
        }
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
          seasonDay: 1,
          rebirthsLeft: left,
          status: TreeStatus.growth,
          isPlanted: false,
          currentWater: 100.0,
          plantedAtGameDay: gameDay,
          waterCollectionProgress: wProg,
          birdGrowthProgress: bProg,
        );
      } else {
        return tree.copyWith(
          seasonDay: 1,
          rebirthsLeft: 0,
          status: TreeStatus.dead,
          isPlanted: false,
          plantedAtGameDay: gameDay,
          waterCollectionProgress: wProg,
          birdGrowthProgress: bProg,
        );
      }
    }
    return tree.copyWith(
      seasonDay: day,
      rebirthsLeft: left,
      waterCollectionProgress: wProg,
      birdGrowthProgress: bProg,
    );
  }

  TreeModel _advanceTree(TreeModel tree) {
    if (tree.status == TreeStatus.dead || !tree.isPlanted) return tree;
    return switch (tree.status) {
      TreeStatus.growth => _advanceGrowth(tree, currentWeather),
      TreeStatus.rest => _advanceRest(tree),
      TreeStatus.dead => tree,
    };
  }

  void nextDay() {
    gameDay++;
    currentWeather = weatherForCycleDay(gameDay);
    _applyAutoWater();
    trees = trees.map(_advanceTree).toList();
    dailyChallenges = dailyChallenges.map((challenge) => challenge.copyWith(current: 0, completed: false, claimed: false)).toList();
    final playerEntry = leaderboard.firstWhere((e) => e.isPlayer, orElse: () => LeaderboardEntry(name: '', wlntBalance: 0.0));
    if (playerEntry.name.isNotEmpty) {
      playerEntry.wlntBalance = wlntBalance;
    }
    if (gameDay % 30 == 0) {
      _rewardTopPlayers();
    }
  }

  bool applyCare(String treeId, String careCode) {
    final idx = trees.indexWhere((t) => t.id == treeId);
    if (idx == -1) return false;
    final tree = trees[idx];
    if (!tree.isPlanted) return false;

    final resourceKey = resourceActionMap[careCode];
    double price = 0;
    bool resourceUsed = false;

    if (resourceKey != null && (inventory[resourceKey] ?? 0) > 0) {
      resourceUsed = true;
    } else {
      switch (careCode) {
        case 'water_bucket':
          price = 200;
          break;
        case 'water_barrel':
          price = 490;
          break;
        case 'water_tank':
          price = 780;
          break;
        case 'auto_water_basic':
          price = 2100;
          break;
        case 'auto_water_cistern':
          price = 5000;
          break;
        case 'fertilize_normal':
          price = 1000;
          break;
        case 'fertilize_super':
          price = 3000;
          break;
        case 'woodpecker_1':
          price = 200;
          break;
        case 'woodpecker_5':
          price = 950;
          break;
        case 'woodpecker_10':
          price = 1900;
          break;
        case 'woodpecker_all':
          price = 5000;
          break;
        case 'set_bucket':
          price = 500;
          break;
        case 'set_barrel':
          price = 1500;
          break;
        case 'set_tank':
          price = 4000;
          break;
        case 'set_nest_son':
          price = 500;
          break;
        case 'set_nest_father':
          price = 1500;
          break;
        case 'set_nest_grandfather':
          price = 4000;
          break;
        case 'set_nest_elder':
          price = 10000;
          break;
        default:
          break;
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
        default:
          return false;
      }
    }

    if (success) {
      if (resourceUsed) {
        final key = resourceKey!;
        inventory[key] = (inventory[key] ?? 0) - 1;
      } else if (price > 0) {
        wlntBalance -= price;
      }
      final playerEntry = leaderboard.firstWhere((e) => e.isPlayer, orElse: () => LeaderboardEntry(name: '', wlntBalance: 0.0));
      if (playerEntry.name.isNotEmpty) {
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
    _incrementChallenge('harvest', 1);
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
    // Prevent planting a tree that is currently listed for sale
    if (trees[i].forSale) return false;
    trees[i] = trees[i].copyWith(
      isPlanted: true,
      status: TreeStatus.growth,
      currentWater: 100.0,
      seasonDay: 1,
      caterpillars: 0,
      plantedAtGameDay: gameDay,
    );
    return true;
  }

  bool sellTree(String id, double price) {
    final i = trees.indexWhere((t) => t.id == id);
    if (i == -1) return false;
    // Do not allow selling a tree that is currently planted (in growth/rest cycle).
    // New NFTs (isPlanted == false) can be listed immediately.
    if (trees[i].isPlanted) return false;
    trees[i] = trees[i].copyWith(forSale: true, price: price);
    return true;
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
      owner: buyer,
      forSale: false,
      price: 0.0,
      isPlanted: true,
      status: TreeStatus.growth,
      currentWater: 100.0,
      seasonDay: 1,
      caterpillars: 0,
      plantedAtGameDay: gameDay,
    );
  }

  void burnTree(String id) {
    final i = trees.indexWhere((t) => t.id == id);
    if (i == -1) return;
    final tree = trees[i];
    wlntBalance += 2000;
    final fertByRarity = <TreeRarity, int>{
      TreeRarity.common: 1,
      TreeRarity.uncommon: 3,
      TreeRarity.rare: 6,
      TreeRarity.epic: 9,
      TreeRarity.legendary: 12,
      TreeRarity.mysterious: 15,
    };
    final amount = fertByRarity[tree.rarity] ?? 0;
    inventory['fertilizer_unit'] = (inventory['fertilizer_unit'] ?? 0) + amount;
    trees.removeAt(i);
  }

  bool convertSolToWlnt(double amount) {
    if (amount <= 0 || solBalance < amount) return false;
    solBalance -= amount;
    wlntBalance += amount * solToWlntRate;
    return true;
  }

  bool convertWlntToSol(double amount) {
    if (amount <= 0 || wlntBalance < amount) return false;
    wlntBalance -= amount;
    solBalance += amount / solToWlntRate;
    return true;
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
    _incrementChallenge('trade', 1);
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

  void _incrementChallenge(String id, int amount) {
    final idx = dailyChallenges.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final challenge = dailyChallenges[idx];
    if (challenge.completed) return;
    final nextValue = (challenge.current + amount).clamp(0, challenge.target);
    final completed = nextValue >= challenge.target;
    dailyChallenges[idx] = challenge.copyWith(current: nextValue, completed: completed);
  }

  bool claimChallenge(String id) {
    final idx = dailyChallenges.indexWhere((c) => c.id == id);
    if (idx == -1) return false;
    final challenge = dailyChallenges[idx];
    if (!challenge.completed || challenge.claimed) return false;
    wlntBalance += challenge.reward;
    dailyChallenges[idx] = challenge.copyWith(claimed: true);
    final playerEntry = leaderboard.firstWhere((e) => e.isPlayer, orElse: () => LeaderboardEntry(name: '', wlntBalance: 0.0));
    if (playerEntry.name.isNotEmpty) {
      playerEntry.wlntBalance = wlntBalance;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        'gameDay': gameDay,
        'wlntBalance': wlntBalance,
        'solBalance': solBalance,
        'currentWeather': currentWeather.name,
        'inventory': inventory,
        'trees': trees.map((t) => t.toJson()).toList(),
        'resourceLots': resourceLots.map((r) => r.toJson()).toList(),
        'leaderboard': leaderboard.map((l) => l.toJson()).toList(),
        'dailyChallenges': dailyChallenges.map((c) => c.toJson()).toList(),
      };

  factory GameEngine.fromJson(Map<String, dynamic> json) => GameEngine(
        gameDay: json['gameDay'] as int,
        wlntBalance: (json['wlntBalance'] as num).toDouble(),
        solBalance: (json['solBalance'] as num?)?.toDouble() ?? 2.5,
        currentWeather: WeatherType.values.byName(json['currentWeather'] as String),
        inventory: Map<String, int>.from(json['inventory'] as Map),
        trees: (json['trees'] as List).map((item) => TreeModel.fromJson(Map<String, dynamic>.from(item as Map))).toList(),
        resourceLots: (json['resourceLots'] as List).map((item) => ResourceLot.fromJson(Map<String, dynamic>.from(item as Map))).toList(),
        leaderboard: (json['leaderboard'] as List).map((item) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(item as Map))).toList(),
        dailyChallenges: json['dailyChallenges'] != null
          ? (json['dailyChallenges'] as List).map((item) => DailyChallenge.fromJson(Map<String, dynamic>.from(item as Map))).toList()
          : null,
      );

  static List<TreeModel> initialTrees() => [
        TreeModel(
          id: '0',
          imageUrl: 'https://gateway.irys.xyz/9tZ8WoKgNzFzGkvfHYsAjuTyHXKX3FGzLPJNxj2uJ1um',
          name: '#0',
          rarity: TreeRarity.mysterious,
          maxRebirths: 100,
          rebirthsLeft: 100,
          currentWater: 100,
          seasonDay: 0,
          caterpillars: 0,
          status: TreeStatus.growth,
          isPlanted: false,
          emotion: 'Without emotion',
          plantedAtGameDay: 1,
        ),
        TreeModel(
          id: '1',
          imageUrl: 'https://gateway.irys.xyz/Dp69bAFua6UaGxg9ZVC8ne9EjpLrw4cM2MdmU2sx2mVD',
          name: '#1',
          rarity: TreeRarity.common,
          maxRebirths: 3,
          rebirthsLeft: 3,
          currentWater: 0,
          seasonDay: 6,
          caterpillars: 2,
          status: TreeStatus.growth,
          isPlanted: true,
          emotion: 'Surprised',
          plantedAtGameDay: 1,
        ),
        TreeModel(
          id: '3',
          imageUrl: 'https://gateway.irys.xyz/CwHyPeeUwbdf7craVzppiM8AETg1Ww7AceqX1CkmFWeu',
          name: '#3',
          rarity: TreeRarity.uncommon,
          maxRebirths: 5,
          rebirthsLeft: 5,
          currentWater: 65,
          seasonDay: 11,
          caterpillars: 0,
          status: TreeStatus.growth,
          isPlanted: true,
          emotion: 'Without emotion',
          plantedAtGameDay: 1,
        ),
        TreeModel(
          id: '6',
          imageUrl: 'https://gateway.irys.xyz/DSvtn4gMQgkB9n7ivke5uBFca3LEzaeaP98USQtb81Wv',
          name: '#6',
          rarity: TreeRarity.common,
          maxRebirths: 3,
          rebirthsLeft: 3,
          currentWater: 70,
          seasonDay: 20,
          caterpillars: 0,
          status: TreeStatus.growth,
          isPlanted: true,
          emotion: 'Indifferent',
          plantedAtGameDay: 1,
        ),
        TreeModel(
          id: '9',
          imageUrl: 'https://gateway.irys.xyz/FbNbh3F2SMX1GhPjn4TyfRKCD7n9ixLNwiNL8mnD6gBK',
          name: '#9',
          rarity: TreeRarity.common,
          maxRebirths: 3,
          rebirthsLeft: 3,
          currentWater: 80,
          seasonDay: 15,
          caterpillars: 0,
          status: TreeStatus.rest,
          isPlanted: true,
          emotion: 'Sad',
          plantedAtGameDay: 1,
        ),
        TreeModel(
          id: '13',
          imageUrl: 'https://gateway.irys.xyz/GZ9JVevPvu5fbSTKWXKMeTNmL5rC2qW3F6xWzrtu8KLN',
          name: '#13',
          rarity: TreeRarity.common,
          maxRebirths: 3,
          rebirthsLeft: 3,
          currentWater: 90,
          seasonDay: 22,
          caterpillars: 0,
          status: TreeStatus.growth,
          isPlanted: true,
          emotion: 'Happy',
          plantedAtGameDay: 1,
        ),
      ];

  static List<ResourceLot> initialResourceLots() => [
        const ResourceLot(id: 'sys_w1', sellerEmail: 'system', resourceType: 'water_unit', quantity: 5, pricePerUnit: 150),
        const ResourceLot(id: 'sys_f1', sellerEmail: 'system', resourceType: 'fertilizer_unit', quantity: 2, pricePerUnit: 800),
        const ResourceLot(id: 'sys_b1', sellerEmail: 'system', resourceType: 'bird_unit', quantity: 1, pricePerUnit: 1000),
      ];

  static List<LeaderboardEntry> initialLeaderboard(String playerEmail) {
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

  static GameEngine initial({required String playerEmail, required double initialWlnt}) => GameEngine(
        gameDay: 1,
        wlntBalance: initialWlnt,
        solBalance: 2.5,
        trees: initialTrees(),
        currentWeather: weatherForCycleDay(1),
        inventory: {'water_unit': 2, 'fertilizer_unit': 1, 'bird_unit': 0},
        resourceLots: initialResourceLots(),
        leaderboard: initialLeaderboard(playerEmail),
      );
}
