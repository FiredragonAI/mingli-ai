// SBTI 结果海报:内容齐全、两种语言都不漏,点「分享」真的弹出海报预览。
//
// 用户反馈"结果分享不了图片"——之前只发文字。这里守住:海报里有类型码/名字/金句/
// 稀有度/落款,英文界面无汉字;分享按钮打开的是带海报与保存按钮的对话框。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mingli_ai/core/sbti/sbti.dart';
import 'package:mingli_ai/l10n/strings.dart';
import 'package:mingli_ai/services/app_state.dart';
import 'package:mingli_ai/services/storage/profile_store.dart';
import 'package:mingli_ai/ui/widgets/sbti_share_card.dart';

final _cjk = RegExp(r'[一-鿿]');

Future<AppState> _state(String lang) async {
  SharedPreferences.setMockInitialValues({'settings.language': lang});
  final state = AppState(ProfileStore());
  await state.init();
  return state;
}

SbtiResult _result() => sbtiEvaluate(List.filled(15, 0));

void main() {
  testWidgets('英文海报:类型码、英文名、金句、落款齐全,且无汉字', (tester) async {
    // 海报高度超过测试画布默认的 600px(英文金句要折两行),给个够高的画布;真实对话框本身会滚动/缩放
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = await _state('en');
    final r = _result();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(home: Scaffold(body: Center(child: SbtiPoster(result: r, s: S(state.language))))),
    ));
    await tester.pumpAndSettle();

    expect(find.text(r.type.code), findsOneWidget);
    expect(find.text(r.type.enName), findsOneWidget);
    expect(find.text(r.type.enTagline), findsOneWidget);
    expect(find.text('FateCode'), findsOneWidget);
    final leaked = <String>[];
    for (final w in tester.widgetList<Text>(find.byType(Text))) {
      final t = w.data ?? w.textSpan?.toPlainText() ?? '';
      if (_cjk.hasMatch(t)) leaked.add(t);
    }
    expect(leaked, isEmpty, reason: '英文海报漏出了中文:$leaked');
  });

  testWidgets('中文海报:中文名与「知命」落款', (tester) async {
    // 海报高度超过测试画布默认的 600px(英文金句要折两行),给个够高的画布;真实对话框本身会滚动/缩放
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = await _state('zh-Hans');
    final r = _result();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(home: Scaffold(body: Center(child: SbtiPoster(result: r, s: S(state.language))))),
    ));
    await tester.pumpAndSettle();

    expect(find.text(r.type.zhName), findsOneWidget);
    expect(find.text('知命'), findsOneWidget);
    expect(find.textContaining('SBTI 性格测试'), findsWidgets);
  });

  testWidgets('分享:弹出带海报预览与保存/分享按钮的对话框', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await _state('zh-Hans');
    final r = _result();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(child: ElevatedButton(onPressed: () => showSbtiShareCard(ctx, r), child: const Text('open'))),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(SbtiPoster), findsOneWidget, reason: '对话框里应有海报预览');
    expect(find.text('只分享文字'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    // 测试跑在桌面(Windows)上 → 是"保存图片";手机上是"分享图片"
    expect(find.byWidgetPredicate((w) => w is FilledButton), findsOneWidget);
  });
}
