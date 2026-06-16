import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════
// МОДЕЛИ ДАННЫХ
// ═══════════════════════════════════════════════════════════════════════════

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

enum WeatherType {
  calm,
  cloudy,
  thunderstorm,
  heatwave,
  forestFire,
  flood,
  fog;
}
extension WeatherTypeExt on WeatherType {
  IconData get icon {
    switch (this) {
      case WeatherType.calm: return Icons.wb_sunny;
      case WeatherType.cloudy: return Icons.cloud;
      case WeatherType.thunderstorm: return Icons.flash_on;
      case WeatherType.heatwave: return Icons.wb_sunny;
      case WeatherType.forestFire: return Icons.local_fire_department;
      case WeatherType.flood: return Icons.water;
      case WeatherType.fog: return Icons.foggy;
    }
  }
  String get label {
    switch (this) {
      case WeatherType.calm: return 'Ясно';
      case WeatherType.cloudy: return 'Облачно';
      case WeatherType.thunderstorm: return 'Гроза';
      case WeatherType.heatwave: return 'Жара';
      case WeatherType.forestFire: return 'Пожар';
      case WeatherType.flood: return 'Наводнение';
      case WeatherType.fog: return 'Туман';
    }
  }
  Color get accent {
    switch (this) {
      case WeatherType.calm: return Colors.amber;
      case WeatherType.cloudy: return Colors.grey;
      case WeatherType.thunderstorm: return Colors.purple;
      case WeatherType.heatwave: return Colors.orange;
      case WeatherType.forestFire: return Colors.red;
      case WeatherType.flood: return Colors.cyan;
      case WeatherType.fog: return Colors.blueGrey;
    }
  }
  bool get isCritical => this == WeatherType.forestFire || this == WeatherType.flood || this == WeatherType.heatwave;
}

class TreeStats {
  final String emoji;
  final Color color;
  final double income;
  final double glowIntensity;
  TreeStats({required this.emoji, required this.color, required this.income, required this.glowIntensity});
}

class TreeModel {
  final String id;
  final String name;
  final String imageUrl;
  final TreeRarity rarity;
  TreeStatus status;
  int seasonDay;
  double currentWater;
  double waterPercent;
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
  dynamic currentContainer;
  double waterCollectionProgress;
  dynamic currentNest;
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
    required this.waterPercent,
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
  double get progress => current / target;
  DailyChallenge({required this.id, required this.description, required this.target, required this.current, required this.completed, required this.claimed, required this.reward});
}

class LeaderboardEntry {
  final String name;
  final double wlntBalance;
  final bool isPlayer;
  LeaderboardEntry({required this.name, required this.wlntBalance, required this.isPlayer});
}

class ResourceLot {
  final String id;
  final String resourceType;
  final int quantity;
  final double pricePerUnit;
  final String sellerEmail;
  ResourceLot({required this.id, required this.resourceType, required this.quantity, required this.pricePerUnit, required this.sellerEmail});
}

// ═══════════════════════════════════════════════════════════════════════════
// СЕРВИСЫ
// ═══════════════════════════════════════════════════════════════════════════

class AudioService {
  bool _muted = false;
  bool get muted => _muted;
  void setMuted(bool v) => _muted = v;
  void playClick() {}
  void playCoins() {}
  void playWeatherChange() {}
  void playBackground(String path) {}
}

class AppTheme {
  static const Color bg = Color(0xFF0A0F0A);
  static const Color panel = Color(0xFF162016);
  static const Color panelBorder = Color(0xFF2A3A2A);
  static const Color text = Color(0xFFE0E0E0);
  static const Color muted = Color(0xFF8A9A8A);
  static const Color gold = Color(0xFFFFD740);
  static const List<Color> neutralGradient = [Color(0xFF1A2A1A), Color(0xFF0D140D)];

  static ThemeData lightTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(primary: Color(0xFF7CFC6E), surface: panel),
  );
  static ThemeData darkTheme = lightTheme;

  static List<BoxShadow> neonGlow(Color color, {double blur = 12}) {
    return [BoxShadow(color: color.withOpacity(0.4), blurRadius: blur)];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GAME ENGINE
// ═══════════════════════════════════════════════════════════════════════════

class GameEngine extends ChangeNotifier {
  double solBalance = 10.0;
  double wlntBalance = 1000.0;
  WeatherType currentWeather = WeatherType.calm;
  bool petDefenderActive = false;
  List<TreeModel> trees = [];
  Map<String, int> inventory = {'water_unit': 5, 'fertilizer_unit': 2, 'bird_unit': 1};
  List<DailyChallenge> dailyChallenges = [];
  List<LeaderboardEntry> leaderboard = [];
  List<ResourceLot> resourceLots = [];
  ValueNotifier<(String treeId, ActionType type)?> actionEvent = ValueNotifier(null);
  bool dailyRewardAvailable = true;

  final Map<String, String> resourceActionMap = {
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
    'set_bucket': 'water_unit',
    'set_barrel': 'water_unit',
    'set_tank': 'water_unit',
    'set_nest_son': 'bird_unit',
    'set_nest_father': 'bird_unit',
    'set_nest_grandfather': 'bird_unit',
    'set_nest_elder': 'bird_unit',
  };

  GameEngine() {
    _initMockTrees();
    _initMockChallenges();
    _initMockLeaderboard();
  }

  void _initMockTrees() {
    trees = [
      TreeModel(
        id: '1', name: 'Мудрый орех', imageUrl: 'https://picsum.photos/200/200?random=1',
        rarity: TreeRarity.epic, status: TreeStatus.growth, seasonDay: 3, currentWater: 80, waterPercent: 0.8,
        caterpillars: 0, rebirthsLeft: 3, maxRebirths: 5, price: 500, forSale: false, isPlanted: true,
        owner: '', emotion: '😊', emotionBonus: 0.1, timeLeftFormatted: '2 дня', canHarvest: false,
        autoWaterDays: 0, autoWaterAmount: 0, waterCollectionProgress: 0, birdGrowthProgress: 0,
        stats: TreeStats(emoji: '🌰', color: Colors.brown, income: 50, glowIntensity: 0.5),
      ),
      TreeModel(
        id: '2', name: 'Золотой желудь', imageUrl: 'https://picsum.photos/200/200?random=2',
        rarity: TreeRarity.legendary, status: TreeStatus.rest, seasonDay: 10, currentWater: 100, waterPercent: 1.0,
        caterpillars: 2, rebirthsLeft: 2, maxRebirths: 3, price: 2000, forSale: false, isPlanted: true,
        owner: '', emotion: '🤩', emotionBonus: 0.2, timeLeftFormatted: '5 дней', canHarvest: true,
        autoWaterDays: 3, autoWaterAmount: 20, waterCollectionProgress: 0.5, birdGrowthProgress: 0.3,
        stats: TreeStats(emoji: '🌟', color: Colors.amber, income: 200, glowIntensity: 0.8),
      ),
    ];
  }

  void _initMockChallenges() {
    dailyChallenges = [
      DailyChallenge(id: '1', description: 'Полить дерево 3 раза', target: 3, current: 0, completed: false, claimed: false, reward: 100),
      DailyChallenge(id: '2', description: 'Собрать урожай', target: 1, current: 0, completed: false, claimed: false, reward: 200),
    ];
  }

  void _initMockLeaderboard() {
    leaderboard = [
      LeaderboardEntry(name: 'Игрок1', wlntBalance: 5000, isPlayer: false),
      LeaderboardEntry(name: 'Игрок2', wlntBalance: 3200, isPlayer: false),
      LeaderboardEntry(name: 'Вы', wlntBalance: wlntBalance, isPlayer: true),
    ];
  }

  void tickRealtime(Duration duration) {}
  void addIncomeListener(void Function(String) listener) {}
  void removeIncomeListener(void Function(String) listener) {}
  void trackChallenge(String type) {}
  double dynamicResourcePrice(double base) => base * (0.8 + Random().nextDouble() * 0.4);
  Future<bool> applyCare(String treeId, String action) async => true;
  Future<void> buyTree(String id) async {}
  Future<void> sellTree(String id, double price) async {}
  Future<void> cancelSell(String id) async {}
  Future<void> plantTree(String id) async {}
  Future<void> harvestTree(String id) async {}
  Future<void> burnTree(String id) async {}
  Future<void> purchaseResourcePackage(String type, int qty, double price) async {
    inventory[type] = (inventory[type] ?? 0) + qty;
    wlntBalance -= price;
    notifyListeners();
  }
  Future<void> buyPetEgg() async {
    petDefenderActive = true;
    notifyListeners();
  }
  Future<void> buyResource(String lotId) async {}
  Future<void> cancelResourceSell(String lotId) async {}
  Future<void> sellResource(String type, int qty, double price) async {}
  Future<void> claimChallenge(String id) async {}
  Future<void> depositSol(double amt) async { solBalance += amt; notifyListeners(); }
  Future<void> withdrawSol(double amt) async { solBalance -= amt; notifyListeners(); }
  Future<void> convertSolToWlnt(double amt) async {
    if (solBalance >= amt) {
      solBalance -= amt;
      wlntBalance += amt * 1000;
      notifyListeners();
    }
  }
  Future<void> convertWlntToSol(double amt) async {
    if (wlntBalance >= amt) {
      wlntBalance -= amt;
      solBalance += amt / 1000;
      notifyListeners();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// APP STATE
// ═══════════════════════════════════════════════════════════════════════════

class AppState extends ChangeNotifier {
  bool initialized = true;
  bool logged = false;
  String userEmail = '';
  String referralCode = 'MYCODE123';
  ThemeMode themeMode = ThemeMode.dark;
  late GameEngine engine;
  late AudioService audioService;

  double get wlntBalance => engine.wlntBalance;
  double get solBalance => engine.solBalance;

  AppState() {
    engine = GameEngine();
    audioService = AudioService();
  }

  static Future<AppState> load() async {
    final state = AppState();
    await Future.delayed(Duration.zero);
    return state;
  }

  Future<bool> login(String email, String password) async {
    userEmail = email;
    logged = true;
    notifyListeners();
    return true;
  }

  Future<bool> register(String email, String password, String refCode) async {
    userEmail = email;
    logged = true;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    logged = false;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  void saveGame() {}
  void startRealtimeTick() {}
  Future<void> nextDay() async {}
  Future<void> updateBalances({double depositWlnt = 0, double withdrawWlnt = 0}) async {
    engine.wlntBalance += depositWlnt;
    engine.wlntBalance -= withdrawWlnt;
    engine.notifyListeners();
  }
  void setUserEmail(String email) {}
}

// ═══════════════════════════════════════════════════════════════════════════
// ЭКРАН АВТОРИЗАЦИИ
// ═══════════════════════════════════════════════════════════════════════════

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onLogin});
  final void Function(String email, String referralCode) onLogin;
  @override State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  bool _obscure = true;
  final _formKey = GlobalKey<FormState>();
  bool _isLoginMode = true;

  @override void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final refCode = _refCtrl.text.trim();

    if (_isLoginMode) {
      final success = await appState.login(email, password);
      if (success) {
        widget.onLogin(email, refCode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный email или пароль')),
        );
      }
    } else {
      final success = await appState.register(email, password, refCode);
      if (success) {
        widget.onLogin(email, refCode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка регистрации. Возможно, email уже занят или реферальный код недействителен.')),
        );
      }
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bg,
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        ShaderMask(shaderCallback: (b) => LinearGradient(colors: [const Color(0xFF7CFC6E), AppTheme.gold]).createShader(b),
          child: const Text('🌳 WALNUT FARM', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
        const SizedBox(height: 8),
        Text(_isLoginMode ? 'Войдите, чтобы начать игру' : 'Создайте новый аккаунт', style: const TextStyle(color: AppTheme.muted, fontSize: 14)),
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
        if (!_isLoginMode) const SizedBox(height: 16),
        if (!_isLoginMode)
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
            onPressed: _submit, child: Text(_isLoginMode ? 'ВОЙТИ' : 'ЗАРЕГИСТРИРОВАТЬСЯ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white)))),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_isLoginMode ? 'Нет аккаунта? ' : 'Уже есть аккаунт? ', style: const TextStyle(color: AppTheme.muted)),
          TextButton(
            onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
            child: Text(_isLoginMode ? 'Зарегистрироваться' : 'Войти'),
          ),
        ]),
        const SizedBox(height: 8),
        Text('Введите код друга и получите 1000 WLNT', style: TextStyle(color: AppTheme.muted.withOpacity(0.6), fontSize: 12), textAlign: TextAlign.center),
      ]))),
    )),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ЭКРАН САДА (FARM SCREEN) – ИСПРАВЛЕННЫЙ
