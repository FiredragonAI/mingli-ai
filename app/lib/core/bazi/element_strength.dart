/// 五行力量与日主强弱。
///
/// 采用可解释、可调参的"计分法":
/// 1. 天干按柱位给基础分,地支按藏干权重 × 柱位分摊到各五行;
/// 2. 按月令旺相休囚死乘季节系数;
/// 3. 归一化成百分比。
///
/// 日主强弱看"帮扶(印比)"与"克泄耗(官杀财食伤)"的比例,再综合得令、得地、得势。
/// 用神取法为扶抑法 + 调候提示,是入门通行口径;专业命师会另有见解,
/// 所以结果里把依据也一起交出去,让 AI 解读时能说清楚"为什么"。
library;

import '../calendar/sexagenary.dart';
import 'five_elements.dart';
import 'hidden_stems.dart';
import 'ten_gods.dart';

/// 柱位权重:年 / 月 / 日 / 时。月令最重。
const List<double> _stemPositionWeight = [0.8, 1.0, 1.0, 0.8];
const List<double> _branchPositionWeight = [0.8, 1.6, 1.0, 0.8];

/// 旺相休囚死系数。
const double _prosperous = 1.4; // 旺
const double _assisting = 1.2; // 相
const double _resting = 0.9; // 休
const double _trapped = 0.7; // 囚
const double _dead = 0.6; // 死

/// 月令所属季节的"当令五行"。辰未戌丑四季月土当令。
Element seasonElementOfMonthBranch(int monthBranch) {
  switch (monthBranch) {
    case 2:
    case 3:
      return Element.wood;
    case 5:
    case 6:
      return Element.fire;
    case 8:
    case 9:
      return Element.metal;
    case 11:
    case 0:
      return Element.water;
    default:
      return Element.earth;
  }
}

/// 某五行在给定月令下的旺衰状态。
String seasonalState(Element element, int monthBranch) {
  final ruler = seasonElementOfMonthBranch(monthBranch);
  switch (ruler.relationTo(element)) {
    case ElementRelation.same:
      return '旺';
    case ElementRelation.iGenerate:
      return '相';
    case ElementRelation.generatesMe:
      return '休';
    case ElementRelation.iControl:
      return '死';
    case ElementRelation.controlsMe:
      return '囚';
  }
}

double _seasonalFactor(Element element, int monthBranch) {
  switch (seasonalState(element, monthBranch)) {
    case '旺':
      return _prosperous;
    case '相':
      return _assisting;
    case '休':
      return _resting;
    case '囚':
      return _trapped;
    default:
      return _dead;
  }
}

/// 日主强弱等级。
enum StrengthLevel {
  veryWeak('极弱'),
  weak('偏弱'),
  balanced('中和'),
  strong('偏强'),
  veryStrong('极强');

  const StrengthLevel(this.label);
  final String label;

  bool get isStrongSide => this == strong || this == veryStrong;
  bool get isWeakSide => this == weak || this == veryWeak;
}

/// 五行分析结果。
class ElementAnalysis {
  const ElementAnalysis({
    required this.rawScores,
    required this.percentages,
    required this.dayMaster,
    required this.supportScore,
    required this.drainScore,
    required this.strength,
    required this.gotSeason,
    required this.gotRoot,
    required this.gotSupport,
    required this.favorable,
    required this.unfavorable,
    required this.primaryUsefulGod,
    required this.climateHint,
    required this.reasoning,
    required this.missing,
  });

  /// 各五行原始分。
  final Map<Element, double> rawScores;

  /// 各五行百分比,和为 100。
  final Map<Element, double> percentages;

  final Element dayMaster;

  /// 帮扶力量(同我 + 生我)。
  final double supportScore;

  /// 克泄耗力量(我生 + 我克 + 克我)。
  final double drainScore;

  final StrengthLevel strength;

  /// 得令:日主在月令为旺或相。
  final bool gotSeason;

  /// 得地:地支藏干中有日主同类本气或中气。
  final bool gotRoot;

  /// 得势:天干中比劫、印星合计 ≥ 2。
  final bool gotSupport;

  /// 喜用五行(按优先级排序)。
  final List<Element> favorable;

  /// 忌讳五行。
  final List<Element> unfavorable;

  /// 首选用神。
  final Element primaryUsefulGod;

  /// 调候提示,例如"冬生木,喜火暖局";无则为空串。
  final String climateHint;

  /// 推理过程,一行一条,给 AI 解读和"为什么"面板。
  final List<String> reasoning;

  /// 缺失的五行(原始分为 0)。
  final List<Element> missing;

  double get supportRatio =>
      supportScore + drainScore == 0 ? 0.5 : supportScore / (supportScore + drainScore);
}

