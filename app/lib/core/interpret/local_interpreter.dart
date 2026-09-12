/// 离线本地解读——不联网、不经过任何大模型 API。
///
/// 每个命理模块在计算时已经把每一条加减分的"依据"留了下来
/// (`reasoning` / `factors` / `reasons` / `notes`),本文件把它们和
/// [plain_language.dart] 里的白话内容库拼成一篇有专业依据、
/// 又有大白话和趣味比喻的 Markdown。**没有随机性,同样的盘面永远同样的文字。**
///
/// 文风约定(与云端提示词保持一致):
/// - 专业术语第一次出现紧跟白话解释;
/// - 每个段落至少一个生活化画面;
/// - 结尾有"一句话版"和"术语小词典";
/// - 不出现疾病、死亡、灾祸与绝对化措辞。
library;

import '../almanac/almanac.dart';
import '../bazi/bazi_chart.dart';
import '../bazi/five_elements.dart';
import '../bazi/hidden_stems.dart';
import '../bazi/shen_sha.dart';
import '../bazi/ten_gods.dart';
import '../calendar/sexagenary.dart';
import '../fortune/daily_fortune.dart';
import '../marriage/marriage.dart';
import '../naming/name_analysis.dart';
import '../naming/numerology.dart';
import '../vision/face_features.dart';
import '../vision/palm_features.dart';
import '../zodiac/western_zodiac.dart';
import 'plain_language.dart';

const _localFooter = '\n\n---\n*以上内容由本机规则引擎生成,未连接任何云端服务;命理是看待性格与节律的一种传统视角,仅供娱乐参考。*';

String _h(String title) => '## $title\n';
String _quote(String s) => '> $s\n';

// ===========================================================================
// 八字
// ===========================================================================

