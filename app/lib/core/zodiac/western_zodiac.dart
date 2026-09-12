/// 西方占星:太阳星座与上升星座。
///
/// 太阳星座按**回归黄道**严格定义:春分点为白羊 0°,每 30° 一宫。
/// 我们已经有精确到角秒级的太阳视黄经([sunApparentLongitude]),
/// 直接用它切宫,比网上流传的"几月几日到几月几日"表准确——
/// 那种表在换宫日前后一两天经常出错,而每年换宫时刻都不一样。
///
/// 上升星座 = 出生时刻东方地平线与黄道的交点,需要出生时间 + 经纬度,
/// 这三样八字排盘本来就要,顺手就能算。
library;

import 'dart:math' as math;

import '../astro/angle.dart';
import '../astro/delta_t.dart';
import '../astro/julian.dart';
import '../astro/nutation.dart';
import '../astro/sun.dart';

/// 占星四元素。
enum ZodiacElement {
  fire('火', '热情、行动、直觉'),
  earth('土', '务实、稳定、感官'),
  air('风', '思辨、沟通、社交'),
  water('水', '情感、共情、直觉');

  const ZodiacElement(this.label, this.keywords);
  final String label;
  final String keywords;
}

/// 三态(基本 / 固定 / 变动)。
enum ZodiacModality {
  cardinal('基本', '开创与发起'),
  fixed('固定', '坚持与深耕'),
  mutable('变动', '适应与调和');

  const ZodiacModality(this.label, this.keywords);
  final String label;
  final String keywords;
}

