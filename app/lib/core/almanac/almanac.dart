/// 黄历(通书)——某一天的干支、建除、值神、二十八宿、宜忌、冲煞、吉神方位。
///
/// 宜忌采用规则引擎:建除十二神给底稿,再由黄道黑道、月破岁破、
/// 杨公忌、三娘煞、受死日、四离四绝等逐条修正。每条修正都留痕,UI 可以展开"为什么"。
library;

import '../astro/julian.dart';
import '../astro/solar_terms.dart';
import '../calendar/lunar_calendar.dart';
import '../calendar/sexagenary.dart';
import 'almanac_rules.dart';

/// 黄历一日。
class AlmanacDay {
  const AlmanacDay({
    required this.dayNumber,
    required this.year,
    required this.month,
    required this.day,
    required this.weekday,
    required this.lunar,
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.solarTerm,
    required this.jianChu,
    required this.zhiShen,
    required this.isHuangDao,
    required this.xiu,
    required this.suitable,
    required this.unsuitable,
    required this.auspiciousGods,
    required this.inauspiciousGods,
    required this.notes,
    required this.clashZodiac,
    required this.clashPillar,
    required this.shaDirection,
    required this.pengZu,
    required this.joyDirection,
    required this.wealthDirection,
    required this.hourFortunes,
  });

  final int dayNumber;
  final int year;
  final int month;
  final int day;

  /// 1 = 周一 … 7 = 周日。
  final int weekday;
  final LunarDate lunar;
  final StemBranch yearPillar;
  final StemBranch monthPillar;
  final StemBranch dayPillar;

  /// 当天交节气则有值。
  final SolarTermEvent? solarTerm;

  /// 建除十二神。
  final String jianChu;

  /// 值神(青龙、明堂……)。
  final String zhiShen;
  final bool isHuangDao;

  /// 二十八宿全称,如"角木蛟"。
  final String xiu;

  final List<String> suitable;
  final List<String> unsuitable;
  final List<String> auspiciousGods;
  final List<String> inauspiciousGods;

  /// 规则命中说明。
  final List<String> notes;

  final String clashZodiac;
  final StemBranch clashPillar;
  final String shaDirection;

  /// 彭祖百忌两句。
  final List<String> pengZu;
  final String joyDirection;
  final String wealthDirection;

  /// 十二时辰吉凶。
  final List<HourFortune> hourFortunes;

  String get weekdayName => '星期${['一', '二', '三', '四', '五', '六', '日'][weekday - 1]}';
  String get zodiac => zodiacAnimals[yearPillar.branch];
  String get dateText => '$year年$month月$day日';
  String get ganZhiText => '${yearPillar.name}年 ${monthPillar.name}月 ${dayPillar.name}日';
  String get clashText => '冲$clashZodiac(${clashPillar.name})煞$shaDirection';

  Map<String, dynamic> toJson() => {
        'date': dateText,
        'weekday': weekdayName,
        'lunar': lunar.toString(),
        'ganZhi': ganZhiText,
        'zodiac': zodiac,
        'solarTerm': solarTerm?.name,
        'jianChu': jianChu,
        'zhiShen': zhiShen,
        'huangDao': isHuangDao,
        'xiu': xiu,
        'suitable': suitable,
        'unsuitable': unsuitable,
        'auspiciousGods': auspiciousGods,
        'inauspiciousGods': inauspiciousGods,
        'clash': clashText,
        'pengZu': pengZu,
        'joyDirection': joyDirection,
        'wealthDirection': wealthDirection,
        'hours': hourFortunes.map((h) => h.toJson()).toList(),
        'notes': notes,
      };
}

/// 一个时辰的吉凶。
class HourFortune {
  const HourFortune(this.branch, this.stemBranch, this.zhiShen, this.isHuangDao);
  final int branch;
  final StemBranch stemBranch;
  final String zhiShen;
  final bool isHuangDao;

  String get range {
    final start = (branch * 2 + 23) % 24;
    final end = (start + 2) % 24;
    return '${start.toString().padLeft(2, '0')}:00–${end.toString().padLeft(2, '0')}:00';
  }

  Map<String, dynamic> toJson() => {
        'hour': stemBranch.name,
        'range': range,
        'zhiShen': zhiShen,
        'huangDao': isHuangDao,
      };
}

