import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:mingli_ai/l10n/app_language.dart';
import 'package:mingli_ai/l10n/s2t.dart';
import 'package:mingli_ai/l10n/strings.dart';

void main() {
  setUpAll(() {
    // 直接读文件,不走 rootBundle,纯 Dart 测试也能跑
    S2T.loadFromJson(File('assets/data/s2t.json').readAsStringSync());
  });

  group('简繁转换:命理场景的陷阱字', () {
    test('天干干支保持"干",地支保持"丑",吉凶保持"凶"', () {
      expect(S2T.convert('天干地支'), '天干地支');
      expect(S2T.convert('日干为甲'), '日干為甲');
      expect(S2T.convert('丑时'), '丑時');
      expect(S2T.convert('吉凶参半'), '吉凶參半');
    });

    test('历法用"曆",历史用"歷"', () {
      expect(S2T.convert('黄历'), '黃曆');
      expect(S2T.convert('农历五月'), '農曆五月');
      expect(S2T.convert('历史'), '歷史');
    });

    test('节气与生克', () {
      expect(S2T.convert('谷雨'), '穀雨');
      expect(S2T.convert('惊蛰'), '驚蟄');
      expect(S2T.convert('相生相克'), '相生相剋');
      expect(S2T.convert('克制'), '克制');
      expect(S2T.convert('刑冲合害'), '刑沖合害');
    });

    test('常见多义字', () {
      expect(S2T.convert('关系'), '關係');
      expect(S2T.convert('后来'), '後來');
      expect(S2T.convert('皇后'), '皇后');
      expect(S2T.convert('头发'), '頭髮');
      expect(S2T.convert('出发'), '出發');
      expect(S2T.convert('面相'), '面相');
      expect(S2T.convert('面条'), '麵條');
      expect(S2T.convert('这里'), '這裡');
      expect(S2T.convert('公里'), '公里');
    });

    test('术语整体', () {
      expect(S2T.convert('紫微斗数 七杀 劫财 伤官 双鱼座 狮子座 青龙 金匮 勾陈'),
          '紫微斗數 七殺 劫財 傷官 雙魚座 獅子座 青龍 金匱 勾陳');
    });

    test('非中文原样', () {
      expect(S2T.convert('Jia-Zi 2024-02-10 12:00'), 'Jia-Zi 2024-02-10 12:00');
    });
  });

  group('文案表', () {
    test('三种语言都非空且英文不含汉字', () {
      final zh = S(AppLanguage.zhHans), tw = S(AppLanguage.zhHant), en = S(AppLanguage.en);
      final probes = <String Function(S)>[
        (s) => s.appTitle, (s) => s.startChart, (s) => s.timeUnknown, (s) => s.forceLocalSub,
        (s) => s.consentDialogBody, (s) => s.disclaimer, (s) => s.hintFallback, (s) => s.noFace,
      ];
      final han = RegExp(r'[一-鿿]');
      for (final p in probes) {
        expect(p(zh), isNotEmpty);
        expect(p(tw), isNotEmpty);
        expect(p(en), isNotEmpty);
        expect(han.hasMatch(p(en)), isFalse, reason: '英文文案含汉字: ${p(en)}');
      }
      expect(tw.navAlmanac, '黃曆');
      expect(en.term('七杀'), 'Seven Killings');
      expect(tw.term('七杀'), '七殺');
      expect(en.shichen(0), startsWith('Zi'));
      expect(zh.shichen(0), '子时 23:00–01:00');
    });
  });

  test('系统语言推断', () {
    expect(AppLanguage.fromSystem(const Locale('zh', 'TW')), AppLanguage.zhHant);
    expect(AppLanguage.fromSystem(const Locale('zh', 'CN')), AppLanguage.zhHans);
    expect(AppLanguage.fromSystem(const Locale('en', 'US')), AppLanguage.en);
  });
}