/// 十二星座。顺序即黄道顺序,索引 = 黄经 ÷ 30。
enum ZodiacSign {
  aries('白羊座', '♈', 'Aries', '3.21 – 4.19', ZodiacElement.fire, ZodiacModality.cardinal, '火星',
      ['勇敢', '直率', '行动派'], ['果断', '热情', '敢于开拓'], ['急躁', '冲动', '缺乏耐心'],
      '红色', [1, 9], '第一印象爽朗直接,做事先动手再想,带着一股不服输的劲头'),
  taurus('金牛座', '♉', 'Taurus', '4.20 – 5.20', ZodiacElement.earth, ZodiacModality.fixed, '金星',
      ['稳重', '务实', '重感官'], ['可靠', '有耐心', '审美好'], ['固执', '占有心强', '慢热'],
      '绿色', [2, 6], '第一印象沉稳可靠,节奏慢但踏实,对物质与舒适有天然的敏感'),
  gemini('双子座', '♊', 'Gemini', '5.21 – 6.21', ZodiacElement.air, ZodiacModality.mutable, '水星',
      ['机敏', '好奇', '善沟通'], ['适应力强', '口才好', '学得快'], ['三心二意', '浮躁', '难以专注'],
      '黄色', [3, 5], '第一印象轻快健谈,反应快、话题多,给人聪明而不易捉摸的感觉'),
  cancer('巨蟹座', '♋', 'Cancer', '6.22 – 7.22', ZodiacElement.water, ZodiacModality.cardinal, '月亮',
      ['重情', '顾家', '敏感'], ['体贴', '忠诚', '直觉强'], ['情绪化', '防御心重', '念旧'],
      '银白色', [2, 7], '第一印象温和内敛,先观察再靠近,熟了以后非常照顾人'),
  leo('狮子座', '♌', 'Leo', '7.23 – 8.22', ZodiacElement.fire, ZodiacModality.fixed, '太阳',
      ['自信', '大方', '有领导力'], ['慷慨', '忠诚', '有感染力'], ['以自我为中心', '好面子', '固执'],
      '金橙色', [1, 4], '第一印象大方有存在感,自然而然成为焦点,乐于承担和给予'),
  virgo('处女座', '♍', 'Virgo', '8.23 – 9.22', ZodiacElement.earth, ZodiacModality.mutable, '水星',
      ['细致', '理性', '追求完美'], ['可靠', '分析力强', '勤勉'], ['挑剔', '易焦虑', '过度自省'],
      '灰蓝色', [5, 6], '第一印象整洁克制,说话有条理,不轻易暴露情绪,细节处见用心'),
  libra('天秤座', '♎', 'Libra', '9.23 – 10.23', ZodiacElement.air, ZodiacModality.cardinal, '金星',
      ['优雅', '公正', '重关系'], ['亲和', '审美好', '善协调'], ['犹豫不决', '依赖他人', '回避冲突'],
      '粉蓝色', [6, 9], '第一印象得体有礼,在意他人感受,天然的调和者与社交润滑剂'),
  scorpio('天蝎座', '♏', 'Scorpio', '10.24 – 11.22', ZodiacElement.water, ZodiacModality.fixed, '冥王星 / 火星',
      ['深沉', '专注', '洞察力强'], ['意志坚定', '忠诚', '看得透'], ['多疑', '走极端', '记仇'],
      '深红色', [8, 11], '第一印象冷静有距离感,眼神专注,话不多但很有分量'),
  sagittarius('射手座', '♐', 'Sagittarius', '11.23 – 12.21', ZodiacElement.fire, ZodiacModality.mutable, '木星',
      ['乐观', '自由', '爱探索'], ['心胸开阔', '幽默', '真诚'], ['散漫', '难以承诺', '直言伤人'],
      '紫色', [3, 9], '第一印象开朗随性,爱笑爱聊,不拘小节,带着旅人般的自由气息'),
  capricorn('摩羯座', '♑', 'Capricorn', '12.22 – 1.19', ZodiacElement.earth, ZodiacModality.cardinal, '土星',
      ['自律', '坚韧', '目标明确'], ['责任感强', '有耐力', '务实'], ['保守', '压抑情感', '工作狂'],
      '黑褐色', [4, 8], '第一印象严肃稳重,显得比实际年龄成熟,言出必行'),
  aquarius('水瓶座', '♒', 'Aquarius', '1.20 – 2.18', ZodiacElement.air, ZodiacModality.fixed, '天王星 / 土星',
      ['独立', '创新', '理想主义'], ['有原创性', '博爱', '有前瞻性'], ['疏离', '叛逆', '不合群'],
      '蓝色', [4, 7], '第一印象特别、有点距离感,想法总和别人不一样,友善但不亲密'),
  pisces('双鱼座', '♓', 'Pisces', '2.19 – 3.20', ZodiacElement.water, ZodiacModality.mutable, '海王星 / 木星',
      ['温柔', '浪漫', '共情力强'], ['想象力丰富', '慈悲', '有艺术感'], ['逃避现实', '过度敏感', '边界模糊'],
      '海绿色', [7, 12], '第一印象柔和梦幻,容易被打动,让人不自觉想保护');

  const ZodiacSign(
    this.name,
    this.symbol,
    this.english,
    this.dateRange,
    this.element,
    this.modality,
    this.ruler,
    this.keywords,
    this.strengths,
    this.weaknesses,
    this.luckyColor,
    this.luckyNumbers,
    this.risingTrait,
  );

  final String name;
  final String symbol;
  final String english;

  /// 大致日期,仅供展示;实际归属按黄经判定。
  final String dateRange;
  final ZodiacElement element;
  final ZodiacModality modality;
  final String ruler;
  final List<String> keywords;
  final List<String> strengths;
  final List<String> weaknesses;
  final String luckyColor;
  final List<int> luckyNumbers;

  /// 作为上升星座时的含义。
  final String risingTrait;

  /// 对宫(黄道上相差 180° 的星座)。
  ZodiacSign get opposite => ZodiacSign.values[(index + 6) % 12];

  /// 黄经所在星座。
  static ZodiacSign fromLongitude(double longitude) =>
      ZodiacSign.values[(normalizeDegrees(longitude) / 30).floor() % 12];
}

/// 一个人的星座档案。
class ZodiacProfile {
  const ZodiacProfile({
    required this.sun,
    required this.sunLongitude,
    required this.rising,
    required this.risingLongitude,
  });

