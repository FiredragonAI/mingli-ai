// 新版应用图标生成器:三个候选方向,纯几何、程序化、原创。
//
// 要求:不用八卦/太极;兼顾神秘感(星象、晶体、命眼)与科技感(HUD 圆环、棱面、节点图),
// 覆盖命理 + 性格测试 + 全部功能的气质。深靛蓝到紫的底 + 青色/金色发光线条。
//
//   dart run tools/gen_icon_v2.dart preview      → store/icon-candidates/icon-{a,b,c}.png(512)+ feature-{a,b,c}.png
//   dart run tools/gen_icon_v2.dart apply <a|b|c> → 写入 Android/iOS/Play/Web 全部尺寸(与 gen_icon.dart 同一套路径)
//
// 画法:4 倍超采样再缩小,线条与圆都是抗锯齿的;发光用逐像素的径向叠加。

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

typedef Rgb = (int, int, int);

const navy = (0x0B, 0x14, 0x37); // 深靛
const violet = (0x2A, 0x1E, 0x5C); // 暗紫
const glowViolet = (0x6B, 0x4C, 0xD6);
const cyan = (0x7F, 0xE7, 0xFF);
const gold = (0xF2, 0xC1, 0x4E);
const white = (0xFF, 0xFF, 0xFF);

img.ColorRgba8 _c(Rgb c, [int a = 255]) => img.ColorRgba8(c.$1, c.$2, c.$3, a);

// ---------------------------------------------------------------- 底层画笔

/// 对角渐变底 + 两团柔光。透明模式下只画在圆角矩形/圆内。
void _background(img.Image im, {required bool rounded, required bool transparent}) {
  final s = im.width;
  final r = rounded ? s * 0.5 : s * 0.22; // 圆形 or 圆角方
  for (var y = 0; y < s; y++) {
    for (var x = 0; x < s; x++) {
      final t = ((x + y) / (2.0 * s)).clamp(0.0, 1.0);
      var rr = (navy.$1 + (violet.$1 - navy.$1) * t).round();
      var gg = (navy.$2 + (violet.$2 - navy.$2) * t).round();
      var bb = (navy.$3 + (violet.$3 - navy.$3) * t).round();
      var a = 255;
      if (transparent) {
        // 圆角矩形(或圆)之外透明
        final dx = math.max(0.0, (x - s / 2).abs() - (s / 2 - r));
        final dy = math.max(0.0, (y - s / 2).abs() - (s / 2 - r));
        final d = math.sqrt(dx * dx + dy * dy);
        a = d > r ? 0 : 255;
      }
      im.setPixelRgba(x, y, rr, gg, bb, a);
    }
  }
  _glow(im, s * 0.82, s * 0.86, s * 0.55, glowViolet, 0.55);
  _glow(im, s * 0.18, s * 0.14, s * 0.40, (0x1F, 0x7A, 0x9E), 0.35);
}

/// 径向柔光:按 (1-d/R)^2 叠加颜色,不动 alpha。
void _glow(img.Image im, double cx, double cy, double radius, Rgb c, double strength) {
  final x0 = math.max(0, (cx - radius).floor()), x1 = math.min(im.width - 1, (cx + radius).ceil());
  final y0 = math.max(0, (cy - radius).floor()), y1 = math.min(im.height - 1, (cy + radius).ceil());
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      final d = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
      if (d >= radius) continue;
      final p = im.getPixel(x, y);
      if (p.a == 0) continue;
      final k = math.pow(1 - d / radius, 2) * strength;
      im.setPixelRgba(
        x,
        y,
        math.min(255, (p.r + c.$1 * k).round()),
        math.min(255, (p.g + c.$2 * k).round()),
        math.min(255, (p.b + c.$3 * k).round()),
        p.a.toInt(),
      );
    }
  }
}

void _ring(img.Image im, double cx, double cy, double r, double thick, Rgb c, {int alpha = 255, double from = 0, double to = 360}) {
  // 用短线段画圆弧,线段够密就是平滑的圆
  final steps = (r * 2 * math.pi / 2).ceil().clamp(64, 4000);
  final a0 = from * math.pi / 180, a1 = to * math.pi / 180;
  double px = cx + r * math.cos(a0), py = cy + r * math.sin(a0);
  for (var i = 1; i <= steps; i++) {
    final a = a0 + (a1 - a0) * i / steps;
    final x = cx + r * math.cos(a), y = cy + r * math.sin(a);
    img.drawLine(im, x1: px.round(), y1: py.round(), x2: x.round(), y2: y.round(), color: _c(c, alpha), thickness: thick.round().clamp(1, 999), antialias: true);
    px = x;
    py = y;
  }
}

