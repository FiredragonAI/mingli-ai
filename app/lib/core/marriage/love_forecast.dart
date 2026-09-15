/// 单人婚缘预测:不需要对方信息,只看本人命盘。
///
/// 传统八字婚姻分析的四块:
/// 1. **配偶星**:男命看财星(正财为妻、偏财为侧),女命看官杀(正官为夫、七杀为侧)。
///    有没有、几个、透干还是藏支、旺不旺、清还是杂。
/// 2. **夫妻宫**:日支。它的五行、藏干十神是配偶的"底色";被冲刑害则婚姻多波动。
/// 3. **婚恋神煞**:桃花、红鸾、天喜(利)、孤辰、寡宿、阴差阳错(不利)。
/// 4. **婚期窗口**:大运流年引动配偶星或夫妻宫、红鸾天喜到位的年份。
///
/// 全部确定性,每条加减分留依据。措辞上只说倾向,不下判决(见 docs/COMPLIANCE.md)。
library;

import '../bazi/bazi_chart.dart';
import '../bazi/five_elements.dart';
import '../bazi/hidden_stems.dart';
import '../bazi/relations.dart';
import '../bazi/ten_gods.dart';
import '../calendar/sexagenary.dart';
import '../interpret/voice.dart';

/// 配偶星分布。
class SpouseStar {
  const SpouseStar({
    required this.direct,
    required this.mixed,
    required this.element,
    required this.stemPositions,
    required this.branchPositions,
    required this.strengthPct,
    required this.state,
  });

  /// 正配(男正财 / 女正官)。
  final TenGod direct;

  /// 偏配(男偏财 / 女七杀)。
  final TenGod mixed;
  final Element element;

  /// 透干的柱位(0 年 1 月 2 日 3 时;日柱天干是日主,不计)。
  final List<int> stemPositions;

  /// 地支本气为配偶星的柱位。
  final List<int> branchPositions;

  /// 配偶星五行在命局中的占比。
  final double strengthPct;

  /// 无 / 清 / 杂 / 弱 / 旺。
  final String state;

  int get count => stemPositions.length + branchPositions.length;
  bool get sitsInPalace => branchPositions.contains(2);
}

/// 一个可能的婚期窗口。
class MarriageWindow {
  const MarriageWindow({required this.year, required this.age, required this.pillar, required this.score, required this.triggers});
  final int year;
  final int age;
  final StemBranch pillar;
  final int score;
  final List<String> triggers;

  Map<String, dynamic> toJson() => {'year': year, 'age': age, 'pillar': pillar.name, 'score': score, 'triggers': triggers};
}

class LoveForecast implements LoveLike {
  const LoveForecast({
    required this.gender,
    required this.star,
    required this.palaceBranch,
    required this.palaceElement,
    required this.palaceGod,
    required this.palaceRelations,
    required this.stars,
    required this.affinity,
    required this.stability,
    required this.romance,
    required this.overall,
    required this.pattern,
    required this.patternNote,
    required this.spouseProfile,
    required this.windows,
    required this.factors,
  });

  final Gender gender;
  final SpouseStar star;

  /// 夫妻宫(日支)。
  final int palaceBranch;
  final Element palaceElement;

  /// 日支本气对日主的十神。
  final TenGod palaceGod;

  /// 夫妻宫与其他柱的关系描述(冲/合/刑/害)。
  final List<String> palaceRelations;

  /// 命中的婚恋神煞。
  @override
  final List<String> stars;

  /// 缘分深浅 / 稳定度 / 桃花指数 / 综合,0–100。
  final int affinity;
  final int stability;
  final int romance;
  @override
  final int overall;

  @override
  String get starState => star.state;

  @override
  List<int> get windowYears => windows.map((w) => w.year).toList();

  /// 感情模式标签与说明。
  final String pattern;
  final String patternNote;

  /// 对方画像:{维度: 描述}。
  final Map<String, String> spouseProfile;

