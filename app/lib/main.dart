import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/naming/stroke_dictionary.dart';
import 'l10n/s2t.dart';
import 'services/app_state.dart';
import 'services/storage/profile_store.dart';
import 'services/vision/tflite_landmark_service.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 端侧模型自检(开发/排障用)。
  //
  // 桌面端:设 MINGLI_SELFTEST=1 启动,不进界面,结果写到临时目录后退出。
  // Android/iOS:拿不到环境变量,改用编译期开关
  //   flutter build apk --dart-define=MINGLI_SELFTEST=1
  // 结果打到系统日志(`adb logcat -s flutter`),app 照常进入界面,方便边看日志边用。
  const buildTimeSelfTest = bool.fromEnvironment('MINGLI_SELFTEST');
  final envSelfTest = Platform.environment['MINGLI_SELFTEST'] == '1';
  if (buildTimeSelfTest || envSelfTest) {
    final report = await TfliteLandmarkService.selfTest();
    if (Platform.isAndroid || Platform.isIOS) {
      // debugPrint 会被长日志截断,逐行打
      for (final line in report.split('\n')) {
        // ignore: avoid_print
        print('[SELFTEST] $line');
      }
    } else {
      final out = File('${Directory.systemTemp.path}${Platform.pathSeparator}mingli_selftest.txt');
      await out.writeAsString(report);
      exit(0);
    }
  }

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
