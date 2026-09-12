/// 离线本地解读——不联网、不经过任何大模型 API。
///
/// 每个命理模块(八字、每日运势、合婚、姓名、黄历、手相、面相)在计算时
/// 已经把每一条加减分的"依据"留了下来(`reasoning` / `factors` / `reasons` /
/// `notes` 这些字段),本文件只是把这些结构化依据按固定模板组装成一段
/// 通顺的 Markdown——**没有随机性,同样的盘面永远生成同样的文字**。
///
/// 这不是"弱化版 AI",而是另一条完全独立的路径:排盘本来就在本机完成,
/// 这里只是把"措辞"这一步也留在本机,给不想连接服务器、不想使用云端
/// 大模型的用户一个不打折扣的替代品。
library;

import '../almanac/almanac.dart';
import '../bazi/bazi_chart.dart';
import '../bazi/five_elements.dart';
import '../bazi/hidden_stems.dart';
import '../bazi/ten_gods.dart';
import '../calendar/sexagenary.dart';
import '../fortune/daily_fortune.dart';
import '../marriage/marriage.dart';
import '../naming/name_analysis.dart';
import '../vision/face_features.dart';
import '../vision/palm_features.dart';
import '../zodiac/western_zodiac.dart';

const _localFooter = '\n\n---\n*以上内容由本机规则引擎生成,未连接任何云端服务,仅供娱乐参考。*';

String _section(String title) => '## $title\n';

/// 八字详批。
String localInterpretBazi(BaziChart c) {
  final e = c.elements;
  final buf = StringBuffer();

  buf.writeln(_section('命盘总览'));
  buf.writeln(
      '${c.input.gender.chartLabel} · ${c.summaryLine},日主为**${c.dayMasterName}**'
      '(${c.dayMaster.label}),生肖属${c.zodiac}。');
  buf.writeln(
      '出生真太阳时:${c.trueSolar.equationOfTimeMinutes >= 0 ? '+' : ''}'
      '${c.trueSolar.equationOfTimeMinutes.toStringAsFixed(1)} 分(均时差)、'
      '${c.trueSolar.longitudeCorrectionMinutes >= 0 ? '+' : ''}'
      '${c.trueSolar.longitudeCorrectionMinutes.toStringAsFixed(1)} 分(经度差)。\n');

  buf.writeln(_section('五行与日主强弱'));
  final pctText = Element.values
      .map((el) => '${el.label} ${e.percentages[el]!.round()}%')
      .join(' · ');
  buf.writeln('$pctText\n');
  buf.writeln('日主**${e.strength.label}**。');
  for (final r in e.reasoning) {
    buf.writeln('- $r');
  }
  buf.writeln();

  buf.writeln(_section('喜用与忌讳'));
  buf.writeln('喜用:${e.favorable.map((x) => x.label).join('、')}'
      '(首选${e.primaryUsefulGod.label});忌讳:${e.unfavorable.map((x) => x.label).join('、')}。');
  if (e.climateHint.isNotEmpty) buf.writeln('${e.climateHint}。');
  if (e.missing.isNotEmpty) {
    buf.writeln('五行缺${e.missing.map((x) => x.label).join('、')},'
        '可从职业、方位、用字上适当补足。');
  }
  buf.writeln();

  if (c.interactions.isNotEmpty) {
    buf.writeln(_section('命局刑冲合会'));
    for (final i in c.interactions) {
      buf.writeln('- ${i.description}');
    }
    buf.writeln();
  }

  if (c.shenSha.isNotEmpty) {
    buf.writeln(_section('神煞'));
    for (final s in c.shenSha) {
      buf.writeln('- **${s.name}**(${s.positions.map((p) => pillarNames[p]).join('')}柱,'
          '${s.nature.name == 'auspicious' ? '吉' : s.nature.name == 'inauspicious' ? '凶' : '中性'}):'
          '${s.meaning}');
    }
    buf.writeln();
  }

  buf.writeln(_section('大运走势'));
  buf.writeln('大运${c.luck.direction},${c.luck.startDescription}。');
  final cur = c.luck.cycles.where((cy) => cy.years.any((y) => y.year == DateTime.now().year)).toList();
  if (cur.isNotEmpty) {
    final cy = cur.first;
    final stemGod = tenGodOf(c.dayStem, cy.pillar.stem).label;
    final branchGod = tenGodOf(c.dayStem, mainHiddenStem(cy.pillar.branch)).label;
    buf.writeln('当前行**${cy.pillar.name}**运(${cy.ageRange}),天干$stemGod、地支主气$branchGod。');
  }
  buf.writeln();

  buf.writeln(_section('小结'));
  buf.writeln('胎元${c.taiYuan.name}、命宫${c.mingGong.name}、身宫${c.shenGong.name}。'
      '${e.strength.label}之命,以${e.primaryUsefulGod.label}为用,'
      '${e.strength.isStrongSide ? '行运喜克泄耗之地' : e.strength.isWeakSide ? '行运喜生扶之地' : '行运喜补益相对不足的五行'}。');

  return buf.toString() + _localFooter;
}

