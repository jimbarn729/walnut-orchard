# 🔧 WALNUT FARM: Готовые примеры кода для рефакторинга

> Этот файл содержит практические примеры кода, которые можно скопировать и использовать для исправления проблем, описанных в ANALYSIS_REPORT.md

---

## 1. ИСПРАВЛЕНИЕ УТЕЧКИ ПАМЯТИ (4.1, 3.1)

### ❌ БЫЛО (Проблемный код)

```dart
class _NftTreeCardState extends State<NftTreeCard> with TickerProviderStateMixin {
  late AnimationController _glowController;
  
  @override void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    widget.game.actionEvent.addListener(_onActionEvent);  // ⚠️ Добавлен слушатель
  }

  @override void dispose() {
    _glowController.dispose();  // ✓ Удаление контроллера
    widget.game.actionEvent.removeListener(_onActionEvent);  // ✓ Удаление слушателя
    super.dispose();
  }
}

// ПРАВИЛЬНО! Но есть проблема в ActionPanel (это StatelessWidget)
```

### ✅ ИСПРАВЛЕНИЕ: Переделать ActionPanel на Stateful

```dart
// lib/screens/farm_screen.dart

class ActionPanelWrapper extends StatefulWidget {
  final TreeModel tree;
  final GameEngine game;
  final void Function(String action) onAction;
  final VoidCallback onClose;
  final AudioService audioService;

  const ActionPanelWrapper({
    Key? key,
    required this.tree,
    required this.game,
    required this.onAction,
    required this.onClose,
    required this.audioService,
  }) : super(key: key);

  @override
  State<ActionPanelWrapper> createState() => _ActionPanelWrapperState();
}

class _ActionPanelWrapperState extends State<ActionPanelWrapper> {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _slideController.forward();  // Запустить анимацию входа
  }

  @override
  void dispose() {
    _slideController.dispose();  // ✓ Очистить ресурсы
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ActionPanel(
        tree: widget.tree,
        game: widget.game,
        onAction: widget.onAction,
        onClose: widget.onClose,
        audioService: widget.audioService,
      ),
    );
  }
}
```

---

## 2. ИСПРАВЛЕНИЕ setState ПОСЛЕ DISPOSE (4.1)

### ❌ БЫЛО

```dart
Future<void> _spin() async {
  if (_spinning) return;
  if (widget.game.wlntBalance < bet) {
    setState(() => _result = 'Недостаточно средств');  // ⚠️ Может быть после dispose
    return;
  }
  _spinning = true;
  setState(() { ... });
  
  // ... await операции ...
  
  await widget.onSpinComplete();  // ← Может привести к dispose
  
  setState(() => _flashHighlight = true);  // ⚠️ setState после dispose!
}
```

### ✅ ИСПРАВЛЕНИЕ

```dart
Future<void> _spin() async {
  if (_spinning) return;
  
  // Проверка перед первым setState
  if (widget.game.wlntBalance < bet) {
    if (mounted) {
      setState(() => _result = 'Недостаточно средств');
    }
    return;
  }

  // Проверка перед длительной операцией
  if (!mounted) return;
  
  setState(() {
    _result = 'Крутим...';
    _spinning = true;
    widget.game.wlntBalance -= bet;
  });

  widget.audioService.playClick();
  _spinController.reset();
  await _spinController.forward();

  // Проверка после длительной операции
  if (!mounted) return;

  // ... выбор приза ...

  if (!mounted) return;
  setState(() => _result = 'Вы выиграли: ${picked.label}');

  widget.audioService.playCoins();
  if (picked.type != 'nothing') _startConfetti();
  
  await widget.onSpinComplete();
  
  if (!mounted) return;
  setState(() => _flashHighlight = true);
  
  // Вместо Future.delayed с setState используйте:
  await Future.delayed(const Duration(milliseconds: 500));
  if (mounted) setState(() => _flashHighlight = false);
  
  _spinning = false;
}
```

