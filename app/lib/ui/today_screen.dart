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
import 'marriage_screen.dart';
import 'naming_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';
import 'vision_screen.dart';
import 'widgets/ai_reading_card.dart';
import 'widgets/disclaimer.dart';
import 'widgets/share_card.dart';
import 'zodiac_screen.dart';

/// 首页"今日":打开就能看到的东西——今天几分、一句话、宜忌、吉时、提醒。
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S.of(context);
    final theme = Theme.of(context);
    final chart = state.chart!;
    final today = state.today ?? todayFortune(chart);
    final now = DateTime.now();
    final almanac = almanacFor(now.year, now.month, now.day);
    final annual = annualFortune(chart, now.year);
    final week = fortuneRange(chart, days: 7);
    final persona = stemPersonas[chart.dayStem];
    final personaEn = enStemPersona(chart.dayStem);
    final sp = scorePlain(today.overall);
    final zodiac = zodiacOfChart(chart);
    final animalZh = chart.zodiac;

    // 提醒:犯太岁 / 今日冲生肖 / 节气
    final banners = <(IconData, Color, String)>[];
    if (annual.isOffendingTaiSui) {
      banners.add((Icons.warning_amber_rounded, AppColors.cinnabar,
          s.taiSuiBanner(annual.taiSui.where((t) => t.isOffending).map((t) => s.term(t.label)).join(s.en ? ', ' : '、'))));
    } else if (annual.taiSui.contains(TaiSuiKind.combine)) {
      banners.add((Icons.auto_awesome, AppColors.jade, s.taiSuiCombineBanner));
    }
    if (almanac.clashZodiac == animalZh) {
      banners.add((Icons.flash_on_outlined, AppColors.gold, s.clashesYourAnimal(s.animal(chart.yearPillar.stemBranch.branch))));
    }
    if (almanac.solarTerm != null) {
      banners.add((Icons.eco_outlined, AppColors.jade, s.solarTermBanner(s.term(almanac.solarTerm!.name))));
    }

    final goodHours = almanac.hourFortunes.where((h) => h.isHuangDao).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.greeting(chart.input.name)),
        actions: [
          IconButton(tooltip: s.shareCard, icon: const Icon(Icons.ios_share), onPressed: () => showShareCard(context, chart, zodiac)),
          IconButton(
            tooltip: s.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ---------- 主卡:日期 + 分数 + 一句话 ----------
              Card(
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [theme.colorScheme.primaryContainer.withValues(alpha: 0.55), theme.colorScheme.surface],
                    ),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.ymd(now.year, now.month, now.day), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                Text(
                                  s.en
                                      ? 'Lunar month ${almanac.lunar.month}${almanac.lunar.isLeapMonth ? ' (leap)' : ''} day ${almanac.lunar.day} · ${s.weekday(almanac.weekday)}'
                                      : s.text('${almanac.lunar.monthName}${almanac.lunar.dayName} · ${s.weekday(almanac.weekday)}'),
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  s.en ? '${stemBranchEn(today.dayPillar)} day' : '${today.dayPillar.name}日',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                ),
                                const SizedBox(height: 10),
                                Text('${s.term(sp.term)} · ${s.todayTheme(s.term(today.theme.label), s.term(today.theme.group))}',
                                    style: theme.textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(s.en ? _dailyOneLinerEn(today.overall) : s.text(sp.plain), style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _ScoreRing(score: today.overall, label: s.todayScoreLabel),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _mini(theme, s.career, today.career),
                          _mini(theme, s.wealth, today.wealth),
                          _mini(theme, s.love, today.love),
                          _mini(theme, s.health, today.health),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Chip(avatar: const Icon(Icons.palette_outlined, size: 16), label: Text('${s.luckyColor} ${s.term(today.luckyColor)}')),
                          Chip(avatar: const Icon(Icons.pin_outlined, size: 16), label: Text('${s.luckyNumbers} ${today.luckyNumbers.join(s.en ? ', ' : '、')}')),
                          Chip(avatar: const Icon(Icons.explore_outlined, size: 16), label: Text('${s.luckyDirection} ${s.term(today.luckyDirection)}')),
                          for (final k in today.keywords) Chip(label: Text('#${s.text(k)}')),
                        ],
                      ),
                      const Divider(height: 24),
                      // 人设一行,并进主卡;点击出分享海报
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => showShareCard(context, chart, zodiac),
                        child: Row(
                          children: [
                            Text(s.en ? stemPinyin[chart.dayStem] : chart.dayMasterName,
                                style: TextStyle(fontSize: s.en ? 16 : 26, fontWeight: FontWeight.w700, color: elementColor[chart.dayMaster.label])),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${s.personaLabel} · ${s.en ? personaEn.image : s.text(persona.image)} × ${s.term(chart.elements.strength.label)}',
                                      style: theme.textTheme.titleSmall),
                                  Text(s.en ? personaEn.traits : s.text(persona.traits.join(' · ')), style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Icon(Icons.ios_share, size: 18, color: theme.colorScheme.outline),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------- 提醒条 ----------
              for (final (icon, color, text) in banners)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.4))),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
                        if (icon == Icons.warning_amber_rounded || icon == Icons.auto_awesome)
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnualScreen())),
                            child: Text(s.annualQuick),
                          ),
                      ],
                    ),
                  ),
                ),

              // ---------- 今日宜忌 + 吉时 ----------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(s.todayDoAvoid, style: theme.textTheme.titleMedium)),
                          Text(
                            '${s.term(almanac.jianChu)} · ${s.term(almanac.zhiShen)}',
                            style: theme.textTheme.labelSmall?.copyWith(color: almanac.isHuangDao ? AppColors.jade : theme.colorScheme.outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _yiji(theme, s.suitable, almanac.suitable.take(6).map(s.text).join(s.en ? ', ' : '  '), AppColors.jade),
                      const SizedBox(height: 6),
                      _yiji(theme, s.unsuitable, almanac.unsuitable.take(6).map(s.text).join(s.en ? ', ' : '  '), AppColors.cinnabar),
                      if (goodHours.isNotEmpty) ...[
                        const Divider(height: 20),
                        Text(s.luckyHoursToday, style: theme.textTheme.labelLarge),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final h in goodHours)
                              Chip(
                                label: Text('${s.en ? stemBranchEn(h.stemBranch) : h.stemBranch.name} ${h.range}'),
                                backgroundColor: AppColors.jade.withValues(alpha: 0.12),
                                side: BorderSide.none,
                              ),
                          ],
                        ),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlmanacScreen())),
                          icon: const Icon(Icons.calendar_month_outlined, size: 18),
                          label: Text(s.viewFullAlmanac),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------- 七天走势 ----------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nextSevenDays, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
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

              // ---------- 探索入口 ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(s.quickActions, style: theme.textTheme.titleMedium),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 6 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.05,
                  children: [
                    _action(context, Icons.timeline, s.annualTitle, const AnnualScreen()),
                    _action(context, Icons.star_border, s.zodiac, const ZodiacScreen()),
                    _action(context, Icons.favorite_outline, s.marriage, const MarriageScreen()),
                    _action(context, Icons.text_fields, s.naming, const NamingScreen()),
                    _action(context, Icons.back_hand_outlined, s.palmAi, const VisionScreen(mode: VisionMode.palm)),
                    _action(context, Icons.face_outlined, s.faceAi, const VisionScreen(mode: VisionMode.face)),
                  ],
                ),
              ),

              // ---------- AI ----------
              AiReadingCard(
                title: s.aiDaily,
                load: (api) => api.interpretDaily(chart.toJson(), today.toJson()),
                localText: () => s.en ? enInterpretDaily(chart, today) : localInterpretDaily(chart, today),
              ),
              ExpansionTile(
                title: Text(s.factors),
                children: [for (final f in today.factors) ListTile(dense: true, title: Text(s.text(f)))],
              ),
              const Disclaimer(),
            ],
          ),
        ),
      ),
    );
  }

  static String _dailyOneLinerEn(int score) {
    if (score >= 85) return 'A green-light day — do the important things today.';
    if (score >= 70) return 'A tailwind day — things in motion move with less effort.';
    if (score >= 55) return 'An ordinary day — stick to the plan.';
    if (score >= 40) return 'A low-battery day — fewer decisions, more tidying.';
    return 'A holding day — guard what you have.';
  }

  Widget _mini(ThemeData theme, String label, int v) => Expanded(
        child: Column(
          children: [
            Text('$v', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      );

  Widget _yiji(ThemeData theme, String label, String text, Color color) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text.isEmpty ? '—' : text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5))),
        ],
      );

  Widget _action(BuildContext context, IconData icon, String label, Widget page) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
          color: theme.colorScheme.surface,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 26),
            const SizedBox(height: 6),
            Text(label, style: theme.textTheme.labelMedium, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
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
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
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
