import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/almanac/almanac.dart';
import '../core/fortune/annual_fortune.dart';
import '../core/fortune/daily_fortune.dart';
import '../core/interpret/local_interpreter.dart';
import '../core/interpret/local_interpreter_en.dart';
import '../core/interpret/plain_language.dart';
import '../l10n/glossary.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import 'almanac_screen.dart';
import 'annual_screen.dart';
import 'love_screen.dart';
import 'naming_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';
import 'vision_screen.dart';
import 'widgets/ai_reading_card.dart';
import 'widgets/disclaimer.dart';
import 'widgets/share_card.dart';
import 'zodiac_screen.dart';

/// 首页"今日"。
///
/// 布局参考同类产品的成熟结构:页头(问候 + 日期)→ 深色 hero(分数与评级)
/// → 一排功能入口 → 提醒 → 宜忌 | 吉时 并排 → 走势 → AI。
/// 宽屏(≥ 900)分两栏:左栏 hero / 入口 / 人设,右栏内容流。
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final chart = state.chart!;
    final today = state.today ?? todayFortune(chart);
    final now = DateTime.now();
    final almanac = almanacFor(now.year, now.month, now.day);
    final annual = annualFortune(chart, now.year);
    final week = fortuneRange(chart, days: 7);
    final zodiac = zodiacOfChart(chart);
    final d = _Data(chart: chart, today: today, almanac: almanac, annual: annual, week: week, zodiac: zodiac, s: s);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 900;
            final header = _Header(d: d);
            if (!wide) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  header,
                  const SizedBox(height: 12),
                  _Hero(d: d),
                  const SizedBox(height: 14),
                  _QuickActions(d: d),
                  const SizedBox(height: 6),
                  ..._banners(context, d),
                  const SizedBox(height: 6),
                  _DoAvoidAndHours(d: d, sideBySide: c.maxWidth >= 560),
                  const SizedBox(height: 12),
                  _Persona(d: d),
                  const SizedBox(height: 12),
                  _WeekTrend(d: d),
                  const SizedBox(height: 12),
                  _ai(d),
                  _factors(context, d),
                  const Disclaimer(),
                ],
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    header,
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 400,
                          child: Column(
                            children: [
                              _Hero(d: d),
                              const SizedBox(height: 14),
                              _QuickActions(d: d),
                              const SizedBox(height: 12),
                              _Persona(d: d),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [
                              ..._banners(context, d),
                              _DoAvoidAndHours(d: d, sideBySide: true),
                              const SizedBox(height: 12),
                              _WeekTrend(d: d),
                              const SizedBox(height: 12),
                              _ai(d),
                              _factors(context, d),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Disclaimer(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _ai(_Data d) => AiReadingCard(
        title: d.s.aiDaily,
        load: (api) => api.interpretDaily(d.chart.toJson(), d.today.toJson()),
        localText: () => d.s.en ? enInterpretDaily(d.chart, d.today) : localInterpretDaily(d.chart, d.today),
      );

  Widget _factors(BuildContext context, _Data d) => ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(d.s.factors, style: Theme.of(context).textTheme.bodyMedium),
        children: [for (final f in d.today.factors) ListTile(dense: true, title: Text(d.s.text(f)))],
      );

  List<Widget> _banners(BuildContext context, _Data d) {
    final s = d.s;
    final theme = Theme.of(context);
    final items = <(IconData, Color, String, bool)>[];
    if (d.annual.isOffendingTaiSui) {
      items.add((Icons.warning_amber_rounded, AppColors.cinnabar,
          s.taiSuiBanner(d.annual.taiSui.where((t) => t.isOffending).map((t) => s.term(t.label)).join(s.en ? ', ' : '、')), true));
    } else if (d.annual.taiSui.contains(TaiSuiKind.combine)) {
      items.add((Icons.auto_awesome, AppColors.jade, s.taiSuiCombineBanner, true));
    }
    if (d.almanac.clashZodiac == d.chart.zodiac) {
      items.add((Icons.flash_on_outlined, AppColors.gold, s.clashesYourAnimal(s.animal(d.chart.yearPillar.stemBranch.branch)), false));
    }
    if (d.almanac.solarTerm != null) {
      items.add((Icons.eco_outlined, AppColors.jade, s.solarTermBanner(s.term(d.almanac.solarTerm!.name)), false));
    }
    return [
      for (final (icon, color, text, toAnnual) in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: toAnnual ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnualScreen())) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
                    if (toAnnual) Icon(Icons.chevron_right, color: color),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

class _Data {
  const _Data({required this.chart, required this.today, required this.almanac, required this.annual, required this.week, required this.zodiac, required this.s});
  final dynamic chart;
  final DailyFortune today;
  final AlmanacDay almanac;
  final AnnualFortune annual;
  final List<DailyFortune> week;
  final dynamic zodiac;
  final S s;
}

// ---------------------------------------------------------------- 页头

class _Header extends StatelessWidget {
  const _Header({required this.d});
  final _Data d;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = d.s;
    final now = DateTime.now();
    final lunar = s.en
        ? 'Lunar month ${d.almanac.lunar.month}${d.almanac.lunar.isLeapMonth ? ' (leap)' : ''} day ${d.almanac.lunar.day}'
        : s.text('${d.almanac.lunar.monthName}${d.almanac.lunar.dayName}');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.greeting(d.chart.input.name), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                '${s.ymd(now.year, now.month, now.day)} · $lunar · ${s.weekday(d.almanac.weekday)}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
        IconButton(tooltip: s.shareCard, icon: const Icon(Icons.ios_share), onPressed: () => showShareCard(context, d.chart, d.zodiac)),
        IconButton(
          tooltip: s.settings,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Hero

class _Hero extends StatelessWidget {
  const _Hero({required this.d});
  final _Data d;

  @override
  Widget build(BuildContext context) {
    final s = d.s;
    final t = d.today;
    final sp = scorePlain(t.overall);
    const fg = Colors.white;
    final fgDim = Colors.white.withValues(alpha: 0.72);
    final oneLiner = s.en ? _oneLinerEn(t.overall) : s.text(sp.plain);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2A3A), Color(0xFF5C2A24)],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Ring(score: t.overall, size: 112, stroke: 10, color: AppColors.gold, track: Colors.white.withValues(alpha: 0.15), fg: fg, label: s.todayScoreLabel),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.term(sp.term), style: const TextStyle(color: AppColors.gold, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1)),
                    const SizedBox(height: 4),
                    Text(
                      '${s.en ? '${stemBranchEn(t.dayPillar)} day' : '${t.dayPillar.name}日'} · ${s.term(t.theme.label)}',
                      style: TextStyle(color: fgDim, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(oneLiner, style: const TextStyle(color: fg, fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _mini(s.career, t.career, fg, fgDim),
              _mini(s.wealth, t.wealth, fg, fgDim),
              _mini(s.love, t.love, fg, fgDim),
              _mini(s.health, t.health, fg, fgDim),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _tag(Icons.palette_outlined, '${s.luckyColor} ${s.term(t.luckyColor)}'),
              _tag(Icons.pin_outlined, '${s.luckyNumbers} ${t.luckyNumbers.join(s.en ? ', ' : '、')}'),
              _tag(Icons.explore_outlined, '${s.luckyDirection} ${s.term(t.luckyDirection)}'),
              for (final k in t.keywords) _tag(null, '#${s.text(k)}'),
            ],
          ),
        ],
      ),
    );
  }

  static String _oneLinerEn(int score) {
    if (score >= 85) return 'A green-light day — do the important things today.';
    if (score >= 70) return 'A tailwind day — things in motion move with less effort.';
    if (score >= 55) return 'An ordinary day — stick to the plan.';
    if (score >= 40) return 'A low-battery day — fewer decisions, more tidying.';
    return 'A holding day — guard what you have.';
  }

  Widget _mini(String label, int v, Color fg, Color dim) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: dim, fontSize: 11)),
            const SizedBox(height: 2),
            Text('$v', style: TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.w700, height: 1.1)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(value: v / 100, minHeight: 3, color: AppColors.gold, backgroundColor: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
          ],
        ),
      );

  Widget _tag(IconData? icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.8)), const SizedBox(width: 4)],
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.score, required this.size, required this.stroke, required this.color, required this.track, required this.fg, required this.label});
  final int score;
  final double size, stroke;
  final Color color, track, fg;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(child: CircularProgressIndicator(value: score / 100, strokeWidth: stroke, strokeCap: StrokeCap.round, color: color, backgroundColor: track)),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$score', style: TextStyle(color: fg, fontSize: size * 0.32, fontWeight: FontWeight.w800, height: 1)),
                Text(label, style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 11)),
              ],
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------- 功能入口

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.d});
  final _Data d;

  @override
  Widget build(BuildContext context) {
    final s = d.s;
    final items = <(IconData, String, Widget)>[
      (Icons.timeline, s.annualQuick, const AnnualScreen()),
      (Icons.star_border, s.zodiac, const ZodiacScreen()),
      (Icons.favorite_outline, s.love, const LoveScreen()),
      (Icons.text_fields, s.naming, const NamingScreen()),
      (Icons.back_hand_outlined, s.palmAi, const VisionScreen(mode: VisionMode.palm)),
      (Icons.face_outlined, s.faceAi, const VisionScreen(mode: VisionMode.face)),
    ];
    return Row(
      children: [
        for (final (icon, label, page) in items)
          Expanded(child: _ActionIcon(icon: icon, label: label, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)))),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6), shape: BoxShape.circle),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: theme.textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 宜忌 | 吉时

