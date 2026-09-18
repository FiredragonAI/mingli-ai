/// 平台差异的唯一入口。
///
/// Web 编译时 `import 'dart:io'` 本身就过不了,所以凡是要碰 Platform、File、
/// Directory 的地方一律走这里,由条件导出决定拿到哪份实现。
/// 业务代码只认这几个顶层函数,不再直接 import 'dart:io'。
library;

export 'native_io.dart' if (dart.library.js_interop) 'native_web.dart';
