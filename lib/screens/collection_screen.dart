import 'package:flutter/material.dart';
import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({
    super.key,
    required this.game,
    required this.userEmail,
    required this.onSelectTree,
    required this.onPlant,
    required this.onSell,
    required this.onCancelSell,
    required this.onHarvest,
    required this.onClaimChallenge,
  });

  final GameEngine game;
  final String userEmail;
  final ValueChanged<String> onSelectTree;
  final ValueChanged<String> onPlant;
  final void Function(String treeId, double price) onSell;
  final ValueChanged<String> onCancelSell;
  final ValueChanged<String> onHarvest;
  final ValueChanged<String> onClaimChallenge;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text('Коллекция', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            ),
            TabBar(
              labelColor: AppTheme.gold,
              unselectedLabelColor: AppTheme.muted,
              indicatorColor: AppTheme.gold,
              tabs: const [Tab(text: 'Деревья'), Tab(text: 'Задания'), Tab(text: 'Рейтинг')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TreesTab(game: game, userEmail: userEmail, onSelectTree: onSelectTree, onPlant: onPlant, onSell: onSell, onCancelSell: onCancelSell, onHarvest: onHarvest),
                  _ChallengesTab(challenges: game.dailyChallenges, onClaim: onClaimChallenge),
                  _LeaderboardTab(leaderboard: game.leaderboard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreesTab extends StatelessWidget {
  const _TreesTab({required this.game, required this.userEmail, required this.onSelectTree, required this.onPlant, required this.onSell, required this.onCancelSell, required this.onHarvest});

  final GameEngine game;
  final String userEmail;
  final ValueChanged<String> onSelectTree;
  final ValueChanged<String> onPlant;
  final void Function(String treeId, double price) onSell;
  final ValueChanged<String> onCancelSell;
  final ValueChanged<String> onHarvest;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: game.trees.length,
      itemBuilder: (context, index) {
        final tree = game.trees[index];
        return Card(
          color: AppTheme.panel,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelectTree(tree.id),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(tree.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.text))),
                      Chip(label: Text(tree.rarity.label, style: const TextStyle(color: Colors.white)), backgroundColor: tree.stats.color),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Статус: ${tree.status.label}', style: const TextStyle(color: AppTheme.muted)),
                  const SizedBox(height: 8),
                  Row(children: [
                    if (!tree.isPlanted)
                      ElevatedButton(
                        onPressed: () => onPlant(tree.id),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                        child: const Text('Посадить'),
                      ),
                    if (!tree.isPlanted && !tree.forSale) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _showSellDialog(context, tree),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text('Продать'),
                      ),
                    ],
                    if (tree.forSale) ...[
                      const SizedBox(width: 8),
                      Text('В продаже ${tree.price.toStringAsFixed(0)} WLNT', style: const TextStyle(color: AppTheme.gold)),
                      const SizedBox(width: 8),
                      TextButton(onPressed: () => onCancelSell(tree.id), child: const Text('Снять', style: TextStyle(color: Colors.red))),
                    ],
                    if (tree.canHarvest) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => onHarvest(tree.id),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                        child: const Text('Собрать урожай'),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSellDialog(BuildContext context, TreeModel tree) {
    final priceCtrl = TextEditingController(text: '1000');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: const Text('Цена продажи', style: TextStyle(color: AppTheme.text)),
        content: TextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.text),
          decoration: const InputDecoration(hintText: 'WLNT', filled: true, fillColor: AppTheme.bg),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceCtrl.text) ?? 0;
              if (price > 0) {
                onSell(tree.id, price);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
            child: const Text('Выставить'),
          ),
        ],
      ),
    );
  }
}

class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab({required this.challenges, required this.onClaim});
  final List<DailyChallenge> challenges;
  final ValueChanged<String> onClaim;

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return Center(child: Text('Нет заданий', style: TextStyle(color: AppTheme.muted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return Card(
          color: AppTheme.panel,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(challenge.description, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.text)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: challenge.progress, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(AppTheme.gold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${challenge.current} / ${challenge.target}', style: const TextStyle(color: AppTheme.muted)),
                    Text('${challenge.reward} WLNT', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                challenge.claimed
                    ? const Text('Получено', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w700))
                    : ElevatedButton(
                        onPressed: challenge.completed ? () => onClaim(challenge.id) : null,
                        style: ElevatedButton.styleFrom(backgroundColor: challenge.completed ? const Color(0xFF00C853) : AppTheme.panel),
                        child: Text(challenge.completed ? 'Забрать' : 'В процессе'),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({required this.leaderboard});
  final List<LeaderboardEntry> leaderboard;

  @override
  Widget build(BuildContext context) {
    final sorted = List<LeaderboardEntry>.from(leaderboard)..sort((a, b) => b.wlntBalance.compareTo(a.wlntBalance));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final entry = sorted[index];
        return ListTile(
          tileColor: AppTheme.panel,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(entry.name, style: TextStyle(color: entry.isPlayer ? AppTheme.gold : AppTheme.text, fontWeight: entry.isPlayer ? FontWeight.w900 : FontWeight.w600)),
          leading: CircleAvatar(child: Text('${index + 1}')),
          trailing: Text('${entry.wlntBalance.toStringAsFixed(0)} WLNT', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
        );
      },
    );
  }
}
