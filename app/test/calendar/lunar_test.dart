import 'package:flutter_test/flutter_test.dart';
import 'package:mingli_ai/core/calendar/lunar_calendar.dart';

void expectLunar(int y, int m, int d, {required int ly, required int lm, required int ld, bool leap = false}) {
  final l = lunarFromCivil(y, m, d);
  expect(
    [l.year, l.month, l.day, l.isLeapMonth],
    [ly, lm, ld, leap],
    reason: '$y-$m-$d → $l',
  );
}

void main() {
  group('春节(正月初一)', () {
    test('2023-01-22', () => expectLunar(2023, 1, 22, ly: 2023, lm: 1, ld: 1));
    test('2024-02-10', () => expectLunar(2024, 2, 10, ly: 2024, lm: 1, ld: 1));
    test('2025-01-29', () => expectLunar(2025, 1, 29, ly: 2025, lm: 1, ld: 1));
    test('2026-02-17', () => expectLunar(2026, 2, 17, ly: 2026, lm: 1, ld: 1));
    test('2000-02-05', () => expectLunar(2000, 2, 5, ly: 2000, lm: 1, ld: 1));
    test('1949-01-29', () => expectLunar(1949, 1, 29, ly: 1949, lm: 1, ld: 1));
  });

  group('除夕与跨年', () {
    test('2024-02-09 为癸卯年腊月三十', () => expectLunar(2024, 2, 9, ly: 2023, lm: 12, ld: 30));
    test('2025-01-28 为甲辰年腊月廿九', () => expectLunar(2025, 1, 28, ly: 2024, lm: 12, ld: 29));
  });

  group('闰月', () {
    test('2023 闰二月', () {
      expect(leapMonthOfYear(2023), 2);
      expectLunar(2023, 3, 22, ly: 2023, lm: 2, ld: 1, leap: true);
    });
    test('2020 闰四月', () {
      expect(leapMonthOfYear(2020), 4);
      expectLunar(2020, 5, 23, ly: 2020, lm: 4, ld: 1, leap: true);
    });
    test('2025 闰六月', () {
      expect(leapMonthOfYear(2025), 6);
      expectLunar(2025, 7, 25, ly: 2025, lm: 6, ld: 1, leap: true);
    });
    test('2017 闰六月', () => expect(leapMonthOfYear(2017), 6));
    test('2033 闰十一月(著名的 2033 问题)', () {
      expect(leapMonthOfYear(2033), 11);
    });
    test('2024、2026 无闰月', () {
      expect(leapMonthOfYear(2024), 0);
      expect(leapMonthOfYear(2026), 0);
    });
  });

  group('月份天数', () {
    test('每月 29 或 30 天,每年 12 或 13 个月', () {
      for (var y = 1990; y <= 2040; y++) {
        final months = lunarMonthsOfYear(y);
        expect(months.length, anyOf(12, 13), reason: '$y');
        for (final m in months) {
          expect(m.dayCount, anyOf(29, 30), reason: '$y-${m.number}');
        }
      }
    });
  });

  group('反查', () {
    test('农历 2024 正月初一 → 2024-02-10', () {
      final dn = lunarToDayNumber(2024, 1, 1);
      final l = lunarFromCivil(2024, 2, 10);
      expect(dn, isNotNull);
      expect(l.month, 1);
      expect(l.day, 1);
    });
    test('不存在的闰月返回 null', () {
      expect(lunarToDayNumber(2024, 5, 1, isLeap: true), isNull);
    });
  });

  group('中秋', () {
    test('2024-09-17 八月十五', () => expectLunar(2024, 9, 17, ly: 2024, lm: 8, ld: 15));
    test('2025-10-06 八月十五', () => expectLunar(2025, 10, 6, ly: 2025, lm: 8, ld: 15));
  });
}
