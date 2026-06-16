import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/audio_service.dart';
import '../widgets/phone_frame.dart';
import 'collection_screen.dart';
import 'farm_screen.dart';
import 'lucky_screen.dart';
import 'market_screen.dart';
import 'wallet_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _tab = 0;
  String? _selectedTreeId;
  Timer? _realtimeTimer;
  final List<String> _notifications = [];
  bool _backgroundStarted = false;

  late AppState _appState;
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appState = context.read<AppState>();
    _audioService = _appState.audioService;
    if (!_backgroundStarted) {
      _backgroundStarted = true;
      _audioService.playBackground('sounds/${_appState.engine.currentWeather.name}.mp3');
      _appState.engine.addIncomeListener(_onIncomeNotification);
      _startRealtimeTimer();
    }
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _appState.engine.removeIncomeListener(_onIncomeNotification);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startRealtimeTimer();
    } else {
      _realtimeTimer?.cancel();
    }
  }

  void _onIncomeNotification(String message) {
    if (!mounted) return;
    setState(() {
      _notifications.add(message);
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _notifications.isNotEmpty) {
        setState(() {
          _notifications.removeAt(0);
        });
      }
    });
    _audioService.playCoins();
  }

  void _startRealtimeTimer() {
    _realtimeTimer?.cancel();
    _realtimeTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (!mounted) return;
      _appState.engine.tickRealtime(const Duration(minutes: 1));
      await _appState.saveGame();
      setState(() {});
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _tab = index;
    });
    _audioService.playClick();
  }

  void _onSelectTree(String? treeId) {
    setState(() {
      _selectedTreeId = _selectedTreeId == treeId ? null : treeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = _appState.engine;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PhoneFrame(
        child: Stack(
          children: [
            IndexedStack(
              index: _tab,
              children: [
                FarmScreen(
                  game: game,
                  selectedTreeId: _selectedTreeId,
                  onSelectTree: _onSelectTree,
                  onDaySkip: () async {
                    await _appState.nextDay();
                    setState(() {});
                  },
                  onPerformCare: (treeId, action) async {
                    await _appState.applyCare(treeId, action);
                    if (mounted) setState(() {});
                    _audioService.playClick();
                    return true;
                  },
                ),
                MarketScreen(
                  game: game,
                  userEmail: _appState.userEmail,
                  onBuyTree: (id) async {
                    await _appState.buyTree(id);
                    setState(() {});
                    _audioService.playClick();
                  },
                  onCancelTreeSell: (id) async {
                    await _appState.cancelSell(id);
                    setState(() {});
                    _audioService.playClick();
                  },
                  onBuyResource: (id) async {
                    await _appState.buyResource(id);
                    setState(() {});
                    _audioService.playClick();
                  },
                  onCancelResourceSell: (id) async {
                    await _appState.cancelResourceSell(id);
                    setState(() {});
                    _audioService.playClick();
                  },
                  onSellResource: (type, qty, price) async {
                    await _appState.sellResource(type, qty, price);
                    setState(() {});
                    _audioService.playClick();
                  },
                  onPurchasePack: (type, qty, price) async {
                    await _appState.purchaseResourcePackage(type, qty, price);
                    setState(() {});
                    _audioService.playClick();
                  },
                  onBuyPetEgg: () async {
                    await _appState.buyPetEgg();
                    setState(() {});
                    _audioService.playClick();
                  },
                ),
                LuckyScreen(
                  game: game,
                  onBurned: (id) async {
                    await _appState.burnTree(id);
                    setState(() {});
                    _audioService.playClick();
                  },
                  onSpinComplete: () async {
                    await _appState.saveGame();
                    setState(() {});
                  },
                ),
                CollectionScreen(
                  game: game,
                  userEmail: _appState.userEmail,
                  onSelectTree: _onSelectTree,
                  onPlant: (id) async {
                    await _appState.plantTree(id);
                    setState(() {});
                    _audioService.playClick();
                  },
                  onSell: (id, price) async {
                    await _appState.sellTree(id, price);
                    setState(() {});
                    _audioService.playClick();
                  },
                  onCancelSell: (id) async {
                    await _appState.cancelSell(id);
                    setState(() {});
                    _audioService.playClick();
                  },
                  onHarvest: (id) async {
                    await _appState.harvestTree(id);
                    setState(() {});
                    _audioService.playCoins();
                  },
                  onClaimChallenge: (id) async {
                    await _appState.claimChallenge(id);
                    setState(() {});
                    _audioService.playCoins();
                  },
                ),
                WalletScreen(
                  solBalance: game.solBalance,
                  wlntBalance: game.wlntBalance,
                  userEmail: _appState.userEmail,
                  myReferralCode: _appState.referralCode,
                  themeMode: _appState.themeMode,
                  onToggleTheme: () => _appState.setThemeMode(_appState.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
                  onToggleAudio: () {
                    setState(() {
                      _audioService.setMuted(!_audioService.muted);
                    });
                  },
                  audioMuted: _audioService.muted,
                  onLogout: () async {
                    await _appState.logout();
                    setState(() {});
                    _audioService.playClick();
                  },
                  onDepositSol: (amount) async {
                    await _appState.depositSol(amount);
                    setState(() {});
                  },
                  onWithdrawSol: (amount) async {
                    await _appState.withdrawSol(amount);
                    setState(() {});
                  },
                  onDepositWlnt: (amount) async {
                    await _appState.updateBalances(depositWlnt: amount);
                    setState(() {});
                  },
                  onWithdrawWlnt: (amount) async {
                    if (amount <= game.wlntBalance) {
                      await _appState.updateBalances(withdrawWlnt: amount);
                      setState(() {});
                    }
                  },
                  onConvertSolToWlnt: (amount) async {
                    await _appState.convertSolToWlnt(amount);
                    setState(() {});
                  },
                  onConvertWlntToSol: (amount) async {
                    await _appState.convertWlntToSol(amount);
                    setState(() {});
                  },
                  dailyRewardAvailable: _appState.dailyRewardAvailable,
                  onClaimDailyReward: () async {
                    final ok = await _appState.claimDailyReward();
                    if (ok && mounted) setState(() {});
                    return ok;
                  },
                ),
              ],
            ),
            if (_notifications.isNotEmpty)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Column(
                  children: _notifications
                      .map((message) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(message, style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.eco_outlined), label: 'Сад'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Магазин'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Удача'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Коллекция'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Кошелёк'),
        ],
      ),
    );
  }
}
