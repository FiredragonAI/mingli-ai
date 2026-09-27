// SBTI 玩梗测试的结构与评分不变量。
//
// 内容是原创文案,改起来很随意——这里守住的是"改文案不会悄悄把玩法改坏":
// 题数/维度/选项分值、模板互不重复且都能被命中、三语没有漏翻、稀有度加起来是 100。

import 'package:flutter_test/flutter_test.dart';
import 'package:mingli_ai/core/bazi/five_elements.dart';
import 'package:mingli_ai/core/sbti/sbti.dart';

void main() {
  test('15 个维度、15 道题(用户要求不超过 20)、每维正好一题、每题三个选项且分值恰为 1/2/3', () {
    expect(sbtiDimensions.length, 15);
    expect(sbtiQuestions.length, 15);
    expect(sbtiQuestions.length, lessThanOrEqualTo(20));
    final perDim = List<int>.filled(15, 0);
    for (final q in sbtiQuestions) {
      expect(q.dim, inInclusiveRange(0, 14));
      perDim[q.dim]++;
      expect(q.options.length, 3);
      expect(q.options.map((o) => o.score).toSet(), {1, 2, 3}, reason: '题目「${q.zh}」的选项分值不是 1/2/3 各一个');
    }
    expect(perDim, everyElement(1));
  });

  test('模板 15 位、互不重复、稀有度加起来正好 100', () {
    final seen = <String>{};
    var rarity = 0;
    for (final t in sbtiTypes) {
      expect(t.profile.length, 15, reason: '${t.code} 模板长度不对');
      expect(seen.add(t.profile.map((x) => x.index).join()), isTrue, reason: '${t.code} 的模板和别的类型重复');
      rarity += t.rarityPct;
    }
    expect(rarity, 100);
  });

  test('每个类型都能被命中:按模板作答就得到它自己', () {
    for (final t in sbtiTypes) {
      final p = t.profile;
      // 每维一题:选 1 分的选项就是低档,2 分中档,3 分高档
      final want = {SbtiTier.low: 1, SbtiTier.mid: 2, SbtiTier.high: 3};
      final answers = <int>[];
      for (final q in sbtiQuestions) {
        final score = want[p[q.dim]]!;
        answers.add(q.options.indexWhere((o) => o.score == score));
      }
      final r = sbtiEvaluate(answers);
      expect(r.type.code, t.code);
      expect(r.totalDiff, 0);
      expect(r.exactMatches, 15);
      expect(r.matchPct, 100);
    }
  });

  test('评分确定、分数在 1–3 之间、越界输入会报错', () {
    final all1 = List.filled(15, 0).asMap().entries.map((e) => sbtiQuestions[e.key].options.indexWhere((o) => o.score == 1)).toList();
    final r1 = sbtiEvaluate(all1);
    final r2 = sbtiEvaluate(all1);
    expect(r1.type.code, r2.type.code);
    expect(r1.scores, everyElement(inInclusiveRange(1, 3)));
    expect(r1.tiers, everyElement(SbtiTier.low));
    expect(() => sbtiEvaluate(List.filled(14, 0)), throwsArgumentError);
    expect(() => sbtiEvaluate(List.filled(15, 3)), throwsArgumentError);
  });

  test('三语没有漏翻:题目、选项、维度、类型的英文都非空且和中文不同', () {
    for (final q in sbtiQuestions) {
      expect(q.en.trim(), isNotEmpty);
      expect(q.en, isNot(q.zh));
      for (final o in q.options) {
        expect(o.en.trim(), isNotEmpty);
      }
    }
    for (final d in sbtiDimensions) {
      for (final v in [d.en, d.enHigh, d.enLow, d.zhHigh, d.zhLow]) {
        expect(v.trim(), isNotEmpty);
      }
    }
    for (final t in sbtiTypes) {
      for (final v in [t.enName, t.enTagline, t.enRoast, t.enTip, t.zhName, t.zhTagline, t.zhRoast, t.zhTip]) {
        expect(v.trim(), isNotEmpty, reason: '${t.code} 有空文案');
      }
    }
  });

  test('命理彩蛋覆盖全部五行;分享文本带类型码', () {
    for (final e in Element.values) {
      expect(sbtiDayMasterLine(e, en: false), isNotEmpty);
      expect(sbtiDayMasterLine(e, en: true), isNotEmpty);
    }
    final r = sbtiEvaluate(List.filled(15, 0));
    expect(sbtiShareText(r, en: false), contains(r.type.code));
    expect(sbtiShareText(r, en: true), contains(r.type.code));
  });
}
