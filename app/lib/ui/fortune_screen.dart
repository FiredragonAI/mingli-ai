import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fortune/daily_fortune.dart';
import '../core/interpret/local_interpreter.dart';
import '../core/interpret/local_interpreter_en.dart';
import '../l10n/glossary.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import 'widgets/ai_reading_card.dart';
import 'widgets/disclaimer.dart';

class FortuneScreen extends StatelessWidget {
  const FortuneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final chart = state.chart!;
    final today = state.today ?? todayFortune(chart);
    final week = fortuneRange(chart, days: 7);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.todayFortune)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(s.fortuneDate(today.year, today.month, today.day, s.en ? stemBranchEn(today.dayPillar) : today.dayPillar.name),
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(s.todayTheme(s.term(today.theme.label), s.term(today.theme.group)), style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      _ScoreRing(score: today.overall, label: s.overall),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiniScore(s.career, today.career),
                          _MiniScore(s.wealth, today.wealth),
                          _MiniScore(s.love, today.love),
                          _MiniScore(s.health, today.health),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Chip(avatar: const Icon(Icons.palette_outlined, size: 16), label: Text('${s.luckyColor} ${s.term(today.luckyColor)}')),
                          Chip(avatar: const Icon(Icons.pin_outlined, size: 16), label: Text('${s.luckyNumbers} ${today.luckyNumbers.join(s.en ? ', ' : '、')}')),
                          Chip(avatar: const Icon(Icons.explore_outlined, size: 16), label: Text('${s.luckyDirection} ${s.term(today.luckyDirection)}')),
                          for (final k in today.keywords) Chip(label: Text(s.text(k))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nextSevenDays, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 100,
                            gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    final i = v.toInt();
                                    if (i < 0 || i >= week.length) return const SizedBox.shrink();
                                    return Text('${week[i].month}/${week[i].day}', style: theme.textTheme.labelSmall);
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [for (var i = 0; i < week.length; i++) FlSpot(i.toDouble(), week[i].overall.toDouble())],
                                isCurved: true,
                                color: theme.colorScheme.primary,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withValues(alpha: 0.12)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.factors, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      for (final f in today.factors)
                        Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('· ${s.text(f)}', style: theme.textTheme.bodySmall)),
                    ],
                  ),
                ),
              ),
              AiReadingCard(
                title: s.aiDaily,
                load: (api) => api.interpretDaily(chart.toJson(), today.toJson()),
                localText: () => s.en ? enInterpretDaily(chart, today) : localInterpretDaily(chart, today),
              ),
              const Disclaimer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.label});
  final int score;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore(this.label, this.score);
  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text('$score', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