/// 计算五行力量与日主强弱。[stems]、[branches] 按年月日时排列,长度 4。
ElementAnalysis analyzeElements(List<int> stems, List<int> branches) {
  final dayStem = stems[2];
  final dayMaster = stemElements[dayStem];
  final monthBranch = branches[1];

  final raw = {for (final e in Element.values) e: 0.0};

  // 天干
  for (var i = 0; i < 4; i++) {
    raw[stemElements[stems[i]]] =
        raw[stemElements[stems[i]]]! + _stemPositionWeight[i];
  }
  // 地支藏干
  for (var i = 0; i < 4; i++) {
    for (final h in hiddenStemsTable[branches[i]]) {
      final el = stemElements[h.stem];
      raw[el] = raw[el]! + h.weight * _branchPositionWeight[i];
    }
  }

  // 季节调整
  final adjusted = {
    for (final e in Element.values) e: raw[e]! * _seasonalFactor(e, monthBranch),
  };
  final total = adjusted.values.fold(0.0, (a, b) => a + b);
  final pct = {
    for (final e in Element.values) e: total == 0 ? 20.0 : adjusted[e]! / total * 100,
  };

  // 帮扶 vs 克泄耗
  double support = 0, drain = 0;
  for (final e in Element.values) {
    final rel = dayMaster.relationTo(e);
    if (rel == ElementRelation.same || rel == ElementRelation.generatesMe) {
      support += adjusted[e]!;
    } else {
      drain += adjusted[e]!;
    }
  }
  final ratio = support / (support + drain);

  // 得令、得地、得势
  final state = seasonalState(dayMaster, monthBranch);
  final gotSeason = state == '旺' || state == '相';

  var gotRoot = false;
  for (final b in branches) {
    final hs = hiddenStemsTable[b];
    for (var k = 0; k < hs.length && k < 2; k++) {
      if (stemElements[hs[k].stem] == dayMaster) gotRoot = true;
    }
  }

  var supportStems = 0;
  for (var i = 0; i < 4; i++) {
    if (i == 2) continue;
    final g = tenGodOf(dayStem, stems[i]);
    if (g.group == '比劫' || g.group == '印星') supportStems++;
  }
  final gotSupport = supportStems >= 2;

  // 综合定级:以比例为主,得令/得地/得势做微调
  var score = ratio;
  if (gotSeason) score += 0.05;
  if (gotRoot) score += 0.04;
  if (gotSupport) score += 0.03;

  StrengthLevel level;
  if (score < 0.30) {
    level = StrengthLevel.veryWeak;
  } else if (score < 0.44) {
    level = StrengthLevel.weak;
  } else if (score <= 0.58) {
    level = StrengthLevel.balanced;
  } else if (score <= 0.72) {
    level = StrengthLevel.strong;
  } else {
    level = StrengthLevel.veryStrong;
  }

  final reasoning = <String>[
    '日主${dayMaster.label},生于${earthlyBranches[monthBranch]}月,处"$state"地,'
        '${gotSeason ? '得令' : '不得令'}',
    gotRoot ? '地支有根,得地' : '地支无根,不得地',
    gotSupport ? '天干印比有 $supportStems 位,得势' : '天干印比仅 $supportStems 位,不得势',
    '帮扶 ${support.toStringAsFixed(1)} : 克泄耗 ${drain.toStringAsFixed(1)},'
        '帮扶占比 ${(ratio * 100).toStringAsFixed(0)}%',
    '综合判定:日主${level.label}',
  ];

  // 用神:扶抑法
  final List<Element> favorable;
  final List<Element> unfavorable;
  Element primary;

  final resource = dayMaster.generatedBy; // 印
  final output = dayMaster.generates; // 食伤
  final wealth = dayMaster.controls; // 财
  final officer = dayMaster.controlledBy; // 官杀

  if (level.isStrongSide) {
    // 身强宜克泄耗。官杀有力先取官杀,否则食伤泄秀,再次取财
    final candidates = [officer, output, wealth]
      ..sort((a, b) => adjusted[b]!.compareTo(adjusted[a]!));
    primary = candidates.first;
    favorable = [primary, ...candidates.where((e) => e != primary)];
    unfavorable = [dayMaster, resource];
    reasoning.add('身强,取克泄耗为用:首选${primary.label}(${_godGroup(dayMaster, primary)})');
  } else if (level.isWeakSide) {
    // 身弱宜印比。官杀重取印化杀;财多取比劫分财;否则先印后比
    final officerHeavy = adjusted[officer]! >= adjusted[wealth]!;
    primary = officerHeavy ? resource : dayMaster;
    favorable = officerHeavy ? [resource, dayMaster] : [dayMaster, resource];
    unfavorable = [officer, wealth, output];
    reasoning.add('身弱,取印比为用:首选${primary.label}(${_godGroup(dayMaster, primary)})');
  } else {
    // 中和:补最弱的那一行以求平衡,忌最旺的那一行
    final sorted = Element.values.toList()
      ..sort((a, b) => adjusted[a]!.compareTo(adjusted[b]!));
    primary = sorted.first;
    favorable = [sorted[0], sorted[1]];
    unfavorable = [sorted.last];
    reasoning.add('中和之命,以补弱抑强为要:首选${primary.label}');
  }

  // 调候
  var climate = '';
  if ([11, 0, 1].contains(monthBranch) && dayMaster != Element.fire) {
    climate = '冬月生人,寒气重,宜火调候暖局';
  } else if ([5, 6, 7].contains(monthBranch) && dayMaster != Element.water) {
    climate = '夏月生人,燥热,宜水调候润局';
  }
  if (climate.isNotEmpty) reasoning.add(climate);

  final missing = [for (final e in Element.values) if (raw[e]! < 1e-9) e];
  if (missing.isNotEmpty) {
    reasoning.add('五行缺${missing.map((e) => e.label).join('、')}');
  }

  return ElementAnalysis(
    rawScores: adjusted,
    percentages: pct,
    dayMaster: dayMaster,
    supportScore: support,
    drainScore: drain,
    strength: level,
    gotSeason: gotSeason,
    gotRoot: gotRoot,
    gotSupport: gotSupport,
    favorable: favorable,
    unfavorable: unfavorable,
    primaryUsefulGod: primary,
    climateHint: climate,
    reasoning: reasoning,
    missing: missing,
  );
}

String _godGroup(Element dayMaster, Element target) {
  switch (dayMaster.relationTo(target)) {
    case ElementRelation.same:
      return '比劫';
    case ElementRelation.generatesMe:
      return '印星';
    case ElementRelation.iGenerate:
      return '食伤';
    case ElementRelation.iControl:
      return '财星';
    case ElementRelation.controlsMe:
      return '官杀';
  }
}
