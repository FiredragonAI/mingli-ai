import 'package:flutter/material.dart' hide Element;

import '../../core/bazi/element_strength.dart';
import '../../core/bazi/five_elements.dart';
import '../../l10n/strings.dart';
import '../theme.dart';

/// 五行占比横条 + 强弱、喜忌。
class ElementBars extends StatelessWidget {
  const ElementBars({super.key, required this.analysis});
  final ElementAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    String els(List<Element> list) => list.map((e) => s.term(e.label)).join(s.en ? ', ' : '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.elementStrength, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final e in Element.values) ...[
              Row(
                children: [
                  SizedBox(
                    width: s.en ? 52 : 24,
                    child: Text(s.term(e.label), style: TextStyle(color: elementColor[e.label], fontWeight: FontWeight.w700)),
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
                Chip(label: Text('${s.dayMasterChip} ${s.term(analysis.dayMaster.label)} · ${s.term(analysis.strength.label)}')),
                Chip(avatar: const Icon(Icons.thumb_up_alt_outlined, size: 16), label: Text('${s.favorable} ${els(analysis.favorable)}')),
                Chip(avatar: const Icon(Icons.block, size: 16), label: Text('${s.unfavorable} ${els(analysis.unfavorable)}')),
                if (analysis.missing.isNotEmpty) Chip(label: Text('${s.missing} ${els(analysis.missing)}')),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(s.reasoning, style: theme.textTheme.bodyMedium),
              children: [
                for (final r in analysis.reasoning)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('· ${s.text(r)}', style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