class _DoAvoidAndHours extends StatelessWidget {
  const _DoAvoidAndHours({required this.d, required this.sideBySide});
  final _Data d;
  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    final doAvoid = _DoAvoidCard(d: d);
    final hours = _HoursCard(d: d);
    if (!sideBySide) {
      return Column(children: [doAvoid, const SizedBox(height: 12), hours]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: doAvoid),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: hours),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, this.trailing, this.onMore, required this.child});
  final String title;
  final Widget? trailing;
  final VoidCallback? onMore;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
                if (trailing != null) trailing!,
                if (onMore != null) IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.chevron_right), onPressed: onMore),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _DoAvoidCard extends StatelessWidget {
  const _DoAvoidCard({required this.d});
  final _Data d;

  @override
  Widget build(BuildContext context) {
    final s = d.s;
    final theme = Theme.of(context);
    final a = d.almanac;
    return _SectionCard(
      title: s.todayDoAvoid,
      trailing: Text('${s.term(a.jianChu)} · ${s.term(a.zhiShen)}',
          style: theme.textTheme.labelSmall?.copyWith(color: a.isHuangDao ? AppColors.jade : theme.colorScheme.outline)),
      onMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlmanacScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(s.suitable, a.suitable.take(8).map(s.text).toList(), AppColors.jade, theme),
          const SizedBox(height: 10),
          _row(s.unsuitable, a.unsuitable.take(8).map(s.text).toList(), AppColors.cinnabar, theme),
        ],
      ),
    );
  }

  Widget _row(String label, List<String> items, Color color, ThemeData theme) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: items.isEmpty
                ? Padding(padding: const EdgeInsets.only(top: 5), child: Text('—', style: theme.textTheme.bodySmall))
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final it in items)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(6)),
                          child: Text(it, style: theme.textTheme.bodySmall),
                        ),
                    ],
                  ),
          ),
        ],
      );
}

