// 发往云端的盘面里不能出现姓名。
//
// 存在的理由:隐私政策(docs/privacy-policy.html)三种语言都写明「发送到解读服务器的
// 盘面数据不含你的姓名」。而 BaziChart.toJson() 原本整个嵌了 input.toJson(),
// 里面带 name——代码和承诺对不上。姓名在提示词里从未被引用(只用 input.year 判断
// 未成年),摘掉不影响解读。这个测试守住这条承诺,免得以后有人把 name 加回去。
//
// 注意:四柱、农历日期、节气偏移合起来本身就能反推出生时刻,所以政策里
// 「不含出生日期」那句是不成立的,已改写为如实披露。姓名则是真的可以不发。

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mingli_ai/core/bazi/bazi_chart.dart';
import 'package:mingli_ai/l10n/app_language.dart';
import 'package:mingli_ai/l10n/strings.dart';

void main() {
  const name = '林知远';
  const input = BirthInput(
    year: 1995,
    month: 6,
    day: 15,
    hour: 12,
    minute: 0,
    gender: Gender.male,
    longitude: 116.41,
    latitude: 39.90,
    placeName: '北京',
    name: name,
  );
  final chart = computeBaziChart(input);

  test('发往云端的盘面 JSON 里没有姓名', () {
    final payload = chart.toJson();
    expect((payload['input'] as Map).containsKey('name'), isFalse,
        reason: 'input 里不该再有 name 字段');
    expect(jsonEncode(payload).contains(name), isFalse,
        reason: '整个 payload 的任何角落都不该出现姓名');
  });

  test('本地存档仍然保留姓名(不受影响)', () {
    expect(input.toJson()['name'], name);
  });

  test('摘掉姓名没有动到解读需要的字段', () {
    final i = chart.toJson()['input'] as Map;
    // 提示词用 input.year 判断未成年;真太阳时与时柱估算也要出生时刻
    expect(i['year'], 1995);
    expect(i['month'], 6);
    expect(i['day'], 15);
    expect(i['hour'], 12);
    expect(chart.toJson()['summary'], isNotEmpty);
  });
  // 录入页那句承诺要跟代码对得上。0.1.1 起打的是云端包:点「更多 AI 解读」会把
  // 算好的盘面发给服务器,所以不能再说"信息不会上传"。姓名是真的不发(上面三个
  // 测试守着),盘面是真的要发——两件事都得说准。
  group('出生信息录入页的隐私承诺', () {
    for (final lang in AppLanguage.values) {
      test('${lang.code}:不能声称什么都不上传', () {
        final note = S(lang).privacyNote;
        expect(note, isNotEmpty);
        expect(note.contains('不会上传'), isFalse,
            reason: '云端包会上传盘面,这句话不成立');
        expect(RegExp('nothing is uploaded', caseSensitive: false).hasMatch(note), isFalse,
            reason: '英文同理');
      });
    }

    test('姓名永不上传这条要写出来(这是真的,别漏说)', () {
      expect(const S(AppLanguage.zhHans).privacyNote, contains('姓名'));
      expect(const S(AppLanguage.en).privacyNote.toLowerCase(), contains('name'));
    });
  });
}
