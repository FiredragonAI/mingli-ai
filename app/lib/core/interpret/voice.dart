/// 解读的"声音":标题、金句、别做/去做、反直觉洞察。
///
/// 这是让文字有个性的那一层。原则:
/// - 第二人称、现在时、命令式,像一个见多识广的朋友直接跟你说话;
/// - 一句话能被截图;夸完补一刀,损完给台阶;
/// - 所有选句都是**确定性**的:同一个人同一天永远同一句,但换一天就换一句;
/// - 不出现疾病、死亡、灾祸、绝对化措辞(见 docs/COMPLIANCE.md)。
library;

import '../bazi/bazi_chart.dart';
import '../bazi/element_strength.dart';
import '../bazi/five_elements.dart';
import '../bazi/ten_gods.dart';
import '../fortune/annual_fortune.dart';
import '../fortune/daily_fortune.dart';
import 'plain_language.dart';

/// 从一组候选里按种子取一条;种子来自命主 + 日期,保证"同人同日同句"。
T pick<T>(List<T> pool, int seed) => pool[seed.abs() % pool.length];

int personSeed(BaziChart c) => c.dayPillar.stemBranch.index * 7 + c.monthPillar.stemBranch.index;

// ===========================================================================
// 八字
// ===========================================================================

/// 八字解读标题:物象 + 强弱 + 一个反转。
String baziHeadline(BaziChart c) {
  final p = stemPersonas[c.dayStem];
  final st = c.elements.strength;
  final image = p.image;
  final pool = switch (st) {
    StrengthLevel.veryStrong || StrengthLevel.strong => [
        '$image长得太旺,记得给别人留点阳光',
        '你是那种"我来"说出口事情就成一半的人',
        '劲儿足是天赋,往哪儿使是功课',
        '$image的命,别把"能扛"活成"只能扛"',
      ],
    StrengthLevel.weak || StrengthLevel.veryWeak => [
        '$image不算高,但你知道往哪儿借光',
        '你的天赋不是硬撑,是找到插座',
        '看起来软,其实是这盘里最会拐弯的那个',
        '弱不是缺点,是你比别人早学会了求助',
      ],
    _ => [
        '$image刚刚好,难的是一直刚刚好',
        '不偏不倚的命,最怕自己嫌太平淡',
        '你是那种朋友里"稳"字打头的人',
      ],
  };
  return pick(pool, personSeed(c));
}

/// 命盘首句金句。
String baziQuote(BaziChart c) {
  final e = c.elements;
  final primary = e.primaryUsefulGod;
  final pool = [
    '你缺的不是运气,是${primary.label}——${elementAdvice[primary]!.fun}',
    '八个字里最重要的是中间那个"${c.dayMasterName}",其他七个都是它的配角。',
    '命盘不是剧本,是天气预报:告诉你带不带伞,不管你去哪儿。',
    '${stemPersonas[c.dayStem].image}的人,${stemPersonas[c.dayStem].tip}',
    '${e.strength.label}的日主,${e.strength.isStrongSide ? '要学的是收' : e.strength.isWeakSide ? '要学的是借' : '要学的是守'}。',
  ];
  return pick(pool, personSeed(c) + 3);
}

/// "你可能没意识到的三件事":从数据里推出的洞察,每条都有依据。
List<String> baziInsights(BaziChart c) {
  final e = c.elements;
  final out = <String>[];

  // 1. 年柱 vs 日主:别人第一眼 vs 真实的你
  final yearGod = c.yearPillar.stemGod;
  if (yearGod != null) {
    final yp = tenGodPlain[yearGod]!;
    out.add('**别人对你的第一印象和真实的你不是一回事。**年柱天干是${yearGod.label}(${yp.plain.split(';').first}),'
        '所以初次见面别人看到的是这个;日主${c.dayMasterName}才是你——${stemPersonas[c.dayStem].traits.join('、')}。'
        '熟了以后别人常说"你跟我一开始想的不一样",就是这个原因。');
  }

  // 2. 缺失或最弱五行
  if (e.missing.isNotEmpty) {
    final m = e.missing.first;
    out.add('**你对"${m.label}"这件事天生不敏感。**命局里${m.label}是空的——'
        '${_missingHint(m)}。这不是缺陷,是知道了就能补的盲区。');
  } else {
    final weakest = Element.values.reduce((a, b) => e.percentages[a]! <= e.percentages[b]! ? a : b);
    out.add('**你最弱的一环是${weakest.label}(${e.percentages[weakest]!.round()}%)。**${_missingHint(weakest)}——补它的成本最低、回报最高。');
  }

  // 3. 十神里出场最多的
  final gods = <TenGod, int>{};
  for (final p in c.pillars) {
    if (p.stemGod != null) gods[p.stemGod!] = (gods[p.stemGod!] ?? 0) + 2;
    for (final h in p.hiddenStems) {
      gods[h.tenGod] = (gods[h.tenGod] ?? 0) + (h.weight >= 0.6 ? 1 : 0);
    }
  }
  if (gods.isNotEmpty) {
    final top = gods.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    out.add('**你的命盘里${top.label}出场最多。**${tenGodPlain[top]!.plain} '
        '这意味着${_dominantGodInsight(top)}');
  }

  // 4. 空亡
  if (c.voidPositions.isNotEmpty) {
    final pos = c.voidPositions.first;
    out.add('**${['年', '月', '日', '时'][pos]}柱落空亡。**'
        '${['祖辈和童年那块的记忆可能比别人淡,不用刻意找补', '事业上"看着近、抓不住"的感觉会比别人多,靠积累不靠押注', '', '晚年和子女相关的事,顺其自然比规划更管用'][pos]}');
  }

  return out.take(3).toList();
}