class _HoursCard extends StatelessWidget {
  const _HoursCard({required this.d});
  final _Data d;

  @override
  Widget build(BuildContext context) {
    final s = d.s;
    final theme = Theme.of(context);
    final good = d.almanac.hourFortunes.where((h) => h.isHuangDao).toList();
    final nowBranch = _hourBranchNow();
    return _SectionCard(
      title: s.luckyHoursToday,
      child: Column(
        children: [
          for (final h in good)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 26,
                    decoration: BoxDecoration(color: h.branch == nowBranch ? theme.colorScheme.primary : AppColors.jade, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.en ? stemBranchEn(h.stemBranch) : '${h.stemBranch.name}时', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text(h.range, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                      ],
                    ),
                  ),
                  Text(s.term(h.zhiShen), style: theme.textTheme.labelSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static int _hourBranchNow() {
    final h = DateTime.now().hour;
    return h >= 23 ? 0 : ((h + 1) ~/ 2);
  }
}

// ---------------------------------------------------------------- 人设

class _Persona extends StatelessWidget {
  const _Persona({required this.d});
  final _Data d;

  @override
  Widget build(BuildContext context) {
    final s = d.s;
    final theme = Theme.of(context);
    final chart = d.chart;
    final p = stemPersonas[chart.dayStem];
    final pe = enStemPersona(chart.dayStem);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showShareCard(context, chart, d.zodiac),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: (elementColor[chart.dayMaster.label] as Color).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                child: Text(s.en ? stemPinyin[chart.dayStem] : chart.dayMasterName,
                    style: TextStyle(fontSize: s.en ? 16 : 30, fontWeight: FontWeight.w800, color: elementColor[chart.dayMaster.label])),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s.en ? pe.image : s.text(p.image)} × ${s.term(chart.elements.strength.label)}', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(s.en ? pe.traits : s.text(p.traits.join(' · ')), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 12)),
                onPressed: () => showShareCard(context, chart, d.zodiac),
                icon: const Icon(Icons.ios_share, size: 16),
                label: Text(s.shareCard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 七天

class _WeekTrend extends StatelessWidget {
  const _WeekTrend({required this.d});
  final _Data d;

  @override
  Widget build(BuildContext context) {
    final s = d.s;
    final theme = Theme.of(context);
    final week = d.week;
    return _SectionCard(
      title: s.nextSevenDays,
      child: SizedBox(
        height: 130,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25, getDrawingHorizontalLine: (_) => FlLine(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((sp) {
                  final f = week[sp.x.toInt()];
                  return LineTooltipItem('${f.month}/${f.day}  ${f.overall}\n${s.term(f.theme.label)}', theme.textTheme.labelSmall!.copyWith(color: Colors.white));
                }).toList(),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= week.length) return const SizedBox.shrink();
                    return Text(i == 0 ? (s.en ? 'Today' : '今') : '${week[i].month}/${week[i].day}',
                        style: theme.textTheme.labelSmall?.copyWith(fontWeight: i == 0 ? FontWeight.w700 : null));
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (var i = 0; i < week.length; i++) FlSpot(i.toDouble(), week[i].overall.toDouble())],
                isCurved: true,
                curveSmoothness: 0.3,
                color: theme.colorScheme.primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, i) => FlDotCirclePainter(
                    radius: i == 0 ? 5 : 3.5,
                    color: i == 0 ? AppColors.gold : theme.colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [theme.colorScheme.primary.withValues(alpha: 0.25), theme.colorScheme.primary.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
