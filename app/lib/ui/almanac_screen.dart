import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/almanac/almanac.dart';
import '../core/interpret/local_interpreter.dart';
import '../core/interpret/local_interpreter_en.dart';
import '../l10n/glossary.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import 'theme.dart';
import 'widgets/ai_reading_card.dart';
import 'widgets/disclaimer.dart';

class AlmanacScreen extends StatefulWidget {
  const AlmanacScreen({super.key});

  @override
  State<AlmanacScreen> createState() => _AlmanacScreenState();
}

class _AlmanacScreenState extends State<AlmanacScreen> {
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final a = almanacFor(_date.year, _date.month, _date.day);
    final theme = Theme.of(context);
    final s = S.of(context);
    final chart = context.watch<AppState>().chart;
    final sep = s.en ? ', ' : '  ';

    final lunarLine = s.en
        ? 'Lunar month ${a.lunar.month}${a.lunar.isLeapMonth ? ' (leap)' : ''}, day ${a.lunar.day} · ${s.weekday(a.weekday)}'
        : s.text('${a.lunar.monthName}${a.lunar.dayName} · ${s.weekday(a.weekday)}');
    final ganZhi = s.en
        ? '${stemBranchEn(a.yearPillar)} year · ${stemBranchEn(a.monthPillar)} month · ${stemBranchEn(a.dayPillar)} day'
        : s.text(a.ganZhiText);
    final clash = s.en
        ? 'Clashes ${animalEnglish[a.clashPillar.branch]} (${stemBranchEn(a.clashPillar)}) · Sha ${s.term(a.shaDirection)}'
        : s.text(a.clashText);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.almanac),
        actions: [
          IconButton(icon: const Icon(Icons.today), tooltip: s.backToToday, onPressed: () => setState(() => _date = DateTime.now())),
        ],
      ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(onPressed: () => setState(() => _date = _date.subtract(const Duration(days: 1))), icon: const Icon(Icons.chevron_left)),
                          TextButton(
                            onPressed: () async {
                              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1900), lastDate: DateTime(2100));
                              if (d != null) setState(() => _date = d);
                            },
                            child: Text(s.ymd(a.year, a.month, a.day), style: theme.textTheme.titleMedium),
                          ),
                          IconButton(onPressed: () => setState(() => _date = _date.add(const Duration(days: 1))), icon: const Icon(Icons.chevron_right)),
                        ],
                      ),
                      Text('${a.day}', style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.cinnabar)),
                      Text(lunarLine, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(ganZhi, style: theme.textTheme.bodyMedium),
                      Text(s.almanacLine(s.animal(a.yearPillar.branch), a.jianChu, a.zhiShen, a.isHuangDao, a.xiu), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                      if (a.solarTerm != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Chip(label: Text(s.solarTermToday(s.term(a.solarTerm!.name))), backgroundColor: AppColors.gold.withValues(alpha: 0.2)),
                        ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _YiJi(title: s.suitable, text: a.suitable.isEmpty ? '—' : s.text(a.suitable.join(sep)), color: AppColors.jade)),
                      const SizedBox(width: 16),
                      Expanded(child: _YiJi(title: s.unsuitable, text: a.unsuitable.isEmpty ? '—' : s.text(a.unsuitable.join(sep)), color: AppColors.cinnabar)),
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
                      _kv(theme, s.clash, clash),
                      _kv(theme, s.auspiciousGods, s.text(a.auspiciousGods.join(' '))),
                      if (a.inauspiciousGods.isNotEmpty) _kv(theme, s.inauspiciousGods, s.text(a.inauspiciousGods.join(' '))),
                      _kv(theme, s.joyGod, s.term(a.joyDirection)),
                      _kv(theme, s.wealthGod, s.term(a.wealthDirection)),
                      _kv(theme, s.pengZu, s.text(a.pengZu.join(';'))),
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
                      Text(s.hourFortunes, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final h in a.hourFortunes)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: h.isHuangDao ? AppColors.jade.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest,
                              ),
                              child: Column(
                                children: [
                                  Text(s.en ? stemBranchEn(h.stemBranch) : h.stemBranch.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  Text(h.range, style: theme.textTheme.labelSmall),
                                  Text(s.term(h.zhiShen), style: theme.textTheme.labelSmall),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ExpansionTile(
                title: Text(s.whyRules),
                children: [for (final n in a.notes) ListTile(dense: true, title: Text(s.text(n)))],
              ),
              AiReadingCard(
                title: s.aiAlmanac,
                load: (api) => api.interpretAlmanac(a.toJson(), chart?.toJson()),
                localText: () => s.en ? enInterpretAlmanac(a, chart: chart) : localInterpretAlmanac(a, chart: chart),
              ),
              const Disclaimer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(ThemeData theme, String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 72, child: Text(k, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline))),
            Expanded(child: Text(v, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
}

class _YiJi extends StatelessWidget {
  const _YiJi({required this.title, required this.text, required this.color});
  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.8)),
      ],
    );
  }
}
