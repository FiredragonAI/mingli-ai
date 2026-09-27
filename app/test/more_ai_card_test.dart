// 「更多 AI 解读」卡在服务器不可达时的表现:提示 + 按钮灰掉,不报错、不影响别的卡。
//
// 它和 AiReadingCard 的核心区别就是没有本机兜底,所以"不可达时安静地等"是它最重要的行为;
// 网页版在没配置服务器之前,用户看到的就是这个状态。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mingli_ai/services/app_state.dart';
import 'package:mingli_ai/services/storage/profile_store.dart';
import 'package:mingli_ai/ui/widgets/more_ai_card.dart';

final _cjk = RegExp(r'[一-鿿]');

Future<AppState> _state(String lang) async {
  SharedPreferences.setMockInitialValues({'settings.language': lang});
  final state = AppState(ProfileStore());
  await state.init(); // 测试环境没有服务器,ping 失败 → serverReachable = false
  return state;
}

Widget _wrap(AppState state) => ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        home: Scaffold(body: MoreAiCard(kind: 'bazi', body: () => {'chart': <String, dynamic>{}})),
      ),
    );

void main() {
  testWidgets('服务器不可达:显示提示,按钮禁用', (tester) async {
    await tester.pumpWidget(_wrap(await _state('zh-Hans')));
    await tester.pumpAndSettle();

    expect(find.text('更多 AI 解读'), findsOneWidget);
    expect(find.textContaining('需要联网的解读服务'), findsOneWidget);
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull, reason: '不可达时按钮应禁用');
  });

  testWidgets('英文界面:整张卡无汉字', (tester) async {
    await tester.pumpWidget(_wrap(await _state('en')));
    await tester.pumpAndSettle();

    expect(find.text('More AI reading'), findsOneWidget);
    final leaked = <String>[];
    for (final w in tester.widgetList<Text>(find.byType(Text))) {
      final s = w.data ?? w.textSpan?.toPlainText() ?? '';
      if (_cjk.hasMatch(s)) leaked.add(s);
    }
    expect(leaked, isEmpty, reason: '英文界面漏出了中文:$leaked');
  });
}
