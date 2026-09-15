/// 干支之间的刑、冲、合、害。
///
/// 全部用索引取模判断,不查大表。柱位:0 年、1 月、2 日、3 时。
library;

import '../calendar/sexagenary.dart';
import 'five_elements.dart';

/// 一条干支关系。
class Interaction {
  const Interaction({
    required this.kind,
    required this.positions,
    required this.description,
    this.resultElement,
  });

  final InteractionKind kind;

  /// 涉及的柱位,0 年 1 月 2 日 3 时。
  final List<int> positions;

  final String description;

  /// 合化出的五行(仅三合、三会、六合有)。
  final Element? resultElement;

  @override
  String toString() => description;
}

enum InteractionKind {
  stemCombine('天干五合', true),
  stemClash('天干相冲', false),
  branchSixCombine('地支六合', true),
  branchTripleCombine('地支三合', true),
  branchHalfCombine('地支半合', true),
  branchDirectional('地支三会', true),
  branchClash('地支六冲', false),
  branchHarm('地支六害', false),
  branchPunish('地支相刑', false),
  branchSelfPunish('地支自刑', false),
  branchDestroy('地支相破', false);

  const InteractionKind(this.label, this.isHarmonious);
  final String label;
  final bool isHarmonious;
}

/// 三合局:[三支, 五行]。
const List<(List<int>, Element)> _tripleCombos = [
  ([8, 0, 4], Element.water), // 申子辰
  ([11, 3, 7], Element.wood), // 亥卯未
  ([2, 6, 10], Element.fire), // 寅午戌
  ([5, 9, 1], Element.metal), // 巳酉丑
];

/// 三会方:[三支, 五行]。
const List<(List<int>, Element)> _directionalCombos = [
  ([2, 3, 4], Element.wood), // 寅卯辰 东方木
  ([5, 6, 7], Element.fire), // 巳午未 南方火
  ([8, 9, 10], Element.metal), // 申酉戌 西方金
  ([11, 0, 1], Element.water), // 亥子丑 北方水
];

/// 六合化气:子丑土、寅亥木、卯戌火、辰酉金、巳申水、午未土(取常见说法)。
Element _sixCombineElement(int a, int b) {
  final s = {a, b};
  if (s.containsAll([0, 1])) return Element.earth;
  if (s.containsAll([2, 11])) return Element.wood;
  if (s.containsAll([3, 10])) return Element.fire;
  if (s.containsAll([4, 9])) return Element.metal;
  if (s.containsAll([5, 8])) return Element.water;
  return Element.earth; // 午未
}

