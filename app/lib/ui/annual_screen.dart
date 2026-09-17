import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fortune/annual_fortune.dart';
import '../core/interpret/local_interpreter.dart';
import '../core/interpret/local_interpreter_en.dart';
import '../l10n/glossary.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import 'theme.dart';
import 'widgets/ai_reading_card.dart';
import 'widgets/disclaimer.dart';

/// 流年运势:选年份 → 总评、太岁、四项、十二流月柱状图、依据、AI。
class AnnualScreen extends StatefulWidget {
  const AnnualScreen({super.key});

  @override
  State<AnnualScreen> createState() => _AnnualScreenState();
}

class _AnnualScreenState extends State<AnnualScreen> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final theme = Theme.of(context);
    final chart = state.chart!;
    final a = annualFortune(chart, _year);
    final now = DateTime.now().year;
    final pillar = s.en ? stemBranchEn(a.yearPillar) : a.yearPillar.name;
    final gradeColor = a.overall >= 65 ? AppColors.jade : a.overall >= 50 ? AppColors.gold : AppColors.cinnabar;

    return Scaffold(
      appBar: AppBar(title: Text(s.annualTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ---------- 年份选择 + 总评 ----------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(onPressed: () => setState(() => _year--), icon: const Icon(Icons.chevron_left)),
                          Column(
                            children: [
                              Text(s.annualHeader(a.year, pillar, a.nominalAge), style: theme.textTheme.titleMedium),
                              if (_year != now)
                                TextButton(onPressed: () => setState(() => _year = now), child: Text(s.thisYear)),
                            ],
                          ),
                          IconButton(onPressed: () => setState(() => _year++), icon: const Icon(Icons.chevron_right)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${a.overall}', style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: gradeColor)),
                      Text(s.term(a.grade), style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        a.luckPillar == null
                            ? s.beforeLuckStart
                            : s.inLuckCycle(s.en ? stemBranchEn(a.luckPillar!.pillar) : a.luckPillar!.pillar.name, a.year - a.luckPillar!.startYear + 1),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                      const SizedBox(height: 12),
                      Text(s.todayTheme(s.term(a.theme.label), s.term(a.theme.group)).replaceFirst(s.en ? 'Today' : '今日', s.en ? 'Theme' : '主题'),
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _mini(theme, s.career, a.career),
                          _mini(theme, s.wealth, a.wealth),
                          _mini(theme, s.love, a.love),
                          _mini(theme, s.health, a.health),
                        ],
                      ),
                      if (a.keywords.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(spacing: 6, children: [for (final k in a.keywords) Chip(label: Text('#${s.text(k)}'))]),
                      ],
                    ],
                  ),
                ),
              ),

              // ---------- 太岁 ----------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(a.isOffendingTaiSui ? Icons.warning_amber_rounded : Icons.shield_outlined,
                              color: a.isOffendingTaiSui ? AppColors.cinnabar : AppColors.jade),
                          const SizedBox(width: 8),
                          Text(a.isOffendingTaiSui ? s.offendingTaiSui : s.taiSuiTitle, style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (a.taiSui.isEmpty)
                        Text(s.noTaiSui, style: theme.textTheme.bodyMedium)
                      else
                        for (final t in a.taiSui)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text.rich(TextSpan(children: [
                              TextSpan(text: '${s.term(t.label)}  ', style: TextStyle(fontWeight: FontWeight.w700, color: t.isOffending ? AppColors.cinnabar : AppColors.jade)),
                              TextSpan(text: s.text(t.meaning), style: theme.textTheme.bodySmall),
                            ])),
                          ),
                    ],
                  ),
                ),
              ),

              // ---------- 十二流月 ----------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.monthlyTitle, style: theme.textTheme.titleMedium),
                      Text(s.monthlyHint, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 170,
                        child: BarChart(
                          BarChartData(
                            minY: 0,
                            maxY: 100,
                            gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (g, gi, rod, ri) {
                                  final m = a.months[g.x.toInt()];
                                  return BarTooltipItem(
                                    '${s.en ? stemBranchEn(m.pillar) : m.pillar.name}  ${m.score}\n${s.term(m.theme.label)}',
                                    theme.textTheme.labelSmall!.copyWith(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget: (v, _) {
                                    if (v != v.roundToDouble()) return const SizedBox.shrink();
                                    final i = v.round();
                                    if (i < 0 || i >= a.months.length) return const SizedBox.shrink();
                                    final m = a.months[i];
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(m.pillar.branchName, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                                        Text(s.monthApprox(monthApproxLabel(i)), style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: theme.colorScheme.outline)),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: [
                              for (final m in a.months)
                                BarChartGroupData(
                                  x: m.index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: m.score.toDouble(),
                                      width: 14,
                                      borderRadius: BorderRadius.circular(4),
                                      color: a.bestMonths.contains(m.index)
                                          ? AppColors.jade
                                          : a.cautionMonths.contains(m.index)
                                              ? AppColors.cinnabar
                                              : theme.colorScheme.primary.withValues(alpha: 0.6),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final m in a.months)
                        if (a.bestMonths.contains(m.index) || a.cautionMonths.contains(m.index))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${a.bestMonths.contains(m.index) ? '⭐' : '⚠'} ${s.en ? stemBranchEn(m.pillar) : '${m.pillar.name}月'} (≈${s.monthApprox(monthApproxLabel(m.index))}) ${m.score} — ${s.text(m.note)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                    ],
                  ),
                ),
              ),

              // ---------- 依据 ----------
              ExpansionTile(
                title: Text(s.factors),
                children: [for (final f in a.factors) ListTile(dense: true, title: Text(s.text(f)))],
              ),

              AiReadingCard(
                key: ValueKey('annual-$_year'),
                title: s.aiAnnual,
                load: (api) => api.interpretAnnual(chart.toJson(), a.toJson()),
                localText: () => s.en ? enInterpretAnnual(chart, a) : localInterpretAnnual(chart, a),
              ),
              const Disclaimer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mini(ThemeData theme, String label, int v) => Expanded(
        child: Column(
          children: [
            Text('$v', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      );
}
