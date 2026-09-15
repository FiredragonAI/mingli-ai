import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bazi/bazi_chart.dart';
import '../core/bazi/shen_sha.dart';
import '../core/interpret/local_interpreter.dart';
import '../core/interpret/local_interpreter_en.dart';
import '../data/cities.dart';
import '../l10n/glossary.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import 'birth_input_screen.dart';
import 'theme.dart';
import 'widgets/ai_reading_card.dart';
import 'widgets/disclaimer.dart';
import 'widgets/element_radar.dart';
import 'widgets/luck_timeline.dart';
import 'widgets/pillar_table.dart';
import 'widgets/share_card.dart';
import 'zodiac_screen.dart' show zodiacOfChart;

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final chart = state.chart!;
    final input = chart.input;

    return Scaffold(
      appBar: AppBar(
        title: Text(input.name.isEmpty ? '${s.term(input.gender.chartLabel)} · ${s.chartTitle}' : '${input.name} · ${s.term(input.gender.chartLabel)}'),
        actions: [
          IconButton(
            tooltip: s.shareCard,
            icon: const Icon(Icons.ios_share),
            onPressed: () => showShareCard(context, chart, zodiacOfChart(chart)),
          ),
          IconButton(
            tooltip: s.editBirth,
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
              ElementRadarCard(analysis: chart.elements),
              _InteractionsCard(chart: chart),
              _ShenShaCard(chart: chart),
              LuckTimeline(chart: chart),
              AiReadingCard(
                title: s.aiBazi,
                load: (api) => api.interpretBazi(chart.toJson()),
                localText: () => s.en ? enInterpretBazi(chart) : localInterpretBazi(chart),
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
    final s = S.of(context);
    final i = chart.input;
    final clock = chart.trueSolar.trueSolarClock;
    final western = zodiacOfChart(chart).sun;
    final place = s.en ? cityEnglish(i.placeName) : s.text(i.placeName);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.en ? summaryEn(chart) : chart.summaryLine,
                style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: s.en ? 0 : 2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('${s.gregorian} ${i.year}-${_p(i.month)}-${_p(i.day)} ${_p(i.hour)}:${_p(i.minute)} · $place', style: theme.textTheme.bodySmall),
            Text(s.en ? lunarEn(chart.lunar) : s.text(chart.lunar.toString()), style: theme.textTheme.bodySmall),
            if (i.useTrueSolarTime)
              Text(
                s.trueSolar('${_p(clock.hour)}:${_p(clock.minute)}', chart.trueSolar.longitudeCorrectionMinutes.toStringAsFixed(0),
                    chart.trueSolar.equationOfTimeMinutes.toStringAsFixed(1)),
                style: theme.textTheme.bodySmall,
              ),
            Text(
              s.termDistance(s.term(chart.previousTerm.name), (chart.effectiveJdUt - chart.previousTerm.jdUt).toStringAsFixed(1),
                  s.term(chart.nextTerm.name), (chart.nextTerm.jdUt - chart.effectiveJdUt).toStringAsFixed(1)),
              style: theme.textTheme.bodySmall,
            ),
            if (i.timeMode.isEstimated)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(s.hourEstimated, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.gold)),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(label: Text('${s.zodiacChip} ${s.animal(chart.yearPillar.stemBranch.branch)}')),
                Chip(label: Text('${western.symbol} ${s.en ? western.english : s.text(western.name)}')),
                Chip(label: Text('${s.dayMasterChip} ${s.en ? stemEn(chart.dayStem) : '${chart.dayMasterName}${s.term(chart.dayMaster.label)}'}')),
                Chip(label: Text('${s.taiYuan} ${s.en ? stemBranchEn(chart.taiYuan) : chart.taiYuan.name}')),
                Chip(label: Text('${s.mingGong} ${s.en ? stemBranchEn(chart.mingGong) : chart.mingGong.name}')),
                Chip(label: Text('${s.shenGong} ${s.en ? stemBranchEn(chart.shenGong) : chart.shenGong.name}')),
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
    final s = S.of(context);
    if (chart.interactions.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.interactions, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final it in chart.interactions)
                  Chip(
                    avatar: Icon(it.kind.isHarmonious ? Icons.favorite_outline : Icons.flash_on_outlined, size: 16),
                    label: Text(s.text(it.description)),
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
    final s = S.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.shenSha, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (chart.shenSha.isEmpty) Text(s.noShenSha, style: theme.textTheme.bodySmall),
            for (final sh in chart.shenSha)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  switch (sh.nature) {
                    ShenShaNature.auspicious => Icons.star_outline,
                    ShenShaNature.inauspicious => Icons.warning_amber_outlined,
                    ShenShaNature.neutral => Icons.circle_outlined,
                  },
                  size: 18,
                  color: switch (sh.nature) {
                    ShenShaNature.auspicious => AppColors.gold,
                    ShenShaNature.inauspicious => theme.colorScheme.error,
                    ShenShaNature.neutral => theme.colorScheme.outline,
                  },
                ),
                title: Text('${s.term(sh.name)} · ${sh.positions.map((p) => s.pillar(p)).join(s.en ? '/' : '')}${s.pillarSuffix}'),
                subtitle: Text('${s.text(sh.meaning)}\n${s.text(sh.basis)}', style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

