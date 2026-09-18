/// 端侧模型自检的平台入口。Web 上没有端侧模型,直接是空实现。
library;

export 'selftest_io.dart' if (dart.library.js_interop) 'selftest_web.dart';
