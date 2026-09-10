/// 二十四节气。
///
/// 定义:太阳视黄经每走满 15° 交一个节气。春分为 0°,立春为 315°。
/// 求解方式是对 [sunApparentLongitude] 做牛顿式迭代——太阳黄经随时间
/// 几乎线性,四五次就收敛到 1e-7 度以内。
///
/// **八字口径提醒**:换月看"节"不看"中气",换年看**立春**不看正月初一。
library;

import 'angle.dart';
import 'delta_t.dart';
import 'julian.dart';
import 'sun.dart';

/// 一个节气的定义。
class SolarTermDef {
  const SolarTermDef(this.index, this.name, this.longitude, this.isMajor);

  /// 序号,以立春为 0,顺排到大寒 23。八字的月支直接由它推。
  final int index;

  /// 中文名。
  final String name;

  /// 对应的太阳视黄经,单位:度。
  final double longitude;

  /// true = 节(换月),false = 中气(定农历月序)。
  final bool isMajor;

  @override
  String toString() => name;
}

/// 以**立春**打头的二十四节气表。索引 0..23。
///
/// 偶数索引是"节",奇数索引是"中气"。
const List<SolarTermDef> solarTermDefs = [
  SolarTermDef(0, '立春', 315, true),
  SolarTermDef(1, '雨水', 330, false),
  SolarTermDef(2, '惊蛰', 345, true),
  SolarTermDef(3, '春分', 0, false),
  SolarTermDef(4, '清明', 15, true),
  SolarTermDef(5, '谷雨', 30, false),
  SolarTermDef(6, '立夏', 45, true),
  SolarTermDef(7, '小满', 60, false),
  SolarTermDef(8, '芒种', 75, true),
  SolarTermDef(9, '夏至', 90, false),
  SolarTermDef(10, '小暑', 105, true),
  SolarTermDef(11, '大暑', 120, false),
  SolarTermDef(12, '立秋', 135, true),
  SolarTermDef(13, '处暑', 150, false),
  SolarTermDef(14, '白露', 165, true),
  SolarTermDef(15, '秋分', 180, false),
  SolarTermDef(16, '寒露', 195, true),
  SolarTermDef(17, '霜降', 210, false),
  SolarTermDef(18, '立冬', 225, true),
  SolarTermDef(19, '小雪', 240, false),
  SolarTermDef(20, '大雪', 255, true),
  SolarTermDef(21, '冬至', 270, false),
  SolarTermDef(22, '小寒', 285, true),
  SolarTermDef(23, '大寒', 300, false),
];

/// 一次具体的交节事件。
class SolarTermEvent {
  const SolarTermEvent(this.def, this.jdUt);

  final SolarTermDef def;

  /// 交节瞬间的儒略日,**UT 尺度**。要显示北京时间请 `+ 8/24`。
  final double jdUt;

  String get name => def.name;
  bool get isMajor => def.isMajor;

  @override
  String toString() => '${def.name} @ JD$jdUt';
}

/// 求 [year] 年内太阳视黄经达到 [targetLongitude] 的时刻。
///
/// 返回 UT 儒略日。[year] 用公历年,所有 24 个节气都落在该公历年内。
double solarTermJdUt(int year, double targetLongitude) {
  // 初值:元旦太阳黄经约 280°,按每天 0.9856° 线性外推
  final jan1 = julianDayFromDate(year, 1, 1.0);
  final approxDays =
      normalizeDegrees(targetLongitude - 280.0) * 365.2422 / 360.0;
  var jde = jdUtToJde(jan1 + approxDays);

  for (var i = 0; i < 10; i++) {
    final lon = sunApparentLongitude(jde);
    final diff = normalizeDegreesSigned(targetLongitude - lon);
    if (diff.abs() < 1e-8) break;
    jde += diff * 365.2422 / 360.0;
  }
  return jdeToJdUt(jde);
}

final Map<int, List<SolarTermEvent>> _yearCache = {};

/// [year] 年的二十四节气,按时间先后排序(即小寒、大寒、立春……冬至)。
List<SolarTermEvent> solarTermsOfYear(int year) {
  final cached = _yearCache[year];
  if (cached != null) return cached;

  final events = solarTermDefs
      .map((d) => SolarTermEvent(d, solarTermJdUt(year, d.longitude)))
      .toList()
    ..sort((a, b) => a.jdUt.compareTo(b.jdUt));

  // 缓存放宽到 8 年,覆盖"翻年查上一年立春"这类越界访问
  if (_yearCache.length > 8) _yearCache.clear();
  _yearCache[year] = events;
  return events;
}

/// [year] 年里指定节气的时刻(UT 儒略日)。
double solarTermOf(int year, int termIndex) =>
    solarTermJdUt(year, solarTermDefs[termIndex].longitude);

/// 距离 [jdUt] 最近的、**在它之前**(含相等)的"节"。
///
/// 月柱、大运起运都靠它。返回值一定是 `isMajor == true` 的节气。
SolarTermEvent previousMajorTerm(double jdUt) {
  final year = calendarDateFromJulianDay(jdUt).year;
  // 往前多看一年,处理 1 月 5 日这种小寒之前的情况
  final candidates = [
    ...solarTermsOfYear(year - 1),
    ...solarTermsOfYear(year),
  ].where((e) => e.isMajor && e.jdUt <= jdUt).toList();
  return candidates.last;
}

/// 距离 [jdUt] 最近的、**在它之后**的"节"。
SolarTermEvent nextMajorTerm(double jdUt) {
  final year = calendarDateFromJulianDay(jdUt).year;
  final candidates = [
    ...solarTermsOfYear(year),
    ...solarTermsOfYear(year + 1),
  ].where((e) => e.isMajor && e.jdUt > jdUt).toList();
  return candidates.first;
}

/// 该时刻所在的"节气月"序号:0 = 寅月(立春起),11 = 丑月。
///
/// 八字月支 = 寅 + 本值。
int solarTermMonthIndex(double jdUt) {
  final term = previousMajorTerm(jdUt);
  // 节的 index 是偶数 0,2,4...22,对应寅、卯、辰……丑
  return term.def.index ~/ 2;
}

/// 判断 [jdUt] 是否已过当年立春——年柱换年的唯一依据。
bool isAfterLiChun(double jdUt) {
  final year = calendarDateFromJulianDay(jdUt).year;
  return jdUt >= solarTermJdUt(year, 315);
}

/// 该时刻所属的"干支年"年份(立春为界)。
int sexagenaryYearOf(double jdUt) {
  final year = calendarDateFromJulianDay(jdUt).year;
  return isAfterLiChun(jdUt) ? year : year - 1;
}

/// 若 [jdUt] 当天恰好交节,返回该节气;否则返回 null。
///
/// [timezoneOffsetHours] 用于确定"当天"的边界,中国大陆传 8。
SolarTermEvent? solarTermOnDay(double jdUt, {double timezoneOffsetHours = 8}) {
  final tzShift = timezoneOffsetHours / 24.0;
  final dayStart = julianDayNumberLocal(jdUt + tzShift) - 0.5 - tzShift;
  final dayEnd = dayStart + 1.0;
  final year = calendarDateFromJulianDay(jdUt).year;
  for (final e in [
    ...solarTermsOfYear(year - 1),
    ...solarTermsOfYear(year),
    ...solarTermsOfYear(year + 1),
  ]) {
    if (e.jdUt >= dayStart && e.jdUt < dayEnd) return e;
  }
  return null;
}
