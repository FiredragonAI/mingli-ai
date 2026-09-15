/// 合婚。
///
/// 六个维度打分再加权:生肖缘(年支)、日柱缘(日干日支)、五行互补、
/// 配偶星、神煞、纳音。每条加减分都写进 reasons,给 AI 和 UI 复述。
library;

import '../bazi/bazi_chart.dart';
import '../bazi/five_elements.dart';
import '../bazi/relations.dart';
import '../bazi/ten_gods.dart';
import '../calendar/sexagenary.dart';
import '../interpret/voice.dart';

class MarriageDimension implements DimensionLike {
  MarriageDimension(this.name, this.weight) : score = 60;
  @override
  final String name;
  final double weight;
  int score;
  final List<String> reasons = [];

  void add(int delta, String why) {
    score += delta;
    reasons.add('${delta >= 0 ? '+' : ''}$delta $why');
  }

  @override
  int get clamped => score.clamp(0, 100);

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': clamped,
        'reasons': reasons,
      };
}

class MarriageResult implements MarriageResultLike {
  const MarriageResult({
    required this.a,
    required this.b,
    required this.overall,
    required this.grade,
    required this.dimensions,
    required this.highlights,
    required this.cautions,
  });

  @override
  final BaziChart a;
  @override
  final BaziChart b;
  final int overall;
  @override
  final String grade;
  @override
  final List<MarriageDimension> dimensions;
  final List<String> highlights;
  final List<String> cautions;

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'grade': grade,
        'dimensions': dimensions.map((d) => d.toJson()).toList(),
        'highlights': highlights,
        'cautions': cautions,
        'partnerA': {
          'gender': a.input.gender.chartLabel,
          'summary': a.summaryLine,
          'dayMaster': a.dayMasterName,
          'zodiac': a.zodiac,
          'strength': a.elements.strength.label,
          'favorable': a.elements.favorable.map((e) => e.label).toList(),
        },
        'partnerB': {
          'gender': b.input.gender.chartLabel,
          'summary': b.summaryLine,
          'dayMaster': b.dayMasterName,
          'zodiac': b.zodiac,
          'strength': b.elements.strength.label,
          'favorable': b.elements.favorable.map((e) => e.label).toList(),
        },
      };
}

