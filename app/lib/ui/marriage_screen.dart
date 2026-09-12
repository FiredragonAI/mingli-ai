import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bazi/bazi_chart.dart';
import '../core/interpret/local_interpreter.dart';
import '../core/interpret/local_interpreter_en.dart';
import '../core/zodiac/western_zodiac.dart';
import '../l10n/glossary.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import 'birth_input_screen.dart';
import 'widgets/ai_reading_card.dart';
import 'widgets/disclaimer.dart';
import 'zodiac_screen.dart' show zodiacOfChart;

class MarriageScreen extends StatelessWidget {
  const MarriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final theme = Theme.of(context);
    final me = state.chart!;
    final partner = state.partnerChart;
    final result = state.marriage;

    String summary(BaziChart c) => s.en ? summaryEn(c) : c.summaryLine;
    String dm(BaziChart c) => s.en ? stemPinyin[c.dayStem] : c.dayMasterName;

    return Scaffold(
      appBar: AppBar(title: Text(s.marriage)),
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
                      title: Text('${s.term(me.input.gender.chartLabel)} ${summary(me)}'),
                      subtitle: Text('${me.input.name.isEmpty ? s.me : me.input.name} · ${s.animalAndDayMaster(s.animal(me.yearPillar.stemBranch.branch), dm(me))}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_outlined),
                      title: Text(partner == null ? s.addPartner : '${s.term(partner.input.gender.chartLabel)} ${summary(partner)}'),
                      subtitle: partner == null ? null : Text(s.animalAndDayMaster(s.animal(partner.yearPillar.stemBranch.branch), dm(partner))),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BirthInputScreen(
                            title: s.partnerBirthDetails,
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
                        Text(s.term(result.grade), style: theme.textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final h in result.highlights) Chip(avatar: const Icon(Icons.favorite, size: 14), label: Text(s.text(h))),
                            for (final c in result.cautions) Chip(avatar: const Icon(Icons.info_outline, size: 14), label: Text(s.text(c))),
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
                              Expanded(child: Text(s.term(d.name), style: theme.textTheme.titleSmall)),
                              Text('${d.clamped}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              Text(' / 100 · ${s.weight} ${(d.weight * 100).round()}%', style: theme.textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: d.clamped / 100, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                          const SizedBox(height: 8),
                          for (final r in d.reasons) Text('· ${s.text(r)}', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                _ZodiacMatchCard(me: zodiacOfChart(me), partner: zodiacOfChart(partner!)),
                AiReadingCard(
                  title: s.aiMarriage,
                  load: (api) => api.interpretMarriage(result.toJson()),
                  localText: () => s.en ? enInterpretMarriage(result) : localInterpretMarriage(result),
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
    final s = S.of(context);
    final m = zodiacMatch(me.sun, partner.sun);
    String name(ZodiacSign z) => s.en ? z.english : s.text(z.name);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('${s.zodiacMatchTitle} · ${m.a.symbol}${name(m.a)} × ${m.b.symbol}${name(m.b)}', style: theme.textTheme.titleSmall)),
                Text('${m.score}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(' · ${s.term(m.summary)}', style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: m.score / 100, minHeight: 8, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 8),
            for (final r in m.reasons) Text('· ${s.text(r)}', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