  final ZodiacSign sun;

  /// 出生时太阳视黄经,度。
  final double sunLongitude;

  /// 上升星座;无经纬度时为 null。
  final ZodiacSign? rising;
  final double? risingLongitude;

  /// 太阳在本宫内的度数,0–30。
  double get sunDegreeInSign => sunLongitude - sun.index * 30;

  /// 是否临近换宫(距边界 1° 以内,约一天)。此时不同历表可能给出不同答案。
  bool get nearCusp => sunDegreeInSign < 1.0 || sunDegreeInSign > 29.0;

  /// 太阳落在"上一个"还是"下一个"星座的边界上。
  ZodiacSign? get cuspNeighbour {
    if (!nearCusp) return null;
    return sunDegreeInSign < 1.0
        ? ZodiacSign.values[(sun.index + 11) % 12]
        : ZodiacSign.values[(sun.index + 1) % 12];
  }

  Map<String, dynamic> toJson() => {
        'sun': {
          'sign': sun.name,
          'symbol': sun.symbol,
          'english': sun.english,
          'element': sun.element.label,
          'modality': sun.modality.label,
          'ruler': sun.ruler,
          'degree': sunDegreeInSign.toStringAsFixed(1),
          'longitude': sunLongitude.toStringAsFixed(2),
          'keywords': sun.keywords,
          'strengths': sun.strengths,
          'weaknesses': sun.weaknesses,
          'luckyColor': sun.luckyColor,
          'luckyNumbers': sun.luckyNumbers,
        },
        'nearCusp': nearCusp,
        'cuspNeighbour': cuspNeighbour?.name,
        if (rising != null)
          'rising': {
            'sign': rising!.name,
            'symbol': rising!.symbol,
            'element': rising!.element.label,
            'degree': (risingLongitude! - rising!.index * 30).toStringAsFixed(1),
            'trait': rising!.risingTrait,
          },
      };
}

/// 由出生时刻(UT 儒略日)与出生地求星座档案。
///
/// [latitude] 为 null 或绝对值 ≥ 66.5°(极圈内上升点定义失效)时不算上升。
ZodiacProfile zodiacProfile({
  required double birthJdUt,
  double? longitude,
  double? latitude,
}) {
  final jde = jdUtToJde(birthJdUt);
  final sunLon = sunApparentLongitude(jde);
  final sun = ZodiacSign.fromLongitude(sunLon);

  ZodiacSign? rising;
  double? risingLon;
  if (longitude != null && latitude != null && latitude.abs() < 66.5) {
    risingLon = ascendantLongitude(birthJdUt, longitude, latitude);
    rising = ZodiacSign.fromLongitude(risingLon);
  }

  return ZodiacProfile(
    sun: sun,
    sunLongitude: sunLon,
    rising: rising,
    risingLongitude: risingLon,
  );
}

/// 格林尼治平恒星时,度(Meeus 12.4)。
double greenwichMeanSiderealTime(double jdUt) {
  final d = jdUt - j2000;
  final t = d / 36525.0;
  final theta = 280.46061837 +
      360.98564736629 * d +
      0.000387933 * t * t -
      t * t * t / 38710000.0;
  return normalizeDegrees(theta);
}

/// 上升点黄经,度。
///
/// ASC = atan2( cos RAMC, −(sin RAMC · cos ε + tan φ · sin ε) ),
/// 其中 RAMC 为当地视恒星时(即中天赤经),ε 真黄赤交角,φ 纬度。
double ascendantLongitude(double jdUt, double longitude, double latitude) {
  final t = julianCenturies(jdUtToJde(jdUt));
  final eps = degToRad(trueObliquity(t));
  final nut = nutation(t);
  final gast = greenwichMeanSiderealTime(jdUt) + nut.longitude * math.cos(eps);
  final ramc = degToRad(normalizeDegrees(gast + longitude));
  final phi = degToRad(latitude);

  final y = math.cos(ramc);
  final x = -(math.sin(ramc) * math.cos(eps) + math.tan(phi) * math.sin(eps));
  return normalizeDegrees(radToDeg(math.atan2(y, x)));
}

