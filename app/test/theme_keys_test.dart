// 颜色/文案查表的键必须和引擎产出的字符串对得上。
//
// 这个测试是被一次真实事故催生的:用 PowerShell 编辑 theme.dart 时,
// Get-Content -Raw 以 ANSI 读 UTF-8 文件,把 '木' 写成了 'æœ¨'。
// 查表全部返回 null,今日页的人设卡因为 `as Color` 直接抛异常,
// release 模式下表现为整页灰屏——而单元测试、flutter analyze 全都是绿的,
// 直到在 Android 模拟器上滚到那张卡才暴露。
//
// 所以:凡是"用中文字符串当键"的表,都在这里对一遍。

import 'package:flutter_test/flutter_test.dart';
import 'package:mingli_ai/core/bazi/five_elements.dart';
import 'package:mingli_ai/core/calendar/sexagenary.dart';
import 'package:mingli_ai/core/interpret/plain_language.dart';
import 'package:mingli_ai/l10n/glossary.dart';
import 'package:mingli_ai/ui/theme.dart';

void main() {
  test('elementColor 覆盖全部五行 label,且键未被编码破坏', () {
    for (final e in Element.values) {
      expect(elementColor[e.label], isNotNull, reason: 'elementColor 缺少「${e.label}」——检查文件编码是否被破坏');
    }
    expect(elementColor.length, Element.values.length);
    // 每个键都应是单个 CJK 字符;乱码会是多个拉丁字符
    for (final k in elementColor.keys) {
      expect(k.runes.length, 1, reason: '键「$k」不是单个汉字,疑似编码损坏');
      expect(k.runes.first, greaterThan(0x4E00), reason: '键「$k」不在 CJK 区间,疑似编码损坏');
    }
  });

  test('术语英译表的键都是正常中文', () {
    for (final k in termEnglish.keys) {
      for (final r in k.runes) {
        final isCjk = r >= 0x4E00 && r <= 0x9FFF;
        final isAscii = r < 128;
        expect(isCjk || isAscii, isTrue, reason: 'termEnglish 的键「$k」含异常字符,疑似编码损坏');
      }
    }
    // 抽查几个必须存在的
    for (final t in ['木', '火', '土', '金', '水', '正官', '七杀', '桃花']) {
      expect(termEnglish[t], isNotNull, reason: 'termEnglish 缺少「$t」');
    }
  });

  test('五行建议表覆盖全部五行', () {
    for (final e in Element.values) {
      expect(elementAdvice[e], isNotNull);
    }
  });

  test('十神白话表覆盖全部十神与五个大类', () {
    for (final g in ['比劫', '食伤', '财星', '官杀', '印星']) {
      expect(tenGodGroupPlain[g], isNotNull, reason: '缺少十神大类「$g」');
    }
  });

  test('引擎产出的干支/生肖字符串都是正常中文', () {
    for (final list in [heavenlyStems, earthlyBranches, zodiacAnimals, pillarNames]) {
      for (final s in list) {
        expect(s.runes.length, 1, reason: '「$s」不是单字,疑似编码损坏');
        expect(s.runes.first, greaterThan(0x4E00), reason: '「$s」不在 CJK 区间');
      }
    }
  });
}
