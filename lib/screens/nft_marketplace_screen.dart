import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';

/// NFT Marketplace for buying/selling unplanted trees between players.
class NftMarketplaceScreen extends StatefulWidget {
  const NftMarketplaceScreen({super.key, required this.game, required this.onRefresh});
  final GameEngine game;
  final VoidCallback onRefresh;

  @override
  State<NftMarketplaceScreen> createState() => _NftMarketplaceScreenState();
}

class _NftMarketplaceScreenState extends State<NftMarketplaceScreen> {
  TreeRarity? _filterRarity;
  _SortMode _sortMode = _SortMode.priceLow;
  int _selectedTab = 0; // 0=buy, 1=my listings, 2=my inventory

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text('🏪 NFT Маркет', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                ),
                _BalanceChip(label: '🪙', value: widget.game.wlntBalance),
              ],
            ),
            const SizedBox(height: 10),

            // Tab bar
            _TabBar(
              tabs: const ['Купить', 'Мои лоты', 'Инвентарь'],
              selected: _selectedTab,
              onSelect: (i) => setState(() => _selectedTab = i),
            ),
            const SizedBox(height: 10),

            // Filters (only for buy tab)
            if (_selectedTab == 0) _buildFilters(),
            if (_selectedTab == 0) const SizedBox(height: 10),

            // Content
            Expanded(
              child: switch (_selectedTab) {
                0 => _buildBuyTab(),
                1 => _buildMyListingsTab(),
                2 => _buildInventoryTab(),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Все',
                  selected: _filterRarity == null,
                  onTap: () => setState(() => _filterRarity = null),
                ),
                ...TreeRarity.values.map((r) => _FilterChip(
                  label: r.label,
                  color: r.stats.color,
                  selected: _filterRarity == r,
                  onTap: () => setState(() => _filterRarity = r),
                )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<_SortMode>(
          onSelected: (m) => setState(() => _sortMode = m),
          icon: const Icon(Icons.sort_rounded, color: AppTheme.muted),
          color: AppTheme.panel,
          itemBuilder: (_) => [
            _sortItem(_SortMode.priceLow, 'Цена ↑'),
            _sortItem(_SortMode.priceHigh, 'Цена ↓'),
            _sortItem(_SortMode.rarity, 'Редкость'),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<_SortMode> _sortItem(_SortMode mode, String label) {
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          if (_sortMode == mode) Icon(Icons.check, size: 16, color: AppTheme.gold),
          if (_sortMode == mode) const SizedBox(width: 6),
          Text(label, style: TextStyle(color: _sortMode == mode ? AppTheme.gold : AppTheme.text)),
        ],
      ),
    );
  }

  // Trees listed for sale by OTHER players (not our own)
  Widget _buildBuyTab() {
    final listings = widget.game.trees.where((t) {
      if (!t.forSale) return false;
      if (t.owner == widget.game.playerEmail) return false;
      if (_filterRarity != null && t.rarity != _filterRarity) return false;
      return true;
    }).toList();

    listings.sort((a, b) => switch (_sortMode) {
      _SortMode.priceLow => a.price.compareTo(b.price),
      _SortMode.priceHigh => b.price.compareTo(a.price),
      _SortMode.rarity => b.rarity.index.compareTo(a.rarity.index),
    });

    if (listings.isEmpty) {
      return const _EmptyState(
        icon: Icons.storefront_rounded,
        title: 'Нет деревьев на продажу',
        subtitle: 'Загляните позже или выставите своё дерево',
      );
    }

    return ListView.builder(
      itemCount: listings.length,
      itemBuilder: (ctx, i) => _NftListingCard(
        tree: listings[i],
        isOwn: false,
        onBuy: () => _confirmBuy(listings[i]),
      ),
    );
  }

  // Trees listed for sale by the current player
  Widget _buildMyListingsTab() {
    final my = widget.game.trees.where((t) => t.forSale && t.owner == widget.game.playerEmail).toList();

    if (my.isEmpty) {
      return const _EmptyState(
        icon: Icons.list_alt_rounded,
        title: 'Нет активных лотов',
        subtitle: 'Выставите дерево из инвентаря на продажу',
      );
    }

    return ListView.builder(
      itemCount: my.length,
      itemBuilder: (ctx, i) => _NftListingCard(
        tree: my[i],
        isOwn: true,
        onCancel: () {
          widget.game.cancelSell(my[i].id);
          widget.onRefresh();
        },
      ),
    );
  }

  // Unplanted trees owned by player, not for sale
  Widget _buildInventoryTab() {
    final unplanted = widget.game.trees.where((t) {
      if (t.isPlanted || t.status == TreeStatus.dead || t.forSale) return false;
      // Include player's own trees and legacy trees (owner empty)
      final isNpc = t.owner.startsWith('npc_');
      return !isNpc;
    }).toList();

    if (unplanted.isEmpty) {
      return const _EmptyState(
        icon: Icons.inventory_2_rounded,
        title: 'Нет деревьев в инвентаре',
        subtitle: 'Купите дерево на рынке или получите за урожай',
      );
    }

    return ListView.builder(
      itemCount: unplanted.length,
      itemBuilder: (ctx, i) => _InventoryTreeCard(
        tree: unplanted[i],
        onList: () => _showListDialog(unplanted[i]),
        onPlant: () {
          widget.game.plantTree(unplanted[i].id);
          widget.onRefresh();
        },
      ),
    );
  }

  void _confirmBuy(TreeModel tree) {
    final totalPrice = tree.price * 1.05;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: Text('Купить ${tree.name}?', style: const TextStyle(color: AppTheme.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Редкость', value: tree.rarity.label, valueColor: tree.rarity.stats.color),
            _DetailRow(label: 'Цена', value: '${tree.price.toStringAsFixed(0)} WLNT'),
            _DetailRow(label: 'Комиссия 5%', value: '${(tree.price * 0.05).toStringAsFixed(0)} WLNT'),
            const Divider(color: AppTheme.panelBorder),
            _DetailRow(label: 'Итого', value: '${totalPrice.toStringAsFixed(0)} WLNT', valueColor: AppTheme.gold),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: widget.game.wlntBalance >= totalPrice
                ? () {
                    widget.game.buyNftTree(tree.id);
                    Navigator.pop(ctx);
                    widget.onRefresh();
                  }
                : null,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
            child: const Text('Купить'),
          ),
        ],
      ),
    );
  }

  void _showListDialog(TreeModel tree) {
    final ctrl = TextEditingController(text: (tree.stats.income * 0.5).toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: Text('Продать ${tree.name}', style: const TextStyle(color: AppTheme.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${tree.rarity.emoji} ${tree.rarity.label}', style: TextStyle(color: tree.rarity.stats.color)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.text),
              decoration: InputDecoration(
                labelText: 'Цена (WLNT)',
                labelStyle: const TextStyle(color: AppTheme.muted),
                filled: true,
                fillColor: AppTheme.panelBorder,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixText: 'WLNT',
                suffixStyle: const TextStyle(color: AppTheme.muted),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Комиссия площадки: 5%', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(ctrl.text) ?? 0;
              if (price > 0) {
                widget.game.sellTree(tree.id, price);
                Navigator.pop(ctx);
                widget.onRefresh();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
            child: const Text('Выставить'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-components
// ---------------------------------------------------------------------------

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tabs, required this.selected, required this.onSelect});
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.black : AppTheme.muted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? (color ?? AppTheme.gold).withOpacity(0.2) : AppTheme.panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? (color ?? AppTheme.gold) : AppTheme.panelBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? (color ?? AppTheme.gold) : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _NftListingCard extends StatelessWidget {
  const _NftListingCard({required this.tree, required this.isOwn, this.onBuy, this.onCancel});
  final TreeModel tree;
  final bool isOwn;
  final VoidCallback? onBuy;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final rarityStats = tree.rarity.stats;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.panelBorder),
        boxShadow: [BoxShadow(color: rarityStats.color.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rarity avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: rarityStats.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: rarityStats.color.withOpacity(0.4)),
                ),
                alignment: Alignment.center,
                child: Text(rarityStats.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tree.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.text)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: rarityStats.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(tree.rarity.label, style: TextStyle(fontSize: 10, color: rarityStats.color, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        Text('Доход: ${rarityStats.income}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                      ],
                    ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tree.price.toStringAsFixed(0)} WLNT',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.gold),
                  ),
                  const Text('+5% комиссия', style: TextStyle(fontSize: 10, color: AppTheme.muted)),
                ],
              ),
            ],
          ),
          if (isOwn)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Снять с продажи'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.red.shade400.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onBuy,
                  icon: const Icon(Icons.shopping_cart_rounded, size: 16),
                  label: const Text('Купить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InventoryTreeCard extends StatelessWidget {
  const _InventoryTreeCard({required this.tree, required this.onList, required this.onPlant});
  final TreeModel tree;
  final VoidCallback onList;
  final VoidCallback onPlant;

  @override
  Widget build(BuildContext context) {
    final rarityStats = tree.rarity.stats;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: rarityStats.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: rarityStats.color.withOpacity(0.4)),
                ),
                alignment: Alignment.center,
                child: Text(rarityStats.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tree.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.text)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: rarityStats.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(tree.rarity.label, style: TextStyle(fontSize: 10, color: rarityStats.color)),
                        ),
                        const SizedBox(width: 6),
                        Text('${rarityStats.income} WLNT', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onList,
                  icon: const Icon(Icons.sell_rounded, size: 16),
                  label: const Text('Продать'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.gold,
                    side: BorderSide(color: AppTheme.gold.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPlant,
                  icon: const Icon(Icons.park_rounded, size: 16),
                  label: const Text('Посадить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(_formatBalance(value), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.gold)),
        ],
      ),
    );
  }

  String _formatBalance(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor ?? AppTheme.text, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.muted),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: AppTheme.text, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

enum _SortMode { priceLow, priceHigh, rarity }
