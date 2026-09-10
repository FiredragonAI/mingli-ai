import 'package:flutter_test/flutter_test.dart';
import 'package:mingli_ai/core/astro/julian.dart';
import 'package:mingli_ai/core/astro/solar_terms.dart';
import 'package:mingli_ai/core/astro/sun.dart';
import 'package:mingli_ai/core/astro/delta_t.dart';

/// 把 UT 儒略日转成北京时间字符串,便于对照历书。
String beijing(double jdUt) => calendarDateFromJulianDay(jdUt + 8 / 24).toString();

/// 断言某节气的北京时间与参照值误差在 [toleranceMinutes] 内。
void expectTerm(int year, double longitude, DateTime expectedBeijing, {double toleranceMinutes = 2}) {
  final jdUt = solarTermJdUt(year, longitude);
  final expectedJd = julianDayFromDateTimeUtc(
        expectedBeijing.year,
        expectedBeijing.month,
        expectedBeijing.day,
        expectedBeijing.hour,
        expectedBeijing.minute,
        expectedBeijing.second.toDouble(),
      ) -
      8 / 24;
  final diffMinutes = (jdUt - expectedJd).abs() * 1440;
  expect(
    diffMinutes,
    lessThan(toleranceMinutes),
    reason: '期望 $expectedBeijing,实得 ${beijing(jdUt)},差 ${diffMinutes.toStringAsFixed(2)} 分',
  );
}

void main() {
  group('儒略日', () {
    test('J2000.0', () {
      expect(julianDayFromDateTimeUtc(2000, 1, 1, 12), 2451545.0);
    });
    test('往返', () {
      final jd = julianDayFromDateTimeUtc(2024, 2, 4, 8, 26, 53);
      final d = calendarDateFromJulianDay(jd);
      expect([d.year, d.month, d.day, d.hour, d.minute], [2024, 2, 4, 8, 26]);
      expect(d.second, closeTo(53, 0.01));
    });
  });

  group('ΔT', () {
    test('2020 前后约 69 秒', () {
      expect(deltaTSeconds(2020), closeTo(69.4, 1.5));
    });
    test('2000 年约 63.8 秒', () {
      expect(deltaTSeconds(2000), closeTo(63.86, 0.1));
    });
  });

  group('太阳视黄经', () {
    test('春分附近黄经接近 0/360', () {
      // 2000-03-20 07:35 UTC 春分
      final jde = jdUtToJde(julianDayFromDateTimeUtc(2000, 3, 20, 7, 35));
      final lon = sunApparentLongitude(jde);
      final wrapped = lon > 180 ? lon - 360 : lon;
      expect(wrapped, closeTo(0, 0.01));
    });
  });

  group('二十四节气(参照《中国天文年历》,北京时间)', () {
    test('2024 立春 02-04 16:27', () {
      expectTerm(2024, 315, DateTime(2024, 2, 4, 16, 27));
    });
    test('2025 立春 02-03 22:10', () {
      expectTerm(2025, 315, DateTime(2025, 2, 3, 22, 10));
    });
    test('2024 冬至 12-21 17:21', () {
      expectTerm(2024, 270, DateTime(2024, 12, 21, 17, 21));
    });
    test('2023 夏至 06-21 22:58', () {
      expectTerm(2023, 90, DateTime(2023, 6, 21, 22, 58));
    });
    test('2000 春分 03-20 15:35', () {
      expectTerm(2000, 0, DateTime(2000, 3, 20, 15, 35));
    });
    test('一年 24 个节气按时间排序且相邻约 15 天', () {
      final terms = solarTermsOfYear(2026);
      expect(terms.length, 24);
      for (var i = 1; i < terms.length; i++) {
        final gap = terms[i].jdUt - terms[i - 1].jdUt;
        expect(gap, inInclusiveRange(14.0, 16.5), reason: '${terms[i - 1].name}→${terms[i].name}');
      }
    });
    test('节气月序:立春后为寅月(0),立春前为丑月(11)', () {
      final liChun = solarTermJdUt(2024, 315);
      expect(solarTermMonthIndex(liChun + 0.01), 0);
      expect(solarTermMonthIndex(liChun - 0.01), 11);
    });
    test('干支年以立春为界', () {
      final liChun = solarTermJdUt(2024, 315);
      expect(sexagenaryYearOf(liChun + 0.001), 2024);
      expect(sexagenaryYearOf(liChun - 0.001), 2023);
    });
  });

  group('均时差', () {
    test('11 月初约 +16 分', () {
      final jde = jdUtToJde(julianDayFromDateTimeUtc(2024, 11, 3, 4));
      expect(equationOfTimeMinutes(jde), closeTo(16.4, 0.6));
    });
    test('2 月中约 −14 分', () {
      final jde = jdUtToJde(julianDayFromDateTimeUtc(2024, 2, 11, 4));
      expect(equationOfTimeMinutes(jde), closeTo(-14.2, 0.6));
    });
    test('全年在 −15 ~ +17 分之间', () {
      for (var d = 0; d < 366; d += 5) {
        final jde = jdUtToJde(julianDayFromDate(2025, 1, 1.0) + d);
        final e = equationOfTimeMinutes(jde);
        expect(e, inInclusiveRange(-15.0, 17.0), reason: 'day $d');
      }
    });
  });
}
