import 'package:flutter_test/flutter_test.dart';
import 'package:mingli_ai/core/bazi/bazi_chart.dart';
import 'package:mingli_ai/core/bazi/ten_gods.dart';
import 'package:mingli_ai/core/interpret/local_interpreter.dart';
import 'package:mingli_ai/core/interpret/local_interpreter_en.dart';
import 'package:mingli_ai/core/marriage/love_forecast.dart';

const forbidden = ['死亡', '疾病', '必定', '注定', '离婚', '劫难', '化解', '开光', '改运', '一定会'];

void main() {
  final him = computeBaziChart(const BirthInput(
    year: 1995, month: 6, day: 15, hour: 12, minute: 0,
    gender: Gender.male, longitude: 116.41, latitude: 39.9, placeName: '北京',
  ));
  final her = computeBaziChart(const BirthInput(
    year: 1996, month: 10, day: 3, hour: 20, minute: 30,
    gender: Gender.female, longitude: 121.47, latitude: 31.23, placeName: '上海',
  ));

  test('男看财星,女看官杀', () {
    final a = loveForecast(him), b = loveForecast(her);
    expect(a.star.direct, TenGod.directWealth);
    expect(a.star.mixed, TenGod.indirectWealth);
    expect(a.star.element, him.dayMaster.controls);
    expect(b.star.direct, TenGod.directOfficer);
    expect(b.star.mixed, TenGod.sevenKillings);
    expect(b.star.element, her.dayMaster.controlledBy);
  });

  test('夫妻宫为日支;分数在范围内;画像四项齐全', () {
    for (final c in [him, her]) {
      final f = loveForecast(c);
      expect(f.palaceBranch, c.dayPillar.stemBranch.branch);
      for (final s in [f.overall, f.affinity, f.stability, f.romance]) {
        expect(s, inInclusiveRange(15, 98));
      }
      expect(f.spouseProfile.keys, containsAll(['气质', '性格', '相识', '方位']));
      expect(f.pattern, isNotEmpty);
      expect(f.factors, isNotEmpty);
    }
  });

  test('婚期窗口在 18–45 岁之间、按年份升序、最多 4 个、每个都有触发依据', () {
    final f = loveForecast(him);
    expect(f.windows.length, inInclusiveRange(1, 4));
    for (var i = 0; i < f.windows.length; i++) {
      final w = f.windows[i];
      expect(w.age, inInclusiveRange(18, 46));
      expect(w.triggers, isNotEmpty);
      if (i > 0) expect(w.year, greaterThan(f.windows[i - 1].year));
    }
  });

  test('配偶星状态是五种之一;确定性', () {
    final f = loveForecast(her);
    expect(['无', '清', '杂', '弱', '旺'], contains(f.star.state));
    expect(loveForecast(her).toJson().toString(), f.toJson().toString());
  });

  test('解读:标题 + 金句 + 别做/去做;无违禁词;中英文都有', () {
    for (final c in [him, her]) {
      final f = loveForecast(c);
      for (final t in [localInterpretLove(c, f), enInterpretLove(c, f)]) {
        final lines = t.split('\n').where((l) => l.trim().isNotEmpty).toList();
        expect(lines.first, startsWith('# '));
        expect(lines.any((l) => l.startsWith('> ')), isTrue);
        expect(t.length, greaterThan(700));
        for (final w in forbidden) {
          expect(t, isNot(contains(w)), reason: '违禁词「$w」');
        }
      }
      expect(localInterpretLove(c, f), contains('婚期窗口'));
      expect(localInterpretLove(c, f), contains('对方画像'));
    }
  });
}
