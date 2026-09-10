import 'package:flutter/material.dart' hide Element;

import '../../core/bazi/element_strength.dart';
import '../../core/bazi/five_elements.dart';
import '../theme.dart';

/// 五行占比横条 + 强弱、喜忌。
class ElementBars extends StatelessWidget {
  const ElementBars({super.key, required this.analysis});
  final ElementAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('五行力量', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final e in Element.values) ...[
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(e.label, style: TextStyle(color: elementColor[e.label], fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: analysis.percentages[e]! / 100,
                        minHeight: 12,
                        color: elementColor[e.label],
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text('${analysis.percentages[e]!.round()}%', textAlign: TextAlign.end, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('日主 ${analysis.dayMaster.label} · ${analysis.strength.label}')),
                Chip(
                  avatar: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                  label: Text('喜 ${analysis.favorable.map((e) => e.label).join('')}'),
                ),
                Chip(
                  avatar: const Icon(Icons.block, size: 16),
                  label: Text('忌 ${analysis.unfavorable.map((e) => e.label).join('')}'),
                ),
                if (analysis.missing.isNotEmpty) Chip(label: Text('缺 ${analysis.missing.map((e) => e.label).join('')}')),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('推断依据', style: theme.textTheme.bodyMedium),
              children: [
                for (final r in analysis.reasoning)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('· $r', style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