void _seg(img.Image im, double x1, double y1, double x2, double y2, double thick, Rgb c, {int alpha = 255}) =>
    img.drawLine(im, x1: x1.round(), y1: y1.round(), x2: x2.round(), y2: y2.round(), color: _c(c, alpha), thickness: thick.round().clamp(1, 999), antialias: true);

void _dot(img.Image im, double cx, double cy, double r, Rgb c, {int alpha = 255}) =>
    img.fillCircle(im, x: cx.round(), y: cy.round(), radius: r.round().clamp(1, 9999), color: _c(c, alpha), antialias: true);

/// 四角星(凹角),给"星点"用。
void _star4(img.Image im, double cx, double cy, double r, Rgb c, {double inner = 0.32}) {
  final pts = <img.Point>[];
  for (var i = 0; i < 8; i++) {
    final a = -math.pi / 2 + i * math.pi / 4;
    final rr = i.isEven ? r : r * inner;
    pts.add(img.Point(cx + rr * math.cos(a), cy + rr * math.sin(a)));
  }
  img.fillPolygon(im, vertices: pts, color: _c(c));
}

// ---------------------------------------------------------------- 三个方案

/// A 星轨罗盘:三层圆环 + 刻度 + 中心星 + 轨道上的金点。
void _drawA(img.Image im) {
  final s = im.width.toDouble();
  final cx = s / 2, cy = s / 2;
  // 外环 + 刻度(每 6° 一格,每 30° 加长):HUD 的味道
  _ring(im, cx, cy, s * 0.40, s * 0.012, cyan, alpha: 230);
  for (var i = 0; i < 60; i++) {
    final a = i * 6 * math.pi / 180;
    final long = i % 5 == 0;
    final r1 = s * 0.40 - s * (long ? 0.045 : 0.025), r2 = s * 0.40 - s * 0.008;
    _seg(im, cx + r1 * math.cos(a), cy + r1 * math.sin(a), cx + r2 * math.cos(a), cy + r2 * math.sin(a), s * (long ? 0.010 : 0.006), cyan, alpha: long ? 230 : 140);
  }
  // 中环:三段金色弧,像在转的轨道
  for (final start in [-120.0, 0.0, 120.0]) {
    _ring(im, cx, cy, s * 0.29, s * 0.010, gold, alpha: 235, from: start, to: start + 80);
  }
  // 内环:细青环
  _ring(im, cx, cy, s * 0.18, s * 0.007, cyan, alpha: 170);
  // 中心星 + 光
  _glow(im, cx, cy, s * 0.20, cyan, 0.9);
  _star4(im, cx, cy, s * 0.115, white);
  _star4(im, cx, cy, s * 0.06, cyan, inner: 0.4);
  // 轨道上的金点
  final a = -40 * math.pi / 180;
  final px = cx + s * 0.29 * math.cos(a), py = cy + s * 0.29 * math.sin(a);
  _glow(im, px, py, s * 0.08, gold, 1.0);
  _dot(im, px, py, s * 0.024, gold);
  // 零星星点
  for (final (x, y, r) in [(0.16, 0.22, 0.008), (0.82, 0.18, 0.006), (0.86, 0.72, 0.007), (0.20, 0.80, 0.005)]) {
    _dot(im, s * x, s * y, s * r, white, alpha: 200);
  }
}

