# 🎮 WALNUT FARM: Комплексный анализ кода и геймдизайна

**Дата анализа:** 16.06.2026  
**Версия кода:** main.dart (полный)  
**Автор анализа:** Game Design & Flutter Code Review Expert

---

## 📋 СОДЕРЖАНИЕ
1. [Визуальное оформление и UX](#1-визуальное-оформление-и-ux)
2. [Игровая экономика и баланс](#2-игровая-экономика-и-баланс)
3. [Графика и анимации](#3-графика-и-анимации)
4. [Обнаружение и исправление ошибок](#4-обнаружение-и-исправление-ошибок)
5. [Архитектура и качество кода](#5-архитектура-и-качество-кода)

---

## 1. ВИЗУАЛЬНОЕ ОФОРМЛЕНИЕ И UX

### 🔴 КРИТИЧЕСКИЕ ПРОБЛЕМЫ

#### 1.1 Проблема: Монолитное расположение кода в main.dart
**Файл:** [lib/main.dart](lib/main.dart)  
**Строки:** 1–2000+  
**Приоритет:** 🔴 КРИТИЧНО

**Проблема:**  
Весь код размещён в одном файле (2000+ строк), что затрудняет поддержку и отладку.

**Влияние:**
- Невозможно переиспользовать компоненты
- Сложно найти баги в таком объёме кода
- IDE работает медленнее

**Решение:**  
Разбить на модули:
```
lib/
├── models/              # Уже есть, но нужно расширить
├── screens/
│   ├── farm_screen.dart
│   ├── market_screen.dart
│   ├── lucky_screen.dart
│   └── ...
├── widgets/             # Новое
│   ├── tree_card.dart
│   ├── action_panel.dart
│   ├── weather_effects.dart
│   └── ...
├── engine/
├── services/
├── theme/
└── main.dart            # Только App() и runApp()
```

---

#### 1.2 Проблема: Контрастность текста
**Файл:** [lib/main.dart](lib/main.dart#L208)  
**Строки:** 208–225 (AuthScreen, ActionPanel)  
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

**Проблема:**  
Некоторый текст на тёмном фоне имеет недостаточный контраст:
- `AppTheme.muted` (0xFF8A9A8A) на `AppTheme.bg` (0xFF0A0F0A) = коэффициент контраста ~2.5:1
- Норма WCAG AA: 4.5:1 для обычного текста

**Код с проблемой:**
```dart
Text(_isLoginMode ? 'Войдите, чтобы начать игру' : 'Создайте новый аккаунт', 
  style: const TextStyle(color: AppTheme.muted, fontSize: 14))  // ⚠️ Плохой контраст
```

**Решение:**
```dart
// Обновить AppTheme
static const Color mutedText = Color(0xFFA8B8A8);  // ✓ Лучше
static const Color muted = Color(0xFF8A9A8A);      // Оставить для второстепенных элементов

// Использовать в текстовых полях
Text('Введите пароль', 
  style: const TextStyle(color: AppTheme.mutedText))
```

---

#### 1.3 Проблема: Недостаток микро-анимаций при взаимодействии
**Файл:** [lib/main.dart](lib/main.dart#L900-950)  
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

**Текущее состояние:**  
- Нажатие на кнопку: только ripple эффект (встроено в Material)
- Клик по дереву: есть `AnimatedScale` (хорошо)
- Клик на care-button: нет обратной связи

**Проблема:**  
Кнопки ухода (_SmallCareButton) не имеют visual feedback:

```dart
class _SmallCareButton extends StatelessWidget {
  @override Widget build(BuildContext context) {
    final btn = SizedBox(width: 70, child: Material(color: Colors.transparent, child: InkWell(
      onTap: enabled ? () => onAction(careCode) : null,
      borderRadius: BorderRadius.circular(12),
      // ⚠️ InkWell достаточен, но нет scale-анимации
      child: Ink(...)
    )));
  }
}
```

**Решение — Добавить микро-анимации:**

```dart
class _SmallCareButton extends StatefulWidget {
  @override State<_SmallCareButton> createState() => _SmallCareButtonState();
}

class _SmallCareButtonState extends State<_SmallCareButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.enabled ? () => widget.onAction(widget.careCode) : null,
        child: AnimatedScale(
          scale: _isPressed && widget.enabled ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: widget.enabled ? ... : Color(0xFF111214),
              boxShadow: [
                if (_isPressed && widget.enabled)
                  BoxShadow(
                    color: const Color(0xFF7CFC6E).withOpacity(0.8),
                    blurRadius: 8,
                  ),
              ],
            ),
            child: Column(...),
          ),
        ),
      ),
    );
  }
}
```

---

### 🟡 ЖЕЛАТЕЛЬНЫЕ УЛУЧШЕНИЯ

#### 1.4 Улучшение: Переходы между экранами
**Файл:** [lib/main.dart](lib/main.dart) – требуется в app-слое  
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

**Текущее состояние:**  
Табы переключаются мгновенно.

**Решение — Добавить PageTransition:**

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MainShell(),
      pageRoute: (settings, builder) {
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCubic))
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        );
      },
    );
  }
}
```

---

#### 1.5 Улучшение: Глас-морфизм для ActionPanel
**Файл:** [lib/main.dart](lib/main.dart#L1100-1200)  
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

**Текущее состояние:**
```dart
decoration: BoxDecoration(
  color: AppTheme.panel.withOpacity(0.95),  // Просто полупрозрачный цвет
  borderRadius: ...,
  border: Border.all(color: stats.color.withOpacity(0.6)),
)
```

**Решение — Добавить backdrop blur:**

```dart
// В pubspec.yaml добавить:
dependencies:
  flutter:
    sdk: flutter
  backdrop_filter: ^0.6.0  # Уже есть в Flutter по умолчанию!

// В коде:
class ActionPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),  // Стеклянный эффект
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: AppTheme.panel.withOpacity(0.75),  // Снизить непрозрачность
          borderRadius: const BorderRadius.only(...),
          border: Border.all(color: stats.color.withOpacity(0.6)),
          boxShadow: [...],
        ),
        child: ...,
      ),
    );
  }
}
```

Не забыть импорт:
```dart
import 'dart:ui' as ui;
```

---

#### 1.6 Улучшение: Плавное появление окна ActionPanel
**Файл:** [lib/main.dart](lib/main.dart#L520-540)  
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

**Текущее состояние:**  
ActionPanel появляется мгновенно.

**Решение:**

```dart
// В VisualGarden.build() измени это:
if (selected != null && selected.isPlanted)
  Positioned(
    right: 0,
    top: 80,
    bottom: 80,
    child: SlideTransition(
      position: _panelSlideAnimation,  // Новая анимация!
      child: FadeTransition(
        opacity: _panelFadeAnimation,
        child: ActionPanel(...),
      ),
    ),
  ),