final int _jdn19000101 = julianDayNumberLocal(julianDayFromDate(1900, 1, 1.5));

/// 生成某一天(北京时间)的黄历。
AlmanacDay almanacFor(int year, int month, int day) {
  final localNoonJd = julianDayFromDate(year, month, day + 0.5);
  final jdUt = localNoonJd - chinaTimezoneHours / 24.0;
  final dayNumber = localDayNumber(jdUt);

  // 星期:JDN 0 是周一,故 (jdn) % 7 → 0 周一
  final weekday = (dayNumber % 7) + 1;

  final sexYear = sexagenaryYearOf(jdUt);
  final yearSb = yearPillar(sexYear);
  final monthSb = monthPillar(yearSb.stem, solarTermMonthIndex(jdUt));
  final daySb = dayPillarFromDaysSince1900(dayNumber - _jdn19000101);
  final lunar = lunarFromJdUt(jdUt);
  final term = solarTermOnDay(jdUt);

  // 建除:日支与月支同为"建"
  final jianChuIdx = ((daySb.branch - monthSb.branch) % 12 + 12) % 12;
  final jianChu = jianChuNames[jianChuIdx];

  // 值神:青龙起例(以月支定青龙所在日支)
  final zhiShenIdx = zhiShenIndex(monthSb.branch, daySb.branch);
  final zhiShen = zhiShenNames[zhiShenIdx];
  final huangDao = huangDaoFlags[zhiShenIdx];

  // 二十八宿:28 日一轮,与星期锁定
  final xiuIdx = ((dayNumber - xiuAnchorDayNumber) % 28 + 28) % 28;
  final xiu = xiuNames[xiuIdx];

  // 冲煞
  final clashSb = daySb.shift(-6);
  final clashZodiac = zodiacAnimals[clashSb.branch];
  final sha = shaDirectionOf(daySb.branch);

  // 宜忌规则引擎
  final ruling = evaluateRules(
    jianChuIdx: jianChuIdx,
    isHuangDao: huangDao,
    zhiShen: zhiShen,
    daySb: daySb,
    monthSb: monthSb,
    yearSb: yearSb,
    lunar: lunar,
    isTermEve: _isTermEve(jdUt),
    termName: term?.name,
  );

  // 时辰吉凶:以日支定青龙时
  final hours = <HourFortune>[
    for (var b = 0; b < 12; b++)
      HourFortune(
        b,
        hourPillar(daySb.stem, b),
        zhiShenNames[zhiShenIndex(daySb.branch, b)],
        huangDaoFlags[zhiShenIndex(daySb.branch, b)],
      ),
  ];

  return AlmanacDay(
    dayNumber: dayNumber,
    year: year,
    month: month,
    day: day,
    weekday: weekday,
    lunar: lunar,
    yearPillar: yearSb,
    monthPillar: monthSb,
    dayPillar: daySb,
    solarTerm: term,
    jianChu: jianChu,
    zhiShen: zhiShen,
    isHuangDao: huangDao,
    xiu: xiu,
    suitable: ruling.suitable,
    unsuitable: ruling.unsuitable,
    auspiciousGods: ruling.auspiciousGods,
    inauspiciousGods: ruling.inauspiciousGods,
    notes: ruling.notes,
    clashZodiac: clashZodiac,
    clashPillar: clashSb,
    shaDirection: sha,
    pengZu: [pengZuStem[daySb.stem], pengZuBranch[daySb.branch]],
    joyDirection: joyDirectionOf(daySb.stem),
    wealthDirection: wealthDirectionOf(daySb.stem),
    hourFortunes: hours,
  );
}

/// 四离四绝:二分二至前一日为四离,四立前一日为四绝。
bool _isTermEve(double jdUt) {
  final tomorrow = solarTermOnDay(jdUt + 1.0);
  if (tomorrow == null) return false;
  const targets = {'春分', '夏至', '秋分', '冬至', '立春', '立夏', '立秋', '立冬'};
  return targets.contains(tomorrow.name);
}

/// 今天的黄历(设备本地时间视为北京时间)。
AlmanacDay almanacToday() {
  final now = DateTime.now();
  return almanacFor(now.year, now.month, now.day);
}