/// 两个星座的配对。
class ZodiacMatch {
  const ZodiacMatch(this.a, this.b, this.score, this.summary, this.reasons);
  final ZodiacSign a;
  final ZodiacSign b;

  /// 0–100。
  final int score;
  final String summary;
  final List<String> reasons;

  Map<String, dynamic> toJson() => {
        'a': a.name,
        'b': b.name,
        'score': score,
        'summary': summary,
        'reasons': reasons,
      };
}

/// 太阳星座配对(元素相性 + 对宫吸引 + 三态互动)。
///
/// 这是占星入门的通行口径,结论只当作"相处风格是否合拍"的参考,不作判决。
ZodiacMatch zodiacMatch(ZodiacSign a, ZodiacSign b) {
  final reasons = <String>[];
  var score = 60;

  final ea = a.element, eb = b.element;
  if (ea == eb) {
    score += 22;
    reasons.add('同属${ea.label}象,价值观与节奏天然接近');
  } else if (_harmonious(ea, eb)) {
    score += 16;
    reasons.add('${ea.label}象与${eb.label}象相辅相成,一方点燃、一方承托');
  } else if ((ea == ZodiacElement.fire && eb == ZodiacElement.earth) ||
      (ea == ZodiacElement.earth && eb == ZodiacElement.fire) ||
      (ea == ZodiacElement.air && eb == ZodiacElement.water) ||
      (ea == ZodiacElement.water && eb == ZodiacElement.air)) {
    score -= 4;
    reasons.add('${ea.label}象与${eb.label}象节奏不同,需要刻意磨合');
  } else {
    score -= 8;
    reasons.add('${ea.label}象与${eb.label}象差异较大,互补明显但也容易互相消耗');
  }

  final diff = (a.index - b.index).abs() % 12;
  if (diff == 6) {
    score += 8;
    reasons.add('互为对宫星座,强烈吸引,像镜子照见彼此缺少的部分');
  } else if (diff == 0) {
    score += 4;
    reasons.add('同一星座,理解容易,但也会放大共同的短板');
  } else if (diff == 4 || diff == 8) {
    score += 6;
    reasons.add('相距 120°(三分相),自然顺畅');
  } else if (diff == 3 || diff == 9) {
    score -= 5;
    reasons.add('相距 90°(四分相),张力大,吵架和成长都多');
  }

  if (a.modality == b.modality) {
    if (a.modality == ZodiacModality.fixed) {
      score -= 4;
      reasons.add('都是固定星座,谁都不肯先让步');
    } else if (a.modality == ZodiacModality.cardinal) {
      score -= 2;
      reasons.add('都是基本星座,都想做主导');
    } else {
      score += 2;
      reasons.add('都是变动星座,灵活好商量');
    }
  }

  score = score.clamp(0, 100);
  final summary = score >= 85
      ? '默契天成'
      : score >= 72
          ? '相处融洽'
          : score >= 58
              ? '互补可为'
              : '需要磨合';

  return ZodiacMatch(a, b, score, summary, reasons);
}

bool _harmonious(ZodiacElement x, ZodiacElement y) =>
    (x == ZodiacElement.fire && y == ZodiacElement.air) ||
    (x == ZodiacElement.air && y == ZodiacElement.fire) ||
    (x == ZodiacElement.earth && y == ZodiacElement.water) ||
    (x == ZodiacElement.water && y == ZodiacElement.earth);

/// 与本星座最合拍的三个星座(按 [zodiacMatch] 分数排序)。
List<ZodiacSign> bestMatchesFor(ZodiacSign sign) {
  final others = ZodiacSign.values.where((s) => s != sign).toList()
    ..sort((x, y) => zodiacMatch(sign, y).score.compareTo(zodiacMatch(sign, x).score));
  return others.take(3).toList();
}