// ═══════════════════════════════════════════════════════════════════════════

class FarmScreen extends StatelessWidget {
  const FarmScreen({super.key, required this.game, required this.selectedId, required this.onDaySkip, required this.onSelectTree, required this.onAction, required this.audioService});
  final GameEngine game; final String? selectedId; final VoidCallback onDaySkip; final ValueChanged<String?> onSelectTree; final bool Function(String treeId, String action) onAction; final AudioService audioService;

  TreeModel? _findSelected() => selectedId == null ? null : game.trees.cast<TreeModel?>().firstWhere((t) => t!.id == selectedId, orElse: () => null);

  @override Widget build(BuildContext context) {
    final selected = _findSelected();
    return SafeArea(child: Stack(children: [
      Column(children: [
        Expanded(flex: 3, child: VisualGarden(game: game, selectedId: selectedId, onTreeTap: (id) {
          if (selectedId == id) {
            onSelectTree(null);
          } else {
            onSelectTree(id);
          }
        }, audioService: audioService)),
        const SizedBox(height: 8),
        _SkipDayButton(onPressed: onDaySkip),
        const SizedBox(height: 8),
      ]),
      if (selected != null && selected.isPlanted)
        Positioned(right: 0, top: 80, bottom: 80, child: ActionPanel(tree: selected, game: game, onAction: (action) => onAction(selected.id, action), onClose: () => onSelectTree(null), audioService: audioService)),
    ]));
  }
}

class VisualGarden extends StatefulWidget {
  const VisualGarden({super.key, required this.game, required this.selectedId, required this.onTreeTap, required this.audioService});
  final GameEngine game; final String? selectedId; final ValueChanged<String> onTreeTap; final AudioService audioService;
  @override State<VisualGarden> createState() => _VisualGardenState();
}

class _VisualGardenState extends State<VisualGarden> with TickerProviderStateMixin {
  late AnimationController _rainCtrl, _fireCtrl, _floodCtrl, _fogCtrl, _transitionCtrl, _petCtrl;
  late Animation<double> _transitionOpacity;
  late Animation<double> _petOffset;
  WeatherType? _lastWeather;

  @override void initState() {
    super.initState();
    _rainCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _fireCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _floodCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _fogCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    
    _transitionCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _transitionOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeInOut));
    _petCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _petOffset = Tween<double>(begin: -36.0, end: 36.0).animate(CurvedAnimation(parent: _petCtrl, curve: Curves.easeInOut));
    
    _lastWeather = widget.game.currentWeather;
    _transitionCtrl.forward();
    if (widget.game.petDefenderActive) _petCtrl.repeat(reverse: true);
  }

  @override void didUpdateWidget(covariant VisualGarden oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.currentWeather != widget.game.currentWeather) {
      _transitionCtrl.forward(from: 0.0);
      widget.audioService.playBackground('sounds/${widget.game.currentWeather.name}.mp3');
      widget.audioService.playWeatherChange();
      _lastWeather = widget.game.currentWeather;
    }
    if (oldWidget.game.petDefenderActive != widget.game.petDefenderActive) {
      if (widget.game.petDefenderActive) {
        _petCtrl.repeat(reverse: true);
        widget.audioService.playClick();
      } else {
        _petCtrl.stop();
      }
    }
  }

  @override void dispose() {
    _rainCtrl.dispose();
    _fireCtrl.dispose();
    _floodCtrl.dispose();
    _fogCtrl.dispose();
    _transitionCtrl.dispose();
    _petCtrl.dispose();
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
          if (widget.game.petDefenderActive) Padding(padding: const EdgeInsets.only(right: 10), child: _GlassChip(icon: Icons.pets, label: 'Питомец охраняет', color: const Color(0xFFFFD740))),
          _GlassChip(icon: weather.icon, label: weather.label, color: weather.accent, critical: weather.isCritical),
        ])),
        Padding(padding: const EdgeInsets.only(top: 50), child: Row(children: [
          Expanded(child: _ZonePanel(title: '🌱 Рост', trees: growthTrees, selectedId: widget.selectedId, onTreeTap: widget.onTreeTap, weather: weather, isGrowth: true, game: game, audioService: widget.audioService)),
          Container(width: 2, color: AppTheme.panelBorder.withOpacity(0.4)),
          Expanded(child: _ZonePanel(title: '❄️ Отдых', trees: restTrees, selectedId: widget.selectedId, onTreeTap: widget.onTreeTap, weather: weather, isGrowth: false, game: game, audioService: widget.audioService)),
        ])),
        if (widget.game.petDefenderActive)
          Positioned(top: 100, left: 0, right: 0, child: AnimatedBuilder(
            animation: _petOffset,
            builder: (_, __) {
              final center = MediaQuery.of(context).size.width / 2;
              return IgnorePointer(
                child: Transform.translate(
                  offset: Offset(center + _petOffset.value - 24, 0),
                  child: Container(
                    alignment: Alignment.topCenter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.25), blurRadius: 12, spreadRadius: 2)],
                      ),
                      child: Padding(padding: const EdgeInsets.all(6.0), child: Icon(Icons.pets, size: 28, color: Colors.brown.shade800)),
                    ),
                  ),
                ),
              );
            },
          )),
        ..._buildWeatherEffects(weather),
        AnimatedBuilder(
          animation: _transitionOpacity,
          builder: (_, __) {
            if (_lastWeather == null || _lastWeather == weather) return const SizedBox.shrink();
            return WeatherTransitionEffect(opacity: _transitionOpacity.value, fromWeather: _lastWeather!, toWeather: weather);
          },
        ),
      ])),
    );
  }

  List<Widget> _buildWeatherEffects(WeatherType weather) {
    switch (weather) {
      case WeatherType.thunderstorm:
        return [Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: AnimatedBuilder(animation: _transitionOpacity, builder: (_, __) {
          return Opacity(opacity: _transitionOpacity.value, child: Stack(children: [
            RainEffect(controller: _rainCtrl),
            Positioned(top: 10, right: 20, child: Icon(Icons.cloud, size: 50, color: const Color(0xBBFFFFFF))),
            AnimatedBuilder(animation: _rainCtrl, builder: (_, __) {
              if (Random().nextDouble() < 0.05) return Positioned(top: 20, left: Random().nextInt(200).toDouble(), child: const Icon(Icons.flash_on, color: Colors.yellow, size: 24));
              return const SizedBox.shrink();
            }),
          ]));
        })))];
      case WeatherType.heatwave:
        return [Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: AnimatedBuilder(animation: _transitionOpacity, builder: (_, __) {
          return Opacity(opacity: _transitionOpacity.value, child: Stack(children: [
            Positioned(top: 10, right: 30, child: Icon(Icons.wb_sunny, size: 50, color: const Color(0xFFFFD740).withOpacity(0.9))),
            Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topRight, radius: 0.6, colors: [Color(0x44FF9100), Colors.transparent]))),
            CustomPaint(painter: CrackPainter(), size: Size.infinite),
          ]));
        })))];
      case WeatherType.forestFire:
        return [Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: AnimatedBuilder(animation: _transitionOpacity, builder: (_, __) {
          return Opacity(opacity: _transitionOpacity.value, child: AnimatedBuilder(animation: _fireCtrl, builder: (_, __) => CustomPaint(painter: _FirePainter(_fireCtrl.value), size: Size.infinite)));
        })))];
      case WeatherType.flood:
        return [Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: AnimatedBuilder(animation: _transitionOpacity, builder: (_, __) {
          return Opacity(opacity: _transitionOpacity.value, child: _FloodEffect(controller: _floodCtrl));
        })))];
      case WeatherType.fog:
        return [Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: AnimatedBuilder(animation: _transitionOpacity, builder: (_, __) {
          return Opacity(opacity: _transitionOpacity.value, child: _FogEffect(controller: _fogCtrl));
        })))];
      case WeatherType.calm:
        return [Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: AnimatedBuilder(animation: _transitionOpacity, builder: (_, __) {
          return Opacity(opacity: _transitionOpacity.value, child: Stack(children: [
            Positioned(top: 10, left: 20, child: Icon(Icons.cloud, size: 40, color: const Color(0xAAFFFFFF))),
            Positioned(top: 15, right: 40, child: Icon(Icons.wb_sunny, size: 35, color: const Color(0xFFFFD740).withOpacity(0.8))),
          ]));
        })))];
      case WeatherType.cloudy:
        return [Positioned(top: 50, left: 0, right: 0, bottom: 0, child: IgnorePointer(child: AnimatedBuilder(animation: _transitionOpacity, builder: (_, __) {
          return Opacity(opacity: _transitionOpacity.value, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Icon(Icons.cloud, size: 40, color: const Color(0xAAFFFFFF)),
            Icon(Icons.cloud, size: 35, color: const Color(0x99FFFFFF)),
            Icon(Icons.cloud, size: 45, color: const Color(0xAAFFFFFF)),
          ]));
        })))];
    }
  }
}

