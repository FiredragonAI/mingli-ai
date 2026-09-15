/// 流年运势 + 犯太岁 + 十二流月。
///
/// 把某一年的干支放进命局里看:年干对日主是什么十神(全年主题)、年支与命局
/// 年支/日支的刑冲合害(犯太岁)、与当年所行大运的叠加(岁运并临、岁运相冲)、
/// 引动了哪些神煞。再按十二节气月拆出每月的小天气。
///
/// 与 daily_fortune 一样完全确定性,每条加减分都留依据。
library;

import '../bazi/bazi_chart.dart';
import '../bazi/hidden_stems.dart';
import '../bazi/luck_cycles.dart';
import '../bazi/relations.dart';
import '../bazi/ten_gods.dart';
import '../calendar/sexagenary.dart';

/// 太岁关系。传统"犯太岁"指前五种;合太岁是好事,一并列出。
enum TaiSuiKind {
  same('值太岁', '本命年:流年支与生肖同位,主变动、压力与转折,宜稳不宜躁', true),
  clash('冲太岁', '流年支与生肖相冲,主变动、搬迁、分离,宜主动求变而非被动承受', true),
  punish('刑太岁', '流年支与生肖相刑,主是非、口舌、人际摩擦,凡事留三分余地', true),
  harm('害太岁', '流年支与生肖相害,主暗中阻滞、小人牵扯,防小人重于防事', true),
  destroy('破太岁', '流年支与生肖相破,主破耗、计划中断,宜守财、不宜大动', true),
  combine('合太岁', '流年支与生肖六合,人缘旺、贵人近,宜合作、宜结缘', false);

  const TaiSuiKind(this.label, this.meaning, this.isOffending);
  final String label;
  final String meaning;

  /// 是否属于传统意义的"犯太岁"。
  final bool isOffending;
}

/// 一个流月。
class MonthlyFortune {
  const MonthlyFortune({
    required this.index,
    required this.pillar,
    required this.score,
    required this.theme,
    required this.note,
  });

  /// 0 = 寅月(立春起)… 11 = 丑月。
  final int index;
  final StemBranch pillar;
  final int score;
  final TenGod theme;
  final String note;

  Map<String, dynamic> toJson() => {
        'index': index,
        'pillar': pillar.name,
        'score': score,
        'theme': theme.label,
        'note': note,
      };
}

class AnnualFortune {
  const AnnualFortune({
    required this.year,
    required this.nominalAge,
    required this.yearPillar,
    required this.luckPillar,
    required this.theme,
    required this.taiSui,
    required this.overall,
    required this.career,
    required this.wealth,
    required this.love,
    required this.health,
    required this.grade,
    required this.factors,
    required this.keywords,
    required this.months,
    required this.bestMonths,
    required this.cautionMonths,
  });

  final int year;

  /// 虚岁。
  final int nominalAge;
  final StemBranch yearPillar;

  /// 当年所行大运;起运前为 null。
  final LuckPillar? luckPillar;

  /// 年干对日主的十神,全年主题。
  final TenGod theme;

  /// 与生肖(命局年支)的太岁关系,可能为空。
  final List<TaiSuiKind> taiSui;

  final int overall;
  final int career;
  final int wealth;
  final int love;
  final int health;
  final String grade;
  final List<String> factors;
  final List<String> keywords;
  final List<MonthlyFortune> months;

  /// 分数最高的两个月(0–11 序号)。
  final List<int> bestMonths;

  /// 分数最低的两个月。
  final List<int> cautionMonths;

  bool get isOffendingTaiSui => taiSui.any((t) => t.isOffending);

  Map<String, dynamic> toJson() => {
        'year': year,
        'nominalAge': nominalAge,
        'yearPillar': yearPillar.name,
        'luckPillar': luckPillar?.pillar.name,
        'luckAgeRange': luckPillar?.ageRange,
        'theme': theme.label,
        'themeGroup': theme.group,
        'taiSui': taiSui.map((t) => {'kind': t.label, 'meaning': t.meaning, 'offending': t.isOffending}).toList(),
        'scores': {'综合': overall, '事业': career, '财运': wealth, '感情': love, '健康': health},
        'grade': grade,
        'factors': factors,
        'keywords': keywords,
        'months': months.map((m) => m.toJson()).toList(),
        'bestMonths': bestMonths.map((i) => months[i].pillar.name).toList(),
        'cautionMonths': cautionMonths.map((i) => months[i].pillar.name).toList(),
      };
}

