/// 姓名测试:五格剖象 + 三才配置 + 八十一数理 + 生肖用字 + 八字五行补益。
library;

import '../bazi/bazi_chart.dart';
import '../bazi/five_elements.dart';
import '../calendar/sexagenary.dart';
import 'numerology.dart';
import 'stroke_dictionary.dart';

/// 数字 → 五行:1,2 木;3,4 火;5,6 土;7,8 金;9,0 水。
Element elementOfNumber(int n) {
  switch (n % 10) {
    case 1:
    case 2:
      return Element.wood;
    case 3:
    case 4:
      return Element.fire;
    case 5:
    case 6:
      return Element.earth;
    case 7:
    case 8:
      return Element.metal;
    default:
      return Element.water;
  }
}

/// 一格。
class Grid {
  const Grid(this.name, this.number, this.meaning, this.element, this.domain);
  final String name;
  final int number;
  final NumberMeaning meaning;
  final Element element;

  /// 该格主管的人生领域。
  final String domain;

  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
        'luck': meaning.luck.label,
        'title': meaning.title,
        'text': meaning.text,
        'element': element.label,
        'domain': domain,
      };
}

class NameAnalysis {
  const NameAnalysis({
    required this.surname,
    required this.givenName,
    required this.strokes,
    required this.unknownChars,
    required this.tian,
    required this.ren,
    required this.di,
    required this.wai,
    required this.zong,
    required this.sanCaiText,
    required this.sanCaiScore,
    required this.sanCaiComment,
    required this.zodiacNotes,
    required this.elementNotes,
    required this.overallScore,
    required this.summary,
  });

  final String surname;
  final String givenName;

  /// 每个字的笔画(与全名同序)。
  final List<int> strokes;

  /// 字典里查不到的字,笔画按 0 计,结果需提示用户。
  final List<String> unknownChars;

  final Grid tian;
  final Grid ren;
  final Grid di;
  final Grid wai;
  final Grid zong;

  final String sanCaiText;
  final int sanCaiScore;
  final String sanCaiComment;

  final List<String> zodiacNotes;
  final List<String> elementNotes;

  final int overallScore;
  final String summary;

  String get fullName => '$surname$givenName';

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'surname': surname,
        'givenName': givenName,
        'strokes': strokes,
        'unknownChars': unknownChars,
        'grids': [tian, ren, di, wai, zong].map((g) => g.toJson()).toList(),
        'sanCai': {'text': sanCaiText, 'score': sanCaiScore, 'comment': sanCaiComment},
        'zodiacNotes': zodiacNotes,
        'elementNotes': elementNotes,
        'overallScore': overallScore,
        'summary': summary,
      };
}

/// 复姓表(只列常见者;遇到时按两字作姓)。
const Set<String> compoundSurnames = {
  '欧阳', '司马', '上官', '诸葛', '东方', '夏侯', '尉迟', '皇甫', '公孙', '慕容',
  '长孙', '宇文', '令狐', '钟离', '闾丘', '澹台', '西门', '南宫', '百里', '呼延',
  '端木', '轩辕', '拓跋', '独孤', '司徒', '司空', '第五', '太史', '公羊', '万俟',
};

/// 拆分姓与名。
(String, String) splitName(String fullName) {
  final s = fullName.trim();
  if (s.length >= 3 && compoundSurnames.contains(s.substring(0, 2))) {
    return (s.substring(0, 2), s.substring(2));
  }
  if (s.length >= 4 && compoundSurnames.contains(s.substring(0, 2))) {
    return (s.substring(0, 2), s.substring(2));
  }
  return (s.substring(0, 1), s.substring(1));
}