class WeatherTransitionEffect extends StatelessWidget {
  const WeatherTransitionEffect({required this.opacity, required this.fromWeather, required this.toWeather});
  final double opacity;
  final WeatherType fromWeather;
  final WeatherType toWeather;

  Color _getWeatherColor(WeatherType weather) => switch (weather) {
    WeatherType.thunderstorm => const Color(0xFF7C4DFF),
    WeatherType.heatwave => const Color(0xFFFF9100),
    WeatherType.forestFire => const Color(0xFFFF1744),
    WeatherType.flood => const Color(0xFF00E5FF),
    WeatherType.fog => const Color(0xFFB0BEC5),
    WeatherType.calm => const Color(0xFFFFD740),
    WeatherType.cloudy => const Color(0xFF90A4AE),
  };

  @override Widget build(BuildContext context) {
    final fromColor = _getWeatherColor(fromWeather);
    final toColor = _getWeatherColor(toWeather);
    final currentColor = Color.lerp(fromColor, toColor, opacity) ?? toColor;
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [currentColor.withOpacity(opacity * 0.15), Colors.transparent],
            ),
          ),
        ),
      ),
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
    final t = progress.clamp(0.0, 1.0);
    final paint = Paint()
      ..shader = LinearGradient(colors: [const Color(0xFFFF1744).withOpacity(0.8), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)
          .createShader(Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4));
    final path = Path();
    final w = size.width, h = size.height;
    for (int i = 0; i < 5; i++) {
      final x = i * w / 4;
      final sway = sin(t * 2 * pi * 2 + i) * 20;
      path.moveTo(x, h);
      path.lineTo(x + sway, h * 0.7);
      path.lineTo(x + w / 8 + sway, h * 0.6);
      path.lineTo(x + w / 4, h * 0.8);
    }
    path.lineTo(w, h);
    path.close();
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
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: controller, builder: (_, __) {
    final shift = controller.value * 400 - 200;
    return Stack(children: [
      Positioned(left: shift, top: 50, child: Container(width: 300, height: 200, color: const Color(0x30FFFFFF))),
      Positioned(left: shift + 200, top: 120, child: Container(width: 250, height: 180, color: const Color(0x20FFFFFF))),
      Positioned(left: shift - 100, top: 10, child: Container(width: 350, height: 150, color: const Color(0x25FFFFFF))),
    ]);
  });
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
      final x = rng.nextDouble() * size.width;
      final speed = 150 + rng.nextDouble() * 200;
      final y0 = rng.nextDouble() * size.height;
      final y = (y0 + speed * progress) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x, y + 12), paint);
    }
  }
  @override bool shouldRepaint(covariant _RainPainter o) => progress != o.progress;
}

class _ZonePanel extends StatelessWidget {
  const _ZonePanel({required this.title, required this.trees, required this.selectedId, required this.onTreeTap, required this.weather, required this.isGrowth, required this.game, required this.audioService});
  final String title; final List<TreeModel> trees; final String? selectedId; final ValueChanged<String> onTreeTap; final WeatherType weather; final bool isGrowth; final GameEngine game; final AudioService audioService;

  @override Widget build(BuildContext context) => Column(children: [
    const SizedBox(height: 4),
    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isGrowth ? const Color(0xFF7CFC6E) : const Color(0xFF80D8FF))),
    Expanded(
      child: trees.isEmpty
          ? Center(child: Text('Нет деревьев', style: TextStyle(color: AppTheme.muted, fontSize: 12)))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.85),
              itemCount: trees.length,
              itemBuilder: (_, i) => NftTreeCard(tree: trees[i], isSelected: trees[i].id == selectedId, onTap: () { onTreeTap(trees[i].id); audioService.playClick(); }, weather: weather, game: game),
            ),
    ),
  ]);
}

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
    }
    _actionAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _actionAnimCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _actionAnimCtrl.reverse();
      if (status == AnimationStatus.dismissed) setState(() => _currentActionType = null);
    });
    widget.game.actionEvent.addListener(_onActionEvent);
  }

  void _onActionEvent() {
    final event = widget.game.actionEvent.value;
    if (event != null && event.$1 == widget.tree.id) {
      _currentActionType = event.$2;
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
    final growth = tree.status == TreeStatus.growth;
    final rest = tree.status == TreeStatus.rest;
    final dead = tree.status == TreeStatus.dead;
    final noWater = tree.currentWater <= 0 && growth;

    Border? border;
    List<BoxShadow> shadows = [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 12, offset: const Offset(0, 6))];
    if (growth && !noWater) {
      border = Border.all(color: widget.isSelected ? Colors.white : accent, width: widget.isSelected ? 3 : 2.5);
      shadows = [...AppTheme.neonGlow(accent, blur: widget.isSelected ? 22 : 14), ...shadows];
    } else if (rest) {
      border = Border.all(color: accent.withOpacity(0.35), width: 1.5);
    } else {
      border = Border.all(color: AppTheme.muted.withOpacity(0.4), width: 1.5);
    }

    Widget nftImage;
    if (noWater) {
      nftImage = Container(color: const Color(0xFF0D120D), child: const Center(child: Text('💀', style: TextStyle(fontSize: 48))));
    } else {
      nftImage = Image.network(tree.imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
        loadingBuilder: (_, child, p) => p == null ? child : Container(color: const Color(0xFF0D120D), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: accent, value: p.expectedTotalBytes != null ? p.cumulativeBytesLoaded / p.expectedTotalBytes! : null))),
        errorBuilder: (_, _, _) => Container(color: const Color(0xFF0D120D), child: Center(child: Text(tree.stats.emoji, style: const TextStyle(fontSize: 48)))));
    }
    if (rest) nftImage = Opacity(opacity: 0.6, child: nftImage);
    if (dead) nftImage = ColorFiltered(colorFilter: const ColorFilter.matrix(<double>[0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0,0,0,1,0]), child: nftImage);

    final stageEmoji = tree.growthStageEmoji;
    Widget? actionOverlay;
    if (_currentActionType != null) {
      final iconEmoji = switch (_currentActionType!) { ActionType.water => '💧', ActionType.fertilize => '🧪', ActionType.bird => '🐦', };
      actionOverlay = AnimatedBuilder(
        animation: _actionAnimCtrl,
        builder: (context, child) {
          final scale = 1.0 + _actionAnimCtrl.value * 0.5;
          final opacity = 1.0 - _actionAnimCtrl.value;
          return Positioned(top: 10, right: 10, child: Transform.scale(scale: scale, child: Opacity(opacity: opacity, child: Text(iconEmoji, style: const TextStyle(fontSize: 32)))));
        },
      );
    }

    List<Widget> catWidgets = [];
    if (tree.caterpillars > 0) {
      final rng = Random(tree.id.hashCode);
      for (int i = 0; i < min(tree.caterpillars, 15); i++) {
        final angle = 2 * pi * i / tree.caterpillars + (rng.nextDouble() - 0.5) * 0.5;
        final radius = 30.0 + rng.nextDouble() * 10;
        catWidgets.add(Positioned(
          left: 50 + cos(angle) * radius - 10,
          top: 50 + sin(angle) * radius - 10,
          child: Transform.rotate(angle: rng.nextDouble() * 2 * pi, child: const Text('🐛', style: TextStyle(fontSize: 16))),
        ));
      }
    }

    Widget? caterpillarCountText;
    if (tree.caterpillars > 0) {
      caterpillarCountText = Center(
        child: Text('🐛 ${tree.caterpillars}', style: const TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4, color: Colors.black)])),
      );
    }

    Widget card = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedScale(scale: widget.isSelected ? 1.03 : 1.0, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: border, boxShadow: shadows),
          child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Stack(fit: StackFit.expand, children: [
            nftImage,
            if (growth && !noWater && stageEmoji.isNotEmpty)
              Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: Text(stageEmoji, style: const TextStyle(fontSize: 20)))),
            Positioned(left: 0, right: 0, bottom: 0, height: 70, child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.75)])))),
            Positioned(left: 10, bottom: 36, right: 10, child: Text(tree.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, shadows: [Shadow(blurRadius: 6, color: Colors.black)]))),
            if (rest) Positioned(top: 8, right: 8, child: _StatusBadge(emoji: '❄️', glow: const Color(0xFF80D8FF))),
            if (dead) Positioned(top: 8, right: 8, child: _StatusBadge(emoji: '🍂', glow: AppTheme.muted)),
            if (growth && !noWater) Positioned(top: 8, left: 40, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: accent.withOpacity(0.25), border: Border.all(color: accent.withOpacity(0.7)), boxShadow: AppTheme.neonGlow(accent, blur: 8)), child: Text('Д${tree.seasonDay}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent)))),
            Positioned(left: 0, right: 0, bottom: 22, child: _MiniProgressBar(progress: tree.waterPercent, color: const Color(0xFF00E5FF))),
            if (tree.currentContainer != null) Positioned(left: 0, right: 0, bottom: 14, child: _MiniProgressBar(progress: (tree.waterCollectionProgress % 1.0), color: const Color(0xFF42A5F5), label: '💧')),
            if (tree.currentNest != null) Positioned(left: 0, right: 0, bottom: 6, child: _MiniProgressBar(progress: (tree.birdGrowthProgress % 1.0), color: const Color(0xFFFFCA28), label: '🐦')),
            ...catWidgets,
            if (caterpillarCountText != null) caterpillarCountText,
            if (actionOverlay != null) actionOverlay,
            if (widget.isSelected) Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.25), width: 2)))),
          ])),
        ),
      ),
    );

    if (tree.stats.glowIntensity > 0 && !dead && _glowAnimation != null) {
      return AnimatedBuilder(
        animation: _glowAnimation!,
        builder: (context, _) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.5 + _glowAnimation!.value * 0.4), blurRadius: 16, spreadRadius: 2),
              BoxShadow(color: accent.withOpacity(0.3), blurRadius: 24),
            ],
          ),
          child: card,
        ),
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
    Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ),
    ),
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

