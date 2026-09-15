import 'package:flutter/material.dart' hide Element;

import '../../core/bazi/bazi_chart.dart';
import '../../core/bazi/ten_gods.dart';
import '../../core/calendar/sexagenary.dart';
import '../../l10n/glossary.dart';
import '../../l10n/strings.dart';
import '../theme.dart';

/// 大运时间轴:每步十年一段,按天干五行喜忌着色,标出"现在",
/// 点选一步展开它的十个流年。
class LuckTimeline extends StatefulWidget {
  const LuckTimeline({super.key, required this.chart});
  final BaziChart chart;

  @override
  State<LuckTimeline> createState() => _LuckTimelineState();
}

class _LuckTimelineState extends State<LuckTimeline> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().year;
    final cycles = widget.chart.luck.cycles;
    for (var i = 0; i < cycles.length; i++) {
      if (now >= cycles[i].startYear && now <= cycles[i].endYear) _selected = i;
    }
  }

  Color _tone(int stem) {
    final el = stemElements[stem];
    final e = widget.chart.elements;
    if (e.favorable.contains(el)) return AppColors.jade;
    if (e.unfavorable.contains(el)) return AppColors.cinnabar;
    return AppColors.gold;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final chart = widget.chart;
    final luck = chart.luck;
    final now = DateTime.now().year;
    final desc = s.en
        ? 'Starts ${luck.startYears}y ${luck.startMonths}m ${luck.startDays}d after birth (${s.term(luck.direction)})'
        : s.text(luck.startDescription);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.luckCycles, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(desc, style: theme.textTheme.bodySmall),
            if (chart.input.timeMode.isEstimated) Text(s.hourEstimated, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.gold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < luck.cycles.length; i++) _cycleColumn(context, i, now),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _legend(theme, AppColors.jade, s.favorable),
                const SizedBox(width: 12),
                _legend(theme, AppColors.gold, s.en ? 'neutral' : '平'),
                const SizedBox(width: 12),
                _legend(theme, AppColors.cinnabar, s.unfavorable),
                const Spacer(),
                Text(s.tapCycleHint, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
            if (_selected != null) ...[
              const Divider(height: 24),
              _yearsGrid(context, luck.cycles[_selected!], now),
            ],
          ],
        ),
      ),
    );
  }

  Widget _legend(ThemeData theme, Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      );

  Widget _cycleColumn(BuildContext context, int i, int now) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final c = widget.chart.luck.cycles[i];
    final tone = _tone(c.pillar.stem);
    final isNow = now >= c.startYear && now <= c.endYear;
    final selected = _selected == i;
    // "现在"在这十年里走到了哪里
    final progress = isNow ? ((now - c.startYear) + 0.5) / 10 : null;

    return GestureDetector(
      onTap: () => setState(() => _selected = selected ? null : i),
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 6),
        child: Column(
          children: [
            SizedBox(
              height: 18,
              child: isNow
                  ? Align(
                      alignment: Alignment(progress! * 2 - 1, 0),
                      child: Text(s.nowMarker, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                    )
                  : null,
            ),
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(color: tone.withValues(alpha: selected ? 1 : 0.55), borderRadius: BorderRadius.circular(4)),
                ),
                if (isNow)
                  Positioned(
                    left: progress! * 78 - 5,
                    top: -3,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle, border: Border.all(color: theme.colorScheme.surface, width: 2)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                border: selected ? Border.all(color: theme.colorScheme.primary) : null,
              ),
              child: Column(
                children: [
                  Text(c.pillar.stemName, style: TextStyle(fontSize: 22, height: 1.1, fontWeight: FontWeight.w700, color: elementColor[c.pillar.stemElement.label])),
                  Text(c.pillar.branchName, style: TextStyle(fontSize: 22, height: 1.1, fontWeight: FontWeight.w700, color: elementColor[c.pillar.branchElement.label])),
                  if (s.en) Text(stemBranchEn(c.pillar), style: theme.textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(s.term(tenGodOf(widget.chart.dayStem, c.pillar.stem).label), style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
                  Text('${c.startNominalAge}–${c.startNominalAge + 9}', style: theme.textTheme.labelSmall),
                  Text('${c.startYear}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _yearsGrid(BuildContext context, dynamic cycle, int now) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final dayStem = widget.chart.dayStem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${s.yearlyLuck} · ${s.en ? stemBranchEn(cycle.pillar) : cycle.pillar.name} (${cycle.startYear}–${cycle.endYear})', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final y in cycle.years)
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: y.year == now ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
                  border: Border.all(color: y.year == now ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Text('${y.year}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                    Text(y.pillar.name, style: TextStyle(fontWeight: FontWeight.w700, color: _tone(y.pillar.stem))),
                    Text(s.term(tenGodOf(dayStem, y.pillar.stem).label), style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
                    Text('${y.nominalAge}${s.age}', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
