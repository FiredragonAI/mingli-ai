/// 神煞。
///
/// 只收录口径较统一、查法明确的常用神煞。每条都记录查法依据,
/// 便于 UI 展示"为什么"以及不同流派切换。
library;

import '../calendar/sexagenary.dart';

/// 神煞吉凶性质。
enum ShenShaNature { auspicious, inauspicious, neutral }

/// 一条命中的神煞。
class ShenSha {
  const ShenSha({
    required this.name,
    required this.nature,
    required this.positions,
    required this.basis,
    required this.meaning,
  });

  final String name;
  final ShenShaNature nature;

  /// 落在哪些柱(0 年 1 月 2 日 3 时)。
  final List<int> positions;

  /// 查法依据,如"以年支查:申子辰见酉"。
  final String basis;

  final String meaning;

  @override
  String toString() => '$name(${positions.map((p) => pillarNames[p]).join()})';
}

/// 三合局起始支 → 对应神煞地支。表键为三合局代表(申子辰=0, 亥卯未=1, 寅午戌=2, 巳酉丑=3)。
int _tripleGroup(int branch) {
  // 申子辰 → 0;亥卯未 → 1;寅午戌 → 2;巳酉丑 → 3
  const map = [0, 3, 2, 1, 0, 3, 2, 1, 0, 3, 2, 1];
  return map[branch];
}

/// 以年支或日支查的三合系神煞:{名: [申子辰, 亥卯未, 寅午戌, 巳酉丑]}
const Map<String, List<int>> _tripleBased = {
  '桃花': [9, 0, 3, 6],
  '驿马': [2, 5, 8, 11],
  '华盖': [4, 7, 10, 1],
  '将星': [0, 3, 6, 9],
  '劫煞': [5, 8, 11, 2],
  '亡神': [11, 2, 5, 8],
};

const Map<String, (ShenShaNature, String)> _tripleMeta = {
  '桃花': (ShenShaNature.neutral, '人缘异性缘佳,魅力强;过多则情感波折'),
  '驿马': (ShenShaNature.neutral, '奔波变动、出行迁移、外地发展'),
  '华盖': (ShenShaNature.neutral, '聪慧孤高,近艺术宗教玄学,偏好独处'),
  '将星': (ShenShaNature.auspicious, '领导力、统御力,宜掌权管事'),
  '劫煞': (ShenShaNature.inauspicious, '易遭意外破耗、竞争剥夺,行事宜谨'),
  '亡神': (ShenShaNature.inauspicious, '城府深、易有暗损失意,宜防口舌官非'),
};

/// 以日干查的神煞:{名: 十天干对应的地支列表}
const Map<String, List<List<int>>> _dayStemBased = {
  // 天乙贵人:甲戊丑未,乙己子申,丙丁亥酉,庚辛午寅,壬癸巳卯
  '天乙贵人': [[1, 7], [0, 8], [11, 9], [11, 9], [1, 7], [0, 8], [6, 2], [6, 2], [5, 3], [5, 3]],
  // 文昌:甲巳 乙午 丙申 丁酉 戊申 己酉 庚亥 辛子 壬寅 癸卯
  '文昌贵人': [[5], [6], [8], [9], [8], [9], [11], [0], [2], [3]],
  // 禄神:甲寅 乙卯 丙巳 丁午 戊巳 己午 庚申 辛酉 壬亥 癸子
  '禄神': [[2], [3], [5], [6], [5], [6], [8], [9], [11], [0]],
  // 羊刃(阳干):甲卯 丙午 戊午 庚酉 壬子;阴干不取
  '羊刃': [[3], [], [6], [], [6], [], [9], [], [0], []],
  // 金舆:甲辰 乙巳 丙未 丁申 戊未 己申 庚戌 辛亥 壬丑 癸寅
  '金舆': [[4], [5], [7], [8], [7], [8], [10], [11], [1], [2]],
  // 太极贵人:甲乙子午 丙丁卯酉 戊己辰戌丑未 庚辛寅亥 壬癸巳申
  '太极贵人': [[0, 6], [0, 6], [3, 9], [3, 9], [4, 10, 1, 7], [4, 10, 1, 7], [2, 11], [2, 11], [5, 8], [5, 8]],
  // 国印贵人:甲戌 乙亥 丙丑 丁寅 戊丑 己寅 庚辰 辛巳 壬未 癸申
  '国印贵人': [[10], [11], [1], [2], [1], [2], [4], [5], [7], [8]],
};