// -------------------- ПАНЕЛЬ ДЕЙСТВИЙ --------------------
class ActionPanel extends StatelessWidget {
  const ActionPanel({super.key, required this.tree, required this.game, required this.onAction, required this.onClose, required this.audioService});
  final TreeModel tree; final GameEngine game; final void Function(String action) onAction; final VoidCallback onClose; final AudioService audioService;

  String _priceLabel(String careCode) {
    final resourceKey = game.resourceActionMap[careCode];
    if (resourceKey != null) {
      final count = game.inventory[resourceKey] ?? 0;
      if (count > 0) return 'Из запаса ($count)';
    }
    return switch (careCode) {
      'water_bucket' => '50 WLNT',
      'water_barrel' => '120 WLNT',
      'water_tank' => '200 WLNT',
      'auto_water_basic' => '500 WLNT',
      'auto_water_cistern' => '1200 WLNT',
      'fertilize_normal' => '300 WLNT',
      'fertilize_super' => '800 WLNT',
      'woodpecker_1' => '50 WLNT',
      'woodpecker_5' => '200 WLNT',
      'woodpecker_10' => '400 WLNT',
      'woodpecker_all' => '1000 WLNT',
      'set_bucket' => '100 WLNT',
      'set_barrel' => '300 WLNT',
      'set_tank' => '800 WLNT',
      'set_nest_son' => '100 WLNT',
      'set_nest_father' => '300 WLNT',
      'set_nest_grandfather' => '800 WLNT',
      'set_nest_elder' => '2000 WLNT',
      _ => ''
    };
  }

  bool _isActionEnabled(String careCode) {
    final resourceKey = game.resourceActionMap[careCode];
    if (resourceKey != null) return (game.inventory[resourceKey] ?? 0) > 0;
    final price = switch (careCode) {
      'water_bucket' => 50,
      'water_barrel' => 120,
      'water_tank' => 200,
      'auto_water_basic' => 500,
      'auto_water_cistern' => 1200,
      'fertilize_normal' => 300,
      'fertilize_super' => 800,
      'woodpecker_1' => 50,
      'woodpecker_5' => 200,
      'woodpecker_10' => 400,
      'woodpecker_all' => 1000,
      'set_bucket' => 100,
      'set_barrel' => 300,
      'set_tank' => 800,
      'set_nest_son' => 100,
      'set_nest_father' => 300,
      'set_nest_grandfather' => 800,
      'set_nest_elder' => 2000,
      _ => double.infinity,
    };
    return price == 0 || game.wlntBalance >= price;
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
          IconButton(icon: const Icon(Icons.close, size: 20, color: AppTheme.muted), onPressed: () { onClose(); audioService.playClick(); }, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ]),
        const SizedBox(height: 12),
        if (isGrowth) ...[
          _SectionHeader('💧 ПОЛИВ'), const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SmallCareButton('Ведро\n+20%', _priceLabel('water_bucket'), 'water_bucket', onAction, enabled: _isActionEnabled('water_bucket')),
            _SmallCareButton('Бочка\n+50%', _priceLabel('water_barrel'), 'water_barrel', onAction, enabled: _isActionEnabled('water_barrel')),
            _SmallCareButton('Бак\n+80%', _priceLabel('water_tank'), 'water_tank', onAction, enabled: _isActionEnabled('water_tank')),
          ]),
          const SizedBox(height: 12), _SectionHeader('🔄 АВТОПОЛИВ'), const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SmallCareButton('Базовый\n7д +20%', _priceLabel('auto_water_basic'), 'auto_water_basic', onAction, enabled: _isActionEnabled('auto_water_basic')),
            _SmallCareButton('Цистерна\n7д +50%', _priceLabel('auto_water_cistern'), 'auto_water_cistern', onAction, enabled: _isActionEnabled('auto_water_cistern')),
          ]),
          const SizedBox(height: 12), _SectionHeader('🌿 УДОБРЕНИЯ'), const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SmallCareButton('Обычное\n-1 день', _priceLabel('fertilize_normal'), 'fertilize_normal', onAction, enabled: _isActionEnabled('fertilize_normal')),
            _SmallCareButton('Супер\n-3 дня', _priceLabel('fertilize_super'), 'fertilize_super', onAction, enabled: _isActionEnabled('fertilize_super')),
          ]),
          const SizedBox(height: 12), _SectionHeader('🐦 ЗАЩИТА'), const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SmallCareButton('Сын\n-1', _priceLabel('woodpecker_1'), 'woodpecker_1', onAction, enabled: _isActionEnabled('woodpecker_1')),
            _SmallCareButton('Отец\n-5', _priceLabel('woodpecker_5'), 'woodpecker_5', onAction, enabled: _isActionEnabled('woodpecker_5')),
            _SmallCareButton('Дед\n-10', _priceLabel('woodpecker_10'), 'woodpecker_10', onAction, enabled: _isActionEnabled('woodpecker_10')),
            _SmallCareButton('Старейшина\nвсе', _priceLabel('woodpecker_all'), 'woodpecker_all', onAction, enabled: _isActionEnabled('woodpecker_all')),
          ]),
        ],
        if (isRest) ...[
          _SectionHeader('💧 СБОР ВОДЫ'), const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SmallCareButton('Ведро', _priceLabel('set_bucket'), 'set_bucket', onAction, enabled: _isActionEnabled('set_bucket')),
            _SmallCareButton('Бочка', _priceLabel('set_barrel'), 'set_barrel', onAction, enabled: _isActionEnabled('set_barrel')),
            _SmallCareButton('Бак', _priceLabel('set_tank'), 'set_tank', onAction, enabled: _isActionEnabled('set_tank')),
          ]),
          if (tree.currentContainer != null) ...[
            const SizedBox(height: 4),
            _ProgressIndicatorRow(label: 'Прогресс:', progress: tree.waterCollectionProgress, color: const Color(0xFF42A5F5)),
            Text('${(tree.waterCollectionProgress % 1 * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
          ],
          const SizedBox(height: 12), _SectionHeader('🐦 ПТИЦЕФЕРМА'), const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SmallCareButton('Сын', _priceLabel('set_nest_son'), 'set_nest_son', onAction, enabled: _isActionEnabled('set_nest_son')),
            _SmallCareButton('Отец', _priceLabel('set_nest_father'), 'set_nest_father', onAction, enabled: _isActionEnabled('set_nest_father')),
            _SmallCareButton('Дед', _priceLabel('set_nest_grandfather'), 'set_nest_grandfather', onAction, enabled: _isActionEnabled('set_nest_grandfather')),
            _SmallCareButton('Старейшина', _priceLabel('set_nest_elder'), 'set_nest_elder', onAction, enabled: _isActionEnabled('set_nest_elder')),
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
  @override Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    return Row(mainAxisSize: MainAxisSize.max, children: [
      Flexible(child: Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.muted), overflow: TextOverflow.ellipsis, maxLines: 1)),
      const SizedBox(width: 6),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(value: (progress % 1.0).clamp(0.0, 1.0), backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 4),
        ),
      ),
    ]);
  });
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.text));
}

class _SmallCareButton extends StatelessWidget {
  final String label, price, careCode;
  final void Function(String) onAction;
  final bool enabled;
  const _SmallCareButton(this.label, this.price, this.careCode, this.onAction, {this.enabled = true});

