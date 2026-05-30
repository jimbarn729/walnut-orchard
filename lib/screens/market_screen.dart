import 'package:flutter/material.dart';
import '../engine/game_engine.dart';
import '../theme/app_theme.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({
    super.key,
    required this.game,
    required this.userEmail,
    required this.onBuyTree,
    required this.onCancelTreeSell,
    required this.onBuyResource,
    required this.onCancelResourceSell,
    required this.onSellResource,
    required this.onPurchasePack,
    required this.onBuyPetEgg,
  });

  final GameEngine game;
  final String userEmail;
  final ValueChanged<String> onBuyTree;
  final ValueChanged<String> onCancelTreeSell;
  final ValueChanged<String> onBuyResource;
  final ValueChanged<String> onCancelResourceSell;
  final void Function(String resourceType, int quantity, double pricePerUnit) onSellResource;
  final void Function(String resourceType, int quantity, double pricePerUnit) onPurchasePack;
  final VoidCallback onBuyPetEgg;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text('🏪 Магазин', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            ),
            TabBar(
              labelColor: AppTheme.gold,
              unselectedLabelColor: AppTheme.muted,
              indicatorColor: AppTheme.gold,
              tabs: const [Tab(text: 'Лоты'), Tab(text: 'Ресурсы')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TreeMarketTab(game: game, userEmail: userEmail, onBuyTree: onBuyTree, onCancelTreeSell: onCancelTreeSell),
                  _ResourceMarketTab(
                    game: game,
                    onBuyResource: onBuyResource,
                    onCancelResourceSell: onCancelResourceSell,
                    onSellResource: onSellResource,
                    onPurchasePack: onPurchasePack,
                    onBuyPetEgg: onBuyPetEgg,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreeMarketTab extends StatelessWidget {
  const _TreeMarketTab({required this.game, required this.userEmail, required this.onBuyTree, required this.onCancelTreeSell});
  final GameEngine game;
  final String userEmail;
  final ValueChanged<String> onBuyTree;
  final ValueChanged<String> onCancelTreeSell;

  @override
  Widget build(BuildContext context) {
    final marketTrees = game.trees.where((tree) => tree.forSale && tree.owner != userEmail).toList();
    return marketTrees.isEmpty
        ? Center(child: Text('Нет доступных лотов', style: TextStyle(color: AppTheme.muted)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: marketTrees.length,
            itemBuilder: (context, index) {
              final tree = marketTrees[index];
              return Card(
                color: AppTheme.panel,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tree.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.text)),
                            const SizedBox(height: 4),
                            Text(tree.rarity.label, style: TextStyle(color: tree.stats.color)),
                            const SizedBox(height: 8),
                            Text('Цена: ${tree.price.toStringAsFixed(0)} WLNT', style: const TextStyle(color: AppTheme.gold)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => onBuyTree(tree.id),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                        child: const Text('Купить'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}

class _ResourceMarketTab extends StatelessWidget {
  const _ResourceMarketTab({
    required this.game,
    required this.onBuyResource,
    required this.onCancelResourceSell,
    required this.onSellResource,
    required this.onPurchasePack,
    required this.onBuyPetEgg,
  });

  final GameEngine game;
  final ValueChanged<String> onBuyResource;
  final ValueChanged<String> onCancelResourceSell;
  final void Function(String resourceType, int quantity, double pricePerUnit) onSellResource;
  final void Function(String resourceType, int quantity, double pricePerUnit) onPurchasePack;
  final VoidCallback onBuyPetEgg;

  String _resourceLabel(String type) {
    return switch (type) {
      'water_unit' => '💧 Вода',
      'fertilizer_unit' => '🌿 Удобрение',
      'bird_unit' => '🐦 Птица',
      _ => type,
    };
  }

  @override
  Widget build(BuildContext context) {
    final lots = game.resourceLots;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Пакеты ресурсов', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _OfferCard(
                  title: '💧 Вода',
                  amount: 1,
                  price: game.dynamicResourcePrice(150),
                  onBuy: () => onPurchasePack('water_unit', 1, game.dynamicResourcePrice(150)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OfferCard(
                  title: '🌿 Удобрение',
                  amount: 1,
                  price: game.dynamicResourcePrice(800),
                  onBuy: () => onPurchasePack('fertilizer_unit', 1, game.dynamicResourcePrice(800)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _OfferCard(
                  title: '🐦 Птица',
                  amount: 1,
                  price: game.dynamicResourcePrice(1000),
                  onBuy: () => onPurchasePack('bird_unit', 1, game.dynamicResourcePrice(1000)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OfferCard(
                  title: '🐾 Питомец',
                  amount: game.petDefenderActive ? 0 : 1,
                  price: 2000,
                  onBuy: onBuyPetEgg,
                  active: game.petDefenderActive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Рынок пользователей', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (lots.isEmpty)
            Center(child: Text('Пока нет лотов', style: TextStyle(color: AppTheme.muted)))
          else
            ...lots.map((lot) => Card(
                  color: AppTheme.panel,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_resourceLabel(lot.resourceType), style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.text)),
                              const SizedBox(height: 4),
                              Text('${lot.quantity} шт. · ${lot.pricePerUnit.toStringAsFixed(0)} WLNT', style: const TextStyle(color: AppTheme.gold)),
                            ],
                          ),
                        ),
                        if (lot.sellerEmail == game.leaderboard.firstWhere((e) => e.isPlayer).name)
                          TextButton(onPressed: () => onCancelResourceSell(lot.id), child: const Text('Снять', style: TextStyle(color: Colors.red)))
                        else
                          ElevatedButton(onPressed: () => onBuyResource(lot.id), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)), child: const Text('Купить'))
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 20),
          _SellResourceForm(onSell: onSellResource),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.title, required this.amount, required this.price, required this.onBuy, this.active = false});
  final String title;
  final int amount;
  final double price;
  final VoidCallback onBuy;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: active ? Colors.amber : Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(active ? 'Активирован' : '${price.toStringAsFixed(0)} WLNT', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: active ? null : onBuy,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
            child: Text(active ? 'Владеете' : 'Купить'),
          ),
        ],
      ),
    );
  }
}

class _SellResourceForm extends StatefulWidget {
  const _SellResourceForm({super.key, required this.onSell});

  final void Function(String resourceType, int quantity, double pricePerUnit) onSell;

  @override
  State<_SellResourceForm> createState() => _SellResourceFormState();
}

class _SellResourceFormState extends State<_SellResourceForm> {
  String _type = 'water_unit';
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController(text: '120');

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Выставить лот', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Ресурс', filled: true, fillColor: AppTheme.bg, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
              items: const [
                DropdownMenuItem(value: 'water_unit', child: Text('💧 Вода')),
                DropdownMenuItem(value: 'fertilizer_unit', child: Text('🌿 Удобрение')),
                DropdownMenuItem(value: 'bird_unit', child: Text('🐦 Птица')),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 10),
            TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Количество', filled: true, fillColor: AppTheme.bg, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            const SizedBox(height: 10),
            TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Цена за шт.', filled: true, fillColor: AppTheme.bg, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(_qtyCtrl.text) ?? 0;
                final price = double.tryParse(_priceCtrl.text) ?? 0;
                if (qty > 0 && price > 0) {
                  widget.onSell(_type, qty, price);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
              child: const Text('Выставить'),
            ),
          ],
        ),
      ),
    );
  }
}
