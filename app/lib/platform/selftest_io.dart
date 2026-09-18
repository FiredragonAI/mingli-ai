/// 端侧模型自检(开发/排障用)。
///
/// 桌面端:设环境变量 MINGLI_SELFTEST=1 启动,不进界面,结果写临时目录后退出。
/// Android/iOS:拿不到环境变量,改用编译期开关
///   flutter build apk --dart-define=MINGLI_SELFTEST=1
/// 结果打到系统日志(`adb logcat -s flutter`),app 照常进界面,方便边看日志边用。
library;

import 'dart:io';

import '../services/vision/tflite_landmark_service.dart';

Future<void> maybeRunSelfTest() async {
  const buildTime = bool.fromEnvironment('MINGLI_SELFTEST');
  final fromEnv = Platform.environment['MINGLI_SELFTEST'] == '1';
  if (!buildTime && !fromEnv) return;

  final report = await TfliteLandmarkService.selfTest();
  if (Platform.isAndroid || Platform.isIOS) {
    // debugPrint 会截断长日志,逐行打
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
