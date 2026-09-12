// 应用级冒烟测试:首次启动应直接落在"填写出生信息"页。
//
// 原文件是 `flutter create` 生成的计数器模板测试(引用不存在的 `MyApp`),
// 从未适配过本项目,替换为真正跑得动的测试。复现 `main()` 里的
// Provider 装配——`MingliApp` 本身不含 Provider,由外层包裹。

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mingli_ai/main.dart';
import 'package:mingli_ai/services/app_state.dart';
import 'package:mingli_ai/services/storage/profile_store.dart';

void main() {
  testWidgets('首次启动无档案时显示出生信息填写页', (WidgetTester tester) async {
    // 测试环境系统语言是 en_US,显式指定简体以校验中文文案
    SharedPreferences.setMockInitialValues({'settings.language': 'zh-Hans'});
    final state = AppState(ProfileStore());
    await state.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: state, child: const MingliApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('请填写出生信息'), findsOneWidget);
    expect(find.text('出生日期(公历)'), findsOneWidget);
  });
}