---

## 3. ИСПРАВЛЕНИЕ waterPercent (4.2)

### ❌ БЫЛО

```dart
class TreeModel {
  double waterPercent;  // ← Может быть рассинхронизирована
  
  TreeModel({
    // ...
    required this.waterPercent,
  });
}
```

### ✅ ИСПРАВЛЕНИЕ

```dart
class TreeModel {
  final double currentWater;
  
  // Добавить getter
  double get waterPercent => (currentWater / 100.0).clamp(0.0, 1.0);
  
  // Удалить параметр waterPercent из конструктора
  TreeModel({
    // ...
    required this.currentWater,
    // ❌ required this.waterPercent,  <- УДАЛИТЬ
  });
  
  // copyWith() тоже нужно обновить
  TreeModel copyWith({
    // ...
    double? currentWater,
    // ❌ double? waterPercent,  <- УДАЛИТЬ
  }) {
    return TreeModel(
      // ...
      currentWater: currentWater ?? this.currentWater,
      // waterPercent уже вычислится автоматически
    );
  }
}
```

---

## 4. ДОБАВЛЕНИЕ CachedNetworkImage (3.2)

### Шаг 1: Обновить pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  cached_network_image: ^3.3.0
  # ... остальные зависимости ...
```

### Шаг 2: Обновить code

```dart
import 'package:cached_network_image/cached_network_image.dart';

// ❌ БЫЛО
nftImage = Image.network(
  tree.imageUrl,
  fit: BoxFit.cover,
  loadingBuilder: (_, child, p) => ...,
);

// ✅ СТАЛО
nftImage = CachedNetworkImage(
  imageUrl: tree.imageUrl,
  fit: BoxFit.cover,
  memCacheHeight: 200,  // Кэш в памяти (макс 200px)
  maxHeightDiskCache: 250,  // Кэш на диске
  placeholder: (context, url) => Container(
    color: const Color(0xFF0D120D),
    child: Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: accent,
      ),
    ),
  ),
  errorWidget: (context, url, error) => Container(
    color: const Color(0xFF0D120D),
    child: Center(child: Text(tree.stats.emoji, style: const TextStyle(fontSize: 48))),
  ),
);
```

---

## 5. ИСПРАВЛЕНИЕ БАЛАНСА ЭКОНОМИКИ (2.1)

### Обновить prices в ActionPanel

```dart
// lib/main.dart -> ActionPanel -> _priceLabel()

// ❌ СТАРЫЕ ЦЕНЫ
String _priceLabel(String careCode) {
  return switch (careCode) {
    'water_bucket' => '50 WLNT',
    'water_barrel' => '120 WLNT',
    'water_tank' => '200 WLNT',
    'auto_water_basic' => '500 WLNT',
    'auto_water_cistern' => '1200 WLNT',
    // ... много других ...
    _ => ''
  };
}

// ✅ НОВЫЕ ЦЕНЫ (рекомендуемые)
String _priceLabel(String careCode) {
  return switch (careCode) {
    'water_bucket' => '40 WLNT',          // -20%
    'water_barrel' => '90 WLNT',          // -25%
    'water_tank' => '150 WLNT',           // -25%
    'auto_water_basic' => '400 WLNT',     // -20%
    'auto_water_cistern' => '900 WLNT',   // -25%
    'fertilize_normal' => '250 WLNT',     // -17%
    'fertilize_super' => '600 WLNT',      // -25%
    'woodpecker_1' => '35 WLNT',          // -30%
    'woodpecker_5' => '140 WLNT',         // -30%
    'woodpecker_10' => '280 WLNT',        // -30%
    'woodpecker_all' => '700 WLNT',       // -30%
    'set_bucket' => '70 WLNT',
    'set_barrel' => '200 WLNT',
    'set_tank' => '500 WLNT',
    'set_nest_son' => '80 WLNT',
    'set_nest_father' => '200 WLNT',
    'set_nest_grandfather' => '500 WLNT',
    'set_nest_elder' => '1200 WLNT',
    _ => ''
  };
}