/// B 玄机棱晶:竖长六边形晶体,三个棱面,右侧折射出三道光。
void _drawB(img.Image im) {
  final s = im.width.toDouble();
  img.Point p(double x, double y) => img.Point(s * x, s * y);
  _glow(im, s * 0.5, s * 0.52, s * 0.42, glowViolet, 0.8);
  // 三个面:左面深蓝、右面紫、顶盖浅
  img.fillPolygon(im, vertices: [p(0.50, 0.12), p(0.32, 0.32), p(0.34, 0.72), p(0.50, 0.88), p(0.50, 0.40)], color: _c((0x3E, 0x56, 0xC9)));
  img.fillPolygon(im, vertices: [p(0.50, 0.12), p(0.68, 0.32), p(0.66, 0.72), p(0.50, 0.88), p(0.50, 0.40)], color: _c((0x8C, 0x6B, 0xE8)));
  img.fillPolygon(im, vertices: [p(0.50, 0.12), p(0.32, 0.32), p(0.50, 0.40), p(0.68, 0.32)], color: _c((0xA9, 0xC9, 0xFF)));
  // 轮廓与棱线
  final outline = [p(0.50, 0.12), p(0.68, 0.32), p(0.66, 0.72), p(0.50, 0.88), p(0.34, 0.72), p(0.32, 0.32)];
  for (var i = 0; i < outline.length; i++) {
    final q = outline[(i + 1) % outline.length];
    _seg(im, outline[i].x.toDouble(), outline[i].y.toDouble(), q.x.toDouble(), q.y.toDouble(), s * 0.010, cyan, alpha: 235);
  }
  _seg(im, s * 0.50, s * 0.40, s * 0.50, s * 0.88, s * 0.007, cyan, alpha: 160);
  _seg(im, s * 0.32, s * 0.32, s * 0.50, s * 0.40, s * 0.007, cyan, alpha: 160);
  _seg(im, s * 0.68, s * 0.32, s * 0.50, s * 0.40, s * 0.007, cyan, alpha: 160);
  // 折射出的三道光:金 / 白 / 青
  final ox = s * 0.66, oy = s * 0.52;
  for (final (ang, col, len) in [(-14.0, gold, 0.26), (0.0, white, 0.30), (14.0, cyan, 0.26)]) {
    final a = ang * math.pi / 180;
    _seg(im, ox, oy, ox + s * len * math.cos(a), oy + s * len * math.sin(a), s * 0.012, col, alpha: 220);
  }
  _glow(im, ox, oy, s * 0.10, white, 0.9);
  // 高光点与一颗小星
  _dot(im, s * 0.44, s * 0.30, s * 0.014, white, alpha: 220);
  _star4(im, s * 0.80, s * 0.22, s * 0.045, white);
}

/// C 命眼星图:杏仁形眼 + 虹膜里的节点星图 + 金色瞳。
void _drawC(img.Image im) {
  final s = im.width.toDouble();
  final cx = s / 2, cy = s / 2;
  // 眼睑:上下两条弧,用大圆的一段来画
  void lid(bool upper) {
    final bulge = s * 0.20;
    final w = s * 0.36;
    // 通过三点的圆:端点 (cx±w, cy),顶点 (cx, cy∓bulge)
    final r = (w * w + bulge * bulge) / (2 * bulge);
    final oy = upper ? cy + (r - bulge) : cy - (r - bulge);
    final half = math.asin(w / r) * 180 / math.pi;
    _ring(im, cx, oy, r, s * 0.020, cyan, alpha: 240, from: upper ? -90 - half : 90 - half, to: upper ? -90 + half : 90 + half);
  }

  lid(true);
  lid(false);
  // 虹膜
  _glow(im, cx, cy, s * 0.24, (0x2F, 0x9E, 0xC8), 0.6);
  _ring(im, cx, cy, s * 0.15, s * 0.010, gold, alpha: 235);
  // 节点星图
  final nodes = [(0.00, -0.10), (0.09, -0.04), (0.07, 0.08), (-0.06, 0.09), (-0.10, -0.02), (0.01, 0.01)];
  final edges = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (5, 0), (5, 2), (5, 4)];
  for (final (a, b) in edges) {
    _seg(im, cx + s * nodes[a].$1, cy + s * nodes[a].$2, cx + s * nodes[b].$1, cy + s * nodes[b].$2, s * 0.006, cyan, alpha: 190);
  }
  for (final (x, y) in nodes) {
    _dot(im, cx + s * x, cy + s * y, s * 0.012, white, alpha: 240);
  }
  // 瞳
  _glow(im, cx, cy, s * 0.08, gold, 1.0);
  _dot(im, cx, cy, s * 0.036, gold);
  // 眼外的一小片星座
  final con = [(0.78, 0.20), (0.86, 0.28), (0.82, 0.38)];
  _seg(im, s * con[0].$1, s * con[0].$2, s * con[1].$1, s * con[1].$2, s * 0.005, cyan, alpha: 150);
  _seg(im, s * con[1].$1, s * con[1].$2, s * con[2].$1, s * con[2].$2, s * 0.005, cyan, alpha: 150);
  for (final (x, y) in con) {
    _dot(im, s * x, s * y, s * 0.009, white, alpha: 220);
  }
  _dot(im, s * 0.16, s * 0.78, s * 0.008, white, alpha: 200);
  _dot(im, s * 0.22, s * 0.86, s * 0.006, white, alpha: 200);
}

// ---------------------------------------------------------------- 组装

const _variants = {'a': _drawA, 'b': _drawB, 'c': _drawC};

