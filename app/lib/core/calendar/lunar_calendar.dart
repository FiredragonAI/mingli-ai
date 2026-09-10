/// 农历(夏历)。
///
/// 采用现行《农历的编算和颁行》国家标准口径:
/// - **定朔**:合朔瞬间所在的那一天为初一;
/// - **定气**:节气用真太阳黄经;
/// - **冬至所在月为十一月**;
/// - 两个冬至之间若有 13 个朔望月,**第一个不含中气的月**为闰月。
///
/// 所有"哪一天"的判断都以北京时间(UTC+8)的日界为准,这也是官方历书的口径。
library;

import '../astro/julian.dart';
import '../astro/moon_phase.dart';
import '../astro/solar_terms.dart';
import 'sexagenary.dart';

/// 中国大陆民用时区。历书按此定日界。
const double chinaTimezoneHours = 8.0;

/// 农历某一天。
class LunarDate {
  const LunarDate({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeapMonth,
    required this.monthDayCount,
  });

  /// 农历年(以正月初一换年,与八字的立春换年**不同**)。
  final int year;

  /// 1–12。
  final int month;

  /// 1–30。
  final int day;

  final bool isLeapMonth;

  /// 本月天数,29(小)或 30(大)。
  final int monthDayCount;

  String get monthName => '${isLeapMonth ? '闰' : ''}${lunarMonthNames[month - 1]}';
  String get dayName => lunarDayNames[day - 1];

  /// 农历年干支,例如"甲辰"。注意这是**历书**口径的年干支(正月换年)。
  StemBranch get yearStemBranch => yearPillar(year);
  String get zodiac => zodiacAnimals[yearStemBranch.branch];

  bool get isBigMonth => monthDayCount == 30;

  @override
  String toString() => '农历${yearStemBranch.name}年$monthName$dayName';
}

const List<String> lunarMonthNames = [
  '正月', '二月', '三月', '四月', '五月', '六月',
  '七月', '八月', '九月', '十月', '冬月', '腊月',
];

const List<String> lunarDayNames = [
  '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
  '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
  '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
];

/// 一个农历月的元信息。
class LunarMonthInfo {
  const LunarMonthInfo({
    required this.lunarYear,
    required this.number,
    required this.isLeap,
    required this.startDayNumber,
    required this.dayCount,
  });

  final int lunarYear;
  final int number;
  final bool isLeap;

  /// 初一的本地儒略日数(JDN)。
  final int startDayNumber;
  final int dayCount;

  int get endDayNumberExclusive => startDayNumber + dayCount;
  bool contains(int dayNumber) =>
      dayNumber >= startDayNumber && dayNumber < endDayNumberExclusive;
}

/// 一"岁":从某年冬至所在的十一月初一,到下一年冬至所在的十一月初一(不含)。
class _Sui {
  const _Sui(this.months);
  final List<LunarMonthInfo> months;

  int get startDay => months.first.startDayNumber;
  int get endDayExclusive => months.last.endDayNumberExclusive;
}

final Map<int, _Sui> _suiCache = {};

/// 本地日数:把 UT 儒略日换到北京时间,再取以午夜为界的整数日编号。
int localDayNumber(double jdUt) =>
    julianDayNumberLocal(jdUt + chinaTimezoneHours / 24.0);

/// 本地日数 → 该日 00:00 的 UT 儒略日。
double jdUtAtLocalMidnight(int dayNumber) =>
    dayNumber - 0.5 - chinaTimezoneHours / 24.0;

/// 找到"包含某个瞬间所在那一天"的朔望月的初一(本地日数)。
int _newMoonDayOnOrBefore(double jdUt) {
  final dayNum = localDayNumber(jdUt);
  // 该日结束时刻(次日 00:00 的 UT)之前的最后一次合朔
  final endOfDay = jdUtAtLocalMidnight(dayNum + 1);
  final nm = lastNewMoonBefore(endOfDay - 1e-6);
  return localDayNumber(nm);
}

