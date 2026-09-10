/// 地支藏干(人元)。
///
/// 每个地支里藏 1~3 个天干,分本气、中气、余气,权重递减。
/// 权重采用最常见的"本气 60 / 中气 30 / 余气 10"分法,
/// 四正(子午卯酉)本气独占;子藏癸不藏壬,午藏丁己。
library;

/// 一条藏干记录。
class HiddenStem {
  const HiddenStem(this.stem, this.weight);

  /// 天干索引 0–9。
  final int stem;

  /// 权重,同一地支内各项之和为 1.0。
  final double weight;
}

/// 十二地支藏干表,索引 = 地支序号。
const List<List<HiddenStem>> hiddenStemsTable = [
  // 子:癸
  [HiddenStem(9, 1.0)],
  // 丑:己 癸 辛
  [HiddenStem(5, 0.6), HiddenStem(9, 0.3), HiddenStem(7, 0.1)],
  // 寅:甲 丙 戊
  [HiddenStem(0, 0.6), HiddenStem(2, 0.3), HiddenStem(4, 0.1)],
  // 卯:乙
  [HiddenStem(1, 1.0)],
  // 辰:戊 乙 癸
  [HiddenStem(4, 0.6), HiddenStem(1, 0.3), HiddenStem(9, 0.1)],
  // 巳:丙 戊 庚
  [HiddenStem(2, 0.6), HiddenStem(4, 0.3), HiddenStem(6, 0.1)],
  // 午:丁 己
  [HiddenStem(3, 0.7), HiddenStem(5, 0.3)],
  // 未:己 丁 乙
  [HiddenStem(5, 0.6), HiddenStem(3, 0.3), HiddenStem(1, 0.1)],
  // 申:庚 壬 戊
  [HiddenStem(6, 0.6), HiddenStem(8, 0.3), HiddenStem(4, 0.1)],
  // 酉:辛
  [HiddenStem(7, 1.0)],
  // 戌:戊 辛 丁
  [HiddenStem(4, 0.6), HiddenStem(7, 0.3), HiddenStem(3, 0.1)],
  // 亥:壬 甲
  [HiddenStem(8, 0.7), HiddenStem(0, 0.3)],
];

/// 地支本气天干。
int mainHiddenStem(int branch) => hiddenStemsTable[branch].first.stem;
