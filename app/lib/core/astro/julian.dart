/// 儒略日换算。
///
/// 本项目内部一律以 **儒略日(JD, UT1 尺度)** 作为时间的唯一表示,
/// 只在最外层输入输出时才转成"北京时间的年月日时分"。
/// 这样可以彻底避开时区、夏令时、跨日等一连串坑。
library;

/// 一天的秒数。
const double secondsPerDay = 86400.0;

/// J2000.0 历元的儒略日。
const double j2000 = 2451545.0;

/// 公历改历日之前(1582-10-15 之前)按儒略历处理。
/// 命理 app 实际只用 1900–2100,但历法代码不应该在边界上撒谎。
const double _gregorianStartJd = 2299160.5;

/// 由公历/儒略历日期求儒略日。
///
/// [day] 可以带小数,例如 1.5 表示 1 日 12:00。
/// 输入必须是 **UT**(世界时),不是本地时间。
double julianDayFromDate(int year, int month, double day) {
  var y = year;
  var m = month;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }

  // 先按儒略历算,再判断是否落在格里高利历区间加上世纪闰年修正
  final jdJulian =
      (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day - 1524.5;

  if (jdJulian >= _gregorianStartJd) {
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return jdJulian + b;
  }
  return jdJulian;
}

/// 由"年月日时分秒"求儒略日(UT)。
double julianDayFromDateTimeUtc(
  int year,
  int month,
  int day, [
  int hour = 0,
  int minute = 0,
  double second = 0,
]) {
  final frac = (hour + minute / 60.0 + second / 3600.0) / 24.0;
  return julianDayFromDate(year, month, day + frac);
}

/// 拆解后的日历日期。
class CalendarDate {
  const CalendarDate(
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.second,
  );

  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final double second;

  /// 当天已过去的小数天,例如 12:00 为 0.5。
  double get dayFraction =>
      (hour + minute / 60.0 + second / 3600.0) / 24.0;

  @override
  String toString() => '$year-${_p(month)}-${_p(day)} '
      '${_p(hour)}:${_p(minute)}:${_p(second.floor())}';

  static String _p(int v) => v.toString().padLeft(2, '0');
}

/// 儒略日还原为日历日期(Meeus, Astronomical Algorithms, ch.7)。
CalendarDate calendarDateFromJulianDay(double jd) {
  final shifted = jd + 0.5;
  final z = shifted.floor();
  var f = shifted - z;

  int a;
  if (z < 2299161) {
    a = z;
  } else {
    final alpha = ((z - 1867216.25) / 36524.25).floor();
    a = z + 1 + alpha - (alpha / 4).floor();
  }

  final b = a + 1524;
  final c = ((b - 122.1) / 365.25).floor();
  final d = (365.25 * c).floor();
  final e = ((b - d) / 30.6001).floor();

  final dayWithFraction = b - d - (30.6001 * e).floor() + f;
  final day = dayWithFraction.floor();
  f = dayWithFraction - day;

  final month = e < 14 ? e - 1 : e - 13;
  final year = month > 2 ? c - 4716 : c - 4715;

  // 把小数天拆成时分秒,并处理浮点误差导致的 60 进位
  var totalSeconds = f * secondsPerDay;
  var hour = (totalSeconds / 3600).floor();
  totalSeconds -= hour * 3600;
  var minute = (totalSeconds / 60).floor();
  var second = totalSeconds - minute * 60;

  if (second >= 59.9995) {
    second = 0;
    minute += 1;
  }
  if (minute >= 60) {
    minute -= 60;
    hour += 1;
  }
  // hour 溢出(24)交给上层极少数情况,这里保守钳制
  if (hour >= 24) hour = 23;

  return CalendarDate(year, month, day, hour, minute, second);
}

/// 儒略日数(JDN):以**当地午夜**为界的整数日编号。
///
/// 日柱、建除、二十八宿这类"按天走"的推算全部基于它,
/// 传入的 [jd] 必须已经是本地时(即已加过时区偏移)。
int julianDayNumberLocal(double jd) => (jd + 0.5).floor();

/// 儒略世纪数(自 J2000.0 起),供天文级数使用。
double julianCenturies(double jde) => (jde - j2000) / 36525.0;

/// 儒略千年数(自 J2000.0 起),VSOP87 用。
double julianMillennia(double jde) => (jde - j2000) / 365250.0;
