/// 八字命盘——把历法、四柱、藏干、十神、五行、神煞、大运串成一个结果对象。
///
/// 这是 core 层对外的主入口。UI 和后端交互只依赖 [BaziChart] 与它的 [toJson]。
library;

import '../astro/julian.dart';
import '../astro/solar_terms.dart';
import '../calendar/lunar_calendar.dart';
import '../calendar/sexagenary.dart';
import '../calendar/true_solar_time.dart';
import 'element_strength.dart';
import 'five_elements.dart';
import 'hidden_stems.dart';
import 'luck_cycles.dart';
import 'relations.dart';
import 'shen_sha.dart';
import 'ten_gods.dart';

enum Gender {
  male('男', '乾造'),
  female('女', '坤造');

  const Gender(this.label, this.chartLabel);
  final String label;
  final String chartLabel;
}

/// 晚子时(23:00–23:59)的日柱处理。
enum ZiHourMode {
  /// 23 点起算次日——多数排盘软件的默认。
  nextDay('晚子时算次日'),

  /// 日柱不换、时柱按次日日干起——"晚子时"派。
  sameDay('晚子时日柱不换');

  const ZiHourMode(this.label);
  final String label;
}

/// 用户对出生时间的把握程度。
enum BirthTimeMode {
  /// 知道几点几分。
  exact,

  /// 只知道时辰(子时、丑时……),按该时辰中点排盘。
  shichen,

  /// 完全不确定,按正午排盘;时柱与依赖时柱的结论都只是估算。
  unknown;

  bool get isEstimated => this == unknown;
}

/// 出生信息。所有时间为**民用时**(用户手表上的时间)。
class BirthInput {
  const BirthInput({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.gender,
    required this.longitude,
    this.latitude = 0,
    this.placeName = '',
    this.timezoneHours = chinaTimezoneHours,
    this.useTrueSolarTime = true,
    this.ziHourMode = ZiHourMode.nextDay,
    this.timeMode = BirthTimeMode.exact,
    this.name = '',
  });

  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final Gender gender;
  final BirthTimeMode timeMode;

  /// 出生时辰(地支序号 0 子 … 11 亥)。
  int get hourBranch => hourBranchOf(hour + minute / 60.0);

  /// 出生地经度,东经为正。
  final double longitude;
  final double latitude;
  final String placeName;
  final double timezoneHours;
  final bool useTrueSolarTime;
  final ZiHourMode ziHourMode;
  final String name;

  bool get isMale => gender == Gender.male;

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'day': day,
        'hour': hour,
        'minute': minute,
        'gender': gender.name,
        'longitude': longitude,
        'latitude': latitude,
        'placeName': placeName,
        'timezoneHours': timezoneHours,
        'useTrueSolarTime': useTrueSolarTime,
        'ziHourMode': ziHourMode.name,
        'timeMode': timeMode.name,
        'name': name,
      };
}

/// 一个藏干及其十神。
class HiddenStemInfo {
  const HiddenStemInfo(this.stem, this.weight, this.tenGod);
  final int stem;
  final double weight;
  final TenGod tenGod;
  String get name => heavenlyStems[stem];
}

/// 十二长生。
const List<String> lifeStages = [
  '长生', '沐浴', '冠带', '临官', '帝旺', '衰', '病', '死', '墓', '绝', '胎', '养',
];

/// 十天干的长生地支:甲亥 乙午 丙寅 丁酉 戊寅 己酉 庚巳 辛子 壬申 癸卯。
const List<int> _lifeStageStart = [11, 6, 2, 9, 2, 9, 5, 0, 8, 3];

/// 日干在某地支上的长生十二宫。阳干顺行、阴干逆行。
String lifeStageOf(int stem, int branch) {
  final start = _lifeStageStart[stem];
  final offset = isStemYang(stem) ? (branch - start) : (start - branch);
  return lifeStages[((offset % 12) + 12) % 12];
}

