import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bazi/bazi_chart.dart';
import '../core/interpret/local_interpreter.dart';
import '../core/interpret/local_interpreter_en.dart';
import '../core/zodiac/western_zodiac.dart';
import '../l10n/glossary.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import 'theme.dart';
import 'widgets/ai_reading_card.dart';
import 'widgets/disclaimer.dart';

/// 由命盘取星座档案(出生时刻、经纬度都在命盘里)。
ZodiacProfile zodiacOfChart(BaziChart c) => zodiacProfile(
      birthJdUt: c.trueSolar.standardJdUt,
      longitude: c.input.longitude,
      latitude: c.input.latitude,
    );

class ZodiacScreen extends StatelessWidget {
  const ZodiacScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final chart = state.chart!;
    final me = zodiacOfChart(chart);
    final partner = state.partnerChart == null ? null : zodiacOfChart(state.partnerChart!);
    final match = partner == null ? null : zodiacMatch(me.sun, partner.sun);
    final theme = Theme.of(context);
    final sign = me.sun;
    final zen = zodiacEn[sign.index];

    String name(ZodiacSign z) => s.en ? z.english : s.text(z.name);
    List<String> kw(List<String> zh, List<String> en) => s.en ? en : zh.map(s.text).toList();
    final joiner = s.en ? ', ' : '、';

    return Scaffold(
      appBar: AppBar(title: Text(s.zodiac)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(sign.symbol, style: const TextStyle(fontSize: 64, height: 1.1)),
                      Text(name(sign), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text('${s.en ? s.text(sign.name) : sign.english} · ${sign.dateRange}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          Chip(label: Text(s.elementSign(s.zodiacElement(sign.element.label))), backgroundColor: _elementColor(sign.element).withValues(alpha: 0.18)),
                          Chip(label: Text(s.modalitySign(s.zodiacModality(sign.modality.label)))),
                          Chip(label: Text(s.ruler(s.term(sign.ruler)))),
                          Chip(label: Text(s.sunDegree(me.sunDegreeInSign.toStringAsFixed(1)))),
                        ],
                      ),
                      if (me.nearCusp)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(s.cuspNote(name(me.cuspNeighbour!)), textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.gold)),
                        ),
                    ],
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Text(me.rising?.symbol ?? '—', style: const TextStyle(fontSize: 28)),
                  title: Text(me.rising == null ? s.risingUnknown : s.risingSign(name(me.rising!))),
                  subtitle: Text(
                    me.rising == null
                        ? s.risingNeedsPlace
                        : '${s.en ? zodiacEn[me.rising!.index].rising : s.text(me.rising!.risingTrait)}.\n${s.risingNote}',
                    style: theme.textTheme.bodySmall,
                  ),
                  isThreeLine: me.rising != null,
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.personality, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _chipRow(theme, s.keywords, kw(sign.keywords, zen.keywords), theme.colorScheme.primaryContainer),
                      const SizedBox(height: 8),
                      _chipRow(theme, s.strengths, kw(sign.strengths, zen.strengths), AppColors.jade.withValues(alpha: 0.18)),
                      const SizedBox(height: 8),
                      _chipRow(theme, s.watchOut, kw(sign.weaknesses, zen.weaknesses), theme.colorScheme.errorContainer.withValues(alpha: 0.6)),
                      const Divider(height: 24),
                      Text(s.luckyLine(s.en ? zen.color : s.text(sign.luckyColor), sign.luckyNumbers.join(joiner)), style: theme.textTheme.bodyMedium),
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
                      Text(s.zodiacMatchTitle, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (match != null) ...[
                        Row(
                          children: [
                            Expanded(child: Text('${match.a.symbol}${name(match.a)} × ${match.b.symbol}${name(match.b)}', style: theme.textTheme.titleSmall)),
                            Text('${match.score}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                            Text(' · ${s.term(match.summary)}', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final r in match.reasons) Text('· ${s.text(r)}', style: theme.textTheme.bodySmall),
                        const Divider(height: 24),
                      ],
                      Text(s.bestMatches(name(sign)), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final b in bestMatchesFor(sign)) Chip(avatar: Text(b.symbol), label: Text('${name(b)} ${zodiacMatch(sign, b).score}')),
                        ],
                      ),
                      if (match == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(s.pairingHint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                        ),
                    ],
                  ),
                ),
              ),
              AiReadingCard(
                key: ValueKey('zodiac-${me.sun.index}-${me.rising?.index}-${match?.score}'),
                title: s.aiZodiac,
                load: (api) => api.interpretZodiac(me.toJson(), match?.toJson(), chart.toJson()),
                localText: () => s.en
                    ? enInterpretZodiac(me, match: match, chart: chart)
                    : localInterpretZodiac(me, match: match, chart: chart),
              ),
              const Disclaimer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipRow(ThemeData theme, String label, List<String> items, Color color) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            ),
          ),
          Expanded(
            child: Wrap(spacing: 6, runSpacing: 6, children: [for (final t in items) Chip(label: Text(t), backgroundColor: color)]),
          ),
        ],
      );

  static Color _elementColor(ZodiacElement e) => switch (e) {
        ZodiacElement.fire => const Color(0xFFD9534F),
        ZodiacElement.earth => const Color(0xFFB8860B),
        ZodiacElement.air => const Color(0xFF6FA8DC),
        ZodiacElement.water => const Color(0xFF2F6FB3),
      };
}