String _missingHint(Element m) => switch (m) {
      Element.wood => '表现为不太会主动生长、规划感弱,需要外界推一把',
      Element.fire => '表现为热情来得慢、不爱表现,容易被误会冷淡',
      Element.earth => '表现为落地和守成的能力偏弱,想法多但扎根难',
      Element.metal => '表现为决断和边界感偏弱,该说不的时候容易心软',
      Element.water => '表现为变通和流动性偏弱,容易在一个地方待太久',
    };

String _dominantGodInsight(TenGod g) => switch (g.group) {
      '比劫' => '你天生有"同伴感",合作比单干强——但也容易在朋友身上花太多钱和情绪。',
      '食伤' => '你的核心竞争力是表达和创造——把它变成产出,别只停在"我有想法"。',
      '财星' => '你对"实在的东西"敏感,适合经营、理财、把事做成钱——留意别把所有关系都算成账。',
      '官杀' => '你对规则和责任有天然的敏感,扛得住压力——但也容易活得太紧,给自己放点假。',
      _ => '你是"被照顾"体质,贵人和学习是你的加速器——别把它用成"等别人来"。',
    };

// ===========================================================================
// 每日
// ===========================================================================

/// 每日标题:十神主题 × 分数档。
String dailyHeadline(BaziChart c, DailyFortune f) {
  final seed = personSeed(c) + f.dayPillar.index;
  final good = f.overall >= 70;
  final low = f.overall < 50;
  final pool = switch (f.theme.group) {
    '财星' => good
        ? ['今天钱包有感觉', '该谈价就谈价的日子', '实在事,今天办']
        : low
            ? ['今天别碰钱包以外的决定', '财星日但别贪', '看紧钱包,其他随缘']
            : ['一个"算账"的日子', '实事求是的一天'],
    '官杀' => good
        ? ['今天靠谱值钱', '老板找你的日子,接住', '压力就是机会,今天尤其']
        : low
            ? ['今天别顶嘴', '规矩日,别踩线', '压力大的日子,少做承诺']
            : ['责任日,按流程走', '正事优先的一天'],
    '印星' => good
        ? ['今天有人愿意教你', '充电日,插好插座', '贵人日,主动开口']
        : low
            ? ['今天适合躺着看书', '休整日,别硬撑', '学点东西,别做决定']
            : ['安静学习的一天', '适合请教前辈的日子'],
    '食伤' => good
        ? ['今天脑子在冒泡', '把想法说出来的日子', '灵感日,记下来']
        : low
            ? ['今天嘴快心快,慢一点', '想法多,落地少,正常', '别把创意当承诺']
            : ['表达日,说清楚就行', '适合写点东西的一天'],
    _ => good
        ? ['组队开黑的日子', '朋友日,别抢着买单', '合作比单干强的一天']
        : low
            ? ['今天别为朋友借钱', '人多的地方少去', '竞争日,守好自己的']
            : ['人来人往的一天', '合作与竞争并见'],
  };
  return pick(pool, seed);
}

/// 每日金句(可截图的那一句)。
String dailyQuote(BaziChart c, DailyFortune f) {
  final seed = personSeed(c) + f.dayPillar.index * 3;
  final pool = <String>[
    ...switch (f.theme.group) {
      '财星' => ['钱来的日子,别急着花;钱走的日子,别急着追。', '今天最值钱的是"实在"两个字。', '把"大概"换成"具体多少",今天就赢了。'],
      '官杀' => ['今天别证明自己,把事做完就是证明。', '压力是别人给的,节奏是自己的。', '今天说"好的"之前,先想三秒。'],
      '印星' => ['今天别急着输出,先听完。', '请教一个人,比刷一小时手机划算。', '被照顾也是一种能力,今天练一练。'],
      '食伤' => ['想法记下来,别只在脑子里转。', '今天的嘴比脑子快,让脑子先走。', '创意不值钱,做出来的才值钱。'],
      _ => ['今天别一个人扛所有伤害。', '朋友是资源,也是开销,今天算清楚。', '竞争的日子,盯着自己的赛道。'],
    },
    if (f.overall >= 80) '今天开挂,别浪。',
    if (f.overall < 45) '省电模式,能不做的决定就别做。',
  ];
  return pick(pool, seed);
}

