import 'dart:math';

import 'package:flutter/material.dart';

import 'engine/game_engine.dart';
import 'services/audio_service.dart';
import 'services/persistence_service.dart';

class AppState extends ChangeNotifier {
  AppState._(this.audioService, this.persistence);

  final AudioService audioService;
  final PersistenceService persistence;
  late GameEngine engine;
  bool initialized = false;
  bool logged = false;
  String userEmail = '';
  String referralCode = '';
  ThemeMode themeMode = ThemeMode.dark;

  static Future<AppState> load() async {
    final service = PersistenceService();
    final state = AppState._(AudioService(), service);
    await state._initialize();
    return state;
  }

  Future<void> _initialize() async {
    final theme = await persistence.loadThemeMode();
    if (theme != null) {
      themeMode = ThemeMode.values.firstWhere((mode) => mode.name == theme, orElse: () => ThemeMode.dark);
    }
    final userData = await persistence.loadUser();
    userEmail = userData['email'] ?? '';
    referralCode = userData['referralCode'] ?? '';

    final savedEngine = await persistence.loadGame();
    if (savedEngine != null && userEmail.isNotEmpty) {
      engine = savedEngine;
      // Normalize loaded trees: a planted tree cannot be for sale.
      for (var i = 0; i < engine.trees.length; i++) {
        final t = engine.trees[i];
        if (t.forSale && t.isPlanted) {
          engine.trees[i] = t.copyWith(forSale: false, price: 0.0);
        }
      }
      logged = true;
    } else {
      engine = GameEngine.initial(playerEmail: userEmail.isNotEmpty ? userEmail : 'player', initialWlnt: 12450.75 + (referralCode.isNotEmpty ? 1000 : 0));
      logged = false;
    }

    initialized = true;
    notifyListeners();
  }

  Future<void> saveGame() async {
    await persistence.saveGame(engine);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await persistence.saveThemeMode(mode.name);
  }

  Future<void> login(String email, String refCode) async {
    userEmail = email;
    referralCode = refCode;
    final code = refCode.trim().isNotEmpty
        ? 'WALNUT${_randomSixDigits()}'
        : 'WALNUT${email.hashCode.abs().toString().padLeft(6, '0').substring(0, 6)}';
    referralCode = code;
    logged = true;
    engine = GameEngine.initial(playerEmail: email, initialWlnt: 12450.75 + (refCode.trim().isNotEmpty ? 1000 : 0));
    await persistence.saveUser(email, code);
    await saveGame();
    notifyListeners();
  }

  Future<void> logout() async {
    logged = false;
    userEmail = '';
    referralCode = '';
    await persistence.saveUser('', '');
    notifyListeners();
  }

  Future<void> nextDay() async {
    engine.nextDay();
    await saveGame();
    notifyListeners();
  }

  Future<bool> applyCare(String treeId, String action) async {
    final ok = engine.applyCare(treeId, action);
    if (ok) {
      await saveGame();
      notifyListeners();
    }
    return ok;
  }

  Future<void> harvestTree(String id) async {
    engine.harvestTree(id);
    await saveGame();
    notifyListeners();
  }

  Future<bool> plantTree(String id) async {
    final ok = engine.plantTree(id);
    if (ok) {
      await saveGame();
      notifyListeners();
    }
    return ok;
  }

  Future<bool> sellTree(String id, double price) async {
    final ok = engine.sellTree(id, price);
    if (!ok) return false;
    await saveGame();
    notifyListeners();
    return true;
  }

  Future<void> cancelSell(String id) async {
    engine.cancelSell(id);
    await saveGame();
    notifyListeners();
  }

  Future<void> buyTree(String id) async {
    engine.buyTree(id, userEmail);
    await saveGame();
    notifyListeners();
  }

  Future<void> burnTree(String id) async {
    engine.burnTree(id);
    await saveGame();
    notifyListeners();
  }

  Future<void> depositSol(double amount) async {
    if (amount <= 0) return;
    engine.solBalance += amount;
    await saveGame();
    notifyListeners();
  }

  Future<bool> withdrawSol(double amount) async {
    if (amount <= 0 || engine.solBalance < amount) return false;
    engine.solBalance -= amount;
    await saveGame();
    notifyListeners();
    return true;
  }

  Future<bool> convertSolToWlnt(double solAmount) async {
    final ok = engine.convertSolToWlnt(solAmount);
    if (!ok) return false;
    await saveGame();
    notifyListeners();
    return true;
  }

  Future<bool> convertWlntToSol(double wlntAmount) async {
    final ok = engine.convertWlntToSol(wlntAmount);
    if (!ok) return false;
    await saveGame();
    notifyListeners();
    return true;
  }

  Future<void> sellResource(String resourceType, int quantity, double pricePerUnit) async {
    engine.sellResource(userEmail, resourceType, quantity, pricePerUnit);
    await saveGame();
    notifyListeners();
  }

  Future<void> buyResource(String lotId) async {
    engine.buyResource(lotId, userEmail);
    await saveGame();
    notifyListeners();
  }

  Future<void> cancelResourceSell(String lotId) async {
    engine.cancelResourceSell(lotId);
    await saveGame();
    notifyListeners();
  }

  Future<void> updateBalances({double? depositSol, double? withdrawSol, double? depositWlnt, double? withdrawWlnt}) async {
    if (depositSol != null) {
      engine.solBalance += depositSol;
    }
    if (withdrawSol != null) {
      engine.solBalance -= withdrawSol;
    }
    if (depositWlnt != null) {
      engine.wlntBalance += depositWlnt;
    }
    if (withdrawWlnt != null) {
      engine.wlntBalance -= withdrawWlnt;
    }
    await saveGame();
    notifyListeners();
  }

  Future<void> startRealtimeTick() async {
    engine.lastRealtimeTick = DateTime.now();
  }

  void dispose() {
    audioService.dispose();
    super.dispose();
  }

  String _randomSixDigits() => Random().nextInt(1000000).toString().padLeft(6, '0');
}