/// 分析姓名。[chart] 可选,提供则做八字五行补益分析。
NameAnalysis analyzeName(String fullName, {BaziChart? chart}) {
  final (surname, given) = splitName(fullName);
  final dict = StrokeDictionary.instance;

  final chars = fullName.trim().split('');
  final unknown = <String>[];
  final strokes = <int>[
    for (final c in chars)
      dict.strokesOf(c) ?? (() {
            unknown.add(c);
            return 0;
          })(),
  ];

  final sLen = surname.length;
  final gLen = given.length;
  final sStrokes = strokes.sublist(0, sLen);
  final gStrokes = strokes.sublist(sLen);

  // ---- 五格 ----
  final tianN = sLen == 1 ? sStrokes[0] + 1 : sStrokes[0] + sStrokes[1];
  final renN = sStrokes.last + (gStrokes.isNotEmpty ? gStrokes.first : 0);
  final diN = gLen == 1 ? gStrokes[0] + 1 : gStrokes.fold(0, (a, b) => a + b);
  final zongN = strokes.fold(0, (a, b) => a + b);
  int waiN;
  if (sLen == 1 && gLen == 1) {
    waiN = 2;
  } else if (sLen == 1) {
    waiN = gStrokes.last + 1;
  } else if (gLen == 1) {
    waiN = sStrokes.first + 1;
  } else {
    waiN = sStrokes.first + gStrokes.last;
  }

  Grid grid(String name, int n, String domain) =>
      Grid(name, n, numberMeaningOf(n), elementOfNumber(n), domain);

  final tian = grid('天格', tianN, '祖业根基,先天运,对本人影响较小');
  final ren = grid('人格', renN, '性格核心与一生总运,五格之主');
  final di = grid('地格', diN, '前半生运势、家庭与子女、基础运');
  final wai = grid('外格', waiN, '人际社交、外部环境与贵人');
  final zong = grid('总格', zongN, '后半生运势、事业成就与晚年');

  // ---- 三才 ----
  final sanCaiText = '${tian.element.label}${ren.element.label}${di.element.label}';
  final (sanCaiScore, sanCaiComment) = _evaluateSanCai(tian.element, ren.element, di.element);

  // ---- 生肖用字 ----
  final zodiacNotes = <String>[];
  if (chart != null) {
    final z = chart.yearPillar.stemBranch.branch;
    final rules = zodiacCharRules[z]!;
    for (var i = sLen; i < chars.length; i++) {
      final info = dict.lookup(chars[i]);
      final radical = info?.radical;
      if (radical == null) continue;
      if (rules.$1.contains(radical)) {
        zodiacNotes.add('「${chars[i]}」含${radical}部,属${zodiacAnimals[z]}年喜用');
      } else if (rules.$2.contains(radical)) {
        zodiacNotes.add('「${chars[i]}」含${radical}部,属${zodiacAnimals[z]}年宜避');
      }
    }
    if (zodiacNotes.isEmpty) zodiacNotes.add('名字用字与生肖${zodiacAnimals[z]}无明显冲忌');
  }

  // ---- 八字五行补益 ----
  final elementNotes = <String>[];
  var elementScore = 0;
  if (chart != null) {
    final fav = chart.elements.favorable;
    final unfav = chart.elements.unfavorable;
    // 人格、地格、总格三格五行 + 名字字义五行
    final nameElements = <Element>[ren.element, di.element, zong.element];
    for (var i = sLen; i < chars.length; i++) {
      final e = dict.lookup(chars[i])?.element;
      if (e != null) nameElements.add(e);
    }
    final favHits = nameElements.where(fav.contains).length;
    final unfavHits = nameElements.where(unfav.contains).length;
    elementScore = favHits * 6 - unfavHits * 6;
    elementNotes.add('八字喜${fav.map((e) => e.label).join('、')},'
        '忌${unfav.map((e) => e.label).join('、')}');
    elementNotes.add('名字五行(格数与字义)中,喜用出现 $favHits 次,忌用出现 $unfavHits 次');
    if (chart.elements.missing.isNotEmpty) {
      final miss = chart.elements.missing;
      final compensated = miss.where(nameElements.contains).toList();
      if (compensated.isNotEmpty) {
        elementNotes.add('八字缺${miss.map((e) => e.label).join()},'
            '名字补了${compensated.map((e) => e.label).join()}');
      } else {
        elementNotes.add('八字缺${miss.map((e) => e.label).join()},名字未予补足');
      }
    }
  }

  // ---- 综合评分 ----
  int luckScore(Luck l) => switch (l) {
        Luck.auspicious => 100,
        Luck.half => 65,
        Luck.inauspicious => 30,
      };
  var score = (luckScore(ren.meaning.luck) * 0.30 +
          luckScore(di.meaning.luck) * 0.15 +
          luckScore(zong.meaning.luck) * 0.20 +
          luckScore(wai.meaning.luck) * 0.10 +
          luckScore(tian.meaning.luck) * 0.05 +
          sanCaiScore * 0.20)
      .round();
  score += elementScore;
  score = score.clamp(0, 100);

  final summary = unknown.isNotEmpty
      ? '「${unknown.join('、')}」不在字典中,笔画按 0 计,结果仅供参考'
      : '人格${ren.number}(${ren.meaning.luck.label})、'
          '总格${zong.number}(${zong.meaning.luck.label}),'
          '三才$sanCaiText${sanCaiScore >= 70 ? '相生' : sanCaiScore >= 50 ? '平和' : '相克'}';

  return NameAnalysis(
    surname: surname,
    givenName: given,
    strokes: strokes,
    unknownChars: unknown,
    tian: tian,
    ren: ren,
    di: di,
    wai: wai,
    zong: zong,
    sanCaiText: sanCaiText,
    sanCaiScore: sanCaiScore,
    sanCaiComment: sanCaiComment,
    zodiacNotes: zodiacNotes,
    elementNotes: elementNotes,
    overallScore: score,
    summary: summary,
  );
}