/// Co-Star 式"别做":一件具体的事。
String dailyDont(BaziChart c, DailyFortune f) {
  final seed = personSeed(c) + f.dayPillar.index * 5;
  final items = {'事业': f.career, '财运': f.wealth, '感情': f.love, '健康': f.health};
  final worst = items.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  final pool = switch (worst) {
    '事业' => ['别在群里跟人争对错。', '别今天提辞职、提加薪、提方案。', '别答应你还没想清楚的事。', '别改已经定好的计划。'],
    '财运' => ['别下单购物车里放了三天的东西。', '别借钱给人,也别开口借。', '别看理财账户。', '别为了凑单多买。'],
    '感情' => ['别翻旧账。', '别在情绪上头时发消息。', '别用"随便"回答"吃什么"。', '别猜,直接问。'],
    _ => ['别熬过十二点。', '别用咖啡代替午饭。', '别久坐超过两小时不起来。', '别把体检再往后拖。'],
  };
  return pick(pool, seed);
}

/// "去做的一件小事":具体、可完成。
String dailyDo(BaziChart c, DailyFortune f) {
  final seed = personSeed(c) + f.dayPillar.index * 11;
  final items = {'事业': f.career, '财运': f.wealth, '感情': f.love, '健康': f.health};
  final best = items.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  final adv = elementAdvice[c.elements.primaryUsefulGod]!;
  final pool = switch (best) {
    '事业' => ['把拖了一周的那封邮件今天发出去。', '主动跟上级同步一次进度,不用等他问。', '把明天要做的三件事写下来再下班。'],
    '财运' => ['记一笔今天的所有花销。', '把该收的钱提醒一次。', '把一个订阅取消掉。'],
    '感情' => ['给一个很久没联系的人发条消息。', '当面说一句谢谢。', '今晚回家先放下手机十分钟。'],
    _ => ['出门走二十分钟,往${adv.direction}走。', '今天穿点${adv.colors}。', '早睡半小时。'],
  };
  return pick(pool, seed);
}

// ===========================================================================
// 流年
// ===========================================================================

String annualHeadline(BaziChart c, AnnualFortune a) {
  final seed = personSeed(c) + a.year;
  if (a.isOffendingTaiSui) {
    return pick(['今年难度调高一档,但通关奖励也多', '犯太岁不是出事,是提醒你系好安全带', '今年的关键词:稳。其他都是配菜'], seed);
  }
  final pool = switch (a.grade) {
    '顺遂年' => ['今年是顺风,别只顾着爽,趁机往前赶', '扶梯年:站着也在上,走两步更快', '今年该出手就出手,风在帮你'],
    '稳中有进' => ['不惊艳,但年底回头会发现存了不少', '今年适合把根扎深', '慢,但每一步都算数'],
    '平年' => ['多云的一年,带把伞就行', '今年没有大戏,正好把小事做扎实', '平淡不是坏事,是攒力气'],
    '守成年' => ['省电模式,守住基本盘', '今年别开新局,把旧局收干净', '守,是今年最聪明的进攻'],
    _ => ['竹子长根的一年,地上看不见,地下在使劲', '今年憋着,明年蹿', '蓄力年,别跟自己较劲'],
  };
  return pick(pool, seed);
}

String annualQuote(BaziChart c, AnnualFortune a) {
  final seed = personSeed(c) + a.year * 3;
  final theme = tenGodGroupPlain[a.theme.group]!;
  return pick([
    theme.fun,
    '今年最顺的月份在${a.bestMonths.map((i) => monthApproxLabel(i)).join('和')},把大事排进去。',
    '一年十二个月,${a.cautionMonths.map((i) => monthApproxLabel(i)).join('和')}收着点,其他随便冲。',
    if (a.luckPillar != null) '这是你${a.luckPillar!.pillar.name}大运的第 ${a.year - a.luckPillar!.startYear + 1} 年,大环境${_luckTone(c, a)}。',
  ], seed);
}

String _luckTone(BaziChart c, AnnualFortune a) {
  final el = a.luckPillar!.pillar.stemElement;
  if (c.elements.favorable.contains(el)) return '在托底';
  if (c.elements.unfavorable.contains(el)) return '偏紧,靠自己';
  return '不好不坏';
}