/// 一柱。
class Pillar {
  const Pillar({
    required this.position,
    required this.stemBranch,
    required this.stemGod,
    required this.hiddenStems,
    required this.voidBranches,
    required this.lifeStage,
  });

  /// 0 年 1 月 2 日 3 时。
  final int position;
  final StemBranch stemBranch;

  /// 天干十神;日柱为 null(日主自身)。
  final TenGod? stemGod;
  final List<HiddenStemInfo> hiddenStems;

  /// 本柱旬空的两个地支。
  final List<int> voidBranches;

  /// 日主在本柱地支的长生十二宫。
  final String lifeStage;

  String get name => stemBranch.name;
  String get positionName => pillarNames[position];
  String get naYin => stemBranch.naYin;

  /// 本气藏干的十神(地支主气十神)。
  TenGod get branchMainGod => hiddenStems.first.tenGod;

  Map<String, dynamic> toJson() => {
        'position': positionName,
        'stem': stemBranch.stemName,
        'branch': stemBranch.branchName,
        'stemElement': stemBranch.stemElement.label,
        'branchElement': stemBranch.branchElement.label,
        'stemGod': stemGod?.label ?? '日主',
        'hiddenStems': [
          for (final h in hiddenStems)
            {'stem': h.name, 'weight': h.weight, 'god': h.tenGod.label},
        ],
        'naYin': naYin,
        'lifeStage': lifeStage,
        'voidBranches': voidBranches.map((b) => earthlyBranches[b]).toList(),
      };
}

/// 完整命盘。
class BaziChart {
  const BaziChart({
    required this.input,
    required this.pillars,
    required this.trueSolar,
    required this.effectiveJdUt,
    required this.lunar,
    required this.previousTerm,
    required this.nextTerm,
    required this.elements,
    required this.interactions,
    required this.shenSha,
    required this.luck,
    required this.taiYuan,
    required this.mingGong,
    required this.shenGong,
  });

  final BirthInput input;

  /// 年月日时四柱。
  final List<Pillar> pillars;

  final TrueSolarTimeResult trueSolar;

  /// 实际用于排盘的时刻(真太阳时或标准时)。
  final double effectiveJdUt;

  final LunarDate lunar;

  /// 出生前后最近的节,用于说明"离换月还差多久"。
  final SolarTermEvent previousTerm;
  final SolarTermEvent nextTerm;

  final ElementAnalysis elements;
  final List<Interaction> interactions;
  final List<ShenSha> shenSha;
  final LuckCycleResult luck;

  /// 胎元:月干进一、月支进三。
  final StemBranch taiYuan;

  /// 命宫。
  final StemBranch mingGong;

  /// 身宫。
  final StemBranch shenGong;

  Pillar get yearPillar => pillars[0];
  Pillar get monthPillar => pillars[1];
  Pillar get dayPillar => pillars[2];
  Pillar get hourPillar => pillars[3];

  int get dayStem => dayPillar.stemBranch.stem;
  Element get dayMaster => stemElements[dayStem];
  String get dayMasterName => heavenlyStems[dayStem];
  String get zodiac => zodiacAnimals[yearPillar.stemBranch.branch];

  List<int> get stems => pillars.map((p) => p.stemBranch.stem).toList();
  List<int> get branches => pillars.map((p) => p.stemBranch.branch).toList();

  /// "甲子 乙丑 丙寅 丁卯"这样的一行文字。
  String get summaryLine => pillars.map((p) => p.name).join(' ');

  /// 日柱空亡是否落在其他柱。
  List<int> get voidPositions {
    final v = dayPillar.voidBranches;
    return [for (var i = 0; i < 4; i++) if (i != 2 && v.contains(branches[i])) i];
  }

