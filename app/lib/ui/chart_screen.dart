import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bazi/bazi_chart.dart';
import '../core/bazi/shen_sha.dart';
import '../core/bazi/ten_gods.dart';
import '../core/calendar/sexagenary.dart';
import '../core/interpret/local_interpreter.dart';
import '../services/app_state.dart';
import 'birth_input_screen.dart';
import 'theme.dart';
import 'widgets/ai_reading_card.dart';
import 'widgets/disclaimer.dart';
import 'widgets/element_bars.dart';
import 'widgets/pillar_table.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final chart = state.chart!;
    final input = chart.input;

    return Scaffold(
      appBar: AppBar(
        title: Text(input.name.isEmpty ? '${input.gender.chartLabel} · 八字命盘' : '${input.name} · ${input.gender.chartLabel}'),
        actions: [
          IconButton(
            tooltip: '编辑出生信息',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BirthInputScreen(initial: input, editIndex: state.activeIndex)),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _HeaderCard(chart: chart),
              PillarTable(chart: chart),
              ElementBars(analysis: chart.elements),
              _InteractionsCard(chart: chart),
              _ShenShaCard(chart: chart),
              _LuckCard(chart: chart),
              AiReadingCard(
                title: 'AI 命理解读',
                load: (api) => api.interpretBazi(chart.toJson()),
                localText: () => localInterpretBazi(chart),
              ),
              const Disclaimer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.chart});
  final BaziChart chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final i = chart.input;
    final clock = chart.trueSolar.trueSolarClock;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chart.summaryLine, style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('公历 ${i.year}-${_p(i.month)}-${_p(i.day)} ${_p(i.hour)}:${_p(i.minute)} · ${i.placeName.isEmpty ? '经度 ${i.longitude}' : i.placeName}',
                style: theme.textTheme.bodySmall),
            Text(chart.lunar.toString(), style: theme.textTheme.bodySmall),
            if (i.useTrueSolarTime)
              Text(
                '真太阳时 ${_p(clock.hour)}:${_p(clock.minute)}'
                '(经度 ${chart.trueSolar.longitudeCorrectionMinutes.toStringAsFixed(0)} 分,均时差 ${chart.trueSolar.equationOfTimeMinutes.toStringAsFixed(1)} 分)',
                style: theme.textTheme.bodySmall,
              ),
            Text(
              '${chart.previousTerm.name}后 ${(chart.effectiveJdUt - chart.previousTerm.jdUt).toStringAsFixed(1)} 天,'
              '距${chart.nextTerm.name} ${(chart.nextTerm.jdUt - chart.effectiveJdUt).toStringAsFixed(1)} 天',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(label: Text('生肖 ${chart.zodiac}')),
                Chip(label: Text('日主 ${chart.dayMasterName}${chart.dayMaster.label}')),
                Chip(label: Text('胎元 ${chart.taiYuan.name}')),
                Chip(label: Text('命宫 ${chart.mingGong.name}')),
                Chip(label: Text('身宫 ${chart.shenGong.name}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _p(int v) => v.toString().padLeft(2, '0');
}

class _InteractionsCard extends StatelessWidget {
  const _InteractionsCard({required this.chart});
  final BaziChart chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (chart.interactions.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('刑冲合害', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final it in chart.interactions)
                  Chip(
                    avatar: Icon(it.kind.isHarmonious ? Icons.favorite_outline : Icons.flash_on_outlined, size: 16),
                    label: Text(it.description),
                    backgroundColor: it.kind.isHarmonious
                        ? AppColors.jade.withValues(alpha: 0.12)
                        : theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShenShaCard extends StatelessWidget {
  const _ShenShaCard({required this.chart});
  final BaziChart chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('神煞', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (chart.shenSha.isEmpty) Text('无显著神煞', style: theme.textTheme.bodySmall),
            for (final s in chart.shenSha)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  switch (s.nature) {
                    ShenShaNature.auspicious => Icons.star_outline,
                    ShenShaNature.inauspicious => Icons.warning_amber_outlined,
                    ShenShaNature.neutral => Icons.circle_outlined,
                  },
                  size: 18,
                  color: switch (s.nature) {
                    ShenShaNature.auspicious => AppColors.gold,
                    ShenShaNature.inauspicious => theme.colorScheme.error,
                    ShenShaNature.neutral => theme.colorScheme.outline,
                  },
                ),
                title: Text('${s.name} · ${s.positions.map((p) => pillarNames[p]).join()}柱'),
                subtitle: Text('${s.meaning}\n${s.basis}', style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _LuckCard extends StatelessWidget {
  const _LuckCard({required this.chart});
  final BaziChart chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final luck = chart.luck;
    final nowYear = DateTime.now().year;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('大运', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(luck.startDescription, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in luck.cycles)
                    Container(
                      width: 72,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: (nowYear >= c.startYear && nowYear <= c.endYear)
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: Column(
                        children: [
                          Text(c.pillar.stemName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: elementColor[c.pillar.stemElement.label])),
                          Text(c.pillar.branchName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: elementColor[c.pillar.branchElement.label])),
                          const SizedBox(height: 4),
                          Text(tenGodOf(chart.dayStem, c.pillar.stem).label, style: theme.textTheme.labelSmall),
                          Text('${c.startNominalAge}岁', style: theme.textTheme.labelSmall),
                          Text('${c.startYear}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                        ],
                      ),
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