// ❌ СТАРЫЕ ЦЕНЫ В _isActionEnabled
bool _isActionEnabled(String careCode) {
  final price = switch (careCode) {
    'water_bucket' => 50,
    'water_barrel' => 120,
    'water_tank' => 200,
    // ...
  };
}

// ✅ НОВЫЕ ЦЕНЫ В _isActionEnabled
bool _isActionEnabled(String careCode) {
  final price = switch (careCode) {
    'water_bucket' => 40,
    'water_barrel' => 90,
    'water_tank' => 150,
    'auto_water_basic' => 400,
    'auto_water_cistern' => 900,
    'fertilize_normal' => 250,
    'fertilize_super' => 600,
    'woodpecker_1' => 35,
    'woodpecker_5' => 140,
    'woodpecker_10' => 280,
    'woodpecker_all' => 700,
    'set_bucket' => 70,
    'set_barrel' => 200,
    'set_tank' => 500,
    'set_nest_son' => 80,
    'set_nest_father' => 200,
    'set_nest_grandfather' => 500,
    'set_nest_elder' => 1200,
    _ => double.infinity,
  };
  return price == 0 || game.wlntBalance >= price;
}
```

### Обновить доход деревьев в game_models.dart

```dart
// ❌ СТАРЫЕ ЗНАЧЕНИЯ
rarityTable = <TreeRarity, RarityStats>{
  TreeRarity.common: RarityStats(
    income: 10000,
    caterpillarIntervalDays: 5,
  ),
  TreeRarity.legendary: RarityStats(
    income: 80000,
    caterpillarIntervalDays: 2,
  ),
  TreeRarity.mysterious: RarityStats(
    income: 300000,  // ⚠️ ВАУ, слишком много!
    caterpillarIntervalDays: 1,
  ),
};

// ✅ НОВЫЕ ЗНАЧЕНИЯ (сбалансированные)
rarityTable = <TreeRarity, RarityStats>{
  TreeRarity.common: RarityStats(
    income: 10000,
    waterConsumption: 4,
    caterpillarIntervalDays: 8,    // ← было 5
    baseWaterDays: 3,
    baseBirdDays: 6,
  ),
  TreeRarity.uncommon: RarityStats(
    income: 15000,                 // ← было 16000
    waterConsumption: 5,
    caterpillarIntervalDays: 6,    // ← было 4
    baseWaterDays: 2,
    baseBirdDays: 5,
  ),
  TreeRarity.rare: RarityStats(
    income: 22000,                 // ← было 25000
    waterConsumption: 6,
    caterpillarIntervalDays: 5,    // ← было 3
    baseWaterDays: 1,
    baseBirdDays: 4,
  ),
  TreeRarity.epic: RarityStats(
    income: 35000,                 // ← было 50000 (35%)
    waterConsumption: 8,           // ← было 7 (+1)
    caterpillarIntervalDays: 4,    // ← было 2
    baseWaterDays: 0.5,
    baseBirdDays: 3,
  ),
  TreeRarity.legendary: RarityStats(
    income: 55000,                 // ← было 80000 (31%)
    waterConsumption: 10,          // ← было 8 (+2)
    caterpillarIntervalDays: 3,    // ← было 2
    baseWaterDays: 0.25,
    baseBirdDays: 2,
  ),
  TreeRarity.mysterious: RarityStats(
    income: 85000,                 // ← было 300000 (72% снижение!)
    waterConsumption: 12,          // ← было 10 (+2)
    caterpillarIntervalDays: 2,    // ← было 1
    baseWaterDays: 0.125,
    baseBirdDays: 1,
  ),
};
```

---

## 6. ДОБАВЛЕНИЕ МИКРО-АНИМАЦИЙ (1.3)

### Улучшенная _SmallCareButton

```dart
class _SmallCareButton extends StatefulWidget {
  final String label, price, careCode;
  final void Function(String) onAction;
  final bool enabled;

