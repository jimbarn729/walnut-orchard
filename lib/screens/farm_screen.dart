import 'package:flutter/material.dart';
import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import '../widgets/weather_effects.dart';
import '../widgets/weather_status_bar.dart';
import '../widgets/moisture_indicator.dart';
import '../widgets/caterpillar_badge.dart';
import '../widgets/action_particles.dart';

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
    final growthTrees = game.trees.where((t) => t.isPlanted && t.status == TreeStatus.growth).toList();
    final restTrees = game.trees.where((t) => t.isPlanted && t.status == TreeStatus.rest).toList();

    return WeatherEffects(
      weather: game.currentWeather,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  const Expanded(child: Text('🌳 Сад', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                  ElevatedButton.icon(
                    onPressed: onDaySkip,
                    icon: const Icon(Icons.fast_forward_rounded),
                    label: const Text('Пропустить день'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.panel,
                      foregroundColor: AppTheme.text,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Weather status bar
              WeatherStatusBar(game: game),
              const SizedBox(height: 10),

              // Tree list
              Expanded(
                child: ListView(
                  children: [
                    if (growthTrees.isNotEmpty) ...[
                      _SectionHeader(label: '🌱 Растущие', count: growthTrees.length),
                      const SizedBox(height: 6),
                      ...growthTrees.map((t) => _TreeCard(
                        tree: t,
                        selected: t.id == selectedTreeId,
                        onTap: () => onSelectTree(t.id == selectedTreeId ? null : t.id),
                        weather: game.currentWeather,
                      )),
                      const SizedBox(height: 12),
                    ],
                    if (restTrees.isNotEmpty) ...[
                      _SectionHeader(label: '❄️ Отдыхающие', count: restTrees.length),
                      const SizedBox(height: 6),
                      ...restTrees.map((t) => _TreeCard(
                        tree: t,
                        selected: t.id == selectedTreeId,
                        onTap: () => onSelectTree(t.id == selectedTreeId ? null : t.id),
                        weather: game.currentWeather,
                      )),
                      const SizedBox(height: 12),
                    ],
                    if (growthTrees.isEmpty && restTrees.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.park_rounded, size: 48, color: AppTheme.muted),
                              const SizedBox(height: 12),
                              const Text('Нет деревьев', style: TextStyle(color: AppTheme.muted, fontSize: 16)),
                              const SizedBox(height: 4),
                              const Text('Купите дерево на рынке', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Care panel for selected tree
              if (selectedTreeId != null)
                _CarePanel(
                  game: game,
                  treeId: selectedTreeId!,
                  onPerformCare: (action) => onPerformCare(selectedTreeId!, action),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.text)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.panelBorder,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count', style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
        ),
      ],
    );
  }
}

class _TreeCard extends StatelessWidget {
  const _TreeCard({
    required this.tree,
    required this.selected,
    required this.onTap,
    required this.weather,
  });

  final TreeModel tree;
  final bool selected;
  final VoidCallback onTap;
  final WeatherType weather;

  @override
  Widget build(BuildContext context) {
    final progress = tree.seasonDay / GameEngine.seasonLength;
    final effectiveWaterLoss = tree.waterConsumptionRate * weather.waterMultiplier;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? Colors.green.shade900.withOpacity(0.3) : AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? tree.stats.color.withOpacity(0.7) : AppTheme.panelBorder,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [BoxShadow(color: tree.stats.color.withOpacity(0.25), blurRadius: 12)]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name + rarity + caterpillars
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tree.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.text),
                    ),
                  ),
                  CaterpillarBadge(count: tree.caterpillars, compact: true),
                  const SizedBox(width: 6),
                  Chip(
                    label: Text(tree.rarity.label, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    backgroundColor: tree.stats.color,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Moisture indicator
              MoistureBarCompact(value: tree.currentWater),
              const SizedBox(height: 4),

              // Stats row
              Row(
                children: [
                  _MiniStat(
                    icon: Icons.calendar_today_rounded,
                    label: '${tree.seasonDay}/30',
                    color: AppTheme.muted,
                  ),
                  const SizedBox(width: 12),
                  _MiniStat(
                    icon: Icons.water_drop_outlined,
                    label: '-${effectiveWaterLoss.toStringAsFixed(1)}%/д',
                    color: effectiveWaterLoss > tree.waterConsumptionRate
                        ? Colors.red.shade300
                        : AppTheme.muted,
                  ),
                  const Spacer(),
                  if (tree.status == TreeStatus.growth) ...[
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 4,
                            backgroundColor: AppTheme.panelBorder,
                            valueColor: AlwaysStoppedAnimation(tree.stats.color),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.text),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (tree.canHarvest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🪙', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 4),
                          Text('Готов!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.amber)),
                        ],
                      ),
                    ),
                  if (tree.status == TreeStatus.dead)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('💀 Мёртво', style: TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

class _CarePanel extends StatelessWidget {
  const _CarePanel({
    required this.game,
    required this.treeId,
    required this.onPerformCare,
  });

  final GameEngine game;
  final String treeId;
  final Future<bool> Function(String action) onPerformCare;

  @override
  Widget build(BuildContext context) {
    final tree = game.trees.firstWhere((t) => t.id == treeId);
    final actions = _availableActions(tree, game);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Уход: ${tree.name}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.text),
                ),
              ),
              // Show caterpillar detail if present
              if (tree.caterpillars > 0)
                CaterpillarBadge(count: tree.caterpillars),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((a) => _CareButton(
              label: a.label,
              icon: a.icon,
              color: a.color,
              cost: a.cost,
              enabled: a.enabled,
              onTap: () async {
                final success = await onPerformCare(a.code);
                if (success && context.mounted) {
                  ActionBurst.show(context, a.particleType);
                }
              },
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _CareAction {
  final String code;
  final String label;
  final IconData icon;
  final Color color;
  final String cost;
  final bool enabled;
  final ActionParticleType particleType;

  const _CareAction({
    required this.code,
    required this.label,
    required this.icon,
    required this.color,
    required this.cost,
    required this.enabled,
    required this.particleType,
  });
}

List<_CareAction> _availableActions(TreeModel tree, GameEngine game) {
  final actions = <_CareAction>[];
  final inv = game.inventory;

  // Water actions (only for growth trees)
  if (tree.status == TreeStatus.growth) {
    final hasWaterUnit = (inv['water_unit'] ?? 0) > 0;
    actions.add(_CareAction(
      code: 'water_bucket',
      label: '🪣 Вода +20',
      icon: Icons.water_drop,
      color: Colors.blue.shade400,
      cost: hasWaterUnit ? '×1 инв.' : '200 WLNT',
      enabled: hasWaterUnit || game.wlntBalance >= 200,
      particleType: ActionParticleType.water,
    ));
    actions.add(_CareAction(
      code: 'water_barrel',
      label: '🛢️ Вода +50',
      icon: Icons.water,
      color: Colors.blue.shade600,
      cost: hasWaterUnit ? '×2 инв.' : '500 WLNT',
      enabled: hasWaterUnit || game.wlntBalance >= 500,
      particleType: ActionParticleType.water,
    ));
    actions.add(_CareAction(
      code: 'fertilize_normal',
      label: '🧪 Удобрение',
      icon: Icons.science,
      color: Colors.brown.shade400,
      cost: (inv['fertilizer_unit'] ?? 0) > 0 ? '×1 инв.' : '1000 WLNT',
      enabled: (inv['fertilizer_unit'] ?? 0) > 0 || game.wlntBalance >= 1000,
      particleType: ActionParticleType.fertilizer,
    ));
  }

  // Bird actions (for caterpillars)
  if (tree.caterpillars > 0) {
    final hasBird = (inv['bird_unit'] ?? 0) > 0;
    actions.add(_CareAction(
      code: 'woodpecker_1',
      label: '🪶 Дятел ×1',
      icon: Icons.pest_control,
      color: Colors.amber.shade400,
      cost: hasBird ? '×1 инв.' : '200 WLNT',
      enabled: hasBird || game.wlntBalance >= 200,
      particleType: ActionParticleType.bird,
    ));
    if (tree.caterpillars >= 5) {
      actions.add(_CareAction(
        code: 'woodpecker_5',
        label: '🪶 Дятел ×5',
        icon: Icons.pest_control,
        color: Colors.amber.shade600,
        cost: hasBird ? '×5 инв.' : '950 WLNT',
        enabled: hasBird || game.wlntBalance >= 950,
        particleType: ActionParticleType.bird,
      ));
    }
  }

  // Harvest
  if (tree.canHarvest) {
    actions.add(_CareAction(
      code: 'harvest',
      label: '🪙 Собрать урожай',
      icon: Icons.monetization_on,
      color: Colors.amber,
      cost: '+${tree.stats.income} WLNT',
      enabled: true,
      particleType: ActionParticleType.harvest,
    ));
  }

  return actions;
}

class _CareButton extends StatelessWidget {
  const _CareButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.cost,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String cost;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: AppTheme.panelBorder,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 4),
                    Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(cost, style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