/// 每日运势。
String localInterpretDaily(BaziChart c, DailyFortune f) {
  final buf = StringBuffer();
  buf.writeln(_section('${f.year} 年 ${f.month} 月 ${f.day} 日 · ${f.dayPillar.name}日'));
  buf.writeln('今日主题:**${f.theme.label}**(${f.theme.group})。综合评分 **${f.overall}**。\n');

  buf.writeln(_section('四项评分'));
  buf.writeln('事业 ${f.career} · 财运 ${f.wealth} · 感情 ${f.love} · 健康 ${f.health}\n');

  buf.writeln(_section('依据'));
  for (final r in f.factors) {
    buf.writeln('- $r');
  }
  buf.writeln();

  buf.writeln(_section('宜忌提示'));
  buf.writeln('幸运色:${f.luckyColor} · 幸运数字:${f.luckyNumbers.join('、')} · 吉方:${f.luckyDirection}');
  if (f.keywords.isNotEmpty) buf.writeln('今日关键词:${f.keywords.join('、')}');

  return buf.toString() + _localFooter;
}

/// 合婚。
String localInterpretMarriage(MarriageResult m) {
  final buf = StringBuffer();
  buf.writeln(_section('总评:${m.grade}(${m.overall} 分)'));
  buf.writeln('${m.a.input.gender.chartLabel}方 ${m.a.summaryLine} × '
      '${m.b.input.gender.chartLabel}方 ${m.b.summaryLine}\n');

  if (m.highlights.isNotEmpty) {
    buf.writeln('**亮点**:${m.highlights.join('、')}\n');
  }
  if (m.cautions.isNotEmpty) {
    buf.writeln('**需留意**:${m.cautions.join('、')}\n');
  }

  buf.writeln(_section('六维详解'));
  for (final d in m.dimensions) {
    buf.writeln('**${d.name}**(${d.clamped} 分,权重 ${(d.weight * 100).round()}%)');
    for (final r in d.reasons) {
      buf.writeln('- $r');
    }
    buf.writeln();
  }

  buf.writeln(_section('相处建议'));
  if (m.overall >= 75) {
    buf.writeln('命理配置基础良好,珍惜彼此的契合之处;');
  } else if (m.overall >= 50) {
    buf.writeln('命理配置有利有弊,多在沟通与包容上下功夫;');
  } else {
    buf.writeln('命理配置存在明显摩擦点,若已在一起,不必因命理数字而焦虑,重点是正视上面列出的具体分歧并主动经营;');
  }
  if (m.cautions.isNotEmpty) buf.writeln('尤其留意:${m.cautions.join('、')}。');

  return buf.toString() + _localFooter;
}

