/// 原生端(Android / iOS / Windows / Linux / macOS)实现。
library;

import 'dart:io' as io;
import 'dart:typed_data';

String get osName => io.Platform.operatingSystem;

bool get isDesktop => io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS;

bool get isIOS => io.Platform.isIOS;

bool get isAndroid => io.Platform.isAndroid;

/// 端侧模型推理是否可用。Web 上 tflite_flutter 依赖 dart:ffi,没法跑。
bool get supportsOnDeviceVision => true;

Future<Uint8List> readFileBytes(String path) => io.File(path).readAsBytes();

Future<void> deleteFileQuietly(String path) async {
  try {
    await io.File(path).delete();
  } catch (_) {
    // 删不掉就算了:这是清理拍照产生的临时文件,失败不影响功能
  }
}

/// 把字节写到用户选定的路径(桌面端"另存为"用)。
Future<void> writeFileBytes(String path, Uint8List bytes) => io.File(path).writeAsBytes(bytes);

/// 系统临时目录下的一个路径,用于分享前落盘。
String tempFilePath(String name) =>
    '${io.Directory.systemTemp.path}${io.Platform.pathSeparator}$name';

/// 浏览器下载。原生端没有这个概念,调用方不会走到。
Future<void> downloadBytes(Uint8List bytes, String filename, String mimeType) async =>
    throw UnsupportedError('downloadBytes 只在 Web 端使用');
