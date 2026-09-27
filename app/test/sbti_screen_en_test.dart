// SBTI 测试页在英文界面下的整段流程:介绍 → 15 题 → 结果。
//
// 存在的理由:用户明确要求"支持英文"。sbti_test.dart 只证明数据层每条都有英文,
// 这里证明界面真的把英文渲染出来了,并且结果页上没有任何一个汉字漏网——
// 比在浏览器里截图更严格,也不依赖那块时灵时不灵的预览面板。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mingli_ai/core/sbti/sbti.dart';
import 'package:mingli_ai/services/app_state.dart';
import 'package:mingli_ai/services/storage/profile_store.dart';
import 'package:mingli_ai/ui/sbti_screen.dart';

final _cjk = RegExp(r'[一-鿿]');

/// Lottie 动画是循环的,pumpAndSettle 永远等不到"稳定";推两帧就够让 setState 生效。
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('英文界面:介绍页、15 道题、结果页全程英文,且结果页无汉字', (WidgetTester tester) async {
    // 结果页是 ListView,给个够高的画布让所有卡片都进树,免得 find.text 找不到折叠区
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({'settings.language': 'en'});
    final state = AppState(ProfileStore());
    await state.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: SbtiScreen()),
      ),
    );
    await settle(tester);

    // 介绍页
    expect(find.text('SBTI Personality Test'), findsOneWidget);
    expect(find.text('Unscientific. Weirdly accurate.'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await settle(tester);

    // 15 题:每题都显示英文题干与英文选项,选第一个
    expect(sbtiQuestions.length, 15);
    for (var i = 0; i < sbtiQuestions.length; i++) {
      final q = sbtiQuestions[i];
      expect(find.text('Question ${i + 1} of 15'), findsOneWidget, reason: '第 ${i + 1} 题进度文字');
      expect(find.text(q.en), findsOneWidget, reason: '第 ${i + 1} 题题干应为英文');
      expect(find.text(q.zh), findsNothing, reason: '第 ${i + 1} 题不应出现中文题干');
      for (final o in q.options) {
        expect(find.text(o.en), findsOneWidget, reason: '第 ${i + 1} 题选项「${o.en}」');
      }
      await tester.tap(find.text(q.options[0].en));
      await settle(tester);
    }

    // 结果页:和引擎算出来的一致
    final expected = sbtiEvaluate(List.filled(15, 0)).type;
    expect(find.text('Your SBTI type'), findsOneWidget);
    expect(find.text(expected.code), findsOneWidget);
    expect(find.text(expected.enName), findsOneWidget);
    expect(find.text(expected.enTagline), findsOneWidget);
    expect(find.text(expected.enRoast), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    // 结果页上任何一个 Text 都不该含汉字(维度标签、提示、脚注都走英文)
    final leaked = <String>[];
    for (final w in tester.widgetList<Text>(find.byType(Text))) {
      final s = w.data ?? w.textSpan?.toPlainText() ?? '';
      if (_cjk.hasMatch(s)) leaked.add(s);
    }
    expect(leaked, isEmpty, reason: '英文界面的结果页里漏出了中文:$leaked');

    // 再测一次要回到介绍页
    await tester.tap(find.text('Retake'));
    await settle(tester);
    expect(find.text('Question 1 of 15'), findsOneWidget);
  });
}
