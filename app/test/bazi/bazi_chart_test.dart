import 'package:flutter_test/flutter_test.dart';
import 'package:mingli_ai/core/bazi/bazi_chart.dart';
import 'package:mingli_ai/core/bazi/five_elements.dart';
import 'package:mingli_ai/core/bazi/ten_gods.dart';
import 'package:mingli_ai/core/calendar/sexagenary.dart';

BirthInput input(int y, int m, int d, int hh, int mm,
        {Gender g = Gender.male, double lon = 120.0, bool tst = false}) =>
    BirthInput(
      year: y, month: m, day: d, hour: hh, minute: mm,
      gender: g, longitude: lon, useTrueSolarTime: tst,
    );

void main() {
  group('干支基础', () {
    test('六十甲子序号与干支互转', () {
      for (var i = 0; i < 60; i++) {
        final sb = StemBranch.fromIndex(i);
        expect(sb.index, i);
      }
      expect(StemBranch(0, 0).name, '甲子');
      expect(StemBranch(9, 11).name, '癸亥');
      expect(StemBranch(0, 10).index, 10); // 甲戌
    });
    test('年柱:1984 甲子,2024 甲辰,2025 乙巳', () {
      expect(yearPillar(1984).name, '甲子');
      expect(yearPillar(2024).name, '甲辰');
      expect(yearPillar(2025).name, '乙巳');
    });
    test('月柱五虎遁:甲年寅月丙寅,癸年丑月乙丑', () {
      expect(monthPillar(0, 0).name, '丙寅');
      expect(monthPillar(9, 11).name, '乙丑');
    });
    test('时柱五鼠遁:甲日子时甲子、午时庚午;乙日子时丙子', () {
      expect(hourPillar(0, 0).name, '甲子');
      expect(hourPillar(0, 6).name, '庚午');
      expect(hourPillar(1, 0).name, '丙子');
    });
    test('时支边界', () {
      expect(hourBranchOf(0), 0);
      expect(hourBranchOf(0.99), 0);
      expect(hourBranchOf(1), 1);
      expect(hourBranchOf(22.99), 11);
      expect(hourBranchOf(23), 0);
    });
  });

  group('日柱(锚点交叉验证)', () {
    test('2000-01-07 甲子', () {
      final c = computeBaziChart(input(2000, 1, 7, 12, 0));
      expect(c.dayPillar.name, '甲子');
    });
    test('1949-10-01 甲子', () {
      final c = computeBaziChart(input(1949, 10, 1, 12, 0));
      expect(c.dayPillar.name, '甲子');
    });
    test('2024-01-01 甲子,2024-02-10 甲辰', () {
      expect(computeBaziChart(input(2024, 1, 1, 12, 0)).dayPillar.name, '甲子');
      expect(computeBaziChart(input(2024, 2, 10, 12, 0)).dayPillar.name, '甲辰');
    });
  });

  group('四柱整体', () {
    test('2024-02-10 12:00 北京 → 甲辰 丙寅 甲辰 庚午', () {
      final c = computeBaziChart(input(2024, 2, 10, 12, 0));
      expect(c.summaryLine, '甲辰 丙寅 甲辰 庚午');
    });
    test('立春前一小时仍是癸卯年乙丑月', () {
      // 2024 立春 16:27
      final c = computeBaziChart(input(2024, 2, 4, 15, 0));
      expect(c.yearPillar.name, '癸卯');
      expect(c.monthPillar.name, '乙丑');
    });
    test('立春后一小时为甲辰年丙寅月', () {
      final c = computeBaziChart(input(2024, 2, 4, 17, 30));
      expect(c.yearPillar.name, '甲辰');
      expect(c.monthPillar.name, '丙寅');
    });
  });

  group('晚子时', () {
    test('23:30 默认算次日日柱', () {
      final a = computeBaziChart(input(2024, 1, 1, 23, 30));
      final b = computeBaziChart(input(2024, 1, 2, 0, 30));
      expect(a.dayPillar.name, b.dayPillar.name);
      expect(a.hourPillar.stemBranch.branch, 0);
    });
    test('晚子时派:日柱不换、时干按次日', () {
      final a = computeBaziChart(BirthInput(
        year: 2024, month: 1, day: 1, hour: 23, minute: 30,
        gender: Gender.male, longitude: 120, useTrueSolarTime: false,
        ziHourMode: ZiHourMode.sameDay,
      ));
      expect(a.dayPillar.name, '甲子');
      // 次日乙丑,乙日子时为丙子
      expect(a.hourPillar.name, '丙子');
    });
  });

  group('真太阳时', () {
    test('乌鲁木齐 E87.6 比北京时间慢约 2 小时 10 分', () {
      final c = computeBaziChart(input(2024, 6, 15, 12, 0, lon: 87.6, tst: true));
      expect(c.trueSolar.longitudeCorrectionMinutes, closeTo(-129.6, 0.1));
    });
    test('经度修正改变时柱', () {
      final bj = computeBaziChart(input(2024, 6, 15, 12, 30, lon: 116.4, tst: true));
      final wlmq = computeBaziChart(input(2024, 6, 15, 12, 30, lon: 87.6, tst: true));
      expect(bj.hourPillar.stemBranch.branch, 6); // 午
      expect(wlmq.hourPillar.stemBranch.branch, 5); // 巳
    });
  });

  group('十神与五行', () {
    test('甲见庚为七杀,见辛为正官,见癸为正印', () {
      expect(tenGodOf(0, 6), TenGod.sevenKillings);
      expect(tenGodOf(0, 7), TenGod.directOfficer);
      expect(tenGodOf(0, 9), TenGod.directResource);
      expect(tenGodOf(0, 0), TenGod.friend);
      expect(tenGodOf(0, 1), TenGod.robWealth);
    });
    test('五行百分比和为 100', () {
      final c = computeBaziChart(input(1990, 8, 15, 10, 0, g: Gender.female));
      final sum = Element.values.fold(0.0, (s, e) => s + c.elements.percentages[e]!);
      expect(sum, closeTo(100, 0.01));
    });
    test('用神在喜用列表首位,喜忌不重叠', () {
      final c = computeBaziChart(input(1988, 12, 3, 4, 20));
      expect(c.elements.favorable.first, c.elements.primaryUsefulGod);
      expect(c.elements.favorable.toSet().intersection(c.elements.unfavorable.toSet()), isEmpty);
    });
  });

  group('大运', () {
    test('阳年男顺行,起运在 0–10 岁间', () {
      final c = computeBaziChart(input(2024, 3, 1, 8, 0));
      expect(c.luck.forward, isTrue);
      expect(c.luck.startYears, inInclusiveRange(0, 10));
      expect(c.luck.cycles.first.pillar, c.monthPillar.stemBranch.shift(1));
    });
    test('阳年女逆行', () {
      final c = computeBaziChart(input(2024, 3, 1, 8, 0, g: Gender.female));
      expect(c.luck.forward, isFalse);
      expect(c.luck.cycles.first.pillar, c.monthPillar.stemBranch.shift(-1));
    });
    test('大运连续,每步 10 年', () {
      final c = computeBaziChart(input(1995, 5, 5, 5, 5));
      for (var i = 1; i < c.luck.cycles.length; i++) {
        expect(c.luck.cycles[i].startYear - c.luck.cycles[i - 1].startYear, 10);
      }
    });
  });

  group('JSON', () {
    test('toJson 可序列化且含关键字段', () {
      final c = computeBaziChart(input(1992, 2, 29, 23, 59, lon: 104.06, tst: true));
      final j = c.toJson();
      expect(j['pillars'], hasLength(4));
      expect(j['elements'], contains('favorable'));
      expect(j['luck'], contains('cycles'));
      expect(j['input'], isNot(contains('image')));
    });
  });
}
