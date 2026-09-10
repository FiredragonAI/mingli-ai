import 'package:flutter_test/flutter_test.dart';
import 'package:mingli_ai/core/almanac/almanac.dart';
import 'package:mingli_ai/core/bazi/bazi_chart.dart';
import 'package:mingli_ai/core/bazi/relations.dart';
import 'package:mingli_ai/core/fortune/daily_fortune.dart';
import 'package:mingli_ai/core/marriage/marriage.dart';
import 'package:mingli_ai/core/naming/name_analysis.dart';
import 'package:mingli_ai/core/naming/numerology.dart';
import 'package:mingli_ai/core/vision/face_features.dart';
import 'package:mingli_ai/core/vision/geometry.dart';
import 'package:mingli_ai/core/vision/palm_features.dart';
import 'package:mingli_ai/services/vision/mediapipe_face_map.dart';

void main() {
  group('地支关系', () {
    test('六合 / 六冲 / 六害 / 三合 / 相刑', () {
      expect(isSixCombine(0, 1), isTrue); // 子丑
      expect(isSixCombine(2, 11), isTrue); // 寅亥
      expect(isClash(0, 6), isTrue); // 子午
      expect(isHarm(0, 7), isTrue); // 子未
      expect(isHarm(8, 11), isTrue); // 申亥
      expect(isTripleCombineMember(8, 0), isTrue); // 申子
      expect(isTripleCombineMember(0, 4), isTrue); // 子辰
      expect(isTripleCombineMember(0, 6), isFalse);
      expect(isPunish(0, 3), isTrue); // 子卯
      expect(isPunish(2, 5), isTrue); // 寅巳
      expect(isPunish(4, 4), isTrue); // 辰辰自刑
      expect(isPunish(0, 0), isFalse);
    });
    test('四柱分析能识别三合局', () {
      // 申子辰
      final r = analyzeInteractions([0, 0, 0, 0], [8, 0, 4, 6]);
      expect(r.any((i) => i.kind == InteractionKind.branchTripleCombine), isTrue);
      expect(r.any((i) => i.kind == InteractionKind.branchClash), isTrue); // 子午
    });
    test('相破:丑辰是,子卯不是', () {
      final r1 = analyzeInteractions([0, 0, 0, 0], [1, 4, 9, 9]);
      expect(r1.any((i) => i.kind == InteractionKind.branchDestroy && i.positions.contains(0) && i.positions.contains(1)), isTrue);
      final r2 = analyzeInteractions([0, 0, 0, 0], [0, 3, 9, 9]);
      expect(r2.any((i) => i.kind == InteractionKind.branchDestroy && i.positions.contains(0) && i.positions.contains(1)), isFalse);
    });
  });

  group('黄历', () {
    test('2024-02-10 春节:甲辰年 丙寅月 甲辰日,周六', () {
      final a = almanacFor(2024, 2, 10);
      expect(a.yearPillar.name, '甲辰');
      expect(a.monthPillar.name, '丙寅');
      expect(a.dayPillar.name, '甲辰');
      expect(a.weekday, 6);
      expect(a.lunar.month, 1);
      expect(a.lunar.day, 1);
    });
    test('建除:日支同月支为建', () {
      // 找一个寅月寅日
      for (var d = 4; d <= 29; d++) {
        final a = almanacFor(2024, 2, d);
        if (a.dayPillar.branch == 2 && a.monthPillar.branch == 2) {
          expect(a.jianChu, '建');
          return;
        }
      }
      fail('未找到寅月寅日');
    });
    test('值神黄黑道各六', () {
      final a = almanacFor(2025, 6, 1);
      final huang = a.hourFortunes.where((h) => h.isHuangDao).length;
      expect(huang, 6);
    });
    test('立春当天标记节气', () {
      expect(almanacFor(2024, 2, 4).solarTerm?.name, '立春');
      expect(almanacFor(2024, 2, 5).solarTerm, isNull);
    });
    test('宜忌互斥', () {
      for (var d = 1; d <= 28; d++) {
        final a = almanacFor(2025, 3, d);
        expect(a.suitable.toSet().intersection(a.unsuitable.toSet()), isEmpty);
      }
    });
  });

  group('姓名', () {
    test('81 数理完整', () {
      expect(numerology81.length, 81);
      for (var i = 0; i < 81; i++) {
        expect(numerology81[i].number, i + 1);
      }
      expect(numberMeaningOf(82).number, 2);
      expect(numberMeaningOf(81).number, 81);
    });
    test('王伟:单姓单名五格', () {
      // 王 4,伟 11:天 5,人 15,地 12,外 2,总 15
      final n = analyzeName('王伟');
      expect(n.tian.number, 5);
      expect(n.ren.number, 15);
      expect(n.di.number, 12);
      expect(n.wai.number, 2);
      expect(n.zong.number, 15);
    });
    test('李思晨:单姓复名', () {
      // 李 7,思 9,晨 11:天 8,人 16,地 20,外 12,总 27
      final n = analyzeName('李思晨');
      expect([n.tian.number, n.ren.number, n.di.number, n.wai.number, n.zong.number], [8, 16, 20, 12, 27]);
    });
    test('复姓拆分', () {
      final (s, g) = splitName('欧阳明');
      expect(s, '欧阳');
      expect(g, '明');
    });
    test('生僻字标记未知', () {
      final n = analyzeName('王龘');
      expect(n.unknownChars, contains('龘'));
    });
  });

  group('合婚 / 运势', () {
    final a = computeBaziChart(const BirthInput(
      year: 1990, month: 5, day: 20, hour: 10, minute: 30,
      gender: Gender.male, longitude: 116.4, useTrueSolarTime: false,
    ));
    final b = computeBaziChart(const BirthInput(
      year: 1992, month: 9, day: 8, hour: 14, minute: 0,
      gender: Gender.female, longitude: 121.5, useTrueSolarTime: false,
    ));
    test('合婚分数在 0–100,六个维度', () {
      final m = analyzeMarriage(a, b);
      expect(m.overall, inInclusiveRange(0, 100));
      expect(m.dimensions.length, 6);
      expect(m.grade, isNotEmpty);
    });
    test('每日运势确定性', () {
      final f1 = dailyFortune(a, 2026, 9, 9);
      final f2 = dailyFortune(a, 2026, 9, 9);
      expect(f1.toJson(), f2.toJson());
      expect(f1.overall, inInclusiveRange(15, 98));
    });
  });

  group('影像特征', () {
    test('理想脸三停约各三分之一,五眼约 5', () {
      final f = computeFaceFeatures(syntheticIdealFace());
      for (final c in f.threeCourts) {
        expect(c, inInclusiveRange(0.30, 0.37));
      }
      expect(f.fiveEyes, closeTo(5.0, 0.3));
      expect(f.symmetry, greaterThan(0.95));
    });
    test('手型分类', () {
      // 方掌短指 → 土型
      final pts = List<Point2>.filled(21, const Point2(0, 0), growable: false).toList();
      pts[0] = const Point2(100, 300); // 腕
      pts[5] = const Point2(60, 200); // 食指根
      pts[9] = const Point2(95, 195); // 中指根
      pts[13] = const Point2(130, 200);
      pts[17] = const Point2(165, 210); // 小指根
      pts[8] = const Point2(60, 130);
      pts[12] = const Point2(95, 120); // 中指长 75,掌长 ≈ 105 → 0.71 短指
      pts[16] = const Point2(130, 130);
      pts[20] = const Point2(165, 160);
      pts[1] = const Point2(60, 280);
      pts[2] = const Point2(40, 260);
      pts[4] = const Point2(10, 230);
      final lm = HandLandmarks(points: pts, isLeftHand: true);
      final f = computePalmFeatures(lm, const []);
      expect(f.handShape, '土型');
      expect(f.toJson()['lines'], isEmpty);
    });
  });
}
