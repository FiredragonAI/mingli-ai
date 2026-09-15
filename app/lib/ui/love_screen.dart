import 'package:flutter/material.dart' hide Element;
import 'package:provider/provider.dart';

import '../core/calendar/sexagenary.dart';
import '../core/interpret/local_interpreter.dart';
import '../core/interpret/local_interpreter_en.dart';
import '../core/marriage/love_forecast.dart';
import '../l10n/glossary.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import 'marriage_screen.dart' show MarriagePairBody;
import 'theme.dart';
import 'widgets/ai_reading_card.dart';
import 'widgets/disclaimer.dart';

/// 感情:「我的婚缘」(只用本人命盘)在前,「合婚」(填对方)在后。
class LoveScreen extends StatefulWidget {
  const LoveScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<LoveScreen> createState() => _LoveScreenState();
}

class _LoveScreenState extends State<LoveScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.love),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, icon: const Icon(Icons.person_outline), label: Text(s.myLove)),
                ButtonSegment(value: 1, icon: const Icon(Icons.people_outline), label: Text(s.pairTab)),
              ],
              selected: {_tab},
              onSelectionChanged: (v) => setState(() => _tab = v.first),
              showSelectedIcon: false,
            ),
          ),
        ),
      ),
      body: _tab == 0 ? const _SoloBody() : const MarriagePairBody(),
    );
  }
}

class _SoloBody extends StatelessWidget {
  const _SoloBody();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final theme = Theme.of(context);
    final chart = state.chart!;
    final f = loveForecast(chart);
    final now = DateTime.now().year;
    final isMale = chart.input.isMale;
    final starLabel = s.en ? (isMale ? 'Wealth' : 'Authority') : (isMale ? '财星' : '官杀');
    final pattern = s.en ? (lovePatternEn[f.pattern] ?? f.pattern) : s.text(f.pattern);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // ---------- 指数 + 模式 ----------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(s.loveIndex, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.outline)),
                    Text('${f.overall}', style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text(pattern, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _bar(theme, s.affinity, f.affinity, AppColors.cinnabar),
                        const SizedBox(width: 12),
                        _bar(theme, s.stability, f.stability, AppColors.jade),
                        const SizedBox(width: 12),
                        _bar(theme, s.romanceScore, f.romance, AppColors.gold),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(s.en ? '' : s.text(f.patternNote), style: theme.textTheme.bodyMedium?.copyWith(height: 1.5), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),

            // ---------- 配偶星 | 夫妻宫 ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: '${s.spouseStar} · $starLabel',
                      big: s.term(f.star.element.label),
                      bigColor: elementColor[f.star.element.label],
                      lines: [
                        '${s.term(f.star.direct.label)} / ${s.term(f.star.mixed.label)}',
                        s.starState(f.star.state),
                        if (f.star.count > 0) s.starCount(f.star.count, f.star.strengthPct.round()),
                        if (f.star.sitsInPalace) s.en ? 'Sits in the palace' : '坐夫妻宫',
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: s.marriagePalace,
                      big: s.en ? branchPinyin[f.palaceBranch] : earthlyBranches[f.palaceBranch],
                      bigColor: elementColor[f.palaceElement.label],
                      lines: [
                        '${s.term(f.palaceElement.label)} · ${s.term(f.palaceGod.label)}',
                        f.palaceStable ? s.palaceStable : s.palaceMoving,
                        ...f.palaceRelations.map(s.text),
                      ],
                      accent: f.palaceStable ? AppColors.jade : AppColors.cinnabar,
                    ),
                  ),
                ],
              ),
            ),

            if (f.stars.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_florist_outlined),
                  title: Text(s.loveStars),
                  subtitle: Wrap(
                    spacing: 6,
                    children: [for (final st in f.stars) Chip(label: Text(s.term(st.replaceAll(RegExp(r'×\d+'), ''))), visualDensity: VisualDensity.compact)],
                  ),
                ),
              ),

            // ---------- 对方画像 ----------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.spouseProfile, style: theme.textTheme.titleMedium),
                    Text(s.profileHint, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                    const SizedBox(height: 10),
                    for (final e in f.spouseProfile.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: s.en ? 96 : 44, child: Text(s.profileKey(e.key), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline))),
                            Expanded(child: Text(s.text(e.value), style: theme.textTheme.bodyMedium)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ---------- 婚期窗口 ----------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.marriageWindows, style: theme.textTheme.titleMedium),
                    Text(s.windowsHint, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                    const SizedBox(height: 12),
                    if (f.windows.isEmpty)
                      Text(s.noWindows, style: theme.textTheme.bodyMedium)
                    else
                      for (final w in f.windows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 64,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: w.year == now
                                      ? theme.colorScheme.primaryContainer
                                      : w.year < now
                                          ? theme.colorScheme.surfaceContainerHighest
                                          : AppColors.cinnabar.withValues(alpha: 0.12),
                                ),
                                child: Column(
                                  children: [
                                    Text('${w.year}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                                    Text(s.en ? stemBranchEn(w.pillar) : w.pillar.name, style: theme.textTheme.labelSmall),
                                    Text('${w.age}${s.age}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (w.year < now || w.year == now)
                                      Text(w.year == now ? s.thisYearTag : s.pastTag, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                                    for (final t in w.triggers) Text('· ${s.text(t)}', style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),

            ExpansionTile(
              title: Text(s.factors),
              children: [for (final x in f.factors) ListTile(dense: true, title: Text(s.text(x)))],
            ),
            AiReadingCard(
              title: s.aiLove,
              load: (api) => api.interpretLove(chart.toJson(), f.toJson()),
              localText: () => s.en ? enInterpretLove(chart, f) : localInterpretLove(chart, f),
            ),
            const Disclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _bar(ThemeData theme, String label, int v, Color color) => Expanded(
        child: Column(
          children: [
            Text('$v', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: color)),
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: v / 100, minHeight: 6, color: color, backgroundColor: theme.colorScheme.surfaceContainerHighest),
            ),
          ],
        ),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.big, required this.lines, this.bigColor, this.accent});
  final String title;
  final String big;
  final Color? bigColor;
  final Color? accent;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(big, style: TextStyle(fontSize: 30, height: 1.1, fontWeight: FontWeight.w800, color: bigColor ?? theme.colorScheme.onSurface)),
                if (accent != null) ...[
                  const SizedBox(width: 8),
                  Container(width: 8, height: 8, margin: const EdgeInsets.only(bottom: 6), decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            for (final l in lines) Text(l, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