/// 分析四柱之间的全部干支关系。
///
/// [stems]、[branches] 长度 4,按年月日时排列。
List<Interaction> analyzeInteractions(List<int> stems, List<int> branches) {
  final result = <Interaction>[];

  String pos(List<int> p) => p.map((i) => pillarNames[i]).join('');

  // ---- 天干 ----
  for (var i = 0; i < 4; i++) {
    for (var j = i + 1; j < 4; j++) {
      final a = stems[i], b = stems[j];
      final diff = (a - b).abs();
      if (diff == 5) {
        result.add(Interaction(
          kind: InteractionKind.stemCombine,
          positions: [i, j],
          description: '${pos([i, j])}干 ${heavenlyStems[a]}${heavenlyStems[b]} 相合',
        ));
      } else if (diff == 6 && a != 4 && a != 5 && b != 4 && b != 5) {
        // 戊己居中无冲
        result.add(Interaction(
          kind: InteractionKind.stemClash,
          positions: [i, j],
          description: '${pos([i, j])}干 ${heavenlyStems[a]}${heavenlyStems[b]} 相冲',
        ));
      }
    }
  }

  // ---- 地支两两 ----
  for (var i = 0; i < 4; i++) {
    for (var j = i + 1; j < 4; j++) {
      final a = branches[i], b = branches[j];
      final label = '${pos([i, j])}支 ${earthlyBranches[a]}${earthlyBranches[b]}';

      if ((a + b) % 12 == 1) {
        result.add(Interaction(
          kind: InteractionKind.branchSixCombine,
          positions: [i, j],
          description: '$label 六合',
          resultElement: _sixCombineElement(a, b),
        ));
      }
      if ((a - b).abs() == 6) {
        result.add(Interaction(
          kind: InteractionKind.branchClash,
          positions: [i, j],
          description: '$label 相冲',
        ));
      }
      if ((a + b) % 12 == 7) {
        result.add(Interaction(
          kind: InteractionKind.branchHarm,
          positions: [i, j],
          description: '$label 相害',
        ));
      }
      // 相破:子酉 丑辰 寅亥 卯午 巳申 未戌 —— 规律是"阴支顺数三位"
      final odd = a.isOdd ? a : (b.isOdd ? b : -1);
      final even = a.isOdd ? b : a;
      if (odd >= 0 && (odd + 3) % 12 == even) {
        result.add(Interaction(
          kind: InteractionKind.branchDestroy,
          positions: [i, j],
          description: '$label 相破',
        ));
      }
      // 自刑:辰辰 午午 酉酉 亥亥
      if (a == b && (a == 4 || a == 6 || a == 9 || a == 11)) {
        result.add(Interaction(
          kind: InteractionKind.branchSelfPunish,
          positions: [i, j],
          description: '$label 自刑',
        ));
      }
      // 无礼之刑:子卯
      if ({a, b}.containsAll([0, 3])) {
        result.add(Interaction(
          kind: InteractionKind.branchPunish,
          positions: [i, j],
          description: '$label 相刑(无礼之刑)',
        ));
      }
      // 半合:三合局中任两支
      for (final (trio, el) in _tripleCombos) {
        if (trio.contains(a) && trio.contains(b) && a != b) {
          result.add(Interaction(
            kind: InteractionKind.branchHalfCombine,
            positions: [i, j],
            description: '$label 半合${el.label}',
            resultElement: el,
          ));
        }
      }
    }
  }

  // ---- 地支三者 ----
  final branchSet = branches.toSet();
  for (final (trio, el) in _tripleCombos) {
    if (branchSet.containsAll(trio)) {
      final positions = [for (var i = 0; i < 4; i++) if (trio.contains(branches[i])) i];
      result.add(Interaction(
        kind: InteractionKind.branchTripleCombine,
        positions: positions,
        description: '${trio.map((b) => earthlyBranches[b]).join()} 三合${el.label}局',
        resultElement: el,
      ));
    }
  }
  for (final (trio, el) in _directionalCombos) {
    if (branchSet.containsAll(trio)) {
      final positions = [for (var i = 0; i < 4; i++) if (trio.contains(branches[i])) i];
      result.add(Interaction(
        kind: InteractionKind.branchDirectional,
        positions: positions,
        description: '${trio.map((b) => earthlyBranches[b]).join()} 三会${el.label}方',
        resultElement: el,
      ));
    }
  }
  // 三刑:寅巳申(无恩)、丑戌未(恃势)——两支相见亦成刑
  for (final (trio, name) in [([2, 5, 8], '无恩之刑'), ([1, 10, 7], '恃势之刑')]) {
    final present = [for (var i = 0; i < 4; i++) if (trio.contains(branches[i])) i];
    final distinct = present.map((i) => branches[i]).toSet();
    if (distinct.length >= 2) {
      result.add(Interaction(
        kind: InteractionKind.branchPunish,
        positions: present,
        description: '${distinct.map((b) => earthlyBranches[b]).join()} 相刑($name)',
      ));
    }
  }

  return result;
}

/// 两个地支是否六合。
bool isSixCombine(int a, int b) => (a + b) % 12 == 1;

/// 两个地支是否六冲。
bool isClash(int a, int b) => (a - b).abs() == 6;

/// 两个地支是否六害。
bool isHarm(int a, int b) => (a + b) % 12 == 7;

/// 两个地支是否同属一个三合局。
bool isTripleCombineMember(int a, int b) =>
    a != b && (a - b).abs() % 4 == 0;

/// 两个地支是否相破:子酉 丑辰 寅亥 卯午 巳申 未戌。
bool isDestroy(int a, int b) {
  final odd = a.isOdd ? a : (b.isOdd ? b : -1);
  final even = a.isOdd ? b : a;
  return odd >= 0 && (odd + 3) % 12 == even;
}

/// 两个地支是否相刑(含自刑)。
bool isPunish(int a, int b) {
  if ({a, b}.containsAll([0, 3])) return true;
  const groups = [
    [2, 5, 8],
    [1, 10, 7],
  ];
  for (final g in groups) {
    if (g.contains(a) && g.contains(b) && a != b) return true;
  }
  return a == b && (a == 4 || a == 6 || a == 9 || a == 11);
}