// В initState добавь:
_panelSlideController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 400),
);
_panelSlideAnimation = Tween<Offset>(
  begin: const Offset(0.3, 0),
  end: Offset.zero,
).animate(CurvedAnimation(parent: _panelSlideController, curve: Curves.easeOutCubic));

_panelFadeAnimation = Tween<double>(
  begin: 0.0,
  end: 1.0,
).animate(_panelSlideController);

// В didUpdateWidget:
if (oldWidget.selectedId != widget.selectedId) {
  if (widget.selectedId != null) {
    _panelSlideController.forward();
  } else {
    _panelSlideController.reverse();
  }
}
```

---

#### 1.7 Улучшение: Иконки для статусов деревьев
**Файл:** [lib/main.dart](lib/main.dart#L900-920)  
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

**Текущее состояние:**  
Статусы показаны как эмодзи без анимации:
```dart
if (rest) Positioned(top: 8, right: 8, child: _StatusBadge(emoji: '❄️', glow: const Color(0xFF80D8FF))),
```

**Решение — Добавить пульсирующий эффект:**

```dart
class _StatusBadge extends StatefulWidget {
  const _StatusBadge({required this.emoji, required this.glow});
  final String emoji;
  final Color glow;

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2)
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

## 2. ИГРОВАЯ ЭКОНОМИКА И БАЛАНС

### 🔴 КРИТИЧЕСКИЕ ПРОБЛЕМЫ