img.Image drawIcon(String variant, int size, {bool rounded = false, bool transparent = false}) {
  const ss = 4;
  final big = img.Image(width: size * ss, height: size * ss, numChannels: 4);
  _background(big, rounded: rounded, transparent: transparent);
  _variants[variant]!(big);
  return img.copyResize(big, width: size, height: size, interpolation: img.Interpolation.cubic);
}

/// 功能图片 1024×500:左侧图标 + 右侧几道装饰环(文字在商店里填)。
img.Image drawFeature(String variant) {
  const w = 1024, h = 500;
  final im = img.Image(width: w, height: h, numChannels: 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final t = (x / w * 0.7 + y / h * 0.3).clamp(0.0, 1.0);
      im.setPixelRgba(x, y, (navy.$1 + (violet.$1 - navy.$1) * t).round(), (navy.$2 + (violet.$2 - navy.$2) * t).round(), (navy.$3 + (violet.$3 - navy.$3) * t).round(), 255);
    }
  }
  _glow(im, 820, 420, 420, glowViolet, 0.5);
  final icon = drawIcon(variant, 300, rounded: false, transparent: true);
  img.compositeImage(im, icon, dstX: 90, dstY: 100);
  for (final (r, col, a) in [(190.0, cyan, 90), (150.0, gold, 110), (110.0, cyan, 70)]) {
    _ring(im, 760, 250, r, 2, col, alpha: a, from: 200, to: 340);
  }
  return im;
}

void main(List<String> args) {
  final root = Directory.current.path;
  if (args.isEmpty || args.first == 'preview') {
    final out = Directory('$root/store/icon-candidates')..createSync(recursive: true);
    for (final v in _variants.keys) {
      File('${out.path}/icon-$v.png').writeAsBytesSync(img.encodePng(drawIcon(v, 512, rounded: false, transparent: true)));
      File('${out.path}/feature-$v.png').writeAsBytesSync(img.encodePng(drawFeature(v)));
      print('候选 $v:icon-$v.png(512)+ feature-$v.png');
    }
    return;
  }
  if (args.first != 'apply' || args.length < 2 || !_variants.containsKey(args[1])) {
    stderr.writeln('用法:preview | apply <a|b|c>');
    exit(2);
  }
  final v = args[1];

  // ---- Android:方形(系统自己裁圆角/圆形)+ 圆形透明版 ----
  const densities = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
  densities.forEach((d, s) {
    final dir = Directory('$root/android/app/src/main/res/mipmap-$d')..createSync(recursive: true);
    File('${dir.path}/ic_launcher.png').writeAsBytesSync(img.encodePng(drawIcon(v, s)));
    File('${dir.path}/ic_launcher_round.png').writeAsBytesSync(img.encodePng(drawIcon(v, s, rounded: true, transparent: true)));
    print('android mipmap-$d  ${s}px');
  });

  // ---- Play 商店素材 ----
  final store = Directory('$root/store')..createSync(recursive: true);
  File('${store.path}/icon-512.png').writeAsBytesSync(img.encodePng(drawIcon(v, 512)));
  File('${store.path}/feature-1024x500.png').writeAsBytesSync(img.encodePng(drawFeature(v)));
  print('store/icon-512.png, store/feature-1024x500.png');

  // ---- iOS(不能有 alpha)----
  final iosDir = Directory('$root/ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (iosDir.existsSync()) {
    const iosSizes = [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024];
    for (final s in iosSizes) {
      final im = drawIcon(v, s);
      final flat = img.Image(width: s, height: s, numChannels: 3);
      img.compositeImage(flat, im);
      File('${iosDir.path}/Icon-App-$s.png').writeAsBytesSync(img.encodePng(flat));
    }
    print('ios AppIcon.appiconset  ${iosSizes.length} sizes');
  }

  // ---- Web(PWA 图标 + favicon)----
  final webDir = Directory('$root/web');
  if (webDir.existsSync()) {
    final icons = Directory('${webDir.path}/icons')..createSync(recursive: true);
    for (final s in [192, 512]) {
      File('${icons.path}/Icon-$s.png').writeAsBytesSync(img.encodePng(drawIcon(v, s, rounded: true, transparent: true)));
      File('${icons.path}/Icon-maskable-$s.png').writeAsBytesSync(img.encodePng(drawIcon(v, s)));
    }
    File('${webDir.path}/favicon.png').writeAsBytesSync(img.encodePng(drawIcon(v, 48, rounded: true, transparent: true)));
    print('web/icons 192/512 + maskable, favicon 48');
  }
  print('done: variant $v');
}