/// 流年支与生肖支的太岁关系。
List<TaiSuiKind> taiSuiRelations(int yearBranch, int natalYearBranch) {
  final out = <TaiSuiKind>[];
  if (yearBranch == natalYearBranch) out.add(TaiSuiKind.same);
  if (isClash(yearBranch, natalYearBranch)) out.add(TaiSuiKind.clash);
  if (isPunish(yearBranch, natalYearBranch) && yearBranch != natalYearBranch) out.add(TaiSuiKind.punish);
  if (isHarm(yearBranch, natalYearBranch)) out.add(TaiSuiKind.harm);
  if (isDestroy(yearBranch, natalYearBranch)) out.add(TaiSuiKind.destroy);
  if (isSixCombine(yearBranch, natalYearBranch)) out.add(TaiSuiKind.combine);
  return out;
}

AnnualFortune annualFortune(BaziChart chart, int year) {
  final ySb = yearPillar(year);
  final dayStem = chart.dayStem;
  final fav = chart.elements.favorable;
  final unfav = chart.elements.unfavorable;
  final natal = chart.branches;
  final factors = <String>[];
  final keywords = <String>{};
  final luck = chart.luck.cycleForYear(year);

  var overall = 60, career = 60, wealth = 60, love = 60, health = 60;
  void bump(int o, int c, int w, int l, int h, String why) {
    overall += o;
    career += c;
    wealth += w;
    love += l;
    health += h;
    factors.add(why);
  }

  // ---- 年干十神:全年主题 ----
  final theme = tenGodOf(dayStem, ySb.stem);
  switch (theme.group) {
    case '财星':
      bump(5, 2, 14, 4, 0, '流年天干${ySb.stemName}为${theme.label},全年主题在财与务实,利经营、置产、谈价');
      keywords.addAll(['求财', '置业']);
    case '官杀':
      bump(2, 12, 0, -2, -5, '流年天干${ySb.stemName}为${theme.label},全年主题在事业与责任,压力与晋升机会并存');
      keywords.addAll(['事业', '责任']);
    case '印星':
      bump(5, 4, -2, 2, 8, '流年天干${ySb.stemName}为${theme.label},全年主题在学习、休整与贵人,利进修、考证、调养');
      keywords.addAll(['学习', '贵人']);
    case '食伤':
      bump(4, 3, 5, 8, 0, '流年天干${ySb.stemName}为${theme.label},全年主题在表达与创造,利创作、演讲、子女缘');
      keywords.addAll(['创作', '表达']);
    default:
      bump(0, 4, -6, 2, 2, '流年天干${ySb.stemName}为${theme.label},全年主题在合作与竞争,朋友多、开销也多');
      keywords.addAll(['合作', '竞争']);
  }

  // ---- 流年干支五行 vs 喜忌 ----
  final yStemEl = stemElements[ySb.stem];
  final yBranchEl = branchElements[ySb.branch];
  if (fav.contains(yStemEl)) {
    bump(10, 6, 6, 6, 6, '流年天干属${yStemEl.label},为命主喜用,顺风年');
  } else if (unfav.contains(yStemEl)) {
    bump(-9, -5, -5, -5, -5, '流年天干属${yStemEl.label},为命主所忌,逆风年');
  }
  if (fav.contains(yBranchEl)) {
    bump(7, 4, 4, 4, 4, '流年地支属${yBranchEl.label},为命主喜用');
  } else if (unfav.contains(yBranchEl)) {
    bump(-6, -4, -4, -4, -4, '流年地支属${yBranchEl.label},为命主所忌');
  }

  // ---- 太岁 ----
  final taiSui = taiSuiRelations(ySb.branch, natal[0]);
  for (final t in taiSui) {
    switch (t) {
      case TaiSuiKind.same:
        bump(-6, -3, -4, -4, -4, '值太岁(本命年):${t.meaning}');
        keywords.add('本命年');
      case TaiSuiKind.clash:
        bump(-10, -6, -5, -6, -5, '冲太岁:${t.meaning}');
        keywords.add('变动');
      case TaiSuiKind.punish:
        bump(-6, -4, -3, -5, -3, '刑太岁:${t.meaning}');
        keywords.add('口舌');
      case TaiSuiKind.harm:
        bump(-5, -3, -3, -5, -2, '害太岁:${t.meaning}');
        keywords.add('防小人');
      case TaiSuiKind.destroy:
        bump(-5, -3, -6, -2, -2, '破太岁:${t.meaning}');
        keywords.add('守财');
      case TaiSuiKind.combine:
        bump(6, 4, 3, 6, 2, '合太岁:${t.meaning}');
        keywords.add('贵人');
    }
  }

  // ---- 流年支 vs 日支(夫妻宫)与月支、时支 ----
  for (var i = 1; i < 4; i++) {
    final b = natal[i];
    final p = pillarNames[i];
    if (isClash(ySb.branch, b)) {
      bump(i == 2 ? -8 : -4, i == 1 ? -5 : -2, -2, i == 2 ? -10 : -2, i == 2 ? -4 : -2,
          '流年${ySb.branchName}冲$p支${earthlyBranches[b]}${i == 2 ? ',冲夫妻宫,感情与身体易起波动' : i == 1 ? ',冲事业宫,工作环境易变' : ''}');
      keywords.add('变动');
    } else if (isSixCombine(ySb.branch, b)) {
      bump(i == 2 ? 8 : 4, 3, 3, i == 2 ? 10 : 3, 2, '流年${ySb.branchName}合$p支${earthlyBranches[b]}${i == 2 ? ',合夫妻宫,利婚恋' : ''}');
      keywords.add('和合');
    } else if (isTripleCombineMember(ySb.branch, b)) {
      bump(3, 2, 2, 2, 2, '流年${ySb.branchName}与$p支${earthlyBranches[b]}三合');
    }
  }

  // ---- 天干五合日主 ----
  if ((ySb.stem - dayStem).abs() == 5) {
    bump(5, 2, 4, 7, 0, '流年天干${ySb.stemName}与日主${chart.dayMasterName}相合,人际与感情机会多,亦要防被"合走"精力');
    keywords.add('机遇');
  }

  // ---- 岁运叠加 ----
  if (luck != null) {
    final lp = luck.pillar;
    if (lp == ySb) {
      bump(-8, -4, -6, -4, -6, '岁运并临:流年与大运同为${lp.name},能量集中,起伏放大,宜稳不宜赌');
      keywords.add('起伏');
    } else {
      if (isClash(lp.branch, ySb.branch)) {
        bump(-6, -4, -3, -3, -3, '岁运相冲:大运${lp.name}与流年${ySb.name}地支相冲,内外环境拉扯');
      } else if (isSixCombine(lp.branch, ySb.branch)) {
        bump(4, 2, 2, 3, 1, '岁运相合:大运${lp.name}与流年${ySb.name}地支六合,内外顺畅');
      }
      if ((lp.stem - ySb.stem).abs() == 5) {
        bump(2, 1, 2, 2, 0, '大运干${lp.stemName}与流年干${ySb.stemName}相合');
      }
    }
    final lEl = stemElements[lp.stem];
    if (fav.contains(lEl)) {
      bump(4, 2, 2, 2, 2, '所行大运${lp.name}天干属${lEl.label},为喜用,大环境托底');
    } else if (unfav.contains(lEl)) {
      bump(-4, -2, -2, -2, -2, '所行大运${lp.name}天干属${lEl.label},为所忌,大环境偏紧');
    }
  }

  // ---- 引动神煞 ----
  for (final s in chart.shenSha) {
    for (final pos in s.positions) {
      if (natal[pos] == ySb.branch) {
        switch (s.name) {
          case '桃花':
          case '红鸾':
          case '天喜':
            bump(3, 0, 0, 10, 0, '流年引动命中${s.name},婚恋喜庆之年');
            keywords.add('桃花');
          case '驿马':
            bump(2, 3, 2, 0, -2, '流年引动驿马,出行、搬迁、换环境之年');
            keywords.add('出行');
          case '天乙贵人':
          case '月德贵人':
          case '天德':
            bump(6, 6, 4, 2, 2, '流年引动${s.name},贵人相助之年');
            keywords.add('贵人');
          case '羊刃':
          case '劫煞':
          case '亡神':
            bump(-5, -3, -6, -2, -5, '流年引动${s.name},慎防意外破耗');
            keywords.add('谨慎');
        }
        break;
      }
    }
  }

  if (chart.dayPillar.voidBranches.contains(ySb.branch)) {
    bump(-4, -3, -4, -2, -1, '流年地支落日柱空亡,多虚少实,宜守不宜攻');
  }

  int clamp(int v) => v.clamp(15, 98);
  overall = clamp(overall);
  career = clamp(career);
  wealth = clamp(wealth);
  love = clamp(love);
  health = clamp(health);

  final grade = overall >= 80
      ? '顺遂年'
      : overall >= 65
          ? '稳中有进'
          : overall >= 50
              ? '平年'
              : overall >= 40
                  ? '守成年'
                  : '蓄力年';

  // ---- 十二流月 ----
  final months = <MonthlyFortune>[];
  for (var m = 0; m < 12; m++) {
    final mSb = monthPillar(ySb.stem, m);
    final mTheme = tenGodOf(dayStem, mSb.stem);
    var score = 60;
    final notes = <String>[];
    final mEl = branchElements[mSb.branch];
    if (fav.contains(mEl)) {
      score += 10;
      notes.add('月支属${mEl.label}为喜用');
    } else if (unfav.contains(mEl)) {
      score -= 8;
      notes.add('月支属${mEl.label}为所忌');
    }
    final sEl = stemElements[mSb.stem];
    if (fav.contains(sEl)) {
      score += 5;
    } else if (unfav.contains(sEl)) {
      score -= 4;
    }
    if (isClash(mSb.branch, natal[2])) {
      score -= 8;
      notes.add('冲日支,感情与身体留意');
    } else if (isSixCombine(mSb.branch, natal[2])) {
      score += 6;
      notes.add('合日支,利感情');
    }
    if (isClash(mSb.branch, natal[0])) {
      score -= 4;
      notes.add('冲年支');
    }
    if (isClash(mSb.branch, ySb.branch)) {
      score -= 5;
      notes.add('月冲流年,变动月');
    }
    switch (mTheme.group) {
      case '财星':
        score += 3;
        notes.add('${mTheme.label}月利财');
      case '官杀':
        notes.add('${mTheme.label}月事业忙');
      case '印星':
        score += 2;
        notes.add('${mTheme.label}月利学习休整');
      case '食伤':
        score += 2;
        notes.add('${mTheme.label}月利表达');
      default:
        score -= 1;
        notes.add('${mTheme.label}月人来人往');
    }
    months.add(MonthlyFortune(
      index: m,
      pillar: mSb,
      score: score.clamp(15, 98),
      theme: mTheme,
      note: notes.join(';'),
    ));
  }
  final sorted = List<int>.generate(12, (i) => i)..sort((a, b) => months[b].score.compareTo(months[a].score));
  final best = sorted.take(2).toList();
  final caution = sorted.reversed.take(2).toList();

  return AnnualFortune(
    year: year,
    nominalAge: year - chart.input.year + 1,
    yearPillar: ySb,
    luckPillar: luck,
    theme: theme,
    taiSui: taiSui,
    overall: overall,
    career: career,
    wealth: wealth,
    love: love,
    health: health,
    grade: grade,
    factors: factors,
    keywords: keywords.take(5).toList(),
    months: months,
    bestMonths: best,
    cautionMonths: caution,
  );
}

/// 流月的本气十神(用于展示)。
TenGod monthBranchGod(BaziChart chart, MonthlyFortune m) => tenGodOf(chart.dayStem, mainHiddenStem(m.pillar.branch));

/// 十二节气月的大致公历月份提示(寅月≈2月…丑月≈1月)。
String monthApproxLabel(int index) {
  const labels = ['2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月', '1月'];
  return labels[index];
}