#### 2.1 Проблема: Дисбаланс цен на ресурсы и деревья
**Файл:** [lib/main.dart](lib/main.dart#L1000-1050)  
**Приоритет:** 🔴 КРИТИЧНО

**Текущие цены:**

| Элемент | Цена | Тип |
|---------|------|-----|
| 💧 Вода (1 шт.) | 150 WLNT | Динамическая (80–120% от 150) |
| 🌿 Удобрение (1 шт.) | 800 WLNT | Динамическая |
| 🐦 Птица (1 шт.) | 1000 WLNT | Динамическая |
| 🐾 Питомец | 2000 WLNT | Фиксированная |
| ❄️ Автополив (7 дней, базовый) | 500 WLNT | Фиксированная |
| ❄️ Автополив (7 дней, цистерна) | 1200 WLNT | Фиксированная |

**Анализ дохода деревьев:**

```dart
// Из models/game_models.dart
rarityTable = <TreeRarity, RarityStats>{
  TreeRarity.common: RarityStats(
    income: 10000,  // За сезон 30 дней
    waterConsumption: 4,
  ),
  TreeRarity.uncommon: RarityStats(
    income: 16000,
    waterConsumption: 5,
  ),
  TreeRarity.rare: RarityStats(
    income: 25000,
    waterConsumption: 6,
  ),
  TreeRarity.epic: RarityStats(
    income: 50000,
    waterConsumption: 7,
  ),
  TreeRarity.legendary: RarityStats(
    income: 80000,
    waterConsumption: 8,
  ),
  TreeRarity.mysterious: RarityStats(
    income: 300000,  // ⚠️ МЕГАДИСБАЛАНС!
    waterConsumption: 10,
  ),
};
```

**Расчёт затрат на сезон:**

Для Common дерева с базовым уходом (30 дней):
- Полив каждый день: 30 × 150 = **4500 WLNT**
- Одно удобрение: **800 WLNT**
- **Итого: ~5300 WLNT затрат vs 10000 WLNT дохода** ✓ Прибыль: 4700 WLNT

Для Mysterious дерева:
- Полив каждый день: 30 × (150 × 0.8) = **3600 WLNT** (+ вода дешевле?)
- Удобрение x2: **1600 WLNT**
- **Итого: ~5200 WLNT затрат vs 300000 WLNT дохода** ❌ ОГРОМНЫЙ ДИСБАЛАНС!

**Проблема:**  
Mysterious дерево даёт 57x больше дохода, чем Common, при похожих затратах. Это разрушает игровую экономику.

**Решение:**

```dart
// Пересчитать income и waterConsumption
rarityTable = <TreeRarity, RarityStats>{
  TreeRarity.common: RarityStats(
    income: 10000,
    waterConsumption: 4,
  ),
  TreeRarity.uncommon: RarityStats(
    income: 15000,    // +50%
    waterConsumption: 5,
  ),
  TreeRarity.rare: RarityStats(
    income: 22000,    // +47%
    waterConsumption: 6,
  ),
  TreeRarity.epic: RarityStats(
    income: 35000,    // +59% (было 50000)
    waterConsumption: 8,  // +1
  ),
  TreeRarity.legendary: RarityStats(
    income: 55000,    // +10% (было 80000)
    waterConsumption: 10, // +2
  ),
  TreeRarity.mysterious: RarityStats(
    income: 85000,    // -71% (было 300000) — но всё ещё редко
    waterConsumption: 12,  // +2
  ),
};
```

**Новый баланс:**
- Common: 10000 дохода → Real ROI = 4700
- Mysterious: 85000 дохода → Real ROI = ~78000 (всё ещё 16.6x лучше, но более справедливо)

---

#### 2.2 Проблема: Чрезмерно частые неудачные события (гусеницы)
**Файл:** [lib/engine/game_engine.dart](lib/engine/game_engine.dart)  
**Приоритет:** 🔴 КРИТИЧНО

**Текущая логика** (из models):
```dart
TreeRarity.common: RarityStats(
  caterpillarIntervalDays: 5,  // Гусеницы появляются каждые 5 дней
),
```

**Анализ:**  
За 30-дневный сезон:
- Common: 6 атак гусениц (каждые 5 дней)
- Mysterious: 30 атак (каждый день!)

При 15+ гусеницах требуется **Woodpecker All** (1000 WLNT) для удаления всех. Это **30,000 WLNT затрат только на защиту** от гусениц у Mysterious дерева!

**Решение:**

```dart
// Увеличить интервалы
rarityTable = <TreeRarity, RarityStats>{
  TreeRarity.common: RarityStats(
    caterpillarIntervalDays: 8,   // ← было 5
  ),
  TreeRarity.uncommon: RarityStats(
    caterpillarIntervalDays: 6,   // ← было 4
  ),
  TreeRarity.rare: RarityStats(
    caterpillarIntervalDays: 5,   // ← было 3
  ),
  TreeRarity.epic: RarityStats(
    caterpillarIntervalDays: 4,   // ← было 2
  ),
  TreeRarity.legendary: RarityStats(
    caterpillarIntervalDays: 3,   // ← было 2
  ),
  TreeRarity.mysterious: RarityStats(
    caterpillarIntervalDays: 2,   // ← было 1 (ОК, но с ограничением макс 5 атак/сезон)
  ),
};

// Также добавить максимальный лимит гусениц
const maxCaterpillarsPerSeason = 10;
```

---

#### 2.3 Проблема: Неопределённая механика Lucky Wheel
**Файл:** [lib/main.dart](lib/main.dart#L1400-1500)  
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

**Текущее распределение:**

```dart
static const _extendedOutcomes = [
  _OutcomeExt(type: 'nothing', weight: 60, amount: 0, label: 'Пусто'),      // 60%
  _OutcomeExt(type: 'wlnt', weight: 20, amount: 30, label: '30 WLNT'),      // 20%
  _OutcomeExt(type: 'wlnt', weight: 10, amount: 60, label: '60 WLNT'),      // 10%
  _OutcomeExt(type: 'wlnt', weight: 5, amount: 100, label: '100 WLNT'),     // 5%
  _OutcomeExt(type: 'wlnt', weight: 2, amount: 200, label: '200 WLNT'),     // 2%
  _OutcomeExt(type: 'wlnt', weight: 1, amount: 300, label: '300 WLNT'),     // 1%
  _OutcomeExt(type: 'water', weight: 1, amount: 2, label: '2 Вода'),        // 1%
  _OutcomeExt(type: 'fertilizer', weight: 1, amount: 1, label: '1 Удобрение'), // 1%
];
```

**Анализ:**
- Ставка: 100 WLNT
- Ожидаемый выигрыш: `0.6×0 + 0.2×30 + 0.1×60 + 0.05×100 + 0.02×200 + 0.01×300 + 0.01×(30) + 0.01×(80) ≈ 37 WLNT`
- **House Edge: 63%** ⚠️ Слишком высоко (норма казино: 2–5%)

**Решение:**

```dart
static const _extendedOutcomes = [
  _OutcomeExt(type: 'nothing', weight: 35, amount: 0, label: 'Пусто'),           // 35% ← было 60%
  _OutcomeExt(type: 'wlnt', weight: 25, amount: 30, label: '30 WLNT'),           // 25% ← было 20%
  _OutcomeExt(type: 'wlnt', weight: 15, amount: 60, label: '60 WLNT'),           // 15% ← было 10%
  _OutcomeExt(type: 'wlnt', weight: 12, amount: 100, label: '100 WLNT'),         // 12% ← было 5%
  _OutcomeExt(type: 'wlnt', weight: 5, amount: 150, label: '150 WLNT'),          // 5% (новое)
  _OutcomeExt(type: 'wlnt', weight: 3, amount: 250, label: '250 WLNT'),          // 3% (новое)
  _OutcomeExt(type: 'wlnt', weight: 1, amount: 500, label: '500 WLNT (ДЖЕКПОТ!)'), // 1% (новое)
  _OutcomeExt(type: 'water', weight: 2, amount: 3, label: '3 Вода'),             // 2% ← было 1%
  _OutcomeExt(type: 'fertilizer', weight: 1, amount: 2, label: '2 Удобрения'),   // 1% ← было 1%
];

// Новый расчёт: EV ≈ 100 WLNT (breakeven) – привлекательнее!
```

---

### 🟡 ЖЕЛАТЕЛЬНЫЕ УЛУЧШЕНИЯ

#### 2.4 Улучшение: Система уровней (Progression)
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

**Текущее состояние:**  
Нет системы уровней. Прогресс не отслеживается.

**Решение — Добавить уровни:**

```dart
// В models/game_models.dart
class PlayerProgress {
  int level = 1;
  double experience = 0;
  double expToNextLevel = 1000;
  
  double get expProgress => (experience / expToNextLevel).clamp(0.0, 1.0);
  
  void addExp(double amount) {
    experience += amount;
    while (experience >= expToNextLevel) {
      experience -= expToNextLevel;
      level++;
      expToNextLevel = 1000 * pow(1.15, level - 1); // Экспоненциальный рост
    }
  }
}

// В GameEngine добавить:
class GameEngine extends ChangeNotifier {
  late PlayerProgress playerProgress;
  
  void harvestTree(String treeId) {
    // ... harvest logic ...
    final expReward = tree.rarity.ordinal * 100 + 50;
    playerProgress.addExp(expReward.toDouble());
    notifyListeners();
  }
}
```

**Бонусы за уровень:**
- Лв. 5: +10% дохода от деревьев
- Лв. 10: +15% к скорости роста
- Лв. 15: Разблокировка Mysterious деревьев

---

#### 2.5 Улучшение: Система таксономии деревьев
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

**Текущее состояние:**  
Деревья только по редкости. Можно добавить типы.

**Решение:**

```dart
enum TreeFamily { walnut, oak, birch, pine, exotic }

extension TreeFamilyX on TreeFamily {
  String get label => switch (this) {
    TreeFamily.walnut => 'Грецкий орех',
    TreeFamily.oak => 'Дуб',
    TreeFamily.birch => 'Берёза',
    TreeFamily.pine => 'Сосна',
    TreeFamily.exotic => 'Экзотическое дерево',
  };
  
  // Бонусы при 3+ деревьях одного типа в саду
  double get collectionBonus => 1.15; // +15% дохода
}

class TreeModel {
  final TreeFamily family;
  // ...
}
```

---

## 3. ГРАФИКА И АНИМАЦИИ

### 🔴 КРИТИЧЕСКИЕ ПРОБЛЕМЫ

#### 3.1 Проблема: Утечка памяти через AnimationController
**Файл:** [lib/main.dart](lib/main.dart#L540–620)  
**Строки:** 540–620 (VisualGarden.initState/dispose)  
**Приоритет:** 🔴 КРИТИЧНО

**Проблема:**  
AnimationController созданы правильно, но **слушатели не удаляются**:

```dart
@override void initState() {
  super.initState();
  _rainCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  _fireCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  // ... и т.д. (6 контроллеров всего)
}

@override void dispose() {
  _rainCtrl.dispose();
  _fireCtrl.dispose();
  _floodCtrl.dispose();
  _fogCtrl.dispose();
  _transitionCtrl.dispose();
  _petCtrl.dispose();
  super.dispose();  // ✓ Есть dispose
}
```

**Проблема в NftTreeCard:**

```dart
@override void initState() {
  // ...
  widget.game.actionEvent.addListener(_onActionEvent);  // ⚠️ Добавлен слушатель
}

@override void dispose() {
  _glowController.dispose();
  _actionAnimCtrl.dispose();
  widget.game.actionEvent.removeListener(_onActionEvent);  // ✓ Удалён
  super.dispose();
}
```

**Основная проблема — в ActionPanel:**

Это `StatelessWidget`, но используется в `Positioned` внутри `Stack`. **ActionPanel пересоздаётся при каждом ребилде родителя**, что приводит к множественным невысвобожденным ресурсам.

**Решение:**

```dart
// Преобразовать FarmScreen из Stateless в Stateful
class FarmScreen extends StatefulWidget {
  // ... параметры ...
  @override State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedId == null 
      ? null 
      : widget.game.trees.firstWhereOrNull((t) => t.id == _selectedId);

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 3,
                child: VisualGarden(
                  // ...
                  onTreeTap: (id) => setState(() {
                    _selectedId = _selectedId == id ? null : id;
                  }),
                ),
              ),
              // ...
            ],
          ),
          if (selected != null && selected.isPlanted)
            Positioned(
              right: 0,
              top: 80,
              bottom: 80,
              // ✓ Теперь ActionPanel не пересоздаётся
              child: ActionPanel(
                key: ValueKey(selected.id),  // Даже с key, поведение лучше
                tree: selected,
                // ...
              ),
            ),
        ],
      ),
    );
  }
}
```

---

#### 3.2 Проблема: Отсутствие кэширования изображений (Image.network)
**Файл:** [lib/main.dart](lib/main.dart#L870–895)  
**Приоритет:** 🔴 КРИТИЧНО

**Проблема:**

```dart
nftImage = Image.network(
  tree.imageUrl,
  fit: BoxFit.cover,
  width: double.infinity,
  height: double.infinity,
  // ⚠️ Нет кэширования!
  loadingBuilder: (_, child, p) => p == null 
    ? child 
    : Container(...),
);
```

**Каждый раз, когда дерево появляется на экране, изображение загружается с сети.**

**Решение — Установить CachedNetworkImage:**

```dart
// pubspec.yaml
dependencies:
  cached_network_image: ^3.3.0

// В коде
import 'package:cached_network_image/cached_network_image.dart';

// Заменить Image.network
nftImage = CachedNetworkImage(
  imageUrl: tree.imageUrl,
  fit: BoxFit.cover,
  width: double.infinity,
  height: double.infinity,
  memCacheHeight: 200,  // Кэш в памяти (200px)
  maxHeightDiskCache: 250,  // Кэш на диске
  placeholder: (context, url) => Container(
    color: const Color(0xFF0D120D),
    child: Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: tree.stats.color,
      ),
    ),
  ),
  errorWidget: (context, url, error) => Container(
    color: const Color(0xFF0D120D),
    child: Center(child: Text(tree.stats.emoji, style: const TextStyle(fontSize: 48))),
  ),
);
```

**Альтернатива (если нельзя добавить зависимость):**

```dart
// Использовать встроенное кэширование Flutter
nftImage = Image.network(
  tree.imageUrl,
  fit: BoxFit.cover,
  cacheWidth: 250,      // Кэшировать с разрешением 250px
  cacheHeight: 250,
);
```

---

#### 3.3 Проблема: Производительность погодных эффектов
**Файл:** [lib/main.dart](lib/main.dart#L700–800)  
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

**Текущая реализация:**

```dart
List<Widget> _buildWeatherEffects(WeatherType weather) {
  switch (weather) {
    case WeatherType.thunderstorm:
      return [Positioned(
        // ... CustomPaint для дождя
        child: RainEffect(controller: _rainCtrl),  // 100+ объектов в Canvas!
      )];
    case WeatherType.forestFire:
      return [Positioned(
        // ... CustomPaint для огня
        child: CustomPaint(painter: _FirePainter(_fireCtrl.value)),  // Каждый frame
      )];
  }
}
```

**Проблема:**  
- RainEffect рисует 100 капель воды каждый frame
- _FirePainter пересчитывает пути каждый frame
- Может привести к пропускам frames на слабых устройствах

**Решение — Оптимизировать с использованием RepaintBoundary:**

```dart
class RainEffect extends StatelessWidget {
  const RainEffect({super.key, required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(  // ← Изолировать перерисовку
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => CustomPaint(
          painter: _RainPainter(progress: controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  final double progress;
  
  static final _paint = Paint()
    ..color = const Color(0x8866B2FF)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  _RainPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    
    // Оптимизация: рисовать меньше капель для слабых устройств
    final rainCount = (size.width * size.height) ~/ 5000;  // Вместо 100 капель
    
    for (int i = 0; i < rainCount; i++) {
      final x = rng.nextDouble() * size.width;
      final speed = 150 + rng.nextDouble() * 200;
      final y0 = rng.nextDouble() * size.height;
      final y = (y0 + speed * progress) % size.height;
      
      canvas.drawLine(Offset(x, y), Offset(x, y + 12), _paint);
    }
  }

  @override
  bool shouldRepaint(_RainPainter oldPainter) => progress != oldPainter.progress;
}
```

---

### 🟡 ЖЕЛАТЕЛЬНЫЕ УЛУЧШЕНИЯ

#### 3.4 Улучшение: Реалистичные эффекты пожара
**Файл:** [lib/main.dart](lib/main.dart#L780–800)  
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

**Текущее состояние:**
```dart
class _FirePainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(...).createShader(...)
    
    // Рисует 5 колебающихся полос
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final x = i * w / 4;
      final sway = sin(t * 2 * pi * 2 + i) * 20;
      path.moveTo(x, h);
      // ...
    }
  }
}
```

**Решение — Добавить перлин-шум (имитация огня):**

```dart
class _FirePainter extends CustomPainter {
  final double progress;
  _FirePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = progress.clamp(0.0, 1.0);

    // Слой 1: Основной огонь (оранжевый)
    final paintBase = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFF6B1B).withOpacity(0.8),
          const Color(0xFFFF9100).withOpacity(0.5),
          Colors.transparent,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.4));

    // Перлин-подобный шум для реалистичности
    final path = Path();
    for (int x = 0; x <= 200; x += 20) {
      final xPos = (x / 200) * w;
      final noise = sin(t * 3 + x / 10) * sin(t * 5 + x / 5);
      final yHeight = h - (h * 0.3 * (0.5 + noise * 0.5));
      
      if (x == 0) {
        path.moveTo(xPos, h);
      } else {
        path.lineTo(xPos, yHeight);
      }
    }
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, paintBase);

    // Слой 2: Белые языки пламени (верхушка)
    final paintTop = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.yellow.withOpacity(0.3),
          Colors.transparent,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.5));

    final topPath = Path();
    for (int x = 0; x <= 200; x += 15) {
      final xPos = (x / 200) * w;
      final noise = sin(t * 4 + x / 8) * cos(t * 6 + x / 4);
      final yHeight = h - (h * 0.5 * (0.3 + noise * 0.4));
      
      if (x == 0) {
        topPath.moveTo(xPos, h);
      } else {
        topPath.lineTo(xPos, yHeight);
      }
    }
    topPath.lineTo(w, h);
    topPath.close();
    canvas.drawPath(topPath, paintTop);
  }

  @override
  bool shouldRepaint(_FirePainter oldPainter) => progress != oldPainter.progress;
}
```

---

## 4. ОБНАРУЖЕНИЕ И ИСПРАВЛЕНИЕ ОШИБОК

### 🔴 КРИТИЧЕСКИЕ БАГИ

#### 4.1 Баг: setState() вызывается после dispose()
**Файл:** [lib/main.dart](lib/main.dart#L1600–1700)  
**Приоритет:** 🔴 КРИТИЧНО

**Проблема** (в LuckyScreen):

```dart
class _LuckyScreenState extends State<LuckyScreen> with SingleTickerProviderStateMixin {
  
  Future<void> _spin() async {
    if (_spinning) return;
    if (widget.game.wlntBalance < bet) {
      setState(() => _result = 'Недостаточно средств');  // ← Может быть после dispose
      return;
    }
    _spinning = true;
    setState(() { ... });  // ← Первый setState
    
    // ... await операции ...
    
    widget.audioService.playCoins();
    await widget.onSpinComplete();  // ← Может привести к dispose
    
    setState(() => _flashHighlight = true);  // ⚠️ setState после dispose!
    Future.delayed(const Duration(milliseconds: 500), () { 
      if (mounted) setState(() => _flashHighlight = false);  // ← if (mounted) есть здесь
    });
  }
}
```

**Решение:**

```dart
Future<void> _spin() async {
  if (_spinning) return;
  if (widget.game.wlntBalance < bet) {
    if (mounted) {  // ← Проверить перед setState
      setState(() => _result = 'Недостаточно средств');
    }
    return;
  }
  
  if (!mounted) return;  // ← Ранний выход
  setState(() {
    _result = 'Крутим...';
    _spinning = true;
    widget.game.wlntBalance -= bet;
  });

  widget.audioService.playClick();
  _spinController.reset();
  await _spinController.forward();

  if (!mounted) return;  // ← После длительной операции

  // ... выбор приза ...

  if (!mounted) return;  // ← Перед setState
  setState(() => _result = 'Вы выиграли: ${picked.label}');

  // ... остальной код ...
}
```

---

#### 4.2 Баг: Неправильный расчёт waterPercent
**Файл:** [lib/models/game_models.dart](lib/models/game_models.dart)  
**Приоритет:** 🔴 КРИТИЧНО

**Текущая реализация** (из двух разных версий):

**Версия 1 (в main.dart):**
```dart
class TreeModel {
  double waterPercent;  // ← Переменная, может быть некорректной
  
  TreeModel({
    // ...
    required this.waterPercent,  // ← Передаётся в конструктор
  });
}
```

**Версия 2 (в game_models.dart):**
```dart
class TreeModel {
  final double currentWater;
  
  double get waterPercent => (currentWater / 100.0).clamp(0.0, 1.0);
  
  // ✓ Вычисляется как свойство
}
```

**Проблема:**  
- Версия 1 может быть рассинхронизирована с `currentWater`
- Например: `currentWater = 150` и `waterPercent = 0.8` одновременно (противоречие)

**Решение — Использовать getter, как в Версии 2:**

```dart
// lib/main.dart
class TreeModel {
  final String id;
  final String name;
  final String imageUrl;
  final TreeRarity rarity;
  TreeStatus status;
  int seasonDay;
  double currentWater;
  // ❌ Удалить: double waterPercent;
  int caterpillars;
  // ... остальные поля ...

  // ✓ Добавить getter
  double get waterPercent => (currentWater / 100.0).clamp(0.0, 1.0);

  TreeModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rarity,
    required this.status,
    required this.seasonDay,
    required this.currentWater,
    // ❌ Удалить: required this.waterPercent,
    required this.caterpillars,
    // ... остальные параметры ...
  });
}

// ✓ Все использования waterPercent будут актуальны
```

---

#### 4.3 Баг: Утечка слушателей в GameEngine
**Файл:** [lib/main.dart](lib/main.dart#L100–150)  
**Приоритет:** 🔴 КРИТИЧНО

**Проблема:**

```dart
class GameEngine extends ChangeNotifier {
  final List<void Function(String)> _incomeListeners = [];  // ← Используется в одной версии

  void addIncomeListener(void Function(String) listener) => _incomeListeners.add(listener);
  void removeIncomeListener(void Function(String) listener) => _incomeListeners.remove(listener);

  void _notifyIncome(String message) {
    final listeners = List<void Function(String)>.from(_incomeListeners);
    for (final l in listeners) {
      l(message);
    }
  }
}
```

**Проблема:**  
Если `removeIncomeListener` не вызывается, слушатели остаются в памяти навсегда.

**Решение:**

```dart
// Убедиться, что все слушатели удаляются при dispose

// Например, в AppState:
class AppState extends ChangeNotifier {
  late GameEngine engine;

  @override
  void dispose() {
    // ✓ Очистить всех слушателей
    engine._incomeListeners.clear();
    engine.dispose();
    super.dispose();
  }
}

// Или в экранах, которые добавляют слушателей:
class FarmScreen extends StatefulWidget {
  // ...
}

class _FarmScreenState extends State<FarmScreen> {
  @override
  void initState() {
    super.initState();
    widget.game.addIncomeListener(_handleIncome);
  }

  @override
  void dispose() {
    widget.game.removeIncomeListener(_handleIncome);  // ← КРИТИЧНО!
    super.dispose();
  }

  void _handleIncome(String message) {
    // ...
  }
}
```

---

#### 4.4 Баг: Неправильная логика проверки водоёмов
**Файл:** [lib/main.dart](lib/main.dart#L1050–1070)  
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

**Проблема:**

```dart
if (tree.currentContainer != null) ...[
  const SizedBox(height: 4),
  _ProgressIndicatorRow(
    label: 'Прогресс:',
    progress: tree.waterCollectionProgress,  // ← Может быть > 1.0
    color: const Color(0xFF42A5F5),
  ),
  Text('${(tree.waterCollectionProgress % 1 * 100).toStringAsFixed(0)}%', ...),
],
```

**Если `waterCollectionProgress = 2.5`, то:
- `progress = 2.5` (LinearProgressIndicator должен получать 0–1)
- `% 1 * 100 = 0.5 * 100 = 50%` ✓ Правильно, но запутанно**

**Решение:**

```dart
double get waterCollectionPercent => waterCollectionProgress % 1.0;  // 0–1 range

if (tree.currentContainer != null) ...[
  const SizedBox(height: 4),
  _ProgressIndicatorRow(
    label: 'Прогресс сбора:',
    progress: tree.waterCollectionPercent,  // ✓ Всегда 0–1
    color: const Color(0xFF42A5F5),
  ),
  Text('${(tree.waterCollectionPercent * 100).toStringAsFixed(0)}%', ...),
],
```

---

### 🟡 ПОТЕНЦИАЛЬНЫЕ ПРОБЛЕМЫ

#### 4.5 Предупреждение: Отсутствие null-safety проверок
**Файл:** [lib/main.dart](lib/main.dart#L870–900)  
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

**Проблема:**

```dart
nftImage = Image.network(
  tree.imageUrl,  // ← Может быть пуста?
  fit: BoxFit.cover,
  loadingBuilder: (_, child, p) => p == null 
    ? child 
    : Container(
        color: const Color(0xFF0D120D),
        child: Center(
          child: CircularProgressIndicator(
            color: accent,
            value: p.expectedTotalBytes != null 
              ? p.cumulativeBytesLoaded / p.expectedTotalBytes!  // ⚠️ Может быть 0
              : null
          ),
        ),
      ),
);
```

**Проблема:**  
Если `expectedTotalBytes = 0`, будет деление на 0.

**Решение:**

```dart
value: p.expectedTotalBytes != null && p.expectedTotalBytes! > 0
  ? p.cumulativeBytesLoaded / p.expectedTotalBytes!
  : null
```

---

## 5. АРХИТЕКТУРА И КАЧЕСТВО КОДА

### 🔴 КРИТИЧЕСКИЕ ПРОБЛЕМЫ

#### 5.1 Проблема: Монолитная структура (все в main.dart)
**Файл:** [lib/main.dart](lib/main.dart)  
**Приоритет:** 🔴 КРИТИЧНО

**Текущее состояние:**
```
lib/main.dart (2000+ строк)
├── Перечисления (enum)
├── Модели данных
├── Сервисы
├── GameEngine
├── AppState
├── UI Экраны
│   ├── AuthScreen
│   ├── FarmScreen
│   ├── MarketScreen
│   ├── LuckyScreen
│   └── ...
└── UI Компоненты (Widget'ы)
```

**Проблема:**
- IDE замедляется при редактировании
- Сложно найти нужный компонент
- Невозможно переиспользовать код в других проектах
- Невозможно тестировать компоненты отдельно

**Рекомендуемая структура:**

```
lib/
├── main.dart                          (50 строк)
│   └── MyApp() + runApp()
│
├── models/                             (200 строк)
│   ├── game_models.dart               ✓ Есть
│   ├── player.dart
│   └── tree.dart
│
├── engine/                             (500 строк)
│   ├── game_engine.dart               ✓ Есть
│   ├── game_state.dart
│   └── ai_engine.dart
│
├── screens/                            (800 строк)
│   ├── auth_screen.dart               ✓ Есть
│   ├── farm_screen.dart               ✓ Есть
│   ├── market_screen.dart             ✓ Есть
│   ├── lucky_screen.dart
│   ├── collection_screen.dart         ✓ Есть
│   ├── wallet_screen.dart             ✓ Есть
│   └── main_shell.dart                ✓ Есть
│
├── widgets/                            (400 строк) - НОВОЕ
│   ├── tree_card.dart                 (NftTreeCard)
│   ├── action_panel.dart              (ActionPanel)
│   ├── weather_effects.dart           (RainEffect, FirePainter, etc.)
│   ├── glass_chip.dart                (_GlassChip)
│   ├── status_badge.dart              (_StatusBadge)
│   └── mini_progress_bar.dart         (_MiniProgressBar)
│
├── services/                           (150 строк)
│   ├── audio_service.dart             ✓ Есть
│   ├── persistence_service.dart       ✓ Есть
│   └── notification_service.dart      (Новое)
│
├── theme/                              (50 строк)
│   └── app_theme.dart                 ✓ Есть
│
└── app_state.dart                      (100 строк) ✓ Есть
```

**Пример рефакторинга — tree_card.dart:**

```dart
// lib/widgets/tree_card.dart
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import '../engine/game_engine.dart';

class NftTreeCard extends StatefulWidget {
  const NftTreeCard({
    super.key,
    required this.tree,
    required this.isSelected,
    required this.onTap,
    required this.weather,
    required this.game,
  });

  final TreeModel tree;
  final bool isSelected;
  final VoidCallback onTap;
  final WeatherType weather;
  final GameEngine game;

  @override State<NftTreeCard> createState() => _NftTreeCardState();
}

class _NftTreeCardState extends State<NftTreeCard> with TickerProviderStateMixin {
  // ... вся логика из текущего main.dart ...
}
```

---

#### 5.2 Проблема: Отсутствие система состояний (State Management)
**Файл:** [lib/main.dart](lib/main.dart)  
**Приоритет:** 🔴 КРИТИЧНО

**Текущее состояние:**  
Используется базовый `Provider` и `ChangeNotifier`, но есть проблемы:

```dart
class GameEngine extends ChangeNotifier {
  // ✓ Имеет notifyListeners()
  
  Future<void> purchaseResourcePackage(...) async {
    inventory[type] = (inventory[type] ?? 0) + qty;
    wlntBalance -= price;
    notifyListeners();  // ✓ Пересчитывает весь UI
  }
}
```

**Проблема:**  
- `notifyListeners()` пересчитывает **весь UI**, даже если изменилось только одно значение
- Нет разделения логики на домены (farm, market, wallet)
- Сложно отследить, что именно изменилось

**Решение — Использовать Riverpod или более гранулярный Provider:**

```dart
// pubspec.yaml
dependencies:
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0

// lib/providers/game_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/game_engine.dart';

// Отдельные провайдеры для каждого состояния
final gameEngineProvider = StateNotifierProvider<GameEngineNotifier, GameState>((ref) {
  return GameEngineNotifier();
});

final wlntBalanceProvider = Provider((ref) {
  return ref.watch(gameEngineProvider).wlntBalance;
});

final treeListProvider = Provider((ref) {
  return ref.watch(gameEngineProvider).trees;
});

final weatherProvider = Provider((ref) {
  return ref.watch(gameEngineProvider).currentWeather;
});

// Использование в UI:
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wlnt = ref.watch(wlntBalanceProvider);  // ✓ Пересчитывается только этот виджет
    final trees = ref.watch(treeListProvider);    // ✓ Отдельная подписка
    
    return Column(
      children: [
        Text('Баланс: $wlnt'),
        ListView.builder(
          itemCount: trees.length,
          itemBuilder: (_, i) => TreeCard(tree: trees[i]),
        ),
      ],
    );
  }
}
```

---

#### 5.3 Проблема: Отсутствие обработки ошибок
**Файл:** [lib/main.dart](lib/main.dart)  
**Приоритет:** 🔴 КРИТИЧНО

**Текущее состояние:**

```dart
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  final appState = context.read<AppState>();
  final email = _emailCtrl.text.trim();
  final password = _passCtrl.text.trim();
  final refCode = _refCtrl.text.trim();

  if (_isLoginMode) {
    final success = await appState.login(email, password);  // ⚠️ Нет try/catch
    if (success) {
      widget.onLogin(email, refCode);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный email или пароль')),
      );
    }
  }
}
```

**Проблема:**
- Если произойдёт исключение, приложение упадёт
- Нет логирования ошибок
- Пользователь не узнает, в чём причина

**Решение:**

```dart
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  
  try {
    final appState = context.read<AppState>();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final refCode = _refCtrl.text.trim();

    // Показать загрузку
    _showLoadingDialog();

    if (_isLoginMode) {
      final success = await appState.login(email, password).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Время ожидания истекло');
        },
      );
      
      if (!mounted) return;
      Navigator.pop(context);  // Закрыть диалог загрузки

      if (success) {
        widget.onLogin(email, refCode);
      } else {
        _showError('Неверный email или пароль');
      }
    } else {
      final success = await appState.register(email, password, refCode);
      
      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        widget.onLogin(email, refCode);
      } else {
        _showError('Ошибка регистрации. Проверьте данные.');
      }
    }
  } on TimeoutException catch (e) {
    _showError('Время ожидания истекло. Попробуйте позже.');
    debugPrint('Login timeout: $e');
  } on FormatException catch (e) {
    _showError('Некорректные данные.');
    debugPrint('Format error: $e');
  } catch (e, stackTrace) {
    _showError('Неизвестная ошибка. Попробуйте позже.');
    debugPrintStack(stackTrace: stackTrace);
    // Отправить в систему логирования (Firebase Crashlytics, Sentry)
  }
}

void _showLoadingDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      title: Text('Загрузка...'),
      content: CircularProgressIndicator(),
    ),
  );
}

void _showError(String message) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red),
  );
}
```

---

### 🟡 ЖЕЛАТЕЛЬНЫЕ УЛУЧШЕНИЯ

#### 5.4 Улучшение: Добавить логирование
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

```dart
// lib/services/logger_service.dart
import 'package:logger/logger.dart';

final logger = Logger();

// Использование
logger.i('Дерево $treeId полито');
logger.w('Низкий баланс: ${game.wlntBalance}');
logger.e('Ошибка при сохранении игры', error: e, stackTrace: st);
```

---

#### 5.5 Улучшение: Добавить тестирование
**Приоритет:** 🟡 ЖЕЛАТЕЛЬНО

```dart
// test/models/tree_model_test.dart
void main() {
  group('TreeModel', () {
    test('waterPercent вычисляется корректно', () {
      final tree = TreeModel(
        // ...
        currentWater: 50.0,
      );
      
      expect(tree.waterPercent, 0.5);
    });
    
    test('waterPercent зажимается в диапазон [0, 1]', () {
      final tree = TreeModel(
        // ...
        currentWater: 150.0,  // > 100
      );
      
      expect(tree.waterPercent, 1.0);
    });
  });
}
```

---

## 📊 ИТОГОВАЯ МАТРИЦА ПРИОРИТЕТОВ

| # | Проблема | Файл | Приоритет | Время | Impact |
|---|----------|------|-----------|-------|--------|
| 1.1 | Монолитный main.dart | main.dart | 🔴 | 4–6ч | ВЫСОКИЙ |
| 1.2 | Контрастность текста | main.dart | 🟡 | 30м | СРЕДНИЙ |
| 1.3 | Микро-анимации | main.dart | 🟡 | 2ч | СРЕДНИЙ |
| 2.1 | Дисбаланс цен | main.dart | 🔴 | 1ч | ВЫСОКИЙ |
| 2.2 | Частые гусеницы | game_engine.dart | 🔴 | 30м | ВЫСОКИЙ |
| 3.1 | Утечка памяти (AnimationController) | main.dart | 🔴 | 1ч | ВЫСОКИЙ |
| 3.2 | Отсутствие кэширования изображений | main.dart | 🔴 | 30м | ВЫСОКИЙ |
| 3.3 | Производительность погодных эффектов | main.dart | 🟡 | 2ч | СРЕДНИЙ |
| 4.1 | setState() после dispose | main.dart | 🔴 | 1ч | ВЫСОКИЙ |
| 4.2 | Неправильный waterPercent | game_models.dart | 🔴 | 30м | ВЫСОКИЙ |
| 4.3 | Утечка слушателей | main.dart | 🔴 | 1ч | ВЫСОКИЙ |
| 5.1 | Монолитная архитектура | main.dart | 🔴 | 4–6ч | ВЫСОКИЙ |
| 5.2 | Отсутствие State Management | main.dart | 🔴 | 3–4ч | ВЫСОКИЙ |
| 5.3 | Отсутствие обработки ошибок | main.dart | 🔴 | 2ч | ВЫСОКИЙ |

---

## 🎯 ПЛАН ДЕЙСТВИЙ (Рекомендуемый порядок)

### Фаза 1: Срочные баги (День 1–2)
- [ ] **4.1** Исправить setState() после dispose
- [ ] **4.2** Исправить waterPercent
- [ ] **3.2** Добавить CachedNetworkImage
- [ ] **2.1** Пересчитать цены на деревья
- [ ] **3.1** Убедиться в dispose всех AnimationController'ов

### Фаза 2: Архитектура (День 3–5)
- [ ] **5.1** Разбить main.dart на модули
- [ ] **5.2** Внедрить Riverpod для State Management
- [ ] **5.3** Добавить обработку ошибок

### Фаза 3: UX & Performance (День 6–8)
- [ ] **1.3** Добавить микро-анимации
- [ ] **3.3** Оптимизировать погодные эффекты
- [ ] **1.4** Добавить переходы между экранами

### Фаза 4: Полировка (День 9+)
- [ ] **1.2** Улучшить контрастность
- [ ] **1.6** Плавное появление ActionPanel
- [ ] **3.4** Реалистичные эффекты пожара

---

## 📝 ЗАКЛЮЧЕНИЕ

**Walnut Farm** — хорошее начало для idle-игры с:
- ✓ Интересной механикой погоды
- ✓ Разнообразием деревьев (6 редкостей)
- ✓ Системой ухода (полив, удобрения, птицы)

**Но требует срочных исправлений:**
- ❌ Критические утечки памяти
- ❌ Баланс экономики нарушен
- ❌ Код не масштабируется
- ❌ Отсутствует обработка ошибок

**Рекомендуемый путь развития:**
1. Срочные баги (неделя)
2. Архитектурный рефакторинг (2 недели)
3. Новые фичи и полировка (3+ недели)

---

**Проведено:** 16.06.2026  
**Автор:** Game Design & Flutter Code Review Expert