/// 三才配置评价:天生人、人生地为上;天克人、地克人为下。
(int, String) _evaluateSanCai(Element tian, Element ren, Element di) {
  var score = 60;
  final notes = <String>[];

  void judge(String a, String b, Element x, Element y, bool xIsAbove) {
    switch (x.relationTo(y)) {
      case ElementRelation.iGenerate:
        score += 15;
        notes.add('$a生$b');
      case ElementRelation.generatesMe:
        score += xIsAbove ? 8 : 12;
        notes.add('$b生$a');
      case ElementRelation.same:
        score += 5;
        notes.add('$a$b比和');
      case ElementRelation.iControl:
        score -= xIsAbove ? 15 : 8;
        notes.add('$a克$b');
      case ElementRelation.controlsMe:
        score -= 12;
        notes.add('$b克$a');
    }
  }

  judge('天格', '人格', tian, ren, true);
  judge('人格', '地格', ren, di, true);

  final s = score.clamp(0, 100);
  final verdict = s >= 80
      ? '配置大吉,基础稳固,成功运佳'
      : s >= 65
          ? '配置尚佳,顺遂平稳'
          : s >= 50
              ? '配置平常,有利有弊'
              : '配置欠佳,易生阻滞,宜以其他格局补救';
  return (s, '${notes.join(',')};$verdict');
}

/// 生肖用字宜忌(部首):{地支: (喜, 忌)}。取各家通行口径的交集,仅作参考。
const Map<int, (Set<String>, Set<String>)> zodiacCharRules = {
  0: ({'米', '豆', '禾', '艸', '宀', '口', '王', '申', '辰', '田'}, {'午', '馬', '火', '日', '羊', '未', '人', '彳'}),
  1: ({'艸', '禾', '田', '宀', '車', '巳', '酉', '子', '水'}, {'心', '月', '羊', '未', '馬', '午', '日', '山', '王', '衣', '示', '龍', '辰', '犬'}),
  2: ({'山', '林', '木', '王', '大', '肉', '月', '心', '馬', '午', '犬', '衣', '巾', '水'}, {'日', '申', '人', '彳', '門', '小', '艸', '田', '虫', '皮', '巳', '辰', '龍'}),
  3: ({'艸', '禾', '米', '豆', '木', '宀', '口', '田', '衣', '巾', '亥', '未', '羊'}, {'日', '酉', '鳥', '西', '金', '心', '月', '人', '彳', '山', '王', '辰', '龍'}),
  4: ({'水', '雨', '雲', '日', '月', '星', '辰', '王', '大', '申', '子', '酉', '鳥', '馬', '午'}, {'山', '田', '艸', '禾', '米', '豆', '戌', '犬', '卯', '虫', '川', '心', '月', '人', '彳'}),
  5: ({'口', '宀', '木', '田', '禾', '艸', '米', '豆', '辰', '龍', '酉', '丑', '馬', '午', '羊', '未', '衣', '巾', '心', '月'}, {'日', '亥', '虫', '人', '彳', '火', '山', '水', '川', '刀'}),
  6: ({'艸', '禾', '豆', '米', '木', '目', '寅', '虎', '戌', '犬', '巳', '未', '羊', '辰', '衣', '巾'}, {'子', '水', '田', '日', '山', '火', '車', '石', '心', '月', '人', '彳'}),
  7: ({'艸', '禾', '米', '豆', '木', '宀', '卯', '亥', '馬', '午', '足', '幾'}, {'心', '月', '肉', '日', '火', '大', '王', '丑', '牛', '戌', '犬', '子', '示', '衣', '巾', '車', '刀', '金'}),
  8: ({'木', '田', '山', '宀', '子', '水', '辰', '龍', '王', '大', '人', '彳', '言', '衣', '巾', '金'}, {'禾', '米', '穀', '火', '日', '寅', '虎', '亥', '石', '口', '皮', '力', '刀', '骨'}),
  9: ({'米', '豆', '禾', '麥', '梁', '山', '宀', '巳', '辰', '龍', '丑', '牛', '衣', '巾', '王'}, {'心', '月', '肉', '卯', '兔', '戌', '犬', '大', '王', '刀', '力', '石', '車', '金', '日', '火', '水', '人', '彳'}),
  10: ({'人', '彳', '宀', '心', '月', '肉', '寅', '虎', '馬', '午', '巾', '衣', '小', '少', '士', '臣'}, {'日', '辰', '龍', '丑', '牛', '酉', '雞', '鳥', '羊', '未', '木', '田', '禾', '米', '豆', '山', '石', '水', '火'}),
  11: ({'豆', '禾', '米', '艸', '木', '田', '宀', '卯', '兔', '未', '羊', '金', '玉', '月', '肉', '心', '人', '彳', '口'}, {'示', '巾', '刀', '力', '血', '皮', '石', '火', '日', '巳', '虫', '弓', '川', '王', '山', '辰', '龍', '申', '邑'}),
};
