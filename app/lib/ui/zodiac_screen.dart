import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bazi/bazi_chart.dart';
import '../core/interpret/local_interpreter.dart';
import '../core/zodiac/western_zodiac.dart';
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
    final chart = state.chart!;
    final me = zodiacOfChart(chart);
    final partner = state.partnerChart == null ? null : zodiacOfChart(state.partnerChart!);
    final match = partner == null ? null : zodiacMatch(me.sun, partner.sun);
    final theme = Theme.of(context);
    final s = me.sun;

    return Scaffold(
      appBar: AppBar(title: const Text('星座')),
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
                      Text(s.symbol, style: const TextStyle(fontSize: 64, height: 1.1)),
                      Text(s.name, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text('${s.english} · ${s.dateRange}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          Chip(label: Text('${s.element.label}象'), backgroundColor: _elementColor(s.element).withValues(alpha: 0.18)),
                          Chip(label: Text('${s.modality.label}星座')),
                          Chip(label: Text('守护星 ${s.ruler}')),
                          Chip(label: Text('太阳 ${me.sunDegreeInSign.toStringAsFixed(1)}°')),
                        ],
                      ),
                      if (me.nearCusp)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            '出生在换宫日附近,距${me.cuspNeighbour!.name}边界不到 1°,两座特质可能兼有。',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.gold),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Text(me.rising?.symbol ?? '—', style: const TextStyle(fontSize: 28)),
                  title: Text(me.rising == null ? '上升星座:信息不足' : '上升 ${me.rising!.name}'),
                  subtitle: Text(
                    me.rising == null
                        ? '需要出生地经纬度'
                        : '${me.rising!.risingTrait}。\n上升星座约每两小时换一个,依赖准确出生时间。',
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
                      Text('性格画像', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('${s.element.label}象:${s.element.keywords} · ${s.modality.label}星座:${s.modality.keywords}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                      const SizedBox(height: 12),
                      _chipRow(theme, '关键词', s.keywords, theme.colorScheme.primaryContainer),
                      const SizedBox(height: 8),
                      _chipRow(theme, '优势', s.strengths, AppColors.jade.withValues(alpha: 0.18)),
                      const SizedBox(height: 8),
                      _chipRow(theme, '需留意', s.weaknesses, theme.colorScheme.errorContainer.withValues(alpha: 0.6)),
                      const Divider(height: 24),
                      Text('幸运色 ${s.luckyColor} · 幸运数字 ${s.luckyNumbers.join('、')}', style: theme.textTheme.bodyMedium),
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
                      Text('星座配对', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (match != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text('${match.a.symbol}${match.a.name} × ${match.b.symbol}${match.b.name}',
                                  style: theme.textTheme.titleSmall),
                            ),
                            Text('${match.score}',
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                            Text(' · ${match.summary}', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final r in match.reasons) Text('· $r', style: theme.textTheme.bodySmall),
                        const Divider(height: 24),
                      ],
                      Text('与${s.name}较合拍:', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final b in bestMatchesFor(s))
                            Chip(avatar: Text(b.symbol), label: Text('${b.name} ${zodiacMatch(s, b).score}')),
                        ],
                      ),
                      if (match == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('在"合婚"里填写对方出生信息后,这里会显示两人的星座配对。',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                        ),
                    ],
                  ),
                ),
              ),
              AiReadingCard(
                key: ValueKey('zodiac-${me.sun.index}-${me.rising?.index}-${match?.score}'),
                title: 'AI 星座解读',
                load: (api) => api.interpretZodiac(me.toJson(), match?.toJson(), chart.toJson()),
                localText: () => localInterpretZodiac(me, match: match, chart: chart),
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
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final t in items) Chip(label: Text(t), backgroundColor: color)],
            ),
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
