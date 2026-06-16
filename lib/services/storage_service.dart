import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _themeModeKey = 'theme_mode';
  static const _loggedUserKey = 'logged_user';

  final SharedPreferences _preferences;

  StorageService(this._preferences);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  String? get savedUserEmail => _preferences.getString(_loggedUserKey);
  String? get savedTheme => _preferences.getString(_themeModeKey);

  Future<void> saveUserEmail(String email) async {
    await _preferences.setString(_loggedUserKey, email);
  }

  Future<void> saveThemeMode(String theme) async {
    await _preferences.setString(_themeModeKey, theme);
  }
}
