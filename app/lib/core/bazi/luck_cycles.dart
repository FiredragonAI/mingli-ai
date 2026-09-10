/// 大运与流年。
///
/// 起运法:阳年生男、阴年生女**顺行**,数到出生后第一个"节";
/// 阴年生男、阳年生女**逆行**,数到出生前最近的"节"。
/// 三日折一年,一日折四月,一时辰折十天。
/// 大运从月柱起,顺行则下一柱,逆行则上一柱,每运十年。
library;

import '../astro/julian.dart';
import '../astro/solar_terms.dart';
import '../calendar/lunar_calendar.dart';
import '../calendar/sexagenary.dart';

/// 平均回归年长度(天)。
const double _tropicalYear = 365.2422;

/// 一个流年。
class YearlyLuck {
  const YearlyLuck({
    required this.year,
    required this.pillar,
    required this.nominalAge,
  });

  /// 公历年份(以立春为界的干支年)。
  final int year;
  final StemBranch pillar;

  /// 虚岁。
  final int nominalAge;
}

/// 一步大运。
class LuckPillar {
  const LuckPillar({
    required this.ordinal,
    required this.pillar,
    required this.startJdUt,
    required this.startYear,
    required this.startNominalAge,
    required this.years,
  });

  /// 第几步,从 1 起。
  final int ordinal;
  final StemBranch pillar;

  /// 交运时刻(UT 儒略日)。
  final double startJdUt;

  /// 交运的公历年。
  final int startYear;

  /// 交运虚岁。
  final int startNominalAge;

  int get endYear => startYear + 9;

  /// 该运内十个流年。
  final List<YearlyLuck> years;

  String get ageRange => '$startNominalAge–${startNominalAge + 9} 岁';
}

/// 大运排布结果。
class LuckCycleResult {
  const LuckCycleResult({
    required this.forward,
    required this.boundaryTerm,
    required this.startYears,
    required this.startMonths,
    required this.startDays,
    required this.startJdUt,
    required this.cycles,
  });

  /// 顺行为 true。
  final bool forward;

  /// 起运所数到的节。
  final SolarTermEvent boundaryTerm;

  /// 出生后多久起运:X 年 Y 月 Z 天。
  final int startYears;
  final int startMonths;
  final int startDays;

  /// 起运时刻(UT 儒略日)。
  final double startJdUt;

  final List<LuckPillar> cycles;

  String get direction => forward ? '顺行' : '逆行';

  String get startDescription =>
      '出生后 $startYears 年 $startMonths 个月 $startDays 天起运($direction),'
      '约 ${startYears + 1} 虚岁交第一步大运';

  /// 某公历年正处于哪一步大运;起运前返回 null。
  LuckPillar? cycleForYear(int year) {
    for (final c in cycles) {
      if (year >= c.startYear && year <= c.endYear) return c;
    }
    return null;
  }
}

/// 排大运。
///
/// [birthJdUt] 出生时刻;[yearStem] 年干;[monthPillar] 月柱;[isMale] 性别。
/// [cycleCount] 排几步大运,默认 9 步(覆盖到九十来岁)。
LuckCycleResult computeLuckCycles({
  required double birthJdUt,
  required int yearStem,
  required StemBranch monthPillar,
  required bool isMale,
  int cycleCount = 9,
}) {
  final forward = isStemYang(yearStem) == isMale;
  final boundary = forward ? nextMajorTerm(birthJdUt) : previousMajorTerm(birthJdUt);

  final diffDays = (boundary.jdUt - birthJdUt).abs();

  // 三日一年
  final totalYears = diffDays / 3.0;
  final years = totalYears.floor();
  final monthsF = (totalYears - years) * 12.0;
  final months = monthsF.floor();
  final days = ((monthsF - months) * 30.0).round();

  final startJd = birthJdUt + totalYears * _tropicalYear;
  final birthYear = calendarDateFromJulianDay(birthJdUt + chinaTimezoneHours / 24).year;

  final cycles = <LuckPillar>[];
  for (var k = 0; k < cycleCount; k++) {
    final cycleStartJd = startJd + k * 10 * _tropicalYear;
    final startYear =
        calendarDateFromJulianDay(cycleStartJd + chinaTimezoneHours / 24).year;
    final pillar = monthPillar.shift(forward ? k + 1 : -(k + 1));
    final startNominalAge = startYear - birthYear + 1;

    final yearly = <YearlyLuck>[
      for (var y = startYear; y < startYear + 10; y++)
        YearlyLuck(
          year: y,
          pillar: yearPillar(y),
          nominalAge: y - birthYear + 1,
        ),
    ];

    cycles.add(LuckPillar(
      ordinal: k + 1,
      pillar: pillar,
      startJdUt: cycleStartJd,
      startYear: startYear,
      startNominalAge: startNominalAge,
      years: yearly,
    ));
  }

  return LuckCycleResult(
    forward: forward,
    boundaryTerm: boundary,
    startYears: years,
    startMonths: months,
    startDays: days,
    startJdUt: startJd,
    cycles: cycles,
  );
}