const Map<String, (ShenShaNature, String)> _dayStemMeta = {
  '天乙贵人': (ShenShaNature.auspicious, '逢凶化吉,多得贵人扶助,人缘与机遇俱佳'),
  '文昌贵人': (ShenShaNature.auspicious, '聪明好学,利考试学业文书,气质文雅'),
  '禄神': (ShenShaNature.auspicious, '衣食丰足,有稳定收入根基'),
  '羊刃': (ShenShaNature.inauspicious, '性刚果决、魄力强,亦主争斗刑伤,宜从武职技术'),
  '金舆': (ShenShaNature.auspicious, '富贵安逸,婚姻多得配偶助力,有车马之福'),
  '太极贵人': (ShenShaNature.auspicious, '好学有悟性,喜哲理玄学,晚年安泰'),
  '国印贵人': (ShenShaNature.auspicious, '掌权印、有公职缘,为人正直守信'),
};

/// 月支查月德合等。
const List<int> _yueDe = [8, 6, 2, 0, 8, 6, 2, 0, 8, 6, 2, 0]; // 寅午戌丙 申子辰壬 亥卯未甲 巳酉丑庚

/// 日柱特殊格局(以六十甲子序号判断)。
final Map<String, (Set<int>, ShenShaNature, String)> _dayPillarSpecial = {
  '魁罡': ({_gz(6, 4), _gz(6, 10), _gz(8, 4), _gz(4, 10)}, ShenShaNature.neutral,
      '性格刚烈果断、聪明有威,好坏两极,宜身强不宜刑冲'),
  '阴差阳错': ({
    _gz(2, 0), _gz(3, 1), _gz(4, 2), _gz(7, 3), _gz(8, 4), _gz(9, 5),
    _gz(2, 6), _gz(3, 7), _gz(4, 8), _gz(7, 9), _gz(8, 10), _gz(9, 11),
  }, ShenShaNature.inauspicious, '婚姻感情易生波折误会,宜多沟通'),
  '孤鸾': ({
    _gz(1, 5), _gz(3, 5), _gz(7, 11), _gz(4, 8), _gz(0, 2), _gz(8, 0), _gz(2, 6), _gz(4, 6), _gz(8, 2),
  }, ShenShaNature.inauspicious, '婚缘较迟或聚少离多,宜晚婚'),
  '十灵日': ({
    _gz(0, 4), _gz(1, 11), _gz(2, 4), _gz(3, 9), _gz(4, 0), _gz(5, 3), _gz(6, 4), _gz(7, 11), _gz(8, 2), _gz(9, 7),
  }, ShenShaNature.auspicious, '天资聪颖,直觉灵敏'),
};

int _gz(int stem, int branch) => StemBranch(stem, branch).index;