  /// 婚期窗口,按可能性排序,最多 4 个。
  final List<MarriageWindow> windows;
  final List<String> factors;

  @override
  bool get palaceStable => !palaceRelations.any((r) => r.contains('冲') || r.contains('刑') || r.contains('害'));

  Map<String, dynamic> toJson() => {
        'gender': gender.chartLabel,
        'spouseStar': {
          'direct': star.direct.label,
          'mixed': star.mixed.label,
          'element': star.element.label,
          'stemPositions': star.stemPositions.map((p) => pillarNames[p]).toList(),
          'branchPositions': star.branchPositions.map((p) => pillarNames[p]).toList(),
          'strengthPct': star.strengthPct.round(),
          'state': star.state,
          'sitsInPalace': star.sitsInPalace,
        },
        'palace': {
          'branch': earthlyBranches[palaceBranch],
          'element': palaceElement.label,
          'god': palaceGod.label,
          'relations': palaceRelations,
          'stable': palaceStable,
        },
        'stars': stars,
        'scores': {'综合': overall, '缘分': affinity, '稳定': stability, '桃花': romance},
        'pattern': pattern,
        'patternNote': patternNote,
        'spouseProfile': spouseProfile,
        'windows': windows.map((w) => w.toJson()).toList(),
        'factors': factors,
      };
}

