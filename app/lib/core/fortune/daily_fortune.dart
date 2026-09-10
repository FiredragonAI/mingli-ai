/// 每日运势:把"今日干支"放进命主的八字里看生克合冲。
///
/// 完全确定性——同一个人同一天永远同一结果,没有随机数。
/// 分五个领域打分,每一条加减都留依据,AI 只做措辞。
library;

import '../astro/julian.dart';
import '../astro/solar_terms.dart';
import '../bazi/bazi_chart.dart';
import '../bazi/five_elements.dart';
import '../bazi/hidden_stems.dart';
import '../bazi/relations.dart';
import '../bazi/ten_gods.dart';
import '../calendar/lunar_calendar.dart';
import '../calendar/sexagenary.dart';

class DailyFortune {
  const DailyFortune({
    required this.year,
    required this.month,
    required this.day,
    required this.dayPillar,
    required this.monthPillar,
    required this.yearPillar,
    required this.theme,
    required this.overall,
    required this.career,
    required this.wealth,
    required this.love,
    required this.health,
    required this.luckyColor,
    required this.luckyNumbers,
    required this.luckyDirection,
    required this.factors,
    required this.keywords,
  });

  final int year;
  final int month;
  final int day;
  final StemBranch dayPillar;
  final StemBranch monthPillar;
  final StemBranch yearPillar;

  /// 今日天干对日主的十神,决定今日主题。
  final TenGod theme;

  final int overall;
  final int career;
  final int wealth;
  final int love;
  final int health;

  final String luckyColor;
  final List<int> luckyNumbers;
  final String luckyDirection;

  /// 影响因素,含加减分依据。
  final List<String> factors;

  /// 今日关键词。
  final List<String> keywords;

  Map<String, dynamic> toJson() => {
        'date': '$year-$month-$day',
        'dayPillar': dayPillar.name,
        'monthPillar': monthPillar.name,
        'yearPillar': yearPillar.name,
        'theme': theme.label,
        'themeGroup': theme.group,
        'scores': {
          '综合': overall,
          '事业': career,
          '财运': wealth,
          '感情': love,
          '健康': health,
        },
        'luckyColor': luckyColor,
        'luckyNumbers': luckyNumbers,
        'luckyDirection': luckyDirection,
        'factors': factors,
        'keywords': keywords,
      };
}

const Map<Element, List<int>> _elementNumbers = {
  Element.wood: [3, 8],
  Element.fire: [2, 7],
  Element.earth: [5, 10],
  Element.metal: [4, 9],
  Element.water: [1, 6],
};

final int _jdn19000101 = julianDayNumberLocal(julianDayFromDate(1900, 1, 1.5));