  /// 供后端 / AI 使用的结构化 JSON。**所有推算都在这里完成,模型只做解读。**
  Map<String, dynamic> toJson() {
    final clock = calendarDateFromJulianDay(effectiveJdUt + chinaTimezoneHours / 24);
    return {
      'input': input.toJson(),
      'gender': input.gender.chartLabel,
      'summary': summaryLine,
      // 出生时间不确定时,时柱、命宫、身宫、起运时刻都是估算——模型解读时必须说明
      'hourPillarEstimated': input.timeMode.isEstimated,
      'dayMaster': {
        'stem': dayMasterName,
        'element': dayMaster.label,
        'yinYang': isStemYang(dayStem) ? '阳' : '阴',
      },
      'zodiac': zodiac,
      'pillars': pillars.map((p) => p.toJson()).toList(),
      'trueSolarTime': {
        'used': input.useTrueSolarTime,
        'clock': clock.toString(),
        'longitudeCorrectionMinutes':
            trueSolar.longitudeCorrectionMinutes.toStringAsFixed(1),
        'equationOfTimeMinutes': trueSolar.equationOfTimeMinutes.toStringAsFixed(1),
      },
      'lunar': {
        'text': lunar.toString(),
        'year': lunar.year,
        'month': lunar.month,
        'day': lunar.day,
        'isLeapMonth': lunar.isLeapMonth,
      },
      'solarTerms': {
        'previous': {
          'name': previousTerm.name,
          'daysBefore': (effectiveJdUt - previousTerm.jdUt).toStringAsFixed(2),
        },
        'next': {
          'name': nextTerm.name,
          'daysAfter': (nextTerm.jdUt - effectiveJdUt).toStringAsFixed(2),
        },
      },
      'elements': {
        'percentages': {
          for (final e in Element.values) e.label: elements.percentages[e]!.round(),
        },
        'strength': elements.strength.label,
        'gotSeason': elements.gotSeason,
        'gotRoot': elements.gotRoot,
        'gotSupport': elements.gotSupport,
        'favorable': elements.favorable.map((e) => e.label).toList(),
        'unfavorable': elements.unfavorable.map((e) => e.label).toList(),
        'primaryUsefulGod': elements.primaryUsefulGod.label,
        'climateHint': elements.climateHint,
        'missing': elements.missing.map((e) => e.label).toList(),
        'reasoning': elements.reasoning,
      },
      'interactions': interactions.map((i) => i.description).toList(),
      'shenSha': [
        for (final s in shenSha)
          {
            'name': s.name,
            'nature': s.nature.name,
            'positions': s.positions.map((p) => pillarNames[p]).join(),
            'basis': s.basis,
            'meaning': s.meaning,
          },
      ],
      'voidPositions': voidPositions.map((p) => pillarNames[p]).toList(),
      'taiYuan': taiYuan.name,
      'mingGong': mingGong.name,
      'shenGong': shenGong.name,
      'luck': {
        'direction': luck.direction,
        'start': luck.startDescription,
        'cycles': [
          for (final c in luck.cycles)
            {
              'ordinal': c.ordinal,
              'pillar': c.pillar.name,
              'startYear': c.startYear,
              'endYear': c.endYear,
              'ageRange': c.ageRange,
              'stemGod': tenGodOf(dayStem, c.pillar.stem).label,
              'branchGod': tenGodOf(dayStem, mainHiddenStem(c.pillar.branch)).label,
              'years': [
                for (final y in c.years)
                  {'year': y.year, 'pillar': y.pillar.name, 'age': y.nominalAge},
              ],
            },
        ],
      },
    };
  }
}

/// JDN 锚点:1900-01-01(北京时间当日)的本地日数。
final int _jdn19000101 = julianDayNumberLocal(julianDayFromDate(1900, 1, 1.5));

