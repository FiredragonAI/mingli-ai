import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/naming/stroke_dictionary.dart';
import 'l10n/s2t.dart';
import 'platform/selftest.dart';
import 'services/app_state.dart';
import 'services/storage/profile_store.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 开发/排障用的端侧模型自检;没开开关时立即返回。
  await maybeRunSelfTest();

  // 康熙笔画字典:有文件就加载,没有就用内置兜底
  try {
    StrokeDictionary.loadFromJson(await rootBundle.loadString('assets/data/kangxi_strokes.json'));
  } catch (_) {}

  // 简繁字表:没有也能跑(只做词级修正),繁体界面会残留部分简体字
  try {
    S2T.loadFromJson(await rootBundle.loadString('assets/data/s2t.json'));
  } catch (_) {}

  final state = AppState(ProfileStore());
  await state.init();

  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const MingliApp(),
    ),
  );
}

class MingliApp extends StatelessWidget {
  const MingliApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    return MaterialApp(
      title: 'Mingli AI',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: lang.locale,
      supportedLocales: const [Locale('zh', 'CN'), Locale('zh', 'TW'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeScreen(),
    );
  }
}
