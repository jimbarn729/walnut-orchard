import 'package:flutter/material.dart';
import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';

class FarmScreen extends StatelessWidget {
  const FarmScreen({
    super.key,
    required this.game,
    required this.selectedTreeId,
    required this.onSelectTree,
    required this.onDaySkip,
    required this.onPerformCare,
  });

  final GameEngine game;
  final String? selectedTreeId;
  final ValueChanged<String?> onSelectTree;
  final Future<void> Function() onDaySkip;
  final Future<bool> Function(String treeId, String action) onPerformCare;

  @override
  Widget build(BuildContext context) {
    final growthTrees = game.trees.where((tree) => tree.isPlanted && tree.status == TreeStatus.growth).toList();
    final restTrees = game.trees.where((tree) => tree.isPlanted && tree.status == TreeStatus.rest).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: Text('🌳 Сад', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                ElevatedButton.icon(
                  onPressed: onDaySkip,
                  icon: const Icon(Icons.fast_forward_rounded),
                  label: const Text('Пропустить день'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _ZoneHeader('Рост', growthTrees.length),
                  ...growthTrees.map((tree) => _TreeCard(tree: tree, selected: selectedTreeId == tree.id, onTap: () => onSelectTree(tree.id))),
                  const SizedBox(height: 12),
                  _ZoneHeader('Отдых', restTrees.length),
                  ...restTrees.map((tree) => _TreeCard(tree: tree, selected: selectedTreeId == tree.id, onTap: () => onSelectTree(tree.id))),
                ],
              ),
            ),
            if (selectedTreeId != null)
              Builder(builder: (context) {
                TreeModel? selectedTree;
                for (final tree in game.trees) {
                  if (tree.id == selectedTreeId) {
                    selectedTree = tree;
                    break;
                  }
                }
                if (selectedTree == null) return const SizedBox.shrink();
                return _ActionPanel(tree: selectedTree, onAction: (action) => onPerformCare(selectedTree!.id, action));
              }),
          ],
        ),
      ),
    );
  }
}

class _ZoneHeader extends StatelessWidget {
  const _ZoneHeader(this.title, this.count);
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('$count деревьев', style: const TextStyle(color: AppTheme.muted)),
        ],
      ),
    );
  }
}

class _TreeCard extends StatelessWidget {
  const _TreeCard({required this.tree, required this.selected, required this.onTap});

  final TreeModel tree;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = tree.status == TreeStatus.growth ? tree.seasonDay / GameEngine.seasonLength : tree.seasonDay / GameEngine.seasonLength;
    return Card(
      color: selected ? Colors.green.shade900 : AppTheme.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
              LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(tree.stats.color)),
              const SizedBox(height: 6),
              Text('День: ${tree.seasonDay} / ${GameEngine.seasonLength}', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.tree, required this.onAction});

  final TreeModel tree;
  final Future<bool> Function(String action) onAction;

  @override
  Widget build(BuildContext context) {
    final actions = tree.status == TreeStatus.growth
        ? [
            _CareButton(label: 'Ведро', action: 'water_bucket', onAction: onAction),
            _CareButton(label: 'Бочка', action: 'water_barrel', onAction: onAction),
            _CareButton(label: 'Удобрить', action: 'fertilize_normal', onAction: onAction),
            _CareButton(label: 'Убрать гусениц', action: 'woodpecker_all', onAction: onAction),
          ]
        : [
            _CareButton(label: 'Собрать воду', action: 'set_bucket', onAction: onAction),
            _CareButton(label: 'Построить гнездо', action: 'set_nest_son', onAction: onAction),
          ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Действия для ${tree.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: actions),
        ],
      ),
    );
  }
}

class _CareButton extends StatelessWidget {
  const _CareButton({required this.label, required this.action, required this.onAction});
  final String label;
  final String action;
  final Future<bool> Function(String action) onAction;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onAction(action),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
      child: Text(label),
    );
  }
}