/// 姓名测试。
String localInterpretName(NameAnalysis n) {
  final buf = StringBuffer();
  buf.writeln(_section('${n.fullName} · 综合评分 ${n.overallScore}'));
  buf.writeln('${n.summary}\n');

  buf.writeln(_section('五格详解'));
  for (final g in [n.tian, n.ren, n.di, n.wai, n.zong]) {
    buf.writeln('**${g.name} ${g.number}**(${g.meaning.title} · ${g.meaning.luck.label}):'
        '${g.meaning.text}。主${g.domain}。');
  }
  buf.writeln();

  buf.writeln(_section('三才配置'));
  buf.writeln('${n.sanCaiText}(天·人·地),${n.sanCaiScore} 分。${n.sanCaiComment}\n');

  if (n.zodiacNotes.isNotEmpty) {
    buf.writeln(_section('生肖用字'));
    for (final z in n.zodiacNotes) {
      buf.writeln('- $z');
    }
    buf.writeln();
  }

  if (n.elementNotes.isNotEmpty) {
    buf.writeln(_section('八字补益'));
    for (final e in n.elementNotes) {
      buf.writeln('- $e');
    }
    buf.writeln();
  }

  if (n.unknownChars.isNotEmpty) {
    buf.writeln('> 提示:「${n.unknownChars.join('、')}」笔画未能识别,以上计算按 0 画处理,仅供参考。');
  }

  return buf.toString() + _localFooter;
}

/// 黄历/择日建议。
String localInterpretAlmanac(AlmanacDay a, {BaziChart? chart}) {
  final buf = StringBuffer();
  buf.writeln(_section('${a.dateText} · ${a.ganZhiText}'));
  buf.writeln('${a.lunar} · ${a.weekdayName} · ${a.jianChu}日 · '
      '${a.zhiShen}(${a.isHuangDao ? '黄道吉日' : '黑道日'}) · ${a.xiu}\n');
  if (a.solarTerm != null) buf.writeln('今日交${a.solarTerm!.name}节气。\n');

  buf.writeln(_section('宜'));
  buf.writeln(a.suitable.isEmpty ? '诸事不宜,宜静守' : a.suitable.join('、'));
  buf.writeln();
  buf.writeln(_section('忌'));
  buf.writeln(a.unsuitable.isEmpty ? '无特别禁忌' : a.unsuitable.join('、'));
  buf.writeln();

  buf.writeln(_section('冲煞与方位'));
  buf.writeln('${a.clashText};喜神${a.joyDirection}、财神${a.wealthDirection}。');
  buf.writeln('彭祖百忌:${a.pengZu.join('；')}\n');

  if (a.notes.isNotEmpty) {
    buf.writeln(_section('依据'));
    for (final n in a.notes) {
      buf.writeln('- $n');
    }
  }

  if (chart != null) {
    buf.writeln('\n${_section('结合命主八字')}');
    final dayEl = chart.dayMaster;
    final favored = chart.elements.favorable.contains(_branchDayElement(a));
    buf.writeln(favored
        ? '当日干支五行与命主喜用较为契合,可优先考虑安排重要事项。'
        : '当日干支五行非命主首选喜用(日主${dayEl.label}),若无必要可另择他日,或以命主喜用之${chart.elements.primaryUsefulGod.label}方位、色彩调和。');
  }

  return buf.toString() + _localFooter;
}

Element _branchDayElement(AlmanacDay a) => branchElements[a.dayPillar.branch];

/// 手相。
String localInterpretPalm(PalmFeatures p) {
  final buf = StringBuffer();
  buf.writeln(_section('${p.hand} · ${p.handShape}'));
  buf.writeln('掌长/掌宽 ${p.palmAspect.toStringAsFixed(2)} · '
      '中指/掌长 ${p.fingerToPalm.toStringAsFixed(2)} · 拇指张角 ${p.thumbAngle.toStringAsFixed(0)}°\n');

  buf.writeln(_section('三大主线'));
  for (final l in p.lines) {
    buf.writeln('**${l.name}**:长度 ${l.length.toStringAsFixed(2)} · 弯曲度 ${l.curvature.toStringAsFixed(2)}'
        '${l.segments > 1 ? ' · 有 ${l.segments - 1} 处断续' : ''}');
  }
  buf.writeln();

  buf.writeln(_section('特征解读'));
  for (final n in p.notes) {
    buf.writeln('- $n');
  }

  return buf.toString() + _localFooter;
}

