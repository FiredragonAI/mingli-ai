import 'package:flutter_test/flutter_test.dart';
import 'package:mingli_ai/core/bazi/bazi_chart.dart';
import 'package:mingli_ai/core/fortune/annual_fortune.dart';

void main() {
  // 1995 乙亥年生 → 生肖猪(亥)
  final me = computeBaziChart(const BirthInput(
    year: 1995, month: 6, day: 15, hour: 12, minute: 0,
    gender: Gender.male, longitude: 116.41, latitude: 39.9, placeName: '北京',
  ));

  group('太岁关系', () {
    test('本命年:值太岁', () => expect(taiSuiRelations(11, 11), contains(TaiSuiKind.same)));
    test('亥巳相冲', () => expect(taiSuiRelations(5, 11), contains(TaiSuiKind.clash)));
    test('亥亥自刑不重复计入值太岁之外', () {
      final r = taiSuiRelations(11, 11);
      expect(r, contains(TaiSuiKind.same));
      expect(r, isNot(contains(TaiSuiKind.punish)));
    });
    test('亥申相害', () => expect(taiSuiRelations(8, 11), contains(TaiSuiKind.harm)));
    test('亥寅六合 + 相破', () {
      final r = taiSuiRelations(2, 11);
      expect(r, contains(TaiSuiKind.combine));
      expect(r, contains(TaiSuiKind.destroy));
    });
    test('无关系为空', () => expect(taiSuiRelations(0, 11), isEmpty));
  });

  group('流年', () {
    test('2031 辛亥为本命年,标记犯太岁', () {
      final a = annualFortune(me, 2031);
      expect(a.yearPillar.name, '辛亥');
      expect(a.isOffendingTaiSui, isTrue);
      expect(a.taiSui, contains(TaiSuiKind.same));
      expect(a.nominalAge, 37);
    });
    test('2025 乙巳冲太岁', () {
      final a = annualFortune(me, 2025);
      expect(a.taiSui, contains(TaiSuiKind.clash));
      expect(a.factors.join(), contains('冲太岁'));
    });
    test('分数在范围内,十二流月齐全,最佳/留意月不重叠', () {
      final a = annualFortune(me, 2026);
      for (final s in [a.overall, a.career, a.wealth, a.love, a.health]) {
        expect(s, inInclusiveRange(15, 98));
      }
      expect(a.months.length, 12);
      expect(a.months.first.pillar.branch, 2, reason: '首月为寅');
      expect(a.bestMonths.toSet().intersection(a.cautionMonths.toSet()), isEmpty);
      expect(a.grade, isNotEmpty);
      expect(a.factors, isNotEmpty);
    });
    test('确定性', () {
      expect(annualFortune(me, 2027).toJson().toString(), annualFortune(me, 2027).toJson().toString());
    });
    test('起运前 luckPillar 为 null', () {
      expect(annualFortune(me, 1996).luckPillar, isNull);
      expect(annualFortune(me, 2026).luckPillar, isNotNull);
    });
  });
}