/// 构建以 [winterSolsticeYear] 年冬至为起点的一岁。
_Sui _buildSui(int winterSolsticeYear) {
  final cached = _suiCache[winterSolsticeYear];
  if (cached != null) return cached;

  final wsA = solarTermJdUt(winterSolsticeYear, 270);
  final wsB = solarTermJdUt(winterSolsticeYear + 1, 270);

  final startDay = _newMoonDayOnOrBefore(wsA);
  final endDay = _newMoonDayOnOrBefore(wsB);

  // 罗列本岁内所有朔日
  final newMoonDays = <int>[startDay];
  var cursor = jdUtAtLocalMidnight(startDay) + 1.0;
  while (true) {
    final nm = nextNewMoonAfter(cursor);
    final d = localDayNumber(nm);
    if (d >= endDay) break;
    newMoonDays.add(d);
    cursor = nm + 1.0;
  }
  newMoonDays.add(endDay); // 哨兵,方便算每月天数

  final monthCount = newMoonDays.length - 1;

  // 定闰:13 个月时,从第二个月起找第一个不含中气的月
  var leapIndex = -1;
  if (monthCount == 13) {
    final midTermDays = <int>[
      localDayNumber(wsA),
      ...solarTermsOfYear(winterSolsticeYear + 1)
          .where((e) => !e.isMajor && e.jdUt < wsB)
          .map((e) => localDayNumber(e.jdUt)),
    ];
    for (var i = 1; i < monthCount; i++) {
      final s = newMoonDays[i];
      final e = newMoonDays[i + 1];
      final hasMidTerm = midTermDays.any((d) => d >= s && d < e);
      if (!hasMidTerm) {
        leapIndex = i;
        break;
      }
    }
  }

  final months = <LunarMonthInfo>[];
  var seenFirstMonth = false;
  for (var i = 0; i < monthCount; i++) {
    final isLeap = i == leapIndex;
    final ordinal = (leapIndex >= 0 && i >= leapIndex) ? i - 1 : i;
    final number = ((ordinal + 10) % 12) + 1; // i=0 → 十一月
    if (number == 1 && !isLeap) seenFirstMonth = true;
    months.add(LunarMonthInfo(
      lunarYear: seenFirstMonth ? winterSolsticeYear + 1 : winterSolsticeYear,
      number: number,
      isLeap: isLeap,
      startDayNumber: newMoonDays[i],
      dayCount: newMoonDays[i + 1] - newMoonDays[i],
    ));
  }

  if (_suiCache.length > 12) _suiCache.clear();
  final sui = _Sui(months);
  _suiCache[winterSolsticeYear] = sui;
  return sui;
}

/// 公历(UT 儒略日)→ 农历。
LunarDate lunarFromJdUt(double jdUt) {
  final dayNum = localDayNumber(jdUt);
  final civilYear = calendarDateFromJulianDay(jdUt + chinaTimezoneHours / 24).year;

  var sui = _buildSui(civilYear - 1);
  if (dayNum >= sui.endDayExclusive) sui = _buildSui(civilYear);

  final month = sui.months.firstWhere((m) => m.contains(dayNum));
  return LunarDate(
    year: month.lunarYear,
    month: month.number,
    day: dayNum - month.startDayNumber + 1,
    isLeapMonth: month.isLeap,
    monthDayCount: month.dayCount,
  );
}

/// 公历本地日期 → 农历。
LunarDate lunarFromCivil(int year, int month, int day) {
  final jdLocalNoon = julianDayFromDate(year, month, day + 0.5);
  return lunarFromJdUt(jdLocalNoon - chinaTimezoneHours / 24.0);
}

/// 某农历年的全部月份(用于日历翻页、择日)。
List<LunarMonthInfo> lunarMonthsOfYear(int lunarYear) {
  // 农历 Y 年的正月起于 (Y-1) 年冬至的岁;其十一、十二月落在 Y 年冬至的岁
  final a = _buildSui(lunarYear - 1).months.where((m) => m.lunarYear == lunarYear);
  final b = _buildSui(lunarYear).months.where((m) => m.lunarYear == lunarYear);
  return [...a, ...b];
}

/// 农历 → 公历本地日期(本地日数)。找不到(如该年无此闰月)返回 null。
int? lunarToDayNumber(int lunarYear, int month, int day, {bool isLeap = false}) {
  for (final m in lunarMonthsOfYear(lunarYear)) {
    if (m.number == month && m.isLeap == isLeap) {
      if (day < 1 || day > m.dayCount) return null;
      return m.startDayNumber + day - 1;
    }
  }
  return null;
}

/// 该农历年的闰月月份,无闰返回 0。
int leapMonthOfYear(int lunarYear) {
  for (final m in lunarMonthsOfYear(lunarYear)) {
    if (m.isLeap) return m.number;
  }
  return 0;
}
