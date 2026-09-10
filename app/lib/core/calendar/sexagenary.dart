/// 天干、地支、六十甲子的基础定义与取模运算。
///
/// 全部以 0 起始的整数索引运算,字符串只在展示时才查表。
library;

import '../bazi/five_elements.dart';

/// 十天干。
const List<String> heavenlyStems = [
  '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
];

/// 十二地支。
const List<String> earthlyBranches = [
  '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
];

/// 四柱名称,索引 0 年 1 月 2 日 3 时。全项目统一用这个柱位编号。
const List<String> pillarNames = ['年', '月', '日', '时'];

/// 十二生肖,与地支同序。
const List<String> zodiacAnimals = [
  '鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪',
];

/// 天干五行:甲乙木、丙丁火、戊己土、庚辛金、壬癸水。
const List<Element> stemElements = [
  Element.wood, Element.wood,
  Element.fire, Element.fire,
  Element.earth, Element.earth,
  Element.metal, Element.metal,
  Element.water, Element.water,
];

/// 地支五行:子水 丑土 寅木 卯木 辰土 巳火 午火 未土 申金 酉金 戌土 亥水。
const List<Element> branchElements = [
  Element.water, Element.earth, Element.wood, Element.wood,
  Element.earth, Element.fire, Element.fire, Element.earth,
  Element.metal, Element.metal, Element.earth, Element.water,
];

/// 天干阴阳:偶数索引为阳(甲丙戊庚壬),奇数为阴。
bool isStemYang(int stem) => stem % 2 == 0;

/// 地支阴阳:子寅辰午申戌为阳。
bool isBranchYang(int branch) => branch % 2 == 0;

/// 一组干支(一柱)。
class StemBranch {
  const StemBranch(this.stem, this.branch)
      : assert(stem >= 0 && stem < 10),
        assert(branch >= 0 && branch < 12);

  /// 由六十甲子序号(0 = 甲子)构造。
  factory StemBranch.fromIndex(int index) {
    final i = index % 60;
    return StemBranch(i % 10, i % 12);
  }

  final int stem;
  final int branch;

  /// 六十甲子序号,0 = 甲子,59 = 癸亥。
  ///
  /// 由 stem ≡ i (mod 10)、branch ≡ i (mod 12) 联立可知
  /// i = (6·stem − 5·branch) mod 60。合法干支的 stem 与 branch 同奇偶。
  int get index => ((6 * stem - 5 * branch) % 60 + 60) % 60;

  String get stemName => heavenlyStems[stem];
  String get branchName => earthlyBranches[branch];
  String get name => '$stemName$branchName';

  Element get stemElement => stemElements[stem];
  Element get branchElement => branchElements[branch];

  bool get isYang => isStemYang(stem);

  /// 纳音五行。
  String get naYin => naYinNames[index ~/ 2];

  StemBranch shift(int steps) => StemBranch.fromIndex(index + steps);

  @override
  bool operator ==(Object other) =>
      other is StemBranch && other.stem == stem && other.branch == branch;

  @override
  int get hashCode => stem * 12 + branch;

  @override
  String toString() => name;
}

/// 三十纳音,每两个干支共用一个,顺序对应六十甲子序号 ÷ 2。
const List<String> naYinNames = [
  '海中金', '炉中火', '大林木', '路旁土', '剑锋金',
  '山头火', '涧下水', '城头土', '白蜡金', '杨柳木',
  '泉中水', '屋上土', '霹雳火', '松柏木', '长流水',
  '沙中金', '山下火', '平地木', '壁上土', '金箔金',
  '覆灯火', '天河水', '大驿土', '钗钏金', '桑柘木',
  '大溪水', '沙中土', '天上火', '石榴木', '大海水',
];

/// 由**干支年**(立春为界)求年柱。1984 年为甲子。
StemBranch yearPillar(int sexagenaryYear) =>
    StemBranch.fromIndex(sexagenaryYear - 1984);

/// 由年干与"节气月序号"(0 = 寅月)求月柱。
///
/// 五虎遁:甲己之年丙作首,乙庚之岁戊为头,丙辛必定寻庚起,
/// 丁壬壬位顺行流,戊癸甲寅好追求。
StemBranch monthPillar(int yearStem, int monthIndex) {
  final stem = ((yearStem % 5) * 2 + 2 + monthIndex) % 10;
  final branch = (2 + monthIndex) % 12; // 寅 = 2
  return StemBranch(stem, branch);
}

/// 由**自 1900-01-01 起的天数**求日柱。1900-01-01 为甲戌(序号 10)。
///
/// 交叉验证:1949-10-01、2000-01-07 均为甲子日,与此锚点一致。
StemBranch dayPillarFromDaysSince1900(int days) =>
    StemBranch.fromIndex(days + 10);

/// 由日干与时支求时柱。
///
/// 五鼠遁:甲己还加甲,乙庚丙作初,丙辛从戊起,丁壬庚子居,戊癸何方发,壬子是真途。
StemBranch hourPillar(int dayStem, int hourBranch) {
  final stem = ((dayStem % 5) * 2 + hourBranch) % 10;
  return StemBranch(stem, hourBranch);
}

/// 由 0–23 时的小数小时求时支。23:00–00:59 为子。
int hourBranchOf(double hour) {
  final h = hour % 24;
  if (h >= 23) return 0;
  return ((h + 1) / 2).floor();
}
