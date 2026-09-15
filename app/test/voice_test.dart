import 'package:flutter_test/flutter_test.dart';
import 'package:mingli_ai/core/bazi/bazi_chart.dart';
import 'package:mingli_ai/core/fortune/annual_fortune.dart';
import 'package:mingli_ai/core/fortune/daily_fortune.dart';
import 'package:mingli_ai/core/interpret/local_interpreter.dart';
import 'package:mingli_ai/core/interpret/local_interpreter_en.dart';
import 'package:mingli_ai/core/interpret/voice.dart';
import 'package:mingli_ai/core/marriage/marriage.dart';

const forbidden = ['死亡', '疾病', '癌', '车祸', '必定', '注定', '劫难', '化解', '开光', '改运', '综上所述', '总的来说'];

void main() {
  final me = computeBaziChart(const BirthInput(
    year: 1995, month: 6, day: 15, hour: 12, minute: 0,
    gender: Gender.male, longitude: 116.41, latitude: 39.9, placeName: '北京',
  ));
  final her = computeBaziChart(const BirthInput(
    year: 1996, month: 10, day: 3, hour: 20, minute: 30,
    gender: Gender.female, longitude: 121.47, latitude: 31.23, placeName: '上海',
  ));

  test('每篇解读以一级标题 + 引用金句开头', () {
    final texts = [
      localInterpretBazi(me),
      localInterpretDaily(me, dailyFortune(me, 2026, 9, 14)),
      localInterpretAnnual(me, annualFortune(me, 2026)),
      localInterpretMarriage(analyzeMarriage(me, her)),
      enInterpretBazi(me),
      enInterpretDaily(me, dailyFortune(me, 2026, 9, 14)),
      enInterpretAnnual(me, annualFortune(me, 2026)),
    ];
    for (final t in texts) {
      final lines = t.split('\n').where((l) => l.trim().isNotEmpty).toList();
      expect(lines.first, startsWith('# '), reason: '首行应为标题:${lines.first}');
      expect(lines.first.length, lessThan(60), reason: '标题要短');
      expect(lines.any((l) => l.startsWith('> ')), isTrue, reason: '应有引用金句');
      for (final w in forbidden) {
        expect(t, isNot(contains(w)), reason: '违禁词「$w」');
      }
    }
  });

  test('每日:同人同日同句,换日换句', () {
    final a1 = dailyHeadline(me, dailyFortune(me, 2026, 9, 14));
    final a2 = dailyHeadline(me, dailyFortune(me, 2026, 9, 14));
    expect(a1, a2);
    final heads = <String>{};
    for (var d = 1; d <= 20; d++) {
      heads.add(dailyHeadline(me, dailyFortune(me, 2026, 9, d)));
    }
    expect(heads.length, greaterThanOrEqualTo(4), reason: '二十天内标题应有变化');
  });

  test('每日有别做/去做,且具体到动作', () {
    final f = dailyFortune(me, 2026, 9, 14);
    final t = localInterpretDaily(me, f);
    expect(t, contains('今天别做的一件事'));
    expect(t, contains('今天去做的一件小事'));
    expect(dailyDont(me, f), startsWith('别'));
    expect(dailyDo(me, f).length, greaterThan(6));
  });

  test('八字洞察 1–3 条,每条有加粗结论', () {
    final ins = baziInsights(me);
    expect(ins.length, inInclusiveRange(1, 3));
    for (final i in ins) {
      expect(i, startsWith('**'));
    }
    expect(localInterpretBazi(me), contains('你可能没意识到的'));
  });

  test('流年:犯太岁年标题不同于普通年;别做清单 1–3 条', () {
    final offending = annualFortune(me, 2031); // 本命年
    final normal = annualFortune(me, 2026);
    expect(annualHeadline(me, offending), isNot(annualHeadline(me, normal)));
    expect(annualDonts(me, offending).first, contains('不可逆'));
    expect(annualDonts(me, normal).length, inInclusiveRange(1, 3));
  });

  test('合婚:组合名与吵架预报', () {
    final m = analyzeMarriage(me, her);
    expect(couplePairName(me, her), contains('×'));
    expect(marriageFightForecast(m), contains('最容易吵的是'));
    expect(localInterpretMarriage(m), contains('吵架预报'));
  });

  test('小标题带 emoji', () {
    final t = localInterpretBazi(me);
    final h2 = t.split('\n').where((l) => l.startsWith('## ')).toList();
    expect(h2.length, greaterThanOrEqualTo(6));
    // 至少八成小标题以非 ASCII 的符号开头
    final withEmoji = h2.where((l) => l.codeUnitAt(3) > 0x2000).length;
    expect(withEmoji / h2.length, greaterThanOrEqualTo(0.8));
  });
}
