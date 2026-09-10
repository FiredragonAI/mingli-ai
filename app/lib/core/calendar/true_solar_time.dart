/// 真太阳时换算。
///
/// 八字排盘的时辰以**当地真太阳时**为准,而用户填的是北京时间。两者之差:
///
/// 1. **经度差**:北京时间是东经 120° 的平太阳时,当地每偏西 1° 就晚 4 分钟。
///    乌鲁木齐(E87.6°)比北京时间慢约 2 小时 10 分,这是最常见的错盘原因。
/// 2. **均时差**:地球轨道是椭圆、黄道又倾斜,真太阳与平太阳的时差
///    全年在 −14 ~ +16 分钟之间摆动,11 月初达到最大。
///
/// 两项都算,才是专业口径。
library;

import '../astro/delta_t.dart';
import '../astro/julian.dart';
import '../astro/sun.dart';
import 'lunar_calendar.dart';

/// 真太阳时换算结果。
class TrueSolarTimeResult {
  const TrueSolarTimeResult({
    required this.standardJdUt,
    required this.trueSolarJdUt,
    required this.longitudeCorrectionMinutes,
    required this.equationOfTimeMinutes,
  });

  /// 用户输入的标准时(UT 儒略日)。
  final double standardJdUt;

  /// 折算成"当地真太阳时后再当作北京时间去读"的 UT 儒略日。
  ///
  /// 后续排时柱用它取小时数即可,不必再做任何时区处理。
  final double trueSolarJdUt;

  /// 经度修正,分钟。西经 120° 以西为负。
  final double longitudeCorrectionMinutes;

  /// 均时差,分钟。
  final double equationOfTimeMinutes;

  double get totalCorrectionMinutes =>
      longitudeCorrectionMinutes + equationOfTimeMinutes;

  /// 真太阳时的"钟面时间"(以本地日历表示)。
  CalendarDate get trueSolarClock =>
      calendarDateFromJulianDay(trueSolarJdUt + chinaTimezoneHours / 24.0);
}

/// 由**北京时间**的公历年月日时分与出生地经度求真太阳时。
///
/// [longitude] 东经为正,西经为负。[timezoneHours] 输入时间所属时区,默认 8。
TrueSolarTimeResult trueSolarTime({
  required int year,
  required int month,
  required int day,
  required int hour,
  required int minute,
  required double longitude,
  double timezoneHours = chinaTimezoneHours,
  bool applyEquationOfTime = true,
}) {
  final localJd = julianDayFromDateTimeUtc(year, month, day, hour, minute);
  final jdUt = localJd - timezoneHours / 24.0;

  final centralMeridian = timezoneHours * 15.0;
  final lonCorrection = (longitude - centralMeridian) * 4.0;

  final eot = applyEquationOfTime ? equationOfTimeMinutes(jdUtToJde(jdUt)) : 0.0;

  final trueJd = jdUt + (lonCorrection + eot) / 1440.0;

  return TrueSolarTimeResult(
    standardJdUt: jdUt,
    trueSolarJdUt: trueJd,
    longitudeCorrectionMinutes: lonCorrection,
    equationOfTimeMinutes: eot,
  );
}