  @override Widget build(BuildContext context) {
    final btn = SizedBox(width: 70, child: Material(color: Colors.transparent, child: InkWell(
      onTap: enabled ? () => onAction(careCode) : null,
      borderRadius: BorderRadius.circular(12),
      child: Ink(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: enabled ? (price.startsWith('Из запаса') ? const Color(0xFF1B5E20) : const Color(0xFF1A2A1A)) : const Color(0xFF111214), border: Border.all(color: const Color(0xFF7CFC6E).withOpacity(0.5))), child: Column(children: [
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: enabled ? AppTheme.text : AppTheme.muted)),
        const SizedBox(height: 2), Text(price, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: enabled ? AppTheme.gold : AppTheme.muted)),
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

class _SkipDayButton extends StatelessWidget {
  const _SkipDayButton({required this.onPressed});
  final VoidCallback onPressed;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Material(color: Colors.transparent, child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(20),
      child: Ink(height: 52, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00C853), Color(0xFF1B5E20)]),
        boxShadow: [BoxShadow(color: const Color(0xFF00E676).withOpacity(0.55), blurRadius: 20, offset: const Offset(0, 4)), BoxShadow(color: const Color(0xFF00C853).withOpacity(0.3), blurRadius: 32)]),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.fast_forward_rounded, color: Colors.white, size: 28), SizedBox(width: 10), Text('ПРОПУСТИТЬ ДЕНЬ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white))])))));
}

// -------------------- ЭКРАН МАГАЗИНА (исправлен) --------------------
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key, required this.game, required this.userEmail, required this.onBuyTree, required this.onCancelTreeSell, required this.onBuyResource, required this.onCancelResourceSell, required this.onSellResource, required this.onPurchasePack, required this.onBuyPetEgg, required this.audioService});
  final GameEngine game; final String userEmail; final ValueChanged<String> onBuyTree, onCancelTreeSell, onBuyResource, onCancelResourceSell; final void Function(String, int, double) onSellResource; final void Function(String, int, double) onPurchasePack; final VoidCallback onBuyPetEgg; final AudioService audioService;

  @override State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  @override Widget build(BuildContext context) {
    final game = widget.game;
    final marketTrees = game.trees.where((t) => t.forSale && t.owner != widget.userEmail).toList();
    final waterPrice = game.dynamicResourcePrice(150);
    final fertilizerPrice = game.dynamicResourcePrice(800);
    final birdPrice = game.dynamicResourcePrice(1000);

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Text('🏪 МАГАЗИН', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onBackground, shadows: [Shadow(blurRadius: 12, color: AppTheme.gold.withOpacity(0.5))]))),
          TabBar(
            labelColor: AppTheme.gold,
            unselectedLabelColor: AppTheme.muted,
            indicatorColor: AppTheme.gold,
            onTap: (_) => widget.audioService.playClick(),
            tabs: const [Tab(text: 'Деревья'), Tab(text: 'Ресурсы')],
          ),
          Expanded(
            child: TabBarView(children: [
              // Вкладка "Деревья"
              marketTrees.isEmpty
                  ? Center(child: Text('Нет лотов', style: TextStyle(color: AppTheme.muted)))
                  : ListView.builder(padding: const EdgeInsets.all(20), itemCount: marketTrees.length, itemBuilder: (_, i) {
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
                          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)), onPressed: () { widget.onBuyTree(tree.id); widget.audioService.playClick(); }, child: const Text('Купить')),
                        ])),
                      );
                    }),
              // Вкладка "Ресурсы"
              SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Быстрая покупка ресурсов', style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _ResourcePackCard(label: '💧 Вода', quantity: 1, price: waterPrice, color: const Color(0xFF00E5FF), onBuy: () { widget.onPurchasePack('water_unit', 1, waterPrice); widget.audioService.playClick(); })),
                  const SizedBox(width: 10),
                  Expanded(child: _ResourcePackCard(label: '🌿 Удобрение', quantity: 1, price: fertilizerPrice, color: const Color(0xFF69F0AE), onBuy: () { widget.onPurchasePack('fertilizer_unit', 1, fertilizerPrice); widget.audioService.playClick(); })),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _ResourcePackCard(label: '🐦 Птица', quantity: 1, price: birdPrice, color: const Color(0xFFFF80AB), onBuy: () { widget.onPurchasePack('bird_unit', 1, birdPrice); widget.audioService.playClick(); })),
                  const SizedBox(width: 10),
                  Expanded(child: _ResourcePackCard(label: '🐾 Питомец', quantity: 1, price: 2000, color: const Color(0xFFFFD740), onBuy: () { widget.onBuyPetEgg(); widget.audioService.playClick(); }, active: game.petDefenderActive)),
                ]),
                const SizedBox(height: 18),
                const Text('Рынок ресурсов', style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (game.resourceLots.isEmpty)
                  Padding(padding: const EdgeInsets.only(bottom: 16), child: Text('Нет лотов ресурсов', style: TextStyle(color: AppTheme.muted)))
                else
                  ...game.resourceLots.map((lot) => Card(color: AppTheme.panel, margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                    Flexible(child: Text(_resourceName(lot.resourceType), style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis, maxLines: 1)), const Spacer(),
                    Flexible(child: Text('${lot.quantity} шт. x ${lot.pricePerUnit.toStringAsFixed(0)} WLNT', style: const TextStyle(color: AppTheme.gold), overflow: TextOverflow.ellipsis, maxLines: 1)),
                    if (lot.sellerEmail == widget.userEmail) TextButton(onPressed: () { widget.onCancelResourceSell(lot.id); widget.audioService.playClick(); }, child: const Text('Снять', style: TextStyle(color: Colors.red)))
                    else ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)), onPressed: () { widget.onBuyResource(lot.id); widget.audioService.playClick(); }, child: const Text('Купить')),
                  ])))),
                const SizedBox(height: 16),
                Text('Выставить свой лот:', style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _SellResourceForm(onSell: widget.onSellResource, inventory: game.inventory, audioService: widget.audioService),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }

  String _resourceName(String type) => switch (type) { 'water_unit' => '💧 Вода', 'fertilizer_unit' => '🌿 Удобрение', 'bird_unit' => '🐦 Птица', _ => type };
}

class _ResourcePackCard extends StatelessWidget {
  const _ResourcePackCard({required this.label, required this.quantity, required this.price, required this.color, required this.onBuy, this.active = false});
  final String label; final int quantity; final double price; final Color color; final VoidCallback onBuy; final bool active;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: active ? Colors.amber : Colors.white12, width: active ? 2.0 : 1.0), boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))]),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.text)),
      const SizedBox(height: 8),
      Text(active ? 'Активирован' : '${price.toStringAsFixed(0)} WLNT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? Colors.greenAccent : AppTheme.gold)),
      const SizedBox(height: 8),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: active ? Colors.grey.shade700 : color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: active ? null : onBuy, child: Text(active ? 'Владеете' : 'Купить', style: const TextStyle(fontWeight: FontWeight.w800))),
    ]),
  );
}

class _SellResourceForm extends StatefulWidget {
  const _SellResourceForm({required this.onSell, required this.inventory, required this.audioService});
  final void Function(String resourceType, int quantity, double pricePerUnit) onSell; final Map<String, int> inventory; final AudioService audioService;
  @override State<_SellResourceForm> createState() => _SellResourceFormState();
}

class _SellResourceFormState extends State<_SellResourceForm> {
  String _type = 'water_unit';
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController(text: '100');

  void _sell() {
    final qty = int.tryParse(_qtyCtrl.text);
    final price = double.tryParse(_priceCtrl.text);
    if (qty == null || price == null || qty <= 0 || price <= 0) return;
    final available = widget.inventory[_type] ?? 0;
    if (available < qty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Недостаточно ресурса. Доступно: $available')));
      return;
    }
    widget.onSell(_type, qty, price);
    widget.audioService.playClick();
    _qtyCtrl.text = '1';
    _priceCtrl.text = '100';
  }

  @override Widget build(BuildContext context) => Column(children: [
    DropdownButton<String>(value: _type, items: const [DropdownMenuItem(value: 'water_unit', child: Text('💧 Вода')), DropdownMenuItem(value: 'fertilizer_unit', child: Text('🌿 Удобрение')), DropdownMenuItem(value: 'bird_unit', child: Text('🐦 Птица'))], onChanged: (v) => setState(() => _type = v!)),
    Row(children: [
      Expanded(child: TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Кол-во'))),
      const SizedBox(width: 12),
      Expanded(child: TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Цена за шт.'))),
    ]),
    const SizedBox(height: 8),
    ElevatedButton(onPressed: _sell, child: const Text('Выставить')),
  ]);
}

// -------------------- ЭКРАН УДАЧИ (исправлен) --------------------
class LuckyScreen extends StatefulWidget {
  const LuckyScreen({super.key, required this.game, required this.onBurned, required this.onSpinComplete, required this.audioService});
  final GameEngine game; final ValueChanged<String> onBurned; final Future<void> Function() onSpinComplete; final AudioService audioService;
  @override State<LuckyScreen> createState() => _LuckyScreenState();
}

class _LuckyScreenState extends State<LuckyScreen> with SingleTickerProviderStateMixin {
  String _result = '';
  static const bet = 100.0;
  bool _spinning = false;
  bool _showConfetti = false;
  bool _flashHighlight = false;
  double _rotation = 0.0;
  late final AnimationController _spinController;
  List<_ConfettiDot> _confetti = [];
  static const _extendedOutcomes = [
    _OutcomeExt(type: 'nothing', weight: 60, amount: 0, label: 'Пусто'),
    _OutcomeExt(type: 'wlnt', weight: 20, amount: 30, label: '30 WLNT'),
    _OutcomeExt(type: 'wlnt', weight: 10, amount: 60, label: '60 WLNT'),
    _OutcomeExt(type: 'wlnt', weight: 5, amount: 100, label: '100 WLNT'),
    _OutcomeExt(type: 'wlnt', weight: 2, amount: 200, label: '200 WLNT'),
    _OutcomeExt(type: 'wlnt', weight: 1, amount: 300, label: '300 WLNT'),
    _OutcomeExt(type: 'water', weight: 1, amount: 2, label: '2 Вода'),
    _OutcomeExt(type: 'fertilizer', weight: 1, amount: 1, label: '1 Удобрение'),
  ];

  @override void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _spinController.addListener(() => setState(() => _rotation = _spinController.value * 6.0));
  }

  @override void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    if (widget.game.wlntBalance < bet) {
      setState(() => _result = 'Недостаточно средств');
      return;
    }
    _spinning = true;
    setState(() {
      _result = 'Крутим...';
      widget.game.wlntBalance -= bet;
    });
    widget.audioService.playClick();
    _spinController.reset();
    await _spinController.forward();

    final totalWeight = _extendedOutcomes.fold<double>(0.0, (s, e) => s + e.weight);
    final rnd = Random().nextDouble() * totalWeight;
    double acc = 0;
    _OutcomeExt picked = _extendedOutcomes.first;
    for (final o in _extendedOutcomes) {
      acc += o.weight;
      if (rnd <= acc) { picked = o; break; }
    }

    if (picked.type == 'wlnt') {
      widget.game.wlntBalance += picked.amount.toDouble();
      setState(() => _result = 'Вы выиграли: ${picked.label}');
    } else if (picked.type == 'water') {
      widget.game.inventory['water_unit'] = (widget.game.inventory['water_unit'] ?? 0) + picked.amount;
      setState(() => _result = 'Вы получили: ${picked.label}');
    } else if (picked.type == 'fertilizer') {
      widget.game.inventory['fertilizer_unit'] = (widget.game.inventory['fertilizer_unit'] ?? 0) + picked.amount;
      setState(() => _result = 'Вы получили: ${picked.label}');
    } else {
      setState(() => _result = 'Ничего не выпало');
    }

    widget.audioService.playCoins();
    if (picked.type != 'nothing') _startConfetti();
    widget.game.trackChallenge('spin');
    await widget.onSpinComplete();
    setState(() => _flashHighlight = true);
    Future.delayed(const Duration(milliseconds: 500), () { if (mounted) setState(() => _flashHighlight = false); });
    await Future.delayed(const Duration(milliseconds: 600));
    _spinning = false;
    setState(() {});
  }

