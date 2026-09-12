import 'package:flutter_test/flutter_test.dart';
import 'package:mingli_ai/core/almanac/almanac.dart';
import 'package:mingli_ai/core/bazi/bazi_chart.dart';
import 'package:mingli_ai/core/fortune/daily_fortune.dart';
import 'package:mingli_ai/core/interpret/local_interpreter.dart';
import 'package:mingli_ai/core/marriage/marriage.dart';
import 'package:mingli_ai/core/naming/name_analysis.dart';
import 'package:mingli_ai/core/zodiac/western_zodiac.dart';

/// 合规红线:本机生成的文字里不得出现这些词(见 docs/COMPLIANCE.md)。
const forbidden = ['死亡', '疾病', '癌', '车祸', '必定', '注定', '劫难', '化解', '开光', '改运'];

void main() {
  final me = computeBaziChart(const BirthInput(
    year: 1995, month: 6, day: 15, hour: 12, minute: 0,
    gender: Gender.male, longitude: 116.41, latitude: 39.9, placeName: '北京',
  ));
  final her = computeBaziChart(const BirthInput(
    year: 1996, month: 10, day: 3, hour: 20, minute: 30,
    gender: Gender.female, longitude: 121.47, latitude: 31.23, placeName: '上海',
  ));

  void checkCommon(String text, {int minLength = 600}) {
    expect(text.length, greaterThan(minLength), reason: '解读过短:${text.length} 字');
    expect(text, contains('## '), reason: '应有分段标题');
    for (final w in forbidden) {
      expect(text, isNot(contains(w)), reason: '出现违禁词「$w」');
    }
    expect(text, contains('本机规则引擎'), reason: '应有来源说明');
  }

  test('八字:有人设、白话、比喻、词典,且确定性', () {
    final t = localInterpretBazi(me);
    checkCommon(t, minLength: 1500);
    expect(t, contains('先说人话'));
    expect(t, contains('一句话人设'));
    expect(t, contains('补品'));
    expect(t, contains('术语小词典'));
    expect(t, contains('>')); // 引用块 = 趣味比喻
    expect(localInterpretBazi(me), t);
  });

  test('每日运势:分数评语与主题白话', () {
    final f = dailyFortune(me, 2026, 9, 11);
    final t = localInterpretDaily(me, f);
    checkCommon(t, minLength: 400);
    expect(t, contains('今天的主题'));
    expect(t, contains('一句话'));
  });

  test('合婚:两人画面与可执行建议', () {
    final m = analyzeMarriage(me, her);
    final t = localInterpretMarriage(m);
    checkCommon(t, minLength: 800);
    expect(t, contains('放在一起'));
    expect(t, contains('相处建议'));
    expect(t, contains('说明书'));
  });

  test('姓名:五格白话', () {
    final t = localInterpretName(analyzeName('李思晨', chart: me));
    checkCommon(t, minLength: 600);
    expect(t, contains('五格是什么'));
    expect(t, contains('主角面板'));
  });

  test('黄历:建除与值神白话 + 个人化', () {
    final a = almanacFor(2026, 9, 11);
    final t = localInterpretAlmanac(a, chart: me);
    checkCommon(t, minLength: 500);
    expect(t, contains('今天是什么日子'));
    expect(t, contains('对你个人而言'));
  });

  test('星座:趣味画面与八字对表', () {
    final z = zodiacProfile(birthJdUt: me.trueSolar.standardJdUt, longitude: 116.41, latitude: 39.9);
    final t = localInterpretZodiac(z, chart: me);
    checkCommon(t, minLength: 600);
    expect(t, contains('内在驱动'));
    expect(t, contains('别人眼里的你'));
    expect(t, contains('对一下表'));
  });

  test('所有十天干都有人设', () {
    for (var s = 0; s < 10; s++) {
      final c = computeBaziChart(BirthInput(
        year: 1990, month: 1, day: 1 + s, hour: 8, minute: 0,
        gender: Gender.female, longitude: 116.41,
      ));
      final t = localInterpretBazi(c);
      expect(t, contains('物象是'), reason: '日干 $s');
    }
  });
}