LoveForecast loveForecast(BaziChart c) {
  final isMale = c.input.isMale;
  final dayStem = c.dayStem;
  final dm = c.dayMaster;
  final stems = c.stems, branches = c.branches;
  final e = c.elements;
  final factors = <String>[];

  // ---- 配偶星 ----
  final direct = isMale ? TenGod.directWealth : TenGod.directOfficer;
  final mixed = isMale ? TenGod.indirectWealth : TenGod.sevenKillings;
  final spouseEl = isMale ? dm.controls : dm.controlledBy;
  final stemPos = [for (var i = 0; i < 4; i++) if (i != 2 && stemElements[stems[i]] == spouseEl) i];
  final branchPos = [for (var i = 0; i < 4; i++) if (stemElements[mainHiddenStem(branches[i])] == spouseEl) i];
  final pct = e.percentages[spouseEl]!;
  var directCount = 0, mixedCount = 0;
  for (final i in stemPos) {
    tenGodOf(dayStem, stems[i]) == direct ? directCount++ : mixedCount++;
  }
  for (final i in branchPos) {
    tenGodOf(dayStem, mainHiddenStem(branches[i])) == direct ? directCount++ : mixedCount++;
  }
  final total = directCount + mixedCount;
  final String state;
  if (total == 0) {
    state = '无';
  } else if (directCount >= 1 && mixedCount >= 1 && total >= 3) {
    state = '杂';
  } else if (pct < 10) {
    state = '弱';
  } else if (pct > 40) {
    state = '旺';
  } else {
    state = '清';
  }
  final star = SpouseStar(
    direct: direct,
    mixed: mixed,
    element: spouseEl,
    stemPositions: stemPos,
    branchPositions: branchPos,
    strengthPct: pct,
    state: state,
  );
  final starLabel = isMale ? '财星' : '官杀';

  var affinity = 60, stability = 60, romance = 60;
  void f(String why) => factors.add(why);

  switch (state) {
    case '无':
      affinity -= 18;
      f('命局不见$starLabel(配偶星):缘分要靠大运流年引动,来得晚但来得实,不必焦虑');
    case '杂':
      affinity -= 6;
      romance += 8;
      f('$starLabel多且正偏混杂($total 位):异性缘不缺,难在取舍;感情经历会比别人丰富');
    case '弱':
      affinity -= 8;
      f('$starLabel偏弱(占比 ${pct.round()}%):缘分在,但对方在你生活里"存在感"偏低,需要主动经营');
    case '旺':
      affinity += 6;
      romance += 6;
      stability -= 4;
      f('$starLabel偏旺(占比 ${pct.round()}%):对方在你生活里分量重,${isMale ? '但身弱财旺容易在关系里累' : '但官杀过旺易感压力'}');
    default:
      affinity += 16;
      f('$starLabel清纯有力(${directCount > 0 ? '正配透出' : '偏配为主'}):婚缘清晰,遇到了容易认得出');
  }
  if (star.sitsInPalace) {
    affinity += 10;
    stability += 6;
    f('配偶星坐夫妻宫(日支):对方就在你的"位置"上,这是传统上最利婚姻的配置之一');
  }
  if (stemPos.isNotEmpty) {
    f('配偶星透出于${stemPos.map((p) => pillarNames[p]).join('、')}柱天干:感情事容易"摆在明面上"');
  }

  // ---- 夫妻宫 ----
  final palace = branches[2];
  final palaceEl = branchElements[palace];
  final palaceGod = tenGodOf(dayStem, mainHiddenStem(palace));
  final rel = <String>[];
  for (var i = 0; i < 4; i++) {
    if (i == 2) continue;
    final b = branches[i];
    final p = pillarNames[i];
    if (isClash(palace, b)) {
      rel.add('$p支${earthlyBranches[b]}冲日支${earthlyBranches[palace]}');
      stability -= 14;
      f('夫妻宫被$p支所冲:婚姻中"变动"的成分多,分居、异地、观念冲突要提前有预案');
    } else if (isSixCombine(palace, b)) {
      rel.add('$p支${earthlyBranches[b]}合日支${earthlyBranches[palace]}');
      stability += 10;
      f('夫妻宫与$p支六合:关系有黏性,吵完还是会回来');
    } else if (isTripleCombineMember(palace, b)) {
      rel.add('$p支${earthlyBranches[b]}与日支三合');
      stability += 4;
    }
    if (isHarm(palace, b)) {
      rel.add('$p支${earthlyBranches[b]}害日支');
      stability -= 7;
      f('夫妻宫被$p支所害:暗中的摩擦多于明面上的争吵,多把话说出口');
    }
    if (isPunish(palace, b) && palace != b) {
      rel.add('$p支${earthlyBranches[b]}刑日支');
      stability -= 7;
      f('夫妻宫被$p支所刑:关系里容易互相较劲,退一步比赢一局重要');
    }
  }
  if (isPunish(palace, palace)) {
    stability -= 5;
    f('日支${earthlyBranches[palace]}自刑:感情里容易自己跟自己过不去,情绪管理是课题');
  }
  switch (dm.relationTo(palaceEl)) {
    case ElementRelation.generatesMe:
      stability += 6;
      f('日支五行生日主:配偶是滋养你的人,这段关系让你变好');
    case ElementRelation.same:
      stability += 4;
      f('日支五行与日主同类:配偶像另一个自己,理解容易,也容易同时犯同一个错');
    case ElementRelation.controlsMe:
      stability -= 5;
      f('日支五行克日主:配偶在关系里偏强势,你需要守住自己的节奏');
    case ElementRelation.iGenerate:
      f('日主生日支五行:你在关系里是付出多的那一方');
    case ElementRelation.iControl:
      f('日主克日支五行:你在关系里偏主导,记得留空间');
  }

  // ---- 神煞 ----
  final names = c.shenSha.map((s) => s.name).toList();
  final loveStars = <String>[];
  final taoHua = names.where((n) => n == '桃花').length;
  if (taoHua > 0) {
    loveStars.add('桃花${taoHua > 1 ? '×$taoHua' : ''}');
    romance += 12 * (taoHua > 2 ? 2 : taoHua);
    f('命带桃花${taoHua > 1 ? ' $taoHua 位' : ''}:异性缘好、有魅力,${taoHua > 1 ? '也要守情专一' : '是加分项'}');
  }
  for (final n in ['红鸾', '天喜']) {
    if (names.contains(n)) {
      loveStars.add(n);
      romance += 8;
      affinity += 4;
      f('命带$n:婚恋喜庆,遇到合适的人时进展会快');
    }
  }
  for (final n in ['孤辰', '寡宿']) {
    if (names.contains(n)) {
      loveStars.add(n);
      stability -= 6;
      f('命带$n:性情偏独立,婚后要刻意留时间陪伴,别让对方觉得你"不需要"');
    }
  }
  if (names.contains('阴差阳错')) {
    loveStars.add('阴差阳错');
    stability -= 10;
    f('日坐阴差阳错:感情里容易误会、错过时机,重要的话当面说,别猜');
  }
  if (names.contains('孤鸾')) {
    loveStars.add('孤鸾');
    affinity -= 5;
    f('日犯孤鸾:传统上主晚婚,慢一点反而是好事');
  }

  // ---- 感情模式 ----
  final strong = e.strength.isStrongSide, weak = e.strength.isWeakSide;
  final outputPct = e.percentages[dm.generates]!;
  final peerPct = e.percentages[dm]!;
  final resourcePct = e.percentages[dm.generatedBy]!;
  String pattern, note;
  if (state == '无') {
    pattern = '晚成型';
    note = '命里配偶星不显,感情靠大运流年"送"来——年轻时不必勉强,到了引动的年份缘分会很明确。';
  } else if (state == '杂') {
    pattern = '选择丰富型';
    note = '不缺追求者,难的是定下来。给自己一条标准,别用"感觉"做唯一尺子。';
  } else if (isMale && strong && pct < 15) {
    pattern = '主动追求型';
    note = '你主动、对方被动,是你习惯的模式。付出多是优点,别把付出当成理所当然的筹码。';
  } else if (isMale && weak && pct > 30) {
    pattern = '被动吸引型';
    note = '异性缘不缺,但容易在关系里累。"选"比"追"重要,找让你省力的人。';
  } else if (!isMale && outputPct > 30) {
    pattern = '需要空间型';
    note = '你的才华和主见会"压"到对方(食伤克官)。找一个欣赏你、而不是想管你的人。';
  } else if (peerPct > 30) {
    pattern = '朋友变恋人型';
    note = '感情常从熟人圈开始,也要留意朋友圈里的竞争。先做朋友再谈,是你的优势。';
  } else if (resourcePct > 30) {
    pattern = '慢热依赖型';
    note = '需要被照顾,慢热但一旦认定很稳。选成熟、有耐心的对象,别选需要你带的。';
  } else {
    pattern = '稳定经营型';
    note = '配偶星与日主力量相当,是能"过日子"的配置。婚姻质量取决于经营,不靠运气。';
  }
  f('感情模式判定:$pattern');

  // ---- 对方画像 ----
  final profile = <String, String>{};
  profile['气质'] = switch (palaceEl) {
    Element.wood => '偏修长、正直有主见,带点书卷气',
    Element.fire => '热情开朗、精神头足,有感染力',
    Element.earth => '敦厚稳重、务实可靠,给人安全感',
    Element.metal => '端正果断、有原则,外冷内热',
    Element.water => '聪慧灵动、善沟通,有点难捉摸',
  };
  profile['性格'] = switch (palaceGod) {
    TenGod.directOfficer || TenGod.directWealth => '靠谱、有责任心、偏传统',
    TenGod.sevenKillings => '强势有魄力,事业心重',
    TenGod.indirectWealth => '大方外向、人脉广',
    TenGod.eatingGod => '温和、会生活、好相处',
    TenGod.hurtingOfficer => '有才华有个性,不好管',
    TenGod.directResource || TenGod.indirectResource => '照顾人、年长感、爱学习',
    _ => '像朋友、独立、有竞争心',
  };
  final where = stemPos.isNotEmpty ? stemPos.first : (branchPos.isNotEmpty ? branchPos.first : -1);
  profile['相识'] = switch (where) {
    0 => '偏早相识,或经家人长辈介绍;对方可能年长',
    1 => '同学、同事、工作圈里遇到的可能性大',
    2 => '缘分来得自然,身边的人',
    3 => '圈子之外遇到,或对方偏年轻;晚一点定下来更稳',
    _ => '靠大运流年引动,相识方式不拘',
  };
  profile['方位'] = '${_direction(spouseEl)}方,或与${spouseEl.label}相关的行业';

  // ---- 婚期窗口 ----
  final natalYear = branches[0];
  final hongLuan = (3 - natalYear + 12) % 12, tianXi = (hongLuan + 6) % 12;
  final birthYear = c.input.year;
  final windows = <MarriageWindow>[];
  for (var y = birthYear + 18; y <= birthYear + 45; y++) {
    final ySb = yearPillar(y);
    var score = 0;
    final trig = <String>[];
    final yGod = tenGodOf(dayStem, ySb.stem);
    if (yGod == direct) {
      score += 4;
      trig.add('流年天干${ySb.stemName}为${direct.label}(正配星)');
    } else if (yGod == mixed) {
      score += 3;
      trig.add('流年天干${ySb.stemName}为${mixed.label}(配偶星)');
    }
    if (isSixCombine(ySb.branch, palace)) {
      score += 4;
      trig.add('流年${ySb.branchName}合夫妻宫');
    } else if (isTripleCombineMember(ySb.branch, palace)) {
      score += 2;
      trig.add('流年${ySb.branchName}与夫妻宫三合');
    }
    if (ySb.branch == hongLuan) {
      score += 3;
      trig.add('红鸾到位');
    }
    if (ySb.branch == tianXi) {
      score += 3;
      trig.add('天喜到位');
    }
    if (stemElements[mainHiddenStem(ySb.branch)] == spouseEl && !trig.any((t) => t.contains('配偶星'))) {
      score += 2;
      trig.add('流年地支藏配偶星');
    }
    if ((ySb.stem - dayStem).abs() == 5) {
      score += 1;
      trig.add('流年天干合日主');
    }
    if (isClash(ySb.branch, palace)) {
      score -= 2;
      trig.add('流年冲夫妻宫(变动而非结合)');
    }
    final luck = c.luck.cycleForYear(y);
    if (luck != null) {
      final lg = tenGodOf(dayStem, luck.pillar.stem);
      if (lg == direct || lg == mixed) {
        score += 2;
        trig.add('大运${luck.pillar.name}天干为配偶星');
      }
      if (isSixCombine(luck.pillar.branch, palace)) {
        score += 2;
        trig.add('大运${luck.pillar.name}合夫妻宫');
      }
    }
    if (score >= 4) windows.add(MarriageWindow(year: y, age: y - birthYear + 1, pillar: ySb, score: score, triggers: trig));
  }
  windows.sort((a, b) => b.score != a.score ? b.score.compareTo(a.score) : a.year.compareTo(b.year));
  final top = windows.take(4).toList()..sort((a, b) => a.year.compareTo(b.year));
  if (top.isNotEmpty) {
    f('婚缘引动较强的年份:${top.map((w) => '${w.year}(${w.age} 岁)').join('、')}');
  }

  int clamp(int v) => v.clamp(15, 98);
  affinity = clamp(affinity);
  stability = clamp(stability);
  romance = clamp(romance);
  final overall = clamp((affinity * 0.4 + stability * 0.35 + romance * 0.25).round());

  return LoveForecast(
    gender: c.input.gender,
    star: star,
    palaceBranch: palace,
    palaceElement: palaceEl,
    palaceGod: palaceGod,
    palaceRelations: rel,
    stars: loveStars,
    affinity: affinity,
    stability: stability,
    romance: romance,
    overall: overall,
    pattern: pattern,
    patternNote: note,
    spouseProfile: profile,
    windows: top,
    factors: factors,
  );
}

String _direction(Element e) => switch (e) {
      Element.wood => '东',
      Element.fire => '南',
      Element.earth => '本地或中部',
      Element.metal => '西',
      Element.water => '北',
    };
