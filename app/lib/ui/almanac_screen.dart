import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/almanac/almanac.dart';
import '../core/interpret/local_interpreter.dart';
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
    final chart = context.watch<AppState>().chart;

    return Scaffold(
      appBar: AppBar(
        title: const Text('黄历'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: '回到今天',
            onPressed: () => setState(() => _date = DateTime.now()),
          ),
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
                              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1900), lastDate: DateTime(2100), locale: const Locale('zh'));
                              if (d != null) setState(() => _date = d);
                            },
                            child: Text(a.dateText, style: theme.textTheme.titleMedium),
                          ),
                          IconButton(onPressed: () => setState(() => _date = _date.add(const Duration(days: 1))), icon: const Icon(Icons.chevron_right)),
                        ],
                      ),
                      Text('${a.day}', style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.cinnabar)),
                      Text('${a.lunar.monthName}${a.lunar.dayName} · ${a.weekdayName}', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(a.ganZhiText, style: theme.textTheme.bodyMedium),
                      Text('属${a.zodiac} · ${a.jianChu}日 · ${a.zhiShen}(${a.isHuangDao ? '黄道' : '黑道'}) · ${a.xiu}', style: theme.textTheme.bodySmall),
                      if (a.solarTerm != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Chip(label: Text('今日 ${a.solarTerm!.name}'), backgroundColor: AppColors.gold.withValues(alpha: 0.2)),
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
                      Expanded(child: _YiJi(title: '宜', items: a.suitable, color: AppColors.jade)),
                      const SizedBox(width: 16),
                      Expanded(child: _YiJi(title: '忌', items: a.unsuitable, color: AppColors.cinnabar)),
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
                      _kv(theme, '冲煞', a.clashText),
                      _kv(theme, '吉神', a.auspiciousGods.join(' ')),
                      if (a.inauspiciousGods.isNotEmpty) _kv(theme, '凶神', a.inauspiciousGods.join(' ')),
                      _kv(theme, '喜神', a.joyDirection),
                      _kv(theme, '财神', a.wealthDirection),
                      _kv(theme, '彭祖', a.pengZu.join(';')),
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
                      Text('时辰吉凶', style: theme.textTheme.titleMedium),
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
                                  Text(h.stemBranch.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  Text(h.range, style: theme.textTheme.labelSmall),
                                  Text(h.zhiShen, style: theme.textTheme.labelSmall),
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
                title: const Text('宜忌依据'),
                children: [for (final n in a.notes) ListTile(dense: true, title: Text(n))],
              ),
              AiReadingCard(
                title: 'AI 择日建议',
                load: (api) => api.interpretAlmanac(a.toJson(), chart?.toJson()),
                localText: () => localInterpretAlmanac(a, chart: chart),
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
            SizedBox(width: 44, child: Text(k, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline))),
            Expanded(child: Text(v, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
}

class _YiJi extends StatelessWidget {
  const _YiJi({required this.title, required this.items, required this.color});
  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        Text(items.isEmpty ? '—' : items.join('  '), style: theme.textTheme.bodyMedium?.copyWith(height: 1.8)),
      ],
    );
  }
}