  void _burnDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppTheme.panel, title: const Text('Сжечь NFT', style: TextStyle(color: AppTheme.text)),
      content: SizedBox(width: double.maxFinite, child: ListView.builder(shrinkWrap: true, itemCount: widget.game.trees.length, itemBuilder: (_, i) {
        final tree = widget.game.trees[i];
        return ListTile(leading: Image.network(tree.imageUrl, width: 40, height: 40, fit: BoxFit.cover), title: Text(tree.name, style: const TextStyle(color: AppTheme.text)), subtitle: Text(tree.rarity.label, style: const TextStyle(color: AppTheme.muted)), onTap: () { Navigator.pop(ctx); widget.onBurned(tree.id); setState(() => _result = 'NFT ${tree.name} сожжён. Получено 2000 WLNT и удобрения.'); widget.audioService.playClick(); });
      })),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена'))],
    ));
  }

  @override Widget build(BuildContext context) {
    final totalWeight = _extendedOutcomes.fold<double>(0.0, (sum, item) => sum + item.weight);
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF071119), Color(0xFF081620), Color(0xFF0D203A)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('🍀 УДАЧА', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 18, color: AppTheme.gold.withOpacity(0.55))])),
            const SizedBox(height: 10),
            Text('Баланс: ${_fmt(widget.game.wlntBalance)} WLNT', style: const TextStyle(color: AppTheme.gold, fontSize: 16)),
            const SizedBox(height: 24),
            Center(
              child: Stack(alignment: Alignment.center, children: [
                Container(width: 330, height: 330, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [Color(0xFF1B2334), Color(0xFF071119)]), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 28, offset: Offset(0, 16))])),
                if (_flashHighlight) Positioned.fill(child: AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: _flashHighlight ? 0.8 : 0, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.white.withOpacity(0.45), Colors.transparent], stops: const [0.0, 0.9]))))),
                ...List.generate(12, (index) {
                  final angle = index * 2 * pi / 12;
                  return Positioned(left: 165 + cos(angle) * 150 - 8, top: 165 + sin(angle) * 150 - 8, child: Icon(Icons.star, size: 10 + (index % 2) * 3, color: Colors.white.withOpacity(0.6)));
                }),
                Transform.rotate(angle: _rotation * 2 * pi, child: CustomPaint(size: const Size(280, 280), painter: _LuckyWheelPainter(_extendedOutcomes))),
                Positioned(top: 18, child: Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppTheme.gold, Colors.amber.shade700]), boxShadow: [BoxShadow(color: AppTheme.gold.withOpacity(0.45), blurRadius: 20, spreadRadius: 2)], border: Border.all(color: Colors.white.withOpacity(0.9), width: 2)), child: const Center(child: Text('W', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black))))),
                const Positioned(top: 14, child: Icon(Icons.arrow_drop_down, size: 42, color: Colors.white)),
                if (_showConfetti) _buildConfetti(),
              ]),
            ),
            const SizedBox(height: 24),
            const Text('Распределение шансов', style: TextStyle(color: AppTheme.text, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: _extendedOutcomes.map((o) {
              final percent = (o.weight / totalWeight) * 100;
              return Container(
                width: (MediaQuery.of(context).size.width - 76) / 2,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.panelBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text(o.label, style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700, fontSize: 12))), Text('${percent.toStringAsFixed(0)}%', style: const TextStyle(color: AppTheme.muted, fontSize: 11))]),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: percent / 100, minHeight: 6, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(o.type == 'wlnt' ? Colors.amber : o.type == 'water' ? const Color(0xFF00E5FF) : o.type == 'fertilizer' ? const Color(0xFF69F0AE) : const Color(0xFFFF80AB)))),
                ]),
              );
            }).toList()),
            const SizedBox(height: 22),
            AnimatedScale(scale: _spinning ? 0.98 : 1.0, duration: const Duration(milliseconds: 150), curve: Curves.easeOutCubic,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), backgroundColor: AppTheme.gold, shadowColor: Colors.amber.withOpacity(0.45), elevation: 12),
                onPressed: _spinning ? null : _spin,
                icon: const Icon(Icons.casino, color: Colors.black),
                label: Text(_spinning ? 'Ждём...' : 'КРУТИТЬ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black)),
              ),
            ),
            const SizedBox(height: 14),
            Text(_result, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.text, fontSize: 15)),
            const SizedBox(height: 26),
            const Divider(color: AppTheme.panelBorder),
            const SizedBox(height: 18),
            const Text('Инвентарь', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _Res('💧 Вода', widget.game.inventory['water_unit'] ?? 0),
            _Res('🌿 Удобрения', widget.game.inventory['fertilizer_unit'] ?? 0),
            _Res('🐦 Птицы', widget.game.inventory['bird_unit'] ?? 0),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _burnDialog,
              icon: const Icon(Icons.local_fire_department, color: Colors.red),
              label: const Text('Сжечь NFT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _Res(String label, int count) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: AppTheme.text)), Text('$count', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700))]));

  void _startConfetti() {
    setState(() {
      _showConfetti = true;
      _confetti = List.generate(24, (index) => _ConfettiDot(
        offset: Offset(Random().nextDouble() * 280, Random().nextDouble() * 280),
        color: [Colors.amber, Colors.green, Colors.blue, Colors.pink, Colors.orange][index % 5],
        radius: 4 + Random().nextDouble() * 5,
        shape: index % 3,
      ));
    });
    Future.delayed(const Duration(milliseconds: 1200), () { if (mounted) setState(() => _showConfetti = false); });
  }

  Widget _buildConfetti() => _showConfetti ? Positioned.fill(child: CustomPaint(painter: _ConfettiPainter(_confetti))) : const SizedBox.shrink();
  String _fmt(double v) { final s = v.toStringAsFixed(0), b = StringBuffer(); for (int i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) b.write(' '); b.write(s[i]); } return b.toString(); }
}

class _OutcomeExt { final String type; final double weight; final int amount; final String label; const _OutcomeExt({required this.type, required this.weight, required this.amount, required this.label}); }
class _ConfettiDot { final Offset offset; final Color color; final double radius; final int shape; const _ConfettiDot({required this.offset, required this.color, required this.radius, required this.shape}); }

Path _diamondPath(Offset center, double radius) => Path()..moveTo(center.dx, center.dy - radius)..lineTo(center.dx + radius, center.dy)..lineTo(center.dx, center.dy + radius)..lineTo(center.dx - radius, center.dy)..close();
Path _starPath(Offset center, double radius) {
  final path = Path();
  for (int i = 0; i < 5; i++) {
    final angle = i * 2 * pi / 5 - pi / 2;
    final x = center.dx + cos(angle) * radius;
    final y = center.dy + sin(angle) * radius;
    if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    final innerAngle = angle + pi / 5;
    final innerX = center.dx + cos(innerAngle) * radius * 0.5;
    final innerY = center.dy + sin(innerAngle) * radius * 0.5;
    path.lineTo(innerX, innerY);
  }
  path.close();
  return path;
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiDot> dots;
  _ConfettiPainter(this.dots);
  @override void paint(Canvas canvas, Size size) {
    for (final dot in dots) {
      final paint = Paint()..color = dot.color.withOpacity(0.9);
      switch (dot.shape) {
        case 1: canvas.drawPath(_diamondPath(dot.offset, dot.radius), paint); break;
        case 2: canvas.drawPath(_starPath(dot.offset, dot.radius), paint); break;
        default: canvas.drawCircle(dot.offset, dot.radius, paint);
      }
    }
  }
  @override bool shouldRepaint(covariant _ConfettiPainter old) => true;
}

class _LuckyWheelPainter extends CustomPainter {
  final List<_OutcomeExt> outcomes;
  _LuckyWheelPainter(this.outcomes);
  @override void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) / 2;
    final totalWeight = outcomes.fold<double>(0.0, (total, item) => total + item.weight);
    double startAngle = -pi / 2;
    for (final outcome in outcomes) {
      final sweep = 2 * pi * outcome.weight / totalWeight;
      final baseColor = _colorForType(outcome.type);
      final paint = Paint()..shader = SweepGradient(startAngle: startAngle, endAngle: startAngle + sweep, colors: [baseColor.withOpacity(0.85), baseColor.withOpacity(1.0)]).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, true, paint);
      final edgePaint = Paint()..color = Colors.white.withOpacity(0.18)..strokeWidth = 1.5..style = PaintingStyle.stroke;
      final edgePath = Path()..moveTo(center.dx, center.dy)..arcTo(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, false);
      canvas.drawPath(edgePath, edgePaint);
      final labelAngle = startAngle + sweep / 2;
      final labelOffset = center + Offset(cos(labelAngle), sin(labelAngle)) * radius * 0.62;
      final textPainter = TextPainter(text: TextSpan(text: outcome.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 4, color: Colors.black45)])), textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout(maxWidth: radius * 0.55);
      canvas.save(); canvas.translate(labelOffset.dx, labelOffset.dy); canvas.rotate(labelAngle + pi / 2); textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2)); canvas.restore();
      startAngle += sweep;
    }
    final borderPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 4..shader = RadialGradient(colors: [Colors.white.withOpacity(0.85), Colors.white.withOpacity(0.15)]).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, borderPaint);
    final centerPaint = Paint()..shader = RadialGradient(colors: [Colors.amber.shade200, Colors.orange.shade800]).createShader(Rect.fromCircle(center: center, radius: radius * 0.18));
    canvas.drawCircle(center, radius * 0.16, centerPaint);
    final shinePaint = Paint()..color = Colors.white.withOpacity(0.35);
    canvas.drawCircle(center.translate(-radius * 0.04, -radius * 0.04), radius * 0.04, shinePaint);
  }
  Color _colorForType(String type) => switch (type) { 'wlnt' => const Color(0xFFFFD740), 'water' => const Color(0xFF00E5FF), 'fertilizer' => const Color(0xFF69F0AE), 'bird' => const Color(0xFFFF80AB), _ => const Color(0xFF616161), };
  @override bool shouldRepaint(covariant _LuckyWheelPainter old) => old.outcomes != outcomes;
}

