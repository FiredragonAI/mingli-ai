// 姓名测试页:输入框必须真的有宽度。
//
// 存在的理由:主题里 FilledButton 的 minimumSize 是 Size.fromHeight(48),
// 而 Size.fromHeight 的宽度是 double.infinity。把这样一个按钮放进 Row,
// 它会吃掉整行,同排的 Expanded 输入框被压成零宽——真机上整行只剩一条竖线,
// 名字看不见也改不了。这个测试守住输入框的宽度,免得以后再被压扁。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mingli_ai/services/app_state.dart';
import 'package:mingli_ai/services/storage/profile_store.dart';
import 'package:mingli_ai/ui/naming_screen.dart';
import 'package:mingli_ai/ui/theme.dart';

Future<AppState> _state() async {
  SharedPreferences.setMockInitialValues({'settings.language': 'zh-Hans'});
  final state = AppState(ProfileStore());
  await state.init();
  return state;
}

void main() {
  testWidgets('姓名输入框占住大半行,测算按钮不抢宽度', (tester) async {
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await _state();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      // 必须带上真实主题:这个 bug 正是主题的 filledButtonTheme 引起的,
      // 用默认主题测等于把要防的东西拿掉了
      child: MaterialApp(theme: buildTheme(Brightness.light), home: const NamingScreen()),
    ));
    await tester.pump();

    final field = tester.getSize(find.byType(TextField));
    final button = tester.getSize(find.byType(FilledButton));
    expect(field.width, greaterThan(150), reason: '输入框被挤扁了,实际宽 ${field.width}');
    expect(button.width, lessThan(200), reason: '测算按钮吃掉了整行,实际宽 ${button.width}');
    // 两者加上间距应当正好填满一行,不溢出
    expect(field.width + 12 + button.width, lessThanOrEqualTo(411 - 32 + 0.5));
  });
}