/// 今年别做的三件事。
List<String> annualDonts(BaziChart c, AnnualFortune a) {
  final out = <String>[];
  if (a.isOffendingTaiSui) out.add('别在今年做"不可逆"的大决定——辞职创业、卖房、闪婚——能等就等到明年立春后。');
  final items = {'事业': a.career, '财运': a.wealth, '感情': a.love, '健康': a.health};
  final sorted = items.entries.toList()..sort((x, y) => x.value.compareTo(y.value));
  for (final e in sorted.take(2)) {
    out.add(switch (e.key) {
      '事业' => '别频繁跳槽,今年的积累明年才兑现。',
      '财运' => '别做大额投资、别给人担保,守住不亏就是赢。',
      '感情' => '别在争吵时说"分手"两个字,今年容易说了就真了。',
      _ => '别把体检往后拖,别拿熬夜换效率。',
    });
  }
  return out.take(3).toList();
}

// ===========================================================================
// 合婚
// ===========================================================================

/// 给这对组合起个名字:两人日主物象。
String couplePairName(BaziChart a, BaziChart b) {
  final pa = stemPersonas[a.dayStem].image, pb = stemPersonas[b.dayStem].image;
  return '$pa × $pb';
}

String marriageHeadline(MarriageResultLike m) {
  final seed = personSeed(m.a) + personSeed(m.b);
  final pool = switch (m.grade) {
    '天作之合' => ['别人吵架你们在笑', '不用解释就懂的那种', '默契是你们的默认设置'],
    '良缘可期' => ['底子好,稍微用心就很好', '拼图缺的那一角,形状对了', '顺的关系,别懒'],
    '中平可为' => ['合不合,看经营', '两种口味,搭得好是招牌菜', '不是不合,是需要说明书'],
    '需多磨合' => ['手动挡的爱情,开熟了更有意思', '摩擦是真的,能说清也是真的', '这对组合,吵架和成长都多'],
    _ => ['差异大,需要两个人都很想', '先商量好谁看地图谁开车', '不是不能走,是得先谈规则'],
  };
  return pick(pool, seed);
}

/// 吵架预测:从最低分维度推。
String marriageFightForecast(MarriageResultLike m) {
  DimensionLike lowest = m.dimensions.first;
  for (final d in m.dimensions) {
    if (d.clamped < lowest.clamped) lowest = d;
  }
  return switch (lowest.name) {
    '生肖缘' => '你们最容易吵的是"过年回谁家"和"你爸妈怎么说"——家庭观念的差异。提前商量,别到节前才谈。',
    '日柱缘' => '你们最容易吵的是日常琐事:钱怎么管、家务怎么分、周末怎么过。听着小,但每天都会碰到。',
    '五行互补' => '你们最容易吵的是"你怎么不理解我":能量类型不同,一个要热闹一个要安静。各自留一块自己的空间。',
    '配偶星' => '你们最容易吵的是"你到底要什么":一方对关系的期待没说清。把期待说出口,别让对方猜。',
    '神煞' => '你们最容易吵的是"你都不陪我":命盘里有提醒多陪伴的标记。固定一个两人专属的时间段。',
    _ => '你们最容易吵的是两家长辈的事。多在长辈面前替对方说好话。',
  };
}

/// 让 voice.dart 不依赖 marriage.dart 的具体类型,只要有这几个字段。
abstract class MarriageResultLike {
  BaziChart get a;
  BaziChart get b;
  String get grade;
  List<DimensionLike> get dimensions;
}

abstract class DimensionLike {
  String get name;
  int get clamped;
}

// ===========================================================================
// 姓名 / 星座 / 手面相
// ===========================================================================

String nameHeadline(int score, String fullName) {
  if (score >= 85) return '「$fullName」——家长当年一定翻了字典';
  if (score >= 70) return '「$fullName」——基础款,但耐穿';
  if (score >= 55) return '「$fullName」——有两处小疙瘩,叫响了就没事';
  return '「$fullName」——数理一般,人比名字重要';
}

String nameQuote(int score) => score >= 70
    ? '名字是每天被叫几十遍的随身符,你这张符画得不错。'
    : '名字是起点不是终点,历史上叫"阿斗"的也不止一个。';

String zodiacQuote(String signName, String weakness, String strength) =>
    '$signName的人生课题:把"$weakness"练成"$strength"的另一面。';

const List<String> palmQuotes = [
  '掌纹三年一变,它讲的是"现在的你",不是判决书。',
  '手相看的是风格,不是寿命——别信那些数生命线长短的。',
  '你的手在说话,只是平时没人翻译。',
];

const List<String> faceQuotes = [
  '相由心生的意思是:表情和习惯会改变面相,所以这是近况快照,不是出厂设置。',
  '面相不评美丑,只看比例——每张脸都有自己的"格局"。',
  '三停五眼是老祖宗的黄金分割,你不用完美,知道自己哪段长就够了。',
];