// -------------------- ЭКРАН КОЛЛЕКЦИИ (исправлен) --------------------
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key, required this.game, required this.userEmail, required this.onSelectTree, required this.onPlant, required this.onSell, required this.onCancelSell, required this.leaderboard, required this.onHarvest, required this.onClaimChallenge, required this.audioService});
  final GameEngine game; final String userEmail; final ValueChanged<String> onSelectTree, onPlant, onCancelSell, onHarvest, onClaimChallenge; final void Function(String treeId, double price) onSell; final List<LeaderboardEntry> leaderboard; final AudioService audioService;

  @override State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDetails(BuildContext context, TreeModel tree) {
    final bool isOwner = tree.owner == widget.userEmail || tree.owner.isEmpty;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (ctx) => Container(
      height: MediaQuery.of(ctx).size.height * 0.7,
      decoration: const BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), border: Border(top: BorderSide(color: AppTheme.panelBorder, width: 1.5))),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.muted, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  tree.imageUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 200,
                    height: 200,
                    color: const Color(0xFF0D120D),
                    child: Center(child: Text(tree.stats.emoji, style: const TextStyle(fontSize: 64))),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(tree.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.text), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(tree.stats.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(tree.rarity.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tree.stats.color)),
              ]),
              const SizedBox(height: 4),
              Text('Эмоция: ${tree.emotion} (бонус +${(tree.emotionBonus * 100).toStringAsFixed(0)}%)', style: const TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 20),
              _DetailRow('Статус', tree.status.label),
              _DetailRow('Перерождения', '${tree.rebirthsLeft} / ${tree.maxRebirths}'),
              if (tree.status == TreeStatus.growth || tree.status == TreeStatus.rest) ...[
                _DetailRow('Оставшееся время', tree.timeLeftFormatted),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Влажность', style: TextStyle(color: AppTheme.muted, fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 8,
                          child: LinearProgressIndicator(
                            value: tree.waterPercent,
                            backgroundColor: const Color(0xFF0A0C10),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${tree.currentWater.round()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.text)),
                  ]),
                ),
                if (tree.status == TreeStatus.growth) _DetailRow('Гусеницы', '${tree.caterpillars}'),
              ],
              if (tree.autoWaterDays > 0) _DetailRow('Автополив', '${tree.autoWaterDays} дн. (${tree.autoWaterAmount}%/день)'),
              if (tree.forSale) _DetailRow('Продаётся', 'Да (${tree.price.toStringAsFixed(0)} WLNT)'),
              const SizedBox(height: 24),
              if (tree.forSale && isOwner)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () { widget.onCancelSell(tree.id); Navigator.pop(ctx); widget.audioService.playClick(); },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Снять с продажи'),
                )
              else if (!tree.isPlanted && isOwner)
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                    onPressed: () { widget.onPlant(tree.id); Navigator.pop(ctx); widget.audioService.playClick(); },
                    icon: const Icon(Icons.eco, color: Colors.white),
                    label: const Text('Посадить', style: TextStyle(color: Colors.white)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    onPressed: () { Navigator.pop(ctx); _showSellDialog(context, tree); },
                    icon: const Icon(Icons.sell, color: Colors.red),
                    label: const Text('Продать', style: TextStyle(color: Colors.red)),
                  ),
                ])
              else if (tree.canHarvest && isOwner)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                  onPressed: () { widget.onHarvest(tree.id); Navigator.pop(ctx); widget.audioService.playClick(); },
                  icon: const Icon(Icons.agriculture),
                  label: const Text('Собрать урожай', style: TextStyle(color: Colors.white)),
                )
              else if (tree.isPlanted && tree.status == TreeStatus.growth && isOwner)
                Text('Нельзя продать во время роста', style: TextStyle(color: AppTheme.muted))
              else if (tree.isPlanted && tree.status == TreeStatus.rest && isOwner)
                Text('Дерево в отдыхе', style: TextStyle(color: AppTheme.muted))
            ]),
          ),
        ),
      ]),
    ));
  }

  void _showSellDialog(BuildContext context, TreeModel tree) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: const Text('Цена продажи', style: TextStyle(color: AppTheme.text)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.text),
          decoration: const InputDecoration(hintText: 'WLNT'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final p = double.tryParse(ctrl.text);
              if (p != null && p > 0) {
                Navigator.pop(ctx);
                widget.onSell(tree.id, p);
                widget.audioService.playClick();
              }
            },
            child: const Text('Продать'),
          ),
        ],
      ),
    );
  }

  @override Widget build(BuildContext context) {
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('ВАША КОЛЛЕКЦИЯ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onBackground,
              shadows: [Shadow(blurRadius: 12, color: AppTheme.gold.withOpacity(0.5))],
            ),
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.muted,
          indicatorColor: AppTheme.gold,
          onTap: (_) => widget.audioService.playClick(),
          tabs: const [
            Tab(text: 'Деревья'),
            Tab(text: 'Ресурсы'),
            Tab(text: 'Задания'),
            Tab(text: 'Рейтинг'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Деревья
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: widget.game.trees.length,
                itemBuilder: (_, i) {
                  final tree = widget.game.trees[i];
                  return _CollectionCard(tree: tree, onTap: () { _showDetails(context, tree); widget.audioService.playClick(); });
                },
              ),
              // Ресурсы
              ListView(padding: const EdgeInsets.all(20), children: [
                ResourceRow('💧 Вода', widget.game.inventory['water_unit'] ?? 0),
                ResourceRow('🌿 Удобрения', widget.game.inventory['fertilizer_unit'] ?? 0),
                ResourceRow('🐦 Птицы', widget.game.inventory['bird_unit'] ?? 0),
              ]),
              // Задания
              _ChallengesTab(challenges: widget.game.dailyChallenges, onClaim: widget.onClaimChallenge),
              // Рейтинг
              LeaderboardScreen(leaderboard: widget.leaderboard),
            ],
          ),
        ),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label, value;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 14)),
      Flexible(
        child: Text(value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.text),
          textAlign: TextAlign.right,
        ),
      ),
    ]),
  );
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.tree, this.onTap});
  final TreeModel tree;
  final VoidCallback? onTap;

  @override Widget build(BuildContext context) {
    final progress = tree.status == TreeStatus.growth
        ? (tree.seasonDay / 14).clamp(0.0, 1.0)
        : (tree.status == TreeStatus.rest ? tree.seasonDay / 14 : 0.0);
    final statusColor = tree.status == TreeStatus.growth
        ? const Color(0xFF7CFC6E)
        : (tree.status == TreeStatus.rest ? const Color(0xFF80D8FF) : AppTheme.muted);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tree.stats.color.withOpacity(0.4)),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                tree.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 70,
                  height: 70,
                  color: const Color(0xFF0D120D),
                  child: Center(child: Text(tree.stats.emoji, style: const TextStyle(fontSize: 30))),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(tree.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.text),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (tree.forSale) const Icon(Icons.sell, size: 16, color: Colors.red),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Flexible(child: Text(tree.stats.emoji, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(tree.rarity.label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tree.stats.color),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    tree.status == TreeStatus.growth ? Icons.eco : (tree.status == TreeStatus.rest ? Icons.ac_unit : Icons.close),
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(tree.status.label,
                      style: TextStyle(fontSize: 11, color: statusColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 8,
                    child: Stack(children: [
                      Container(color: const Color(0xFF0A0C10)),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [tree.stats.color.withOpacity(0.5), tree.stats.color]),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Доход: ${tree.stats.income.toStringAsFixed(0)} WLNT', style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
                const SizedBox(height: 4),
                Text('День: ${tree.seasonDay}/14  |  Перерождений: ${tree.rebirthsLeft}/${tree.maxRebirths}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.muted),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab({required this.challenges, required this.onClaim});
  final List<DailyChallenge> challenges;
  final ValueChanged<String> onClaim;

  @override Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return Center(child: Text('Нет ежедневных заданий', style: TextStyle(color: AppTheme.muted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: challenges.length,
      itemBuilder: (_, index) {
        final challenge = challenges[index];
        return Card(
          color: AppTheme.panel,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(challenge.description, style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: challenge.progress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFF0A0C10),
                  valueColor: AlwaysStoppedAnimation<Color>(challenge.completed ? const Color(0xFF00C853) : AppTheme.gold),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('${challenge.current} / ${challenge.target}', style: const TextStyle(color: AppTheme.muted))),
                Text('${challenge.reward} WLNT', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                if (challenge.claimed)
                  const Text('Получено', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w700))
                else if (challenge.completed)
                  ElevatedButton(
                    onPressed: () => onClaim(challenge.id),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                    child: const Text('Забрать'),
                  )
                else
                  Text('В процессе', style: TextStyle(color: AppTheme.muted)),
                if (challenge.completed && !challenge.claimed) const Icon(Icons.emoji_events, color: AppTheme.gold) else const SizedBox.shrink(),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key, required this.leaderboard});
  final List<LeaderboardEntry> leaderboard;

  @override Widget build(BuildContext context) {
    final sorted = List<LeaderboardEntry>.from(leaderboard)..sort((a, b) => b.wlntBalance.compareTo(a.wlntBalance));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final entry = sorted[i];
        return Card(
          color: entry.isPlayer ? const Color(0xFF1B3D1F) : AppTheme.panel,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: entry.isPlayer ? AppTheme.gold : Colors.transparent, width: entry.isPlayer ? 2 : 0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Text('${i + 1}.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: i == 0 ? AppTheme.gold : (i == 1 ? Colors.grey.shade400 : (i == 2 ? Colors.brown.shade300 : AppTheme.text)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(entry.name,
                  style: TextStyle(
                    fontWeight: entry.isPlayer ? FontWeight.bold : FontWeight.normal,
                    color: entry.isPlayer ? AppTheme.gold : AppTheme.text,
                  ),
                ),
              ),
              Text('${entry.wlntBalance.toStringAsFixed(0)} WLNT',
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class ResourceRow extends StatelessWidget {
  final String label; final int count;
  const ResourceRow(this.label, this.count, {super.key});
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(label, style: const TextStyle(color: AppTheme.text)),
      const Spacer(),
      Text(count.toString(), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
    ]),
  );
}

// -------------------- ЭКРАН КОШЕЛЬКА (исправлен) --------------------
class WalletScreen extends StatelessWidget {
  const WalletScreen({
    super.key,
    required this.solBalance,
    required this.wlntBalance,
    required this.userEmail,
    required this.myReferralCode,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onLogout,
    required this.onDepositSol,
    required this.onWithdrawSol,
    required this.onDepositWlnt,
    required this.onWithdrawWlnt,
    required this.onConvertSolToWlnt,
    required this.onConvertWlntToSol,
    required this.onToggleAudio,
    required this.audioService,
    this.dailyRewardAvailable = false,
  });
  final double solBalance, wlntBalance;
  final String userEmail, myReferralCode;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme, onLogout, onToggleAudio;
  final ValueChanged<double> onDepositSol, onWithdrawSol, onDepositWlnt, onWithdrawWlnt, onConvertSolToWlnt, onConvertWlntToSol;
  final AudioService audioService;
  final bool dailyRewardAvailable;

  Future<void> _amountDialog(BuildContext context, String title, String label, ValueChanged<double> onConfirm) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: AppTheme.text)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppTheme.text),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(color: AppTheme.muted),
              filled: true,
              fillColor: AppTheme.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null || double.parse(v) <= 0
                ? 'Некорректная сумма'
                : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена', style: TextStyle(color: AppTheme.muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, double.parse(ctrl.text));
              }
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
    if (result != null) onConfirm(result);
  }

  @override Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('КОШЕЛЁК',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onBackground,
                  shadows: [Shadow(blurRadius: 12, color: AppTheme.gold.withOpacity(0.5))],
                ),
              ),
            ),
            IconButton(
              icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode, color: AppTheme.gold),
              onPressed: () { onToggleTheme(); audioService.playClick(); },
              tooltip: 'Переключить тему',
            ),
            IconButton(
              icon: Icon(audioService.muted ? Icons.volume_off : Icons.volume_up, color: AppTheme.gold),
              onPressed: () { onToggleAudio(); audioService.playClick(); },
              tooltip: audioService.muted ? 'Включить звук' : 'Отключить звук',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.muted),
              onPressed: () { onLogout(); audioService.playClick(); },
              tooltip: 'Выйти',
            ),
          ]),
          const SizedBox(height: 8),
          Text(userEmail, style: const TextStyle(color: AppTheme.muted, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Мой код: $myReferralCode', style: const TextStyle(color: AppTheme.gold, fontSize: 14)),
          const SizedBox(height: 24),
          _BalanceCard(
            icon: Icons.currency_bitcoin,
            label: 'Solana (SOL)',
            balance: solBalance.toStringAsFixed(4),
            color: const Color(0xFF9945FF),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _ActionChip(
                label: 'Пополнить',
                icon: Icons.add_circle_outline,
                onTap: () { audioService.playClick(); _amountDialog(context, 'Пополнить SOL', 'Сумма SOL', onDepositSol); },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionChip(
                label: 'Вывести',
                icon: Icons.arrow_circle_up_outlined,
                onTap: () {
                  audioService.playClick();
                  _amountDialog(context, 'Вывести SOL', 'Сумма SOL', (a) {
                    if (a <= solBalance) onWithdrawSol(a);
                    else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Недостаточно средств')));
                  });
                },
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.panelBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('Обмен валют', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.text)),
              SizedBox(height: 6),
              Text('Курс обмена: 1 SOL = 1000 WLNT', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
              SizedBox(height: 4),
              Text('Обменяйте SOL на WLNT для покупки ресурсов и редких улучшений.',
                style: TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _ActionChip(
                label: 'SOL → WLNT',
                icon: Icons.swap_horiz,
                onTap: () { audioService.playClick(); _amountDialog(context, 'Обменять SOL на WLNT', 'Сумма SOL', onConvertSolToWlnt); },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionChip(
                label: 'WLNT → SOL',
                icon: Icons.swap_horiz,
                onTap: () { audioService.playClick(); _amountDialog(context, 'Обменять WLNT на SOL', 'Сумма WLNT', onConvertWlntToSol); },
              ),
            ),
          ]),
          const SizedBox(height: 32),
          _BalanceCard(
            icon: Icons.eco,
            label: 'Walnut Token (WLNT)',
            balance: _fmt(wlntBalance),
            color: AppTheme.gold,
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _ActionChip(
                label: 'Пополнить',
                icon: Icons.add_circle_outline,
                onTap: () { audioService.playClick(); _amountDialog(context, 'Пополнить WLNT', 'Сумма WLNT', onDepositWlnt); },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionChip(
                label: 'Вывести',
                icon: Icons.arrow_circle_up_outlined,
                onTap: () {
                  audioService.playClick();
                  _amountDialog(context, 'Вывести WLNT', 'Сумма WLNT', (a) {
                    if (a <= wlntBalance) onWithdrawWlnt(a);
                    else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Недостаточно средств')));
                  });
                },
              ),
            ),
          ]),
        ]),
      ),
    ),
  );

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final frac = parts.length > 1 ? '.${parts[1]}' : '';
    final b = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) b.write(' ');
      b.write(intPart[i]);
    }
    return '$b$frac';
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.icon, required this.label, required this.balance, required this.color});
  final IconData icon; final String label, balance; final Color color;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Row(children: [
      Icon(icon, size: 36, color: color),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.muted)),
          const SizedBox(height: 6),
          Text(balance,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, letterSpacing: 1),
          ),
        ]),
      ),
    ]),
  );
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon, required this.onTap});
  final String label; final IconData icon; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.panel,
          border: Border.all(color: AppTheme.panelBorder),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: AppTheme.text),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.text))),
        ]),
      ),
    ),
  );
}