  const _SmallCareButton(
    this.label,
    this.price,
    this.careCode,
    this.onAction,
    {this.enabled = true},
  );

  @override
  State<_SmallCareButton> createState() => _SmallCareButtonState();
}

class _SmallCareButtonState extends State<_SmallCareButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _tapController;
  late Animation<double> _tapAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _tapAnimation = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _tapController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _onTapDown() {
    if (!widget.enabled) return;
    _tapController.forward();
    setState(() => _isPressed = true);
  }

  void _onTapUp() {
    _tapController.reverse();
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    _tapController.reverse();
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: _onTapCancel,
      onTap: widget.enabled ? () => widget.onAction(widget.careCode) : null,
      child: ScaleTransition(
        scale: _tapAnimation,
        child: SizedBox(
          width: 70,
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: widget.enabled
                  ? (widget.price.startsWith('Из запаса')
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFF1A2A1A))
                  : const Color(0xFF111214),
              border: Border.all(
                color: const Color(0xFF7CFC6E).withOpacity(0.5),
              ),
              boxShadow: _isPressed && widget.enabled
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7CFC6E).withOpacity(0.8),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: widget.enabled ? AppTheme.text : AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.price,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: widget.enabled ? AppTheme.gold : AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 7. ДОБАВЛЕНИЕ GLASS-МОРФИЗМА (1.5)

### Обновленный ActionPanel с BackdropFilter

```dart
import 'dart:ui' as ui;

class ActionPanel extends StatelessWidget {
  const ActionPanel({
    super.key,
    required this.tree,
    required this.game,
    required this.onAction,
    required this.onClose,
    required this.audioService,
  });

  final TreeModel tree;
  final GameEngine game;
  final void Function(String action) onAction;
  final VoidCallback onClose;
  final AudioService audioService;

  @override
  Widget build(BuildContext context) {
    final stats = tree.stats;

    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),  // ← Стеклянный эффект
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 240,
        decoration: BoxDecoration(
          color: AppTheme.panel.withOpacity(0.75),  // ← Снизить непрозрачность на 20%
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
          border: Border.all(color: stats.color.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 20,
              offset: const Offset(-4, 0),
            ),
            ...AppTheme.neonGlow(stats.color, blur: 12),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... остальной UI ...
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 8. ПУЛЬСИРУЮЩИЕ СТАТУСЫ (1.7)

### Обновленный _StatusBadge

```dart
class _StatusBadge extends StatefulWidget {
  final String emoji;
  final Color glow;

  const _StatusBadge({required this.emoji, required this.glow});

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.5),
          boxShadow: [
            ...AppTheme.neonGlow(widget.glow, blur: 10),
            BoxShadow(
              color: widget.glow.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(widget.emoji, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
```

---

## 9. СИСТЕМА УРОВНЕЙ (2.4)

### Новый файл: lib/models/player_progress.dart

```dart
import 'dart:math';

class PlayerProgress {
  int level = 1;
  double experience = 0;
  
  double get expToNextLevel => 1000 * pow(1.15, level - 1).toDouble();
  double get expProgress => (experience / expToNextLevel).clamp(0.0, 1.0);
  
  // Бонусы по уровню
  double get incomeMultiplier {
    if (level >= 15) return 1.50;
    if (level >= 10) return 1.25;
    if (level >= 5) return 1.10;
    return 1.0;
  }
  
  double get growthSpeedMultiplier {
    if (level >= 20) return 1.35;
    if (level >= 15) return 1.25;
    if (level >= 10) return 1.15;
    return 1.0;
  }
  
  bool get canUseMysteryTrees => level >= 15;
  
  void addExperience(double amount) {
    experience += amount;
    
    while (experience >= expToNextLevel) {
      experience -= expToNextLevel;
      level++;
    }
  }
  
  Map<String, dynamic> toJson() => {
    'level': level,
    'experience': experience,
  };
  
  static PlayerProgress fromJson(Map<String, dynamic> json) {
    return PlayerProgress()
      ..level = json['level'] ?? 1
      ..experience = (json['experience'] ?? 0).toDouble();
  }
}
```

### Использование в GameEngine

```dart
class GameEngine extends ChangeNotifier {
  late PlayerProgress playerProgress;
  
  GameEngine() {
    playerProgress = PlayerProgress();
  }
  
  void harvestTree(String treeId) {
    final tree = trees.firstWhere((t) => t.id == treeId);
    
    // Базовый доход с бонусом за уровень
    final baseIncome = tree.rarity.stats.income;
    final totalIncome = (baseIncome * playerProgress.incomeMultiplier).toInt();
    
    wlntBalance += totalIncome;
    
    // Опыт
    final expReward = (tree.rarity.index + 1) * 100 + 50.0;
    playerProgress.addExperience(expReward);
    
    notifyListeners();
  }
}
```

---

## 10. ОБРАБОТКА ОШИБОК (5.3)

### Обновленный AuthScreen._submit()

```dart
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    final appState = context.read<AppState>();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final refCode = _refCtrl.text.trim();

    // Показать диалог загрузки
    _showLoadingDialog();

    if (_isLoginMode) {
      final success = await appState.login(email, password).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Время ожидания истекло');
        },
      );

      if (!mounted) return;
      Navigator.pop(context);  // Закрыть диалог

      if (success) {
        if (mounted) {
          widget.onLogin(email, refCode);
        }
      } else {
        _showError('Неверный email или пароль');
      }
    } else {
      final success = await appState.register(email, password, refCode).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Время ожидания истекло');
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        if (mounted) {
          widget.onLogin(email, refCode);
        }
      } else {
        _showError('Ошибка регистрации. Проверьте данные.');
      }
    }
  } on TimeoutException catch (e) {
    if (mounted) {
      Navigator.pop(context);
      _showError('Время ожидания истекло. Попробуйте позже.');
    }
    debugPrint('Timeout: $e');
  } on SocketException catch (e) {
    if (mounted) {
      Navigator.pop(context);
      _showError('Ошибка сети. Проверьте подключение.');
    }
    debugPrint('Network error: $e');
  } on FormatException catch (e) {
    if (mounted) {
      Navigator.pop(context);
      _showError('Некорректные данные.');
    }
    debugPrint('Format error: $e');
  } catch (e, stackTrace) {
    if (mounted) {
      Navigator.pop(context);
      _showError('Неизвестная ошибка. Попробуйте позже.');
    }
    debugPrintStack(stackTrace: stackTrace);
  }
}

void _showLoadingDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Dialog(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка...'),
          ],
        ),
      ),
    ),
  );
}

void _showError(String message) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
      duration: const Duration(seconds: 4),
    ),
  );
}
```

---

## 📋 ЧЕК-ЛИСТ ДЛЯ ВНЕДРЕНИЯ

- [ ] Шаг 1: Исправить setState() после dispose (код #2)
- [ ] Шаг 2: Исправить waterPercent (код #3)
- [ ] Шаг 3: Добавить CachedNetworkImage (код #4)
- [ ] Шаг 4: Обновить цены (код #5)
- [ ] Шаг 5: Протестировать новый баланс в 10+ прогонов
- [ ] Шаг 6: Добавить микро-анимации (код #6)
- [ ] Шаг 7: Добавить BackdropFilter (код #7)
- [ ] Шаг 8: Добавить пульсирующие статусы (код #8)
- [ ] Шаг 9: Добавить систему уровней (код #9)
- [ ] Шаг 10: Добавить обработку ошибок (код #10)

---

**Общее время внедрения:** 12–16 часов (2 полных дня разработки)

Начните с **шага 1–3** (3 часа), это даст наибольший эффект в плане стабильности.
