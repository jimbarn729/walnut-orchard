import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../engine/game_engine.dart';

class PersistenceService {
  static const _gameKey = 'walnut_game_state';
  static const _themeKey = 'walnut_theme_mode';
  static const _userEmailKey = 'walnut_user_email';
  static const _referralKey = 'walnut_referral_code';
  static const _dailyRewardKey = 'walnut_daily_reward_ts';

  Future<void> saveGame(GameEngine engine) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gameKey, jsonEncode(engine.toJson()));
  }

  Future<GameEngine?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_gameKey);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return GameEngine.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode);
  }

  Future<String?> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey);
  }

  Future<void> saveDailyRewardTimestamp(int timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyRewardKey, timestamp);
  }

  Future<int?> loadDailyRewardTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyRewardKey);
  }

  Future<void> saveUser(String email, String referralCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_referralKey, referralCode);
  }

  Future<Map<String, String>> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_userEmailKey) ?? '',
      'referralCode': prefs.getString(_referralKey) ?? '',
    };
  }
}