/// 计算全部神煞。
///
/// [stems]、[branches] 按年月日时排列;[isMale] 用于孤辰寡宿等性别相关神煞。
List<ShenSha> analyzeShenSha(List<int> stems, List<int> branches, {required bool isMale}) {
  final result = <ShenSha>[];
  final yearBranch = branches[0];
  final monthBranch = branches[1];
  final dayStem = stems[2];
  final dayBranch = branches[2];

  // ---- 三合系:分别以年支、日支为基准查其余三柱 ----
  _tripleBased.forEach((name, table) {
    final meta = _tripleMeta[name]!;
    for (final (baseIdx, baseName) in [(0, '年支'), (2, '日支')]) {
      final target = table[_tripleGroup(branches[baseIdx])];
      final hits = [
        for (var i = 0; i < 4; i++)
          if (i != baseIdx && branches[i] == target) i,
      ];
      if (hits.isNotEmpty) {
        result.add(ShenSha(
          name: name,
          nature: meta.$1,
          positions: hits,
          basis: '以$baseName${earthlyBranches[branches[baseIdx]]}查,见${earthlyBranches[target]}',
          meaning: meta.$2,
        ));
      }
    }
  });

  // ---- 日干系 ----
  _dayStemBased.forEach((name, table) {
    final meta = _dayStemMeta[name]!;
    final targets = table[dayStem];
    final hits = [for (var i = 0; i < 4; i++) if (targets.contains(branches[i])) i];
    if (hits.isNotEmpty) {
      result.add(ShenSha(
        name: name,
        nature: meta.$1,
        positions: hits,
        basis: '以日干${heavenlyStems[dayStem]}查,见${targets.map((b) => earthlyBranches[b]).join('、')}',
        meaning: meta.$2,
      ));
    }
  });

  // ---- 红鸾 / 天喜(年支) ----
  final hongLuan = (3 - yearBranch + 12) % 12;
  final tianXi = (hongLuan + 6) % 12;
  for (final (name, target, meaning) in [
    ('红鸾', hongLuan, '婚恋喜庆、人缘桃花,利感情进展'),
    ('天喜', tianXi, '喜事临门、添丁进财,心情愉悦'),
  ]) {
    final hits = [for (var i = 1; i < 4; i++) if (branches[i] == target) i];
    if (hits.isNotEmpty) {
      result.add(ShenSha(
        name: name,
        nature: ShenShaNature.auspicious,
        positions: hits,
        basis: '以年支${earthlyBranches[yearBranch]}查,见${earthlyBranches[target]}',
        meaning: meaning,
      ));
    }
  }

  // ---- 孤辰 / 寡宿(年支) ----
  // 亥子丑:孤寅寡戌;寅卯辰:孤巳寡丑;巳午未:孤申寡辰;申酉戌:孤亥寡未
  final quadrant = ((yearBranch + 1) % 12) ~/ 3; // 亥子丑→0 寅卯辰→1 巳午未→2 申酉戌→3
  final guChen = [2, 5, 8, 11][quadrant];
  final guaSu = [10, 1, 4, 7][quadrant];
  for (final (name, target, meaning) in [
    ('孤辰', guChen, isMale ? '男怕孤辰:性情孤独,婚缘宜迟' : '性情独立,少依赖'),
    ('寡宿', guaSu, isMale ? '性情独立,少依赖' : '女怕寡宿:感情易孤寂,宜多社交'),
  ]) {
    final hits = [for (var i = 1; i < 4; i++) if (branches[i] == target) i];
    if (hits.isNotEmpty) {
      result.add(ShenSha(
        name: name,
        nature: ShenShaNature.inauspicious,
        positions: hits,
        basis: '以年支${earthlyBranches[yearBranch]}查,见${earthlyBranches[target]}',
        meaning: meaning,
      ));
    }
  }

  // ---- 月德贵人(月支查天干) ----
  final yueDeStem = _yueDe[monthBranch];
  final yueDeHits = [for (var i = 0; i < 4; i++) if (stems[i] == yueDeStem) i];
  if (yueDeHits.isNotEmpty) {
    result.add(ShenSha(
      name: '月德贵人',
      nature: ShenShaNature.auspicious,
      positions: yueDeHits,
      basis: '以月支${earthlyBranches[monthBranch]}查,见天干${heavenlyStems[yueDeStem]}',
      meaning: '心地仁厚,凶险可解,一生少灾',
    ));
  }

  // ---- 天医(月支前一位) ----
  final tianYi = (monthBranch + 11) % 12;
  final tianYiHits = [for (var i = 0; i < 4; i++) if (i != 1 && branches[i] == tianYi) i];
  if (tianYiHits.isNotEmpty) {
    result.add(ShenSha(
      name: '天医',
      nature: ShenShaNature.auspicious,
      positions: tianYiHits,
      basis: '以月支${earthlyBranches[monthBranch]}查前一位,见${earthlyBranches[tianYi]}',
      meaning: '与医药养生有缘,身体康健或适合从医',
    ));
  }

  // ---- 日柱特殊 ----
  final dayIdx = StemBranch(dayStem, dayBranch).index;
  _dayPillarSpecial.forEach((name, meta) {
    if (meta.$1.contains(dayIdx)) {
      result.add(ShenSha(
        name: name,
        nature: meta.$2,
        positions: const [2],
        basis: '日柱${StemBranch(dayStem, dayBranch).name}',
        meaning: meta.$3,
      ));
    }
  });

  // ---- 天赦日 ----
  final season = _seasonOf(monthBranch);
  const tianShe = {0: (4, 2), 1: (0, 6), 2: (4, 8), 3: (0, 0)}; // 春戊寅 夏甲午 秋戊申 冬甲子
  final ts = tianShe[season];
  if (ts != null && dayStem == ts.$1 && dayBranch == ts.$2) {
    result.add(ShenSha(
      name: '天赦',
      nature: ShenShaNature.auspicious,
      positions: const [2],
      basis: '${['春', '夏', '秋', '冬'][season]}生${StemBranch(dayStem, dayBranch).name}日',
      meaning: '天赦之日,百事宽免,一生逢凶化吉',
    ));
  }

  return result;
}

/// 0 春 1 夏 2 秋 3 冬(寅卯辰 春 …)。
int _seasonOf(int monthBranch) => ((monthBranch + 10) % 12) ~/ 3;

/// 空亡(旬空):某柱所在旬里缺的两个地支。
List<int> voidBranchesOf(StemBranch pillar) {
  final head = pillar.index - pillar.index % 10;
  return [(head + 10) % 12, (head + 11) % 12];
}
