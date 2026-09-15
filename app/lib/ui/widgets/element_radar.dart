import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide Element;

import '../../core/bazi/element_strength.dart';
import '../../core/bazi/five_elements.dart';
import '../../l10n/strings.dart';
import '../theme.dart';

/// 五行雷达图:一眼看出哪边鼓、哪边瘪。
///
/// 五个轴按相生顺序排(木→火→土→金→水),相邻轴是相生关系,
/// 所以"鼓起来的一片"就是命局里互相滋养的那组五行。
class ElementRadar extends StatelessWidget {
  const ElementRadar({super.key, required this.analysis, this.size = 220});
  final ElementAnalysis analysis;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final primary = theme.colorScheme.primary;
    final maxPct = Element.values.map((e) => analysis.percentages[e]!).reduce((a, b) => a > b ? a : b);
    // 让最大的那根轴顶到 90%,图形不会缩成一团
    final scale = maxPct > 0 ? 0.9 / (maxPct / 100) : 1.0;

    return SizedBox(
      width: size,
      height: size,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 3,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 1),
          tickBorderData: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
          gridBorderData: BorderSide(color: theme.colorScheme.outlineVariant),
          radarBorderData: BorderSide(color: theme.colorScheme.outlineVariant),
          radarBackgroundColor: Colors.transparent,
          titlePositionPercentageOffset: 0.12,
          getTitle: (index, angle) {
            final e = Element.values[index];
            final pct = analysis.percentages[e]!.round();
            return RadarChartTitle(text: '${s.term(e.label)} $pct%', angle: 0);
          },
          titleTextStyle: theme.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600),
          dataSets: [
            RadarDataSet(
              fillColor: primary.withValues(alpha: 0.22),
              borderColor: primary,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: [
                for (final e in Element.values) RadarEntry(value: analysis.percentages[e]! / 100 * scale),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 雷达图 + 右侧五行说明的组合卡片。
class ElementRadarCard extends StatelessWidget {
  const ElementRadarCard({super.key, required this.analysis});
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
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 480;
                final legend = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final e in Element.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: elementColor[e.label], shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            SizedBox(width: s.en ? 56 : 24, child: Text(s.term(e.label), style: theme.textTheme.bodySmall)),
                            SizedBox(
                              width: 90,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: analysis.percentages[e]! / 100,
                                  minHeight: 6,
                                  color: elementColor[e.label],
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${analysis.percentages[e]!.round()}%', style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                  ],
                );
                final radar = ElementRadar(analysis: analysis, size: wide ? 200 : 220);
                return wide
                    ? Row(children: [radar, const SizedBox(width: 16), Expanded(child: legend)])
                    : Column(children: [Center(child: radar), const SizedBox(height: 8), legend]);
              },
            ),
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
                  Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('· ${s.text(r)}', style: theme.textTheme.bodySmall)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
