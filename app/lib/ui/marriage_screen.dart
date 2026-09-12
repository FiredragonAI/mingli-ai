import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bazi/bazi_chart.dart';
import '../core/interpret/local_interpreter.dart';
import '../core/zodiac/western_zodiac.dart';
import '../services/app_state.dart';
import 'birth_input_screen.dart';
import 'zodiac_screen.dart' show zodiacOfChart;
import 'widgets/ai_reading_card.dart';
import 'widgets/disclaimer.dart';

class MarriageScreen extends StatelessWidget {
  const MarriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final me = state.chart!;
    final partner = state.partnerChart;
    final result = state.marriage;

    return Scaffold(
      appBar: AppBar(title: const Text('合婚')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text('${me.input.gender.chartLabel} ${me.summaryLine}'),
                      subtitle: Text('${me.input.name.isEmpty ? '本人' : me.input.name} · 属${me.zodiac} · 日主${me.dayMasterName}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_outlined),
                      title: Text(partner == null ? '添加对方出生信息' : '${partner.input.gender.chartLabel} ${partner.summaryLine}'),
                      subtitle: partner == null ? null : Text('属${partner.zodiac} · 日主${partner.dayMasterName}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BirthInputScreen(
                            title: '对方出生信息',
                            initial: partner?.input ??
                                BirthInput(
                                  year: 1995, month: 6, day: 15, hour: 12, minute: 0,
                                  gender: me.input.gender == Gender.male ? Gender.female : Gender.male,
                                  longitude: 116.41,
                                ),
                            onSubmit: (i) => context.read<AppState>().setPartner(i),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (result != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('${result.overall}', style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                        Text(result.grade, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final h in result.highlights) Chip(avatar: const Icon(Icons.favorite, size: 14), label: Text(h)),
                            for (final c in result.cautions) Chip(avatar: const Icon(Icons.info_outline, size: 14), label: Text(c)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                for (final d in result.dimensions)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(d.name, style: theme.textTheme.titleSmall)),
                              Text('${d.clamped}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              Text(' / 100 · 权重 ${(d.weight * 100).round()}%', style: theme.textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: d.clamped / 100, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                          const SizedBox(height: 8),
                          for (final r in d.reasons) Text('· $r', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                _ZodiacMatchCard(me: zodiacOfChart(me), partner: zodiacOfChart(partner!)),
                AiReadingCard(
                  title: 'AI 合婚解读',
                  load: (api) => api.interpretMarriage(result.toJson()),
                  localText: () => localInterpretMarriage(result),
                ),
              ],
              const Disclaimer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZodiacMatchCard extends StatelessWidget {
  const _ZodiacMatchCard({required this.me, required this.partner});
  final ZodiacProfile me;
  final ZodiacProfile partner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = zodiacMatch(me.sun, partner.sun);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('星座配对 · ${m.a.symbol}${m.a.name} × ${m.b.symbol}${m.b.name}',
                      style: theme.textTheme.titleSmall),
                ),
                Text('${m.score}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(' · ${m.summary}', style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: m.score / 100, minHeight: 8, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 8),
            for (final r in m.reasons) Text('· $r', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