MarriageResult analyzeMarriage(BaziChart a, BaziChart b) {
  final zodiacDim = MarriageDimension('生肖缘', 0.15);
  final dayDim = MarriageDimension('日柱缘', 0.30);
  final elementDim = MarriageDimension('五行互补', 0.25);
  final spouseDim = MarriageDimension('配偶星', 0.15);
  final shenShaDim = MarriageDimension('神煞', 0.10);
  final naYinDim = MarriageDimension('纳音', 0.05);

  final highlights = <String>[];
  final cautions = <String>[];

  // ---- 生肖(年支) ----
  final ya = a.yearPillar.stemBranch.branch, yb = b.yearPillar.stemBranch.branch;
  final za = zodiacAnimals[ya], zb = zodiacAnimals[yb];
  if (isSixCombine(ya, yb)) {
    zodiacDim.add(25, '$za$zb六合,天生亲近');
    highlights.add('生肖六合');
  } else if (isTripleCombineMember(ya, yb)) {
    zodiacDim.add(18, '$za$zb三合,志趣相投');
    highlights.add('生肖三合');
  } else if (ya == yb) {
    zodiacDim.add(5, '同属$za,习性相似');
  }
  if (isClash(ya, yb)) {
    zodiacDim.add(-25, '$za$zb相冲,观念易对立');
    cautions.add('生肖相冲');
  }
  if (isHarm(ya, yb)) {
    zodiacDim.add(-15, '$za$zb相害,易生嫌隙');
    cautions.add('生肖相害');
  }
  if (isPunish(ya, yb)) {
    zodiacDim.add(-12, '$za$zb相刑,需互相包容');
  }

  // ---- 日柱 ----
  final da = a.dayPillar.stemBranch, db = b.dayPillar.stemBranch;
  if (isSixCombine(da.branch, db.branch)) {
    dayDim.add(20, '日支${da.branchName}${db.branchName}六合,夫妻宫相合');
    highlights.add('日支六合');
  } else if (isTripleCombineMember(da.branch, db.branch)) {
    dayDim.add(14, '日支${da.branchName}${db.branchName}三合');
  }
  if (isClash(da.branch, db.branch)) {
    dayDim.add(-22, '日支${da.branchName}${db.branchName}相冲,夫妻宫相冲');
    cautions.add('日支相冲');
  }
  if (isHarm(da.branch, db.branch)) dayDim.add(-12, '日支相害');
  if (isPunish(da.branch, db.branch)) dayDim.add(-10, '日支相刑');

  final stemDiff = (da.stem - db.stem).abs();
  if (stemDiff == 5) {
    dayDim.add(12, '日干${da.stemName}${db.stemName}五合,心意相通');
    highlights.add('日干相合');
  } else if (stemDiff == 6 && ![4, 5].contains(da.stem) && ![4, 5].contains(db.stem)) {
    dayDim.add(-8, '日干${da.stemName}${db.stemName}相冲');
  } else if (da.stem == db.stem) {
    dayDim.add(3, '日干相同,性情相近');
  }

  final relAB = a.dayMaster.relationTo(b.dayMaster);
  switch (relAB) {
    case ElementRelation.iGenerate:
      dayDim.add(10, '${a.dayMaster.label}生${b.dayMaster.label},${a.input.gender.label}方付出较多');
    case ElementRelation.generatesMe:
      dayDim.add(10, '${b.dayMaster.label}生${a.dayMaster.label},${b.input.gender.label}方付出较多');
    case ElementRelation.same:
      dayDim.add(4, '日主同五行,理解容易');
    case ElementRelation.iControl:
      dayDim.add(-8, '${a.dayMaster.label}克${b.dayMaster.label},${a.input.gender.label}方较强势');
    case ElementRelation.controlsMe:
      dayDim.add(-8, '${b.dayMaster.label}克${a.dayMaster.label},${b.input.gender.label}方较强势');
  }

  // ---- 五行互补 ----
  double favShare(BaziChart me, BaziChart partner) =>
      me.elements.favorable.fold(0.0, (s, e) => s + partner.elements.percentages[e]!);
  double unfavShare(BaziChart me, BaziChart partner) =>
      me.elements.unfavorable.fold(0.0, (s, e) => s + partner.elements.percentages[e]!);

  final favA = favShare(a, b), favB = favShare(b, a);
  final unfavA = unfavShare(a, b), unfavB = unfavShare(b, a);
  final favDelta = (((favA + favB) / 2 - 35) * 0.7).round();
  final unfavDelta = -(((unfavA + unfavB) / 2 - 35) * 0.5).round();
  elementDim.add(favDelta,
      '对方命局中我方喜用五行占比 ${favA.toStringAsFixed(0)}% / ${favB.toStringAsFixed(0)}%');
  elementDim.add(unfavDelta,
      '对方命局中我方忌讳五行占比 ${unfavA.toStringAsFixed(0)}% / ${unfavB.toStringAsFixed(0)}%');
  if (favDelta >= 10) highlights.add('五行互补性强');
  if (unfavDelta <= -10) cautions.add('对方旺我所忌');

  // 一方所缺恰是另一方所旺
  for (final (me, other) in [(a, b), (b, a)]) {
    for (final miss in me.elements.missing) {
      if (other.elements.percentages[miss]! >= 25) {
        elementDim.add(6, '${me.input.gender.label}方缺${miss.label},对方${miss.label}旺可补');
      }
    }
  }

  // ---- 配偶星 ----
  void spouseStar(BaziChart c) {
    final targetGod = c.input.isMale ? TenGod.directWealth : TenGod.directOfficer;
    final mixedGod = c.input.isMale ? TenGod.indirectWealth : TenGod.sevenKillings;
    final label = c.input.isMale ? '财星' : '官星';
    var direct = 0, mixed = 0;
    for (final p in c.pillars) {
      if (p.stemGod == targetGod) direct++;
      if (p.stemGod == mixedGod) mixed++;
      if (p.branchMainGod == targetGod) direct++;
      if (p.branchMainGod == mixedGod) mixed++;
    }
    final who = c.input.gender.label;
    if (direct >= 1 && direct + mixed <= 2) {
      spouseDim.add(8, '$who方$label清纯有力,婚缘清晰');
    } else if (direct + mixed == 0) {
      spouseDim.add(-6, '$who方命局无明显$label,婚缘需靠大运引动');
    } else if (direct + mixed >= 3) {
      spouseDim.add(-5, '$who方$label过多(${direct + mixed} 位),感情选择多而杂');
    }
    // 夫妻宫受冲
    final dayB = c.dayPillar.stemBranch.branch;
    for (var i = 0; i < 4; i++) {
      if (i != 2 && isClash(c.branches[i], dayB)) {
        spouseDim.add(-6, '$who方夫妻宫被${pillarNames[i]}支所冲');
        break;
      }
    }
  }
  spouseStar(a);
  spouseStar(b);

  // ---- 神煞 ----
  for (final c in [a, b]) {
    final who = c.input.gender.label;
    final names = c.shenSha.map((s) => s.name).toSet();
    if (names.contains('红鸾') || names.contains('天喜')) {
      shenShaDim.add(6, '$who方命带红鸾/天喜,利婚姻喜庆');
    }
    if (names.contains('孤辰') || names.contains('寡宿')) {
      shenShaDim.add(-5, '$who方命带孤辰/寡宿,宜多陪伴沟通');
    }
    if (names.contains('阴差阳错')) {
      shenShaDim.add(-6, '$who方日坐阴差阳错,感情易生误会');
      cautions.add('$who方阴差阳错日');
    }
    if (names.contains('孤鸾')) shenShaDim.add(-6, '$who方犯孤鸾,宜晚婚');
    final taoHua = c.shenSha.where((s) => s.name == '桃花').length;
    if (taoHua >= 2) shenShaDim.add(-3, '$who方桃花较多,需守情专一');
  }

  // ---- 纳音 ----
  final naA = _naYinElement(a.yearPillar.stemBranch.naYin);
  final naB = _naYinElement(b.yearPillar.stemBranch.naYin);
  switch (naA.relationTo(naB)) {
    case ElementRelation.iGenerate:
    case ElementRelation.generatesMe:
      naYinDim.add(10, '年柱纳音${a.yearPillar.naYin}与${b.yearPillar.naYin}相生');
    case ElementRelation.same:
      naYinDim.add(4, '纳音同气');
    default:
      naYinDim.add(-6, '年柱纳音${a.yearPillar.naYin}与${b.yearPillar.naYin}相克');
  }

  final dims = [zodiacDim, dayDim, elementDim, spouseDim, shenShaDim, naYinDim];
  final overall =
      dims.fold(0.0, (s, d) => s + d.clamped * d.weight).round().clamp(0, 100);

  final grade = overall >= 85
      ? '天作之合'
      : overall >= 75
          ? '良缘可期'
          : overall >= 62
              ? '中平可为'
              : overall >= 50
                  ? '需多磨合'
                  : '慎重考虑';

  return MarriageResult(
    a: a,
    b: b,
    overall: overall,
    grade: grade,
    dimensions: dims,
    highlights: highlights,
    cautions: cautions,
  );
}

Element _naYinElement(String naYin) {
  final last = naYin[naYin.length - 1];
  switch (last) {
    case '金':
      return Element.metal;
    case '木':
      return Element.wood;
    case '水':
      return Element.water;
    case '火':
      return Element.fire;
    default:
      return Element.earth;
  }
}