DailyFortune dailyFortune(BaziChart chart, int year, int month, int day) {
  final jdUt = julianDayFromDate(year, month, day + 0.5) - chinaTimezoneHours / 24;
  final dayNumber = localDayNumber(jdUt);

  final ySb = yearPillar(sexagenaryYearOf(jdUt));
  final mSb = monthPillar(ySb.stem, solarTermMonthIndex(jdUt));
  final dSb = dayPillarFromDaysSince1900(dayNumber - _jdn19000101);

  final dayStem = chart.dayStem;
  final fav = chart.elements.favorable;
  final unfav = chart.elements.unfavorable;
  final factors = <String>[];
  final keywords = <String>{};

  var overall = 60, career = 60, wealth = 60, love = 60, health = 60;

  void bump(int o, int c, int w, int l, int h, String why) {
    overall += o;
    career += c;
    wealth += w;
    love += l;
    health += h;
    factors.add(why);
  }

  // ---- 今日天干十神:主题 ----
  final theme = tenGodOf(dayStem, dSb.stem);
  switch (theme.group) {
    case '财星':
      bump(4, 2, 12, 4, 0, '今日${dSb.stemName}为${theme.label},利财务与实务');
      keywords.addAll(['求财', '交易']);
    case '官杀':
      bump(2, 10, 0, -2, -4, '今日${dSb.stemName}为${theme.label},事业压力与机会并存');
      keywords.addAll(['责任', '规矩']);
    case '印星':
      bump(4, 4, -2, 2, 8, '今日${dSb.stemName}为${theme.label},利学习休养、得长辈助');
      keywords.addAll(['学习', '贵人']);
    case '食伤':
      bump(3, 2, 4, 8, 0, '今日${dSb.stemName}为${theme.label},表达与创意活跃');
      keywords.addAll(['表达', '创意']);
    default:
      bump(0, 4, -5, 2, 2, '今日${dSb.stemName}为${theme.label},竞争与合作并见,防破财');
      keywords.addAll(['合作', '竞争']);
  }

  // ---- 今日干支五行 vs 喜忌 ----
  final dStemEl = stemElements[dSb.stem];
  final dBranchEl = branchElements[dSb.branch];
  if (fav.contains(dStemEl)) {
    bump(10, 6, 6, 6, 6, '今日天干属${dStemEl.label},为命主喜用');
  } else if (unfav.contains(dStemEl)) {
    bump(-9, -5, -5, -5, -5, '今日天干属${dStemEl.label},为命主所忌');
  }
  if (fav.contains(dBranchEl)) {
    bump(7, 4, 4, 4, 4, '今日地支属${dBranchEl.label},为命主喜用');
  } else if (unfav.contains(dBranchEl)) {
    bump(-6, -4, -4, -4, -4, '今日地支属${dBranchEl.label},为命主所忌');
  }

  // ---- 今日地支 vs 命局四支 ----
  final branches = chart.branches;
  final db = dSb.branch;
  for (var i = 0; i < 4; i++) {
    final b = branches[i];
    final p = pillarNames[i];
    if (isClash(db, b)) {
      final penalty = i == 2 ? -14 : (i == 0 ? -6 : -4);
      bump(penalty, i == 1 ? -6 : -3, -3, i == 2 ? -10 : -2, i == 2 ? -6 : -2,
          '今日${dSb.branchName}冲$p支${earthlyBranches[b]}${i == 2 ? ',冲夫妻宫/自身,情绪波动' : ''}');
      keywords.add('变动');
    } else if (isSixCombine(db, b)) {
      bump(i == 2 ? 10 : 5, 3, 3, i == 2 ? 10 : 4, 2,
          '今日${dSb.branchName}合$p支${earthlyBranches[b]}');
      keywords.add('和合');
    } else if (isTripleCombineMember(db, b)) {
      bump(4, 3, 3, 3, 2, '今日${dSb.branchName}与$p支${earthlyBranches[b]}三合');
    }
    if (isHarm(db, b)) bump(-4, -2, -2, -4, -2, '今日${dSb.branchName}害$p支${earthlyBranches[b]}');
    if (isPunish(db, b)) bump(-4, -3, -2, -2, -4, '今日${dSb.branchName}刑$p支${earthlyBranches[b]}');
  }

  // 天干五合
  if ((dSb.stem - dayStem).abs() == 5) {
    bump(5, 2, 4, 6, 0, '今日${dSb.stemName}与日主${chart.dayMasterName}相合,人际顺遂');
  }

  // ---- 流年流月大势 ----
  for (final (sb, label) in [(ySb, '流年'), (mSb, '流月')]) {
    final el = stemElements[sb.stem];
    if (fav.contains(el)) {
      bump(4, 2, 2, 2, 2, '$label${sb.name}天干属${el.label},大势有利');
    } else if (unfav.contains(el)) {
      bump(-3, -2, -2, -2, -2, '$label${sb.name}天干属${el.label},大势偏逆');
    }
  }

  // ---- 今日地支引动命中神煞 ----
  for (final s in chart.shenSha) {
    // 神煞落于某柱地支,今日地支相同视为引动
    for (final pos in s.positions) {
      if (branches[pos] == db) {
        switch (s.name) {
          case '桃花':
          case '红鸾':
          case '天喜':
            bump(3, 0, 0, 10, 0, '今日引动命中${s.name},感情缘分活跃');
            keywords.add('桃花');
          case '驿马':
            bump(2, 3, 2, 0, -2, '今日引动驿马,宜出行走动、忌久坐');
            keywords.add('出行');
          case '天乙贵人':
          case '月德贵人':
          case '天德':
            bump(6, 6, 4, 2, 2, '今日引动${s.name},易得人相助');
            keywords.add('贵人');
          case '羊刃':
          case '劫煞':
          case '亡神':
            bump(-5, -3, -5, -2, -5, '今日引动${s.name},慎防意外破耗');
            keywords.add('谨慎');
        }
        break;
      }
    }
  }

  // 日柱空亡
  if (chart.dayPillar.voidBranches.contains(db)) {
    bump(-4, -3, -4, -2, -1, '今日地支落日柱空亡,事多虚浮,宜守不宜攻');
  }

  int clamp(int v) => v.clamp(15, 98);

  final primary = chart.elements.primaryUsefulGod;
  final colorText = elementAttributes[primary]!['色']!;
  final dirText = elementAttributes[primary]!['方位']!;

  return DailyFortune(
    year: year,
    month: month,
    day: day,
    dayPillar: dSb,
    monthPillar: mSb,
    yearPillar: ySb,
    theme: theme,
    overall: clamp(overall),
    career: clamp(career),
    wealth: clamp(wealth),
    love: clamp(love),
    health: clamp(health),
    luckyColor: colorText,
    luckyNumbers: _elementNumbers[primary]!,
    luckyDirection: dirText,
    factors: factors,
    keywords: keywords.take(4).toList(),
  );
}

/// 今日运势。
DailyFortune todayFortune(BaziChart chart) {
  final now = DateTime.now();
  return dailyFortune(chart, now.year, now.month, now.day);
}

/// 未来 [days] 天的运势曲线(默认 7 天),供折线图使用。
List<DailyFortune> fortuneRange(BaziChart chart, {int days = 7}) {
  final start = DateTime.now();
  return [
    for (var i = 0; i < days; i++)
      () {
        final d = start.add(Duration(days: i));
        return dailyFortune(chart, d.year, d.month, d.day);
      }(),
  ];
}

/// 用于展示今日主题的辅助:主气藏干十神。
TenGod dayBranchMainGod(BaziChart chart, StemBranch daySb) =>
    tenGodOf(chart.dayStem, mainHiddenStem(daySb.branch));