// -------------------- MAIN SHELL (исправлен) --------------------
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  String? _selectedTreeId;
  late AppState _appState;
  late AudioService _audioService;
  late GameEngine _gameEngine;

  @override void didChangeDependencies() {
    super.didChangeDependencies();
    _appState = context.watch<AppState>();
    _audioService = _appState.audioService;
    _gameEngine = _appState.engine;
  }

  Future<void> _daySkip() async {
    await _appState.nextDay();
    if (mounted) setState(() {});
  }

  void _selectTree(String? id) => setState(() => _selectedTreeId = id);

  Future<bool> _treeAction(String treeId, String action) async {
    final ok = await _appState.engine.applyCare(treeId, action);
    if (ok) {
      setState(() {});
      _audioService.playClick();
    }
    return ok;
  }

  Future<void> _sellTree(String treeId, double price) async {
    final tree = _appState.engine.trees.firstWhere((t) => t.id == treeId);
    if (tree.isPlanted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя продать посаженное дерево. Дождитесь завершения цикла.')),
      );
      return;
    }
    await _appState.engine.sellTree(treeId, price);
    setState(() {});
    _audioService.playClick();
  }

  Future<void> _cancelSell(String treeId) async {
    await _appState.engine.cancelSell(treeId);
    setState(() {});
    _audioService.playClick();
  }

  Future<void> _buyTree(String treeId) async {
    await _appState.engine.buyTree(treeId);
    setState(() {});
    _audioService.playClick();
  }

  Future<void> _sellResource(String type, int qty, double price) async {
    await _appState.engine.sellResource(type, qty, price);
    setState(() {});
    _audioService.playClick();
  }

  Future<void> _buyResource(String lotId) async {
    await _appState.engine.buyResource(lotId);
    setState(() {});
    _audioService.playClick();
  }

  Future<void> _cancelResourceSell(String lotId) async {
    await _appState.engine.cancelResourceSell(lotId);
    setState(() {});
    _audioService.playClick();
  }

  Future<void> _depositSol(double amount) async {
    await _appState.engine.depositSol(amount);
    setState(() {});
  }

  Future<void> _withdrawSol(double amount) async {
    await _appState.engine.withdrawSol(amount);
    setState(() {});
  }

  Future<void> _convertSolToWlnt(double amount) async {
    await _appState.engine.convertSolToWlnt(amount);
    setState(() {});
  }

  Future<void> _convertWlntToSol(double amount) async {
    await _appState.engine.convertWlntToSol(amount);
    setState(() {});
  }

  Future<void> _purchasePack(String type, int qty, double price) async {
    await _appState.engine.purchaseResourcePackage(type, qty, price);
    setState(() {});
  }

  Future<void> _buyPetEgg() async {
    await _appState.engine.buyPetEgg();
    setState(() {});
  }

  Future<void> _burnTree(String id) async {
    await _appState.engine.burnTree(id);
    _audioService.playClick();
    setState(() {});
  }

  Future<void> _plantTree(String id) async {
    await _appState.engine.plantTree(id);
    setState(() {});
    _audioService.playClick();
  }

  Future<void> _harvestTree(String id) async {
    await _appState.engine.harvestTree(id);
    _audioService.playCoins();
    setState(() {});
  }

  Future<void> _claimChallenge(String id) async {
    await _appState.engine.claimChallenge(id);
    _audioService.playCoins();
    setState(() {});
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(
        index: _tab,
        children: [
          FarmScreen(
            game: _gameEngine,
            selectedId: _selectedTreeId,
            onDaySkip: _daySkip,
            onSelectTree: _selectTree,
            onAction: (treeId, action) => _treeAction(treeId, action) as bool,
            audioService: _audioService,
          ),
          MarketScreen(
            game: _gameEngine,
            userEmail: _appState.userEmail,
            onBuyTree: _buyTree,
            onCancelTreeSell: _cancelSell,
            onBuyResource: _buyResource,
            onCancelResourceSell: _cancelResourceSell,
            onSellResource: _sellResource,
            onPurchasePack: _purchasePack,
            onBuyPetEgg: _buyPetEgg,
            audioService: _audioService,
          ),
          LuckyScreen(
            game: _gameEngine,
            onBurned: _burnTree,
            onSpinComplete: () async {
              await _appState.saveGame();
              if (mounted) setState(() {});
            },
            audioService: _audioService,
          ),
          CollectionScreen(
            game: _gameEngine,
            userEmail: _appState.userEmail,
            onSelectTree: _selectTree,
            onPlant: _plantTree,
            onSell: _sellTree,
            onCancelSell: _cancelSell,
            leaderboard: _gameEngine.leaderboard,
            onHarvest: _harvestTree,
            onClaimChallenge: _claimChallenge,
            audioService: _audioService,
          ),
          WalletScreen(
            solBalance: _gameEngine.solBalance,
            wlntBalance: _gameEngine.wlntBalance,
            userEmail: _appState.userEmail,
            myReferralCode: _appState.referralCode,
            themeMode: _appState.themeMode,
            onToggleTheme: () => _appState.setThemeMode(_appState.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
            onLogout: () async { await _appState.logout(); if (mounted) setState(() {}); },
            onDepositSol: _depositSol,
            onWithdrawSol: _withdrawSol,
            onDepositWlnt: (a) async { await _appState.updateBalances(depositWlnt: a); if (mounted) setState(() {}); },
            onWithdrawWlnt: (a) async {
              if (a <= _gameEngine.wlntBalance) {
                await _appState.updateBalances(withdrawWlnt: a);
                if (mounted) setState(() {});
              }
            },
            onConvertSolToWlnt: _convertSolToWlnt,
            onConvertWlntToSol: _convertWlntToSol,
            onToggleAudio: () { setState(() { _audioService.setMuted(!_audioService.muted); }); },
            audioService: _audioService,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          _audioService.playClick();
        },
        backgroundColor: AppTheme.panel,
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

class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});
  final Widget child;
  @override Widget build(BuildContext context) => Container(
    width: 450,
    height: 900,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(40),
      border: Border.all(color: Colors.black87, width: 8),
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(35), child: child),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = await AppState.load();
  runApp(ChangeNotifierProvider.value(value: appState, child: const WalnutFarmApp()));
}

class WalnutFarmApp extends StatelessWidget {
  const WalnutFarmApp({super.key});
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'Walnut Farm',
      debugShowCheckedModeBanner: false,
      themeMode: state.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      builder: (c, child) => PhoneFrame(child: child ?? const SizedBox.shrink()),
      home: !state.initialized
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : state.logged
              ? MainShell(key: ValueKey(state.userEmail))
              : AuthScreen(onLogin: (email, refCode) => state.login(email, refCode)),
    );
  }
}