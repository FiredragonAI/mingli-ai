/// Web 端实现。
///
/// 没有文件系统:读图一律走 XFile.readAsBytes(),存图走浏览器下载。
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

String get osName => 'web';

bool get isDesktop => false;

bool get isIOS => false;

bool get isAndroid => false;

/// tflite_flutter 依赖 dart:ffi,Web 上不可用 —— 手相/面相入口据此隐藏。
bool get supportsOnDeviceVision => false;

Future<Uint8List> readFileBytes(String path) async =>
    throw UnsupportedError('Web 端没有文件路径,请用 XFile.readAsBytes()');

Future<void> deleteFileQuietly(String path) async {
  // 浏览器里没有需要清理的临时文件
}

Future<void> writeFileBytes(String path, Uint8List bytes) async =>
    throw UnsupportedError('Web 端不能写任意路径,请用 downloadBytes()');

String tempFilePath(String name) =>
    throw UnsupportedError('Web 端没有临时目录');

/// 生成一个 Blob URL 并触发 <a download>,浏览器弹保存对话框。
Future<void> downloadBytes(Uint8List bytes, String filename, String mimeType) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  web.document.body!.appendChild(a);
  a.click();
  a.remove();
  // 立刻回收会让下载中途断掉,给浏览器留出时间
  await Future<void>.delayed(const Duration(seconds: 1));
  web.URL.revokeObjectURL(url);
}