/// 排盘主函数。
BaziChart computeBaziChart(BirthInput input) {
  final tst = trueSolarTime(
    year: input.year,
    month: input.month,
    day: input.day,
    hour: input.hour,
    minute: input.minute,
    longitude: input.longitude,
    timezoneHours: input.timezoneHours,
  );

  // 时辰、日界用真太阳时;节气交接是物理瞬间,用标准时比较
  final clockJd = input.useTrueSolarTime ? tst.trueSolarJdUt : tst.standardJdUt;
  final physicalJd = tst.standardJdUt;

  // ---- 年柱、月柱 ----
  final sexYear = sexagenaryYearOf(physicalJd);
  final yearSb = yearPillar(sexYear);
  final monthIdx = solarTermMonthIndex(physicalJd);
  final monthSb = monthPillar(yearSb.stem, monthIdx);

  // ---- 日柱 ----
  final clock = calendarDateFromJulianDay(clockJd + chinaTimezoneHours / 24);
  final hourDecimal = clock.hour + clock.minute / 60.0;
  var dayNumber = localDayNumber(clockJd);
  final isLateZi = hourDecimal >= 23.0;
  if (isLateZi && input.ziHourMode == ZiHourMode.nextDay) dayNumber += 1;
  final daySb = dayPillarFromDaysSince1900(dayNumber - _jdn19000101);

  // ---- 时柱 ----
  final hourBranch = hourBranchOf(hourDecimal);
  final stemForHour = (isLateZi && input.ziHourMode == ZiHourMode.sameDay)
      ? (daySb.stem + 1) % 10
      : daySb.stem;
  final hourSb = hourPillar(stemForHour, hourBranch);

  final sbs = [yearSb, monthSb, daySb, hourSb];
  final stems = sbs.map((s) => s.stem).toList();
  final branches = sbs.map((s) => s.branch).toList();
  final dayStem = daySb.stem;

  final pillars = <Pillar>[
    for (var i = 0; i < 4; i++)
      Pillar(
        position: i,
        stemBranch: sbs[i],
        stemGod: i == 2 ? null : tenGodOf(dayStem, sbs[i].stem),
        hiddenStems: [
          for (final h in hiddenStemsTable[sbs[i].branch])
            HiddenStemInfo(h.stem, h.weight, tenGodOf(dayStem, h.stem)),
        ],
        voidBranches: voidBranchesOf(sbs[i]),
        lifeStage: lifeStageOf(dayStem, sbs[i].branch),
      ),
  ];

  // ---- 胎元、命宫、身宫 ----
  final taiYuan = StemBranch((monthSb.stem + 1) % 10, (monthSb.branch + 3) % 12);
  // 命宫:(26 − 月支 − 时支) mod 12,干以年干五虎遁推。此为通行排盘软件口径。
  final mingBranch = ((26 - monthSb.branch - hourBranch) % 12 + 12) % 12;
  final mingGong = _stemForBranchByYear(yearSb.stem, mingBranch);
  // 身宫:(月支 + 时支 − 2) mod 12
  final shenBranch = ((monthSb.branch + hourBranch - 2) % 12 + 12) % 12;
  final shenGong = _stemForBranchByYear(yearSb.stem, shenBranch);

  final elements = analyzeElements(stems, branches);
  final interactions = analyzeInteractions(stems, branches);
  final shenSha = analyzeShenSha(stems, branches, isMale: input.isMale);
  final luck = computeLuckCycles(
    birthJdUt: physicalJd,
    yearStem: yearSb.stem,
    monthPillar: monthSb,
    isMale: input.isMale,
  );

  return BaziChart(
    input: input,
    pillars: pillars,
    trueSolar: tst,
    effectiveJdUt: clockJd,
    lunar: lunarFromJdUt(tst.standardJdUt),
    previousTerm: previousMajorTerm(physicalJd),
    nextTerm: nextMajorTerm(physicalJd),
    elements: elements,
    interactions: interactions,
    shenSha: shenSha,
    luck: luck,
    taiYuan: taiYuan,
    mingGong: mingGong,
    shenGong: shenGong,
  );
}

/// 以年干五虎遁,给定地支配天干(寅月起)。
StemBranch _stemForBranchByYear(int yearStem, int branch) {
  final monthIdx = ((branch - 2) % 12 + 12) % 12;
  return monthPillar(yearStem, monthIdx);
}
