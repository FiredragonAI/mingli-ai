import 'package:flutter_test/flutter_test.dart';
import 'package:mingli_ai/core/astro/julian.dart';
import 'package:mingli_ai/core/astro/solar_terms.dart';
import 'package:mingli_ai/core/zodiac/western_zodiac.dart';

/// 北京时间 → UT 儒略日。
double bj(int y, int m, int d, int h, int min) =>
    julianDayFromDateTimeUtc(y, m, d, h, min) - 8 / 24;

void main() {
  group('太阳星座', () {
    test('春分瞬间前后:双鱼 → 白羊', () {
      final equinox = solarTermJdUt(2000, 0); // 春分,黄经 0°
      expect(zodiacProfile(birthJdUt: equinox - 1 / 1440).sun, ZodiacSign.pisces);
      expect(zodiacProfile(birthJdUt: equinox + 1 / 1440).sun, ZodiacSign.aries);
    });

    test('冬至瞬间前后:射手 → 摩羯', () {
      final solstice = solarTermJdUt(2024, 270);
      expect(zodiacProfile(birthJdUt: solstice - 1 / 1440).sun, ZodiacSign.sagittarius);
      expect(zodiacProfile(birthJdUt: solstice + 1 / 1440).sun, ZodiacSign.capricorn);
    });

    test('常规日期', () {
      expect(zodiacProfile(birthJdUt: bj(1995, 6, 15, 12, 0)).sun, ZodiacSign.gemini);
      expect(zodiacProfile(birthJdUt: bj(1990, 1, 1, 12, 0)).sun, ZodiacSign.capricorn);
      expect(zodiacProfile(birthJdUt: bj(2000, 8, 8, 8, 0)).sun, ZodiacSign.leo);
      expect(zodiacProfile(birthJdUt: bj(2010, 11, 5, 0, 0)).sun, ZodiacSign.scorpio);
    });

    test('换宫日标记 nearCusp', () {
      final p = zodiacProfile(birthJdUt: solarTermJdUt(2000, 0) + 0.5);
      expect(p.nearCusp, isTrue);
      expect(p.cuspNeighbour, ZodiacSign.pisces);
      final q = zodiacProfile(birthJdUt: bj(1995, 6, 15, 12, 0));
      expect(q.nearCusp, isFalse);
    });

    test('宫内度数在 0–30', () {
      for (var m = 1; m <= 12; m++) {
        final p = zodiacProfile(birthJdUt: bj(2024, m, 10, 6, 0));
        expect(p.sunDegreeInSign, inInclusiveRange(0, 30));
      }
    });
  });

  group('上升星座', () {
    // 日出时东方地平线上正是太阳,上升点 ≈ 太阳黄经;日落时 ≈ 太阳黄经 + 180°。
    // 北京 2024-03-20 日出约 06:17、日落约 18:26(北京时间)。
    const lon = 116.41, lat = 39.90;

    test('日出时上升点接近太阳', () {
      final p = zodiacProfile(birthJdUt: bj(2024, 3, 20, 6, 17), longitude: lon, latitude: lat);
      final diff = ((p.risingLongitude! - p.sunLongitude + 540) % 360) - 180;
      expect(diff.abs(), lessThan(8), reason: '上升 ${p.risingLongitude} vs 太阳 ${p.sunLongitude}');
      // 当天春分在北京时间 11:06,日出时太阳仍在双鱼末度,上升点同样落在双鱼
      expect(p.sun, ZodiacSign.pisces);
      expect(p.rising, ZodiacSign.pisces);
    });

    test('日落时上升点接近太阳对宫', () {
      final p = zodiacProfile(birthJdUt: bj(2024, 3, 20, 18, 26), longitude: lon, latitude: lat);
      final diff = ((p.risingLongitude! - p.sunLongitude - 180 + 540) % 360) - 180;
      expect(diff.abs(), lessThan(8));
      expect(p.rising, ZodiacSign.libra);
    });

    test('一天内上升点走完一圈', () {
      final signs = <ZodiacSign>{};
      for (var h = 0; h < 24; h++) {
        signs.add(zodiacProfile(birthJdUt: bj(2024, 6, 1, h, 0), longitude: lon, latitude: lat).rising!);
      }
      expect(signs.length, 12);
    });

    test('极圈内不算上升', () {
      final p = zodiacProfile(birthJdUt: bj(2024, 6, 1, 12, 0), longitude: 25.0, latitude: 70.0);
      expect(p.rising, isNull);
    });

    test('格林尼治恒星时 J2000.0 ≈ 280.46°', () {
      expect(greenwichMeanSiderealTime(j2000), closeTo(280.46, 0.01));
    });
  });

  group('配对', () {
    test('同元素高分,火水低分,对宫加分', () {
      expect(zodiacMatch(ZodiacSign.aries, ZodiacSign.leo).score,
          greaterThan(zodiacMatch(ZodiacSign.aries, ZodiacSign.cancer).score));
      expect(zodiacMatch(ZodiacSign.aries, ZodiacSign.libra).reasons.join(), contains('对宫'));
    });

    test('对称', () {
      for (final a in ZodiacSign.values) {
        for (final b in ZodiacSign.values) {
          expect(zodiacMatch(a, b).score, zodiacMatch(b, a).score);
        }
      }
    });

    test('最佳配对返回三个且不含自身', () {
      final best = bestMatchesFor(ZodiacSign.scorpio);
      expect(best.length, 3);
      expect(best, isNot(contains(ZodiacSign.scorpio)));
    });
  });

  test('JSON 含关键字段', () {
    final j = zodiacProfile(birthJdUt: bj(1995, 6, 15, 12, 0), longitude: 116.41, latitude: 39.9).toJson();
    expect(j['sun'], isA<Map>());
    expect((j['sun'] as Map)['sign'], '双子座');
    expect(j['rising'], isA<Map>());
  });
}
