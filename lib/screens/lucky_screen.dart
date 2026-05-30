import 'dart:math';
import 'package:flutter/material.dart';
import '../engine/game_engine.dart';
import '../theme/app_theme.dart';

class LuckyScreen extends StatefulWidget {
  const LuckyScreen({
    super.key,
    required this.game,
    required this.onBurned,
    required this.onSpinComplete,
  });

  final GameEngine game;
  final ValueChanged<String> onBurned;
  final Future<void> Function() onSpinComplete;

  @override
  State<LuckyScreen> createState() => _LuckyScreenState();
}

class _LuckyScreenState extends State<LuckyScreen> {
  String _result = '';
  bool _spinning = false;

  Future<void> _spin() async {
    if (_spinning) return;
    if (widget.game.wlntBalance < 100) {
      setState(() => _result = 'Недостаточно WLNT для спина');
      return;
    }
    setState(() {
      _spinning = true;
      _result = 'Крутим...';
      widget.game.wlntBalance -= 100;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    final outcome = Random().nextInt(5);
    switch (outcome) {
      case 0:
        widget.game.wlntBalance += 250;
        _result = 'Вы выиграли 250 WLNT!';
        break;
      case 1:
        widget.game.inventory['water_unit'] = (widget.game.inventory['water_unit'] ?? 0) + 2;
        _result = 'Вы получили 2 воды!';
        break;
      case 2:
        widget.game.inventory['fertilizer_unit'] = (widget.game.inventory['fertilizer_unit'] ?? 0) + 1;
        _result = 'Вы получили 1 удобрение!';
        break;
      case 3:
        widget.game.inventory['bird_unit'] = (widget.game.inventory['bird_unit'] ?? 0) + 1;
        _result = 'Вы получили 1 птицу!';
        break;
      default:
        _result = 'Пусто, повезёт в следующий раз';
        break;
    }
    widget.game.trackChallenge('spin');
    await widget.onSpinComplete();
    setState(() => _spinning = false);
  }

  void _burn() {
    if (widget.game.trees.isEmpty) return;
    final tree = widget.game.trees.first;
    widget.onBurned(tree.id);
    setState(() => _result = 'Сожжено ${tree.name}. Получено 2000 WLNT.');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('🍀 Колесо удачи', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Text('Баланс: ${widget.game.wlntBalance.toStringAsFixed(0)} WLNT', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.circular(22)),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Шанс получить бонусы', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    _OutcomeRow(label: '250 WLNT', weight: '30%'),
                    _OutcomeRow(label: '2 воды', weight: '20%'),
                    _OutcomeRow(label: '1 удобрение', weight: '20%'),
                    _OutcomeRow(label: '1 птица', weight: '15%'),
                    _OutcomeRow(label: 'Пусто', weight: '15%'),
                    const Spacer(),
                    Text(_result, style: const TextStyle(color: AppTheme.text)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _spinning ? null : _spin,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: Text(_spinning ? 'Ждём...' : 'Крутить за 100 WLNT'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _burn,
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: const Text('Сжечь NFT для 2000 WLNT', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({required this.label, required this.weight});
  final String label;
  final String weight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.text))),
          Text(weight, style: const TextStyle(color: AppTheme.muted)),
        ],
      ),
    );
  }
}