/// 面相。
String localInterpretFace(FaceFeatures f) {
  final buf = StringBuffer();
  buf.writeln(_section('${f.faceShape} · 对称度 ${(f.symmetry * 100).round()}%'));
  buf.writeln('三停比例 ${f.threeCourts.map((c) => (c * 100).round()).join(' : ')}'
      ' · 五眼比 ${f.fiveEyes.toStringAsFixed(1)}\n');

  buf.writeln(_section('十二宫气色'));
  for (final e in f.palaces.entries) {
    buf.writeln('**${e.key}**:${e.value}');
  }
  buf.writeln();

  buf.writeln(_section('整体印象'));
  for (final n in f.notes) {
    buf.writeln('- $n');
  }

  return buf.toString() + _localFooter;
}

/// 星座。
String localInterpretZodiac(ZodiacProfile p, {ZodiacMatch? match, BaziChart? chart}) {
  final s = p.sun;
  final buf = StringBuffer();

  buf.writeln(_section('太阳星座 · ${s.symbol} ${s.name}'));
  buf.writeln('${s.element.label}象 · ${s.modality.label}星座 · 守护星${s.ruler},'
      '太阳位于本宫 ${p.sunDegreeInSign.toStringAsFixed(1)}°。');
  buf.writeln('${s.element.label}象的核心是${s.element.keywords};'
      '${s.modality.label}星座擅长${s.modality.keywords}。\n');
  if (p.nearCusp) {
    buf.writeln('> 出生在换宫日附近(距${p.cuspNeighbour!.name}边界不到 1°),'
        '两个星座的特质可能兼而有之。\n');
  }

  buf.writeln(_section('性格画像'));
  buf.writeln('关键词:${s.keywords.join('、')}');
  buf.writeln('- 优势:${s.strengths.join('、')}');
  buf.writeln('- 需留意:${s.weaknesses.join('、')}\n');

  buf.writeln(_section('上升星座'));
  if (p.rising == null) {
    buf.writeln('未提供出生地经纬度,无法推算上升星座。\n');
  } else {
    final r = p.rising!;
    buf.writeln('${r.symbol} ${r.name}(${r.element.label}象)。${r.risingTrait}。');
    if (r.element != s.element) {
      buf.writeln('上升与太阳分属${r.element.label}象和${s.element.label}象,'
          '外在表现与内在动力有落差——别人眼里的你和你眼里的自己不太一样。');
    } else {
      buf.writeln('上升与太阳同属${s.element.label}象,内外一致,别人看到的和你感受到的基本相同。');
    }
    buf.writeln('(上升星座每两小时换一个,依赖准确的出生时间。)\n');
  }

  if (chart != null) {
    buf.writeln(_section('与八字对照'));
    buf.writeln('八字日主${chart.dayMasterName}${chart.dayMaster.label},'
        '${chart.elements.strength.label};太阳星座属${s.element.label}象。');
    buf.writeln('五行讲的是生克平衡,四元素讲的是气质倾向,两套体系不能直接换算,'
        '但可以互为参照:若两边都指向同一种性情,那大概是相当稳定的特质。\n');
  }

  if (match != null) {
    buf.writeln(_section('配对 · ${match.a.symbol}${match.a.name} × ${match.b.symbol}${match.b.name}'));
    buf.writeln('**${match.summary}**(${match.score} 分)');
    for (final r in match.reasons) {
      buf.writeln('- $r');
    }
    buf.writeln();
  } else {
    final best = bestMatchesFor(s);
    buf.writeln(_section('合拍的星座'));
    buf.writeln(best.map((b) => '${b.symbol}${b.name}').join('、'));
    buf.writeln();
  }

  buf.writeln(_section('小贴士'));
  buf.writeln('幸运色 ${s.luckyColor} · 幸运数字 ${s.luckyNumbers.join('、')}');

  return buf.toString() + _localFooter;
}