String localInterpretBazi(BaziChart c) {
  final e = c.elements;
  final persona = stemPersonas[c.dayStem];
  final strength = strengthPlain(e.strength);
  final buf = StringBuffer();

  // ---- 开场:一句话人设 ----
  buf.writeln(_h('先说人话:你是哪种人'));
  buf.writeln('${c.input.gender.chartLabel},八字 **${c.summaryLine}**,日主 **${c.dayMasterName}${c.dayMaster.label}**'
      '(日主=出生那天的天干,代表你本人)。');
  buf.writeln('${c.dayMasterName}${c.dayMaster.label}的物象是**${persona.image}**——${persona.plain}');
  buf.writeln(_quote(persona.fun));
  buf.writeln('再叠上"${strength.term}":${strength.plain}');
  buf.writeln(_quote(strength.fun));
  buf.writeln('所以一句话人设:**${persona.image} × ${e.strength.label}** —— '
      '${persona.traits.join('、')},${_strengthTag(e)}。\n');
  if (c.input.timeMode.isEstimated) {
    buf.writeln(_quote('出生时间不确定:时柱、命宫、身宫和起运时刻都是按正午估算的,'
        '下面凡是牵涉这几项的结论都只当参考,重点看年、月、日三柱。'));
  }

  // ---- 四柱 ----
  buf.writeln(_h('四根柱子各管什么'));
  buf.writeln('八字就是四组"天干+地支",每组管人生一段:');
  const scope = ['年柱=祖辈与童年、你给人的第一印象', '月柱=父母兄弟与青年、你的事业舞台', '日柱=你自己与配偶、婚姻宫', '时柱=子女与晚年、你的内心底色'];
  for (var i = 0; i < 4; i++) {
    final p = c.pillars[i];
    final god = p.stemGod;
    final godText = god == null ? '日主本人' : '${god.label}(${tenGodPlain[god]!.plain.split(';').first})';
    buf.writeln('- **${p.positionName}柱 ${p.name}** · ${scope[i]}。天干为$godText;'
        '地支藏${p.hiddenStems.map((h) => '${h.name}(${h.tenGod.label})').join('、')};'
        '日主在此为"${p.lifeStage}"。');
  }
  buf.writeln();

  // ---- 五行 ----
  buf.writeln(_h('五行体检报告'));
  final pct = Element.values.map((el) => '${el.label} ${e.percentages[el]!.round()}%').join(' · ');
  buf.writeln('$pct\n');
  buf.writeln('专业判定过程(每条都是打分依据):');
  for (final r in e.reasoning) {
    buf.writeln('- $r');
  }
  buf.writeln();
  buf.writeln('翻译成白话:${_threeGets(e)}');
  if (e.missing.isNotEmpty) {
    buf.writeln('五行缺**${e.missing.map((x) => x.label).join('、')}**——不是坏事,'
        '相当于菜里少了一味调料,知道缺什么就知道往哪儿补。');
  }
  buf.writeln();

  // ---- 喜用 ----
  final primary = e.primaryUsefulGod;
  final adv = elementAdvice[primary]!;
  buf.writeln(_h('你的"补品"和"过敏原"'));
  buf.writeln('用神(对你最有帮助的五行)是 **${primary.label}**;喜用 ${e.favorable.map((x) => x.label).join('、')},'
      '忌 ${e.unfavorable.map((x) => x.label).join('、')}。');
  if (e.climateHint.isNotEmpty) buf.writeln('${e.climateHint}。');
  buf.writeln();
  buf.writeln('落到生活里怎么用(围绕${primary.label}):');
  buf.writeln('- 方位:${adv.direction};颜色:${adv.colors}');
  buf.writeln('- 行业属性:${adv.industries}');
  buf.writeln('- 日常:${adv.habits}');
  buf.writeln(_quote(adv.fun));
  final avoid = e.unfavorable.first;
  buf.writeln('忌${avoid.label}不是"碰不得",是"别把它当主食":'
      '${elementAdvice[avoid]!.industries.split('、').take(2).join('、')}这类事可以做,但别把全部筹码压上去。\n');

  // ---- 十神画像 ----
  buf.writeln(_h('性格拆解:命盘里的几位"配角"'));
  final gods = <TenGod, int>{};
  for (final p in c.pillars) {
    if (p.stemGod != null) gods[p.stemGod!] = (gods[p.stemGod!] ?? 0) + 2;
    for (final h in p.hiddenStems) {
      gods[h.tenGod] = (gods[h.tenGod] ?? 0) + (h.weight >= 0.6 ? 1 : 0);
    }
  }
  final top = gods.entries.where((x) => x.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
  for (final g in top.take(3)) {
    final p = tenGodPlain[g.key]!;
    buf.writeln('- **${p.term}**(出场 ${g.value} 次):${p.plain}');
    buf.writeln('  > ${p.fun}');
  }
  final absent = TenGod.values.where((g) => !gods.containsKey(g)).map((g) => g.group).toSet();
  if (absent.isNotEmpty) {
    buf.writeln('- 命盘里几乎没有 ${absent.join('、')} 这类星:对应的领域要靠后天大运或身边人来补,不是没有,是"外置"的。');
  }
  buf.writeln();

  // ---- 刑冲合会 ----
  if (c.interactions.isNotEmpty) {
    buf.writeln(_h('字与字之间的化学反应'));
    buf.writeln('地支之间会"合"(抱团、顺)、"冲"(对撞、变动)、"刑""害"(别扭、消耗)。你的盘里有:');
    for (final i in c.interactions) {
      buf.writeln('- ${i.description}${i.kind.isHarmonious ? ' —— 加分项,像两块磁铁自然贴合' : ' —— 摩擦项,像两把钥匙插同一把锁,需要外力调和'}');
    }
    buf.writeln();
  }

  // ---- 神煞 ----
  if (c.shenSha.isNotEmpty) {
    buf.writeln(_h('命盘上的小徽章:神煞'));
    buf.writeln('神煞是命盘里的特殊标记,有吉有凶,像游戏角色身上的徽章——有,不代表一定发生;没有,也不代表缺什么。');
    for (final s in c.shenSha) {
      final tag = switch (s.nature) {
        ShenShaNature.auspicious => '🟡吉',
        ShenShaNature.inauspicious => '🔴需留意',
        ShenShaNature.neutral => '⚪中性',
      };
      buf.writeln('- **${s.name}**($tag,${s.positions.map((p) => pillarNames[p]).join()}柱):${s.meaning}');
    }
    if (c.voidPositions.isNotEmpty) {
      buf.writeln('- **空亡**落在${c.voidPositions.map((p) => pillarNames[p]).join('、')}柱:'
          '这个位置像信号弱的格子,相关的事多想少赌,不必焦虑。');
    }
    buf.writeln();
  }

  // ---- 大运 ----
  buf.writeln(_h('人生天气预报:大运'));
  buf.writeln('大运是十年换一次的大环境,流年是每一年的小天气。你的大运${c.luck.direction},${c.luck.startDescription}。');
  final now = DateTime.now().year;
  final cur = c.luck.cycleForYear(now);
  if (cur != null) {
    final sg = tenGodOf(c.dayStem, cur.pillar.stem);
    final bg = tenGodOf(c.dayStem, mainHiddenStem(cur.pillar.branch));
    final el = stemElements[cur.pillar.stem];
    final good = e.favorable.contains(el);
    final bad = e.unfavorable.contains(el);
    buf.writeln('**现在(${cur.startYear}–${cur.endYear},${cur.ageRange})走 ${cur.pillar.name} 运**:'
        '天干${sg.label}、地支${bg.label}。${tenGodPlain[sg]!.plain}');
    buf.writeln(good
        ? '这步运的天干属${el.label},正是你的喜用——顺风的十年,该出手时别客气。'
        : bad
            ? '这步运的天干属${el.label},是你所忌——逆风的十年,不是不能走,是步子放稳、少做大额赌注。'
            : '这步运的天干属${el.label},不喜不忌——平稳的十年,靠积累。');
    final next = c.luck.cycleForYear(cur.endYear + 1);
    if (next != null) {
      final nel = stemElements[next.pillar.stem];
      buf.writeln('下一步 ${next.pillar.name} 运(${next.startYear} 起)天干属${nel.label},'
          '${e.favorable.contains(nel) ? '风向转好' : e.unfavorable.contains(nel) ? '要提前把防风的事做在前头' : '气候平稳'}。');
    }
    final thisYear = cur.years.where((y) => y.year == now).firstOrNull;
    if (thisYear != null) {
      final yg = tenGodOf(c.dayStem, thisYear.pillar.stem);
      buf.writeln('今年 ${thisYear.pillar.name} 年(${thisYear.nominalAge} 虚岁)天干为${yg.label}——${tenGodGroupPlain[yg.group]!.plain}');
    }
  } else {
    buf.writeln('尚未起运或已超出排布范围。');
  }
  buf.writeln();

  // ---- 小结 ----
  buf.writeln(_h('一句话版'));
  buf.writeln('${persona.image}命,${e.strength.label},靠${primary.label}吃饭,'
      '${e.strength.isStrongSide ? '多输出、多担事' : e.strength.isWeakSide ? '多借力、多学习' : '顺势而为'}。'
      '${persona.tip}');
  buf.writeln();
  buf.writeln('胎元 ${c.taiYuan.name} · 命宫 ${c.mingGong.name} · 身宫 ${c.shenGong.name}(进阶参数,一般看看就好)\n');

  buf.writeln(_h('术语小词典'));
  for (final g in baziGlossary) {
    buf.writeln('- **${g.term}**:${g.plain}(${g.fun})');
  }

  return buf.toString() + _localFooter;
}

String _strengthTag(ElementAnalysisLike e) => e.strength.isStrongSide
    ? '劲头足、主意大'
    : e.strength.isWeakSide
        ? '心思细、会借力'
        : '不偏不倚、稳';

String _threeGets(ElementAnalysisLike e) {
  final parts = <String>[
    e.gotSeason ? '出生的季节帮你(得令)' : '出生的季节不帮你(不得令)',
    e.gotRoot ? '脚下有根(得地)' : '脚下没根(不得地)',
    e.gotSupport ? '身边有帮手(得势)' : '身边帮手少(不得势)',
  ];
  final n = [e.gotSeason, e.gotRoot, e.gotSupport].where((x) => x).length;
  final verdict = n == 3
      ? '三样全占,底子厚,像开局就带装备。'
      : n == 2
          ? '占了两样,底子不错,缺的那样后天补。'
          : n == 1
              ? '占了一样,底子一般,得靠运和人。'
              : '三样都不占,但这种命反而常有贵人——因为你知道要找人。';
  return '${parts.join(',')}。$verdict';
}

/// 只为了让上面两个帮手不依赖具体类型名——实际传入的就是 ElementAnalysis。
typedef ElementAnalysisLike = dynamic;

// ===========================================================================
// 每日运势
// ===========================================================================

String localInterpretDaily(BaziChart c, DailyFortune f) {
  final sp = scorePlain(f.overall);
  final theme = tenGodGroupPlain[f.theme.group]!;
  final buf = StringBuffer();

  buf.writeln(_h('${f.month} 月 ${f.day} 日 · ${f.dayPillar.name}日 · ${sp.term}'));
  buf.writeln('综合 **${f.overall}** 分。${sp.plain}');
  buf.writeln(_quote(sp.fun));

  buf.writeln(_h('今天的主题:${theme.term}'));
  buf.writeln('今天的天干${f.dayPillar.stemName}对你来说是**${f.theme.label}**(${tenGodPlain[f.theme]!.plain})。${theme.plain}');
  buf.writeln(_quote(theme.fun));

  buf.writeln(_h('四项分数怎么看'));
  final items = {'事业': f.career, '财运': f.wealth, '感情': f.love, '健康': f.health};
  final best = items.entries.reduce((a, b) => a.value >= b.value ? a : b);
  final worst = items.entries.reduce((a, b) => a.value <= b.value ? a : b);
  buf.writeln(items.entries.map((x) => '${x.key} ${x.value}').join(' · '));
  buf.writeln('最亮的是**${best.key}**(${best.value}),把重要的${best.key}相关的事排在今天;'
      '最需要留意的是**${worst.key}**(${worst.value}),${_worstAdvice(worst.key)}\n');

  buf.writeln(_h('为什么是这个分(依据)'));
  for (final r in f.factors) {
    buf.writeln('- $r');
  }
  buf.writeln();

  buf.writeln(_h('今日小抄'));
  buf.writeln('幸运色 **${f.luckyColor}** · 幸运数字 **${f.luckyNumbers.join('、')}** · 吉方 **${f.luckyDirection}**');
  if (f.keywords.isNotEmpty) buf.writeln('关键词:${f.keywords.map((k) => '#$k').join(' ')}');
  buf.writeln();
  buf.writeln('一句话:${_dailyOneLiner(f)}');

  return buf.toString() + _localFooter;
}

String _worstAdvice(String k) => switch (k) {
      '事业' => '今天别硬推方案,把材料准备好等明天。',
      '财运' => '大额支出、投资决定往后挪一天。',
      '感情' => '容易话赶话,少说一句比多说一句划算。',
      _ => '早点睡,别熬夜,饮食清淡一点。',
    };

String _dailyOneLiner(DailyFortune f) {
  if (f.overall >= 80) return '想做的事今天做,想见的人今天见。';
  if (f.overall >= 65) return '顺着做,别逆着来。';
  if (f.overall >= 50) return '按部就班,不冒进,今天的稳就是明天的快。';
  return '守好手里的,今天适合整理、复盘、早睡。';
}

// ===========================================================================
// 合婚
// ===========================================================================

String localInterpretMarriage(MarriageResult m) {
  final gp = marriageGradePlain(m.grade);
  final pa = stemPersonas[m.a.dayStem], pb = stemPersonas[m.b.dayStem];
  final buf = StringBuffer();

  buf.writeln(_h('总评:${m.grade} · ${m.overall} 分'));
  buf.writeln('${m.a.input.gender.chartLabel}方 ${m.a.summaryLine}(${m.a.dayMasterName}${m.a.dayMaster.label},${pa.image}) × '
      '${m.b.input.gender.chartLabel}方 ${m.b.summaryLine}(${m.b.dayMasterName}${m.b.dayMaster.label},${pb.image})');
  buf.writeln(gp.plain);
  buf.writeln(_quote(gp.fun));

  buf.writeln(_h('两个人放在一起是什么画面'));
  buf.writeln('一个是**${pa.image}**(${pa.traits.join('、')}),一个是**${pb.image}**(${pb.traits.join('、')})。');
  buf.writeln(_elementPairFun(m.a.dayMaster, m.b.dayMaster));
  buf.writeln();

  if (m.highlights.isNotEmpty) buf.writeln('**加分项**:${m.highlights.join('、')}\n');
  if (m.cautions.isNotEmpty) buf.writeln('**磨合点**:${m.cautions.join('、')}\n');

  buf.writeln(_h('六个维度逐条说'));
  for (final d in m.dimensions) {
    final p = marriageDimensionPlain[d.name];
    buf.writeln('**${d.name} ${d.clamped} 分**(权重 ${(d.weight * 100).round()}%)'
        '${p == null ? '' : ' —— ${p.plain}'}');
    if (p != null) buf.writeln('> ${p.fun}');
    for (final r in d.reasons) {
      buf.writeln('- $r');
    }
    buf.writeln();
  }

  buf.writeln(_h('相处建议(可执行版)'));
  final lowest = m.dimensions.reduce((a, b) => a.clamped <= b.clamped ? a : b);
  buf.writeln('1. 最低分是**${lowest.name}**,${_dimAdvice(lowest.name)}');
  buf.writeln('2. ${pa.tip}(给${m.a.input.gender.label}方)');
  buf.writeln('3. ${pb.tip}(给${m.b.input.gender.label}方)');
  buf.writeln();
  buf.writeln('合婚是相处说明书,不是判决书:分数说的是"默认设置"合不合,人是可以改设置的。');

  return buf.toString() + _localFooter;
}

String _elementPairFun(Element a, Element b) {
  final rel = a.relationTo(b);
  return switch (rel) {
    ElementRelation.same => '同属${a.label},像两个同款——理解零成本,但也容易同时犯同一个错。',
    ElementRelation.iGenerate => '${a.label}生${b.label}:前者像给后者供电的那一方,付出多;后者记得回头充电。',
    ElementRelation.generatesMe => '${b.label}生${a.label}:后者像给前者供电的那一方,付出多;前者记得回头充电。',
    ElementRelation.iControl => '${a.label}克${b.label}:前者更强势,像开车的那位——开得稳没问题,别抢方向盘。',
    ElementRelation.controlsMe => '${b.label}克${a.label}:后者更强势,像开车的那位——开得稳没问题,别抢方向盘。',
  };
}

String _dimAdvice(String name) => switch (name) {
      '生肖缘' => '第一印象和两家人的相处需要多花心思,节假日别怕麻烦多走动。',
      '日柱缘' => '这是过日子的核心项,建议尽早把"钱怎么管、家务怎么分、假期回谁家"这三件事聊透。',
      '五行互补' => '两人能量类型接近或相斥,各自要有自己的充电方式,别指望对方全包。',
      '配偶星' => '有一方对"关系"的需求不太清晰,把期待说出口,别让对方猜。',
      '神煞' => '命盘里有些提醒多陪伴的标记,固定一个两人专属的时间段。',
      _ => '家庭层面的气场略有差异,多在长辈面前替对方说好话。',
    };

// ===========================================================================
// 姓名
// ===========================================================================

String localInterpretName(NameAnalysis n) {
  final buf = StringBuffer();
  buf.writeln(_h('${n.fullName} · ${n.overallScore} 分'));
  buf.writeln('笔画(康熙):${n.strokes.join(' · ')}。${n.summary}');
  buf.writeln(_quote(n.overallScore >= 80
      ? '这名字在数理上是"好学生"型,家长当年没少翻字典。'
      : n.overallScore >= 65
          ? '中上水平,像一件基础款——不惊艳但耐穿。'
          : '数理上有几处小疙瘩,不过名字是拿来叫的,不是拿来考试的。'));

  buf.writeln(_h('五格是什么'));
  buf.writeln('五格剖象把名字拆成五个数,每个数对应人生一块。先看人格和总格,其他是配菜。');
  for (final g in [n.ren, n.zong, n.di, n.wai, n.tian]) {
    final p = gridPlain[g.name]!;
    final icon = switch (g.meaning.luck) {
      Luck.auspicious => '🟢',
      Luck.half => '🟡',
      Luck.inauspicious => '🔴',
    };
    buf.writeln('- $icon **${g.name} ${g.number} · ${g.meaning.title}**(${g.meaning.luck.label}):${g.meaning.text}。');
    buf.writeln('  ${p.plain} ${p.fun}');
  }
  buf.writeln();

  buf.writeln(_h('三才:天·人·地怎么搭'));
  buf.writeln('三才 **${n.sanCaiText}**,${n.sanCaiScore} 分。${n.sanCaiComment}');
  buf.writeln(_quote(n.sanCaiScore >= 70
      ? '三层楼一层托一层,结构稳。'
      : n.sanCaiScore >= 50
          ? '三层楼有一处承重墙略薄,住着没问题,别堆太重的东西。'
          : '三层楼有相克的地方,靠人格这层撑着——性格越稳,名字越不是问题。'));

  if (n.elementNotes.isNotEmpty) {
    buf.writeln(_h('和你八字对不对路'));
    for (final e in n.elementNotes) {
      buf.writeln('- $e');
    }
    buf.writeln('名字是每天被叫几十遍的"随身符",五行对路就是顺手加 buff,不对路也不扣血。\n');
  }

  if (n.zodiacNotes.isNotEmpty) {
    buf.writeln(_h('生肖用字'));
    for (final z in n.zodiacNotes) {
      buf.writeln('- $z');
    }
    buf.writeln();
  }

  if (n.unknownChars.isNotEmpty) {
    buf.writeln(_quote('「${n.unknownChars.join('、')}」笔画未能识别,按 0 画计,结果仅供参考。'));
  }

  buf.writeln(_h('一句话版'));
  buf.writeln('人格${n.ren.number}${n.ren.meaning.luck.label}、总格${n.zong.number}${n.zong.meaning.luck.label},'
      '${n.overallScore >= 70 ? '名字和人是互相成就的关系' : '名字只是起点,叫响了就是好名字'}。');

  return buf.toString() + _localFooter;
}

// ===========================================================================
// 黄历
// ===========================================================================

String localInterpretAlmanac(AlmanacDay a, {BaziChart? chart}) {
  final jc = jianChuPlain[a.jianChu];
  final zs = zhiShenPlain[a.zhiShen];
  final buf = StringBuffer();

  buf.writeln(_h('${a.dateText} · ${a.ganZhiText}'));
  buf.writeln('${a.lunar} · ${a.weekdayName} · ${a.xiu}');
  if (a.solarTerm != null) buf.writeln('今天交**${a.solarTerm!.name}**——节气换挡,身体和日程都给点缓冲。');
  buf.writeln();

  buf.writeln(_h('今天是什么日子'));
  buf.writeln('建除:**${a.jianChu}日**。${jc?.plain ?? ''}');
  if (jc != null) buf.writeln(_quote(jc.fun));
  buf.writeln('值神:**${a.zhiShen}**(${a.isHuangDao ? '黄道吉日' : '黑道日'})。${zs?.plain ?? ''}');
  if (zs != null) buf.writeln(_quote(zs.fun));
  buf.writeln(_dayVerdict(a));
  buf.writeln();

  buf.writeln(_h('宜 · 忌'));
  buf.writeln('**宜**:${a.suitable.isEmpty ? '诸事不宜,宜静守' : a.suitable.join('、')}');
  buf.writeln('**忌**:${a.unsuitable.isEmpty ? '无特别禁忌' : a.unsuitable.join('、')}\n');

  buf.writeln(_h('冲煞与方位'));
  buf.writeln('${a.clashText}——属${a.clashZodiac}的朋友今天办大事稍缓,方位"煞${a.shaDirection}"少往那边动土远行。');
  buf.writeln('喜神${a.joyDirection}、财神${a.wealthDirection}:出门第一步往这边迈,是老辈人的仪式感。');
  buf.writeln('彭祖百忌:${a.pengZu.join(';')}(古人的经验口诀,听着玩儿也行,照着做也不亏)\n');

  final goodHours = a.hourFortunes.where((h) => h.isHuangDao).toList();
  if (goodHours.isNotEmpty) {
    buf.writeln(_h('今天的黄金时段'));
    buf.writeln(goodHours.map((h) => '${h.stemBranch.name}时 ${h.range}(${h.zhiShen})').join(' · '));
    buf.writeln('重要的事往这些时段挪,和"赶在早高峰前出门"一个道理。\n');
  }

  if (a.notes.isNotEmpty) {
    buf.writeln(_h('宜忌是怎么来的'));
    for (final n in a.notes) {
      buf.writeln('- $n');
    }
    buf.writeln();
  }

  if (chart != null) {
    buf.writeln(_h('对你个人而言'));
    final dayEl = branchElements[a.dayPillar.branch];
    final fav = chart.elements.favorable.contains(dayEl);
    final unfav = chart.elements.unfavorable.contains(dayEl);
    final clash = a.clashZodiac == chart.zodiac;
    buf.writeln(clash
        ? '今天冲的正是你的生肖${chart.zodiac}——不是禁止出门,是今天别做需要"运气"的决定。'
        : '今天不冲你的生肖,常规操作。');
    buf.writeln(fav
        ? '今日地支属${dayEl.label},是你的喜用:黄历和你的命盘方向一致,重要事项优先今天。'
        : unfav
            ? '今日地支属${dayEl.label},是你所忌:黄历再好也打个八折,可办不可赌。'
            : '今日地支属${dayEl.label},与你不喜不忌:按黄历来即可。');
  }

  return buf.toString() + _localFooter;
}

String _dayVerdict(AlmanacDay a) {
  final good = a.isHuangDao;
  final jc = a.jianChu;
  if (good && ['成', '开', '定', '满'].contains(jc)) return '两项都亮绿灯:**办事的好日子**。';
  if (!good && ['破', '危', '闭'].contains(jc)) return '两项都偏弱:**适合休息、整理、不开新局的日子**。';
  return '一好一平:**普通的可用日**,重要的事挑黄道时辰办。';
}

// ===========================================================================
// 手相
// ===========================================================================

String localInterpretPalm(PalmFeatures p) {
  final hs = handShapePlain[p.handShape];
  final buf = StringBuffer();

  buf.writeln(_h('${p.hand} · ${p.handShape}'));
  buf.writeln('掌长/掌宽 ${p.palmAspect.toStringAsFixed(2)} · 中指/掌长 ${p.fingerToPalm.toStringAsFixed(2)} · 拇指张角 ${p.thumbAngle.toStringAsFixed(0)}°');
  if (hs != null) {
    buf.writeln('${hs.term}:${hs.plain}');
    buf.writeln(_quote(hs.fun));
  }

  buf.writeln(_h('三大主线(掌纹里的"三条主干道")'));
  buf.writeln('生命线看精力与生活节奏,智慧线看思维方式,感情线看情感表达——**都不是看寿命和结果,是看风格**。');
  for (final l in p.lines) {
    buf.writeln('- **${l.name}**:长 ${l.length.toStringAsFixed(2)} · 弯 ${l.curvature.toStringAsFixed(2)}'
        '${l.segments > 1 ? ' · ${l.segments - 1} 处断续(掌纹断续在传统上主"阶段变化",很多人都有)' : ''}');
  }
  buf.writeln();

  buf.writeln(_h('手指在说什么'));
  for (final e in p.fingerRatios.entries) {
    buf.writeln('- ${e.key} ${e.value.toStringAsFixed(2)}');
  }
  buf.writeln();

  buf.writeln(_h('综合解读'));
  for (final n in p.notes) {
    buf.writeln('- $n');
  }
  buf.writeln();
  buf.writeln('一句话:${hs?.plain ?? '掌相是性格的另一面镜子'} 掌纹会随年龄和用手习惯变化,今年和三年后看可能不一样——这恰好说明它讲的是"现在的你"。');

  return buf.toString() + _localFooter;
}

// ===========================================================================
// 面相
// ===========================================================================

String localInterpretFace(FaceFeatures f) {
  final fs = faceShapePlain[f.faceShape];
  final buf = StringBuffer();
  final courts = f.threeCourts.map((c) => (c * 100).round()).toList();

  buf.writeln(_h('${f.faceShape} · 对称度 ${(f.symmetry * 100).round()}%'));
  if (fs != null) {
    buf.writeln('${fs.term}:${fs.plain}');
    buf.writeln(_quote(fs.fun));
  }

  buf.writeln(_h('三停五眼:面相的"标尺"'));
  buf.writeln('三停把脸从上到下分三段:上停(发际到眉)看早年与思虑,中停(眉到鼻底)看中年与行动,下停(鼻底到下巴)看晚年与意志。');
  buf.writeln('你的三停 **${courts.join(' : ')}**(理想约 33:33:33),五眼比 **${f.fiveEyes.toStringAsFixed(1)}**(理想约 5)。');
  final maxIdx = courts.indexOf(courts.reduce((a, b) => a > b ? a : b));
  buf.writeln(_quote(['上停略长:脑子转得多,想在做前面。', '中停略长:行动派,三十到五十岁是主场。', '下停略长:越老越稳,意志力是长项。'][maxIdx]));

  buf.writeln(_h('十二宫:五官各管一块'));
  buf.writeln('面相把脸分成十二个"宫",各对应一个人生领域。下面是几何测量给出的描述(只描述形状,不评美丑):');
  for (final e in f.palaces.entries) {
    buf.writeln('- **${e.key}**:${e.value}');
  }
  buf.writeln();

  buf.writeln(_h('综合印象'));
  for (final n in f.notes) {
    buf.writeln('- $n');
  }
  buf.writeln();
  buf.writeln('一句话:面相讲的是"相由心生"的那个"心"——表情、习惯、状态都会改变它,所以它更像一张近况快照,而不是出厂设置。');

  return buf.toString() + _localFooter;
}

// ===========================================================================
// 星座
// ===========================================================================

String localInterpretZodiac(ZodiacProfile p, {ZodiacMatch? match, BaziChart? chart}) {
  final s = p.sun;
  final buf = StringBuffer();

  buf.writeln(_h('太阳星座 · ${s.symbol} ${s.name}'));
  buf.writeln('${s.element.label}象 · ${s.modality.label}星座 · 守护星${s.ruler},太阳位于本宫 ${p.sunDegreeInSign.toStringAsFixed(1)}°。');
  buf.writeln('太阳星座讲的是你的**内在驱动**——什么事让你觉得"活着"。'
      '${s.element.label}象的核心是${s.element.keywords};${s.modality.label}星座擅长${s.modality.keywords}。');
  buf.writeln(_quote(_zodiacFun(s)));
  if (p.nearCusp) {
    buf.writeln(_quote('出生在换宫日附近(距${p.cuspNeighbour!.name}边界不到 1°),两个星座的特质可能兼而有之——'
        '别人说你"不像${s.name}"的时候,可以理直气壮地说"我是混血"。'));
  }

  buf.writeln(_h('性格画像'));
  buf.writeln('关键词:${s.keywords.join('、')}');
  buf.writeln('- 优势:${s.strengths.join('、')}');
  buf.writeln('- 需留意:${s.weaknesses.join('、')}——优点用过头就是它。\n');

  buf.writeln(_h('上升星座:别人眼里的你'));
  if (p.rising == null) {
    buf.writeln('未提供出生地经纬度,无法推算上升星座。');
  } else {
    final r = p.rising!;
    buf.writeln('${r.symbol} **${r.name}**(${r.element.label}象)。${r.risingTrait}。');
    buf.writeln(r.element != s.element
        ? '上升(${r.element.label}象)和太阳(${s.element.label}象)不是一路的:别人看到的你和你感受到的自己有落差——'
            '像穿着${r.name}的外套,里面是${s.name}的 T 恤。'
        : '上升与太阳同属${s.element.label}象,内外一致,你给人的第一印象基本就是你本人,省了不少解释成本。');
    buf.writeln('(上升星座约每两小时换一个,依赖准确的出生时间。)');
  }
  buf.writeln();

  if (chart != null) {
    final persona = stemPersonas[chart.dayStem];
    buf.writeln(_h('星座 × 八字:两套系统对一下表'));
    buf.writeln('八字说你是**${persona.image}**(日主${chart.dayMasterName}${chart.dayMaster.label},${chart.elements.strength.label}),'
        '星座说你是**${s.name}**(${s.element.label}象)。');
    buf.writeln(_crossCheck(chart.dayMaster, s.element));
    buf.writeln('五行讲生克平衡,四元素讲气质倾向,不能直接换算;但两边都指向同一种性情时,那大概是相当稳定的特质。\n');
  }

  if (match != null) {
    buf.writeln(_h('配对 · ${match.a.symbol}${match.a.name} × ${match.b.symbol}${match.b.name}'));
    buf.writeln('**${match.summary}**(${match.score} 分)');
    for (final r in match.reasons) {
      buf.writeln('- $r');
    }
    buf.writeln();
  } else {
    final best = bestMatchesFor(s);
    buf.writeln(_h('和谁最合拍'));
    buf.writeln(best.map((b) => '${b.symbol}${b.name}(${zodiacMatch(s, b).score})').join('、'));
    buf.writeln('对宫 ${s.opposite.symbol}${s.opposite.name} 是"互补型吸引",像镜子照见你缺的那一半。\n');
  }

  buf.writeln(_h('小贴士'));
  buf.writeln('幸运色 ${s.luckyColor} · 幸运数字 ${s.luckyNumbers.join('、')}');
  buf.writeln('一句话:${s.name}的人生课题是把"${s.weaknesses.first}"练成"${s.strengths.first}"的另一面。');

  return buf.toString() + _localFooter;
}

String _zodiacFun(ZodiacSign s) => switch (s) {
      ZodiacSign.aries => '群里发"冲"的永远是你,发完真的冲了。',
      ZodiacSign.taurus => '换手机之前先用坏三个手机壳。',
      ZodiacSign.gemini => '一个人能把群聊聊出四个人的效果。',
      ZodiacSign.cancer => '朋友失恋你比他先哭,然后给他煮面。',
      ZodiacSign.leo => '合影永远在 C 位,不是抢的,是大家自动让的。',
      ZodiacSign.virgo => '别人的 PPT 你一眼看到第三页字体不统一。',
      ZodiacSign.libra => '"都行""你定"是口头禅,其实心里有答案。',
      ZodiacSign.scorpio => '三年前谁说过什么你都记得,但你不说。',
      ZodiacSign.sagittarius => '说走就走的旅行,票是在去机场的路上买的。',
      ZodiacSign.capricorn => '二十岁活得像四十岁,四十岁活得像二十岁。',
      ZodiacSign.aquarius => '朋友觉得你是外星人,你觉得他们才是。',
      ZodiacSign.pisces => '看广告都能看哭,然后买了。',
    };

String _crossCheck(Element dayMaster, ZodiacElement ze) {
  final warm = dayMaster == Element.fire || dayMaster == Element.wood;
  final hot = ze == ZodiacElement.fire || ze == ZodiacElement.air;
  if (warm && hot) return '两边都偏"向外、向上":热情外放这一点应该很准。';
  if (!warm && !hot) return '两边都偏"向内、向下":沉稳内敛这一点应该很准。';
  return '一边外放一边内敛:你可能是"看场合切换模式"的人,熟人面前和陌生人面前不太一样。';
}
