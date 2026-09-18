// 生成应用图标:藏青底 + 金环 + 朱砂/宣纸太极。
//
// 纯几何绘制,不依赖字体,所以在任何机器上跑结果都一样。
// 用法(在 app/ 目录下):
//   dart run tools/gen_icon.dart
// 产出:
//   android/app/src/main/res/mipmap-*/ic_launcher.png   各密度启动图标
//   android/app/src/main/res/mipmap-*/ic_launcher_round.png
//   store/icon-512.png                                  Play 商店图标(无 alpha)
//   store/feature-1024x500.png                          Play 功能图片
//   ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png  iOS 各尺寸

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

// 国风三色,与 app 主题 (lib/ui/theme.dart) 一致
const ink = (0x1F, 0x2A, 0x3A); // 藏青
const cinnabar = (0xB8, 0x40, 0x2E); // 朱砂
const paper = (0xF7, 0xF3, 0xEA); // 宣纸
const gold = (0xC9, 0xA5, 0x5A); // 金

img.ColorRgb8 c((int, int, int) t) => img.ColorRgb8(t.$1, t.$2, t.$3);

/// 画一枚方形图标。[size] 边长;[rounded] 是否裁成圆形(round 图标用)。
img.Image drawIcon(int size, {bool rounded = false, bool transparent = false}) {
  final im = img.Image(width: size, height: size, numChannels: 4);
  img.fill(im, color: img.ColorRgba8(0, 0, 0, 0));

  final cx = size / 2, cy = size / 2;
  // 背景圆角方形的圆角半径;rounded 时直接用整圆
  final corner = size * 0.22;
  final bgR = size / 2; // rounded 用
  final taijiR = size * 0.30; // 太极半径
  final ringR = size * 0.385; // 金环半径
  final ringW = size * 0.028;

  // 超采样:每个像素取 3×3 子样本做抗锯齿
  const ss = 3;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      var rSum = 0.0, gSum = 0.0, bSum = 0.0, aSum = 0.0;
      for (var sy = 0; sy < ss; sy++) {
        for (var sx = 0; sx < ss; sx++) {
          final px = x + (sx + 0.5) / ss;
          final py = y + (sy + 0.5) / ss;
          final (sr, sg, sb, sa) = _sample(px, py, cx, cy, size, corner, bgR, taijiR, ringR, ringW, rounded, transparent);
          rSum += sr;
          gSum += sg;
          bSum += sb;
          aSum += sa;
        }
      }
      const n = ss * ss;
      im.setPixelRgba(x, y, (rSum / n).round(), (gSum / n).round(), (bSum / n).round(), (aSum / n).round());
    }
  }
  return im;
}

/// 返回该点的 RGBA。
(double, double, double, double) _sample(double px, double py, double cx, double cy, int size, double corner,
    double bgR, double taijiR, double ringR, double ringW, bool rounded, bool transparent) {
  final dx = px - cx, dy = py - cy;
  final r = math.sqrt(dx * dx + dy * dy);

  // ---- 是否在背景内 ----
  bool inBg;
  if (rounded) {
    inBg = r <= bgR;
  } else {
    // 圆角方形:到内缩矩形的距离
    final ax = (dx.abs() - (size / 2 - corner)).clamp(0.0, double.infinity);
    final ay = (dy.abs() - (size / 2 - corner)).clamp(0.0, double.infinity);
    inBg = math.sqrt(ax * ax + ay * ay) <= corner;
  }
  if (!inBg) {
    return transparent ? (0, 0, 0, 0) : (ink.$1.toDouble(), ink.$2.toDouble(), ink.$3.toDouble(), 255);
  }

  // ---- 金环 ----
  if ((r - ringR).abs() <= ringW / 2) {
    return (gold.$1.toDouble(), gold.$2.toDouble(), gold.$3.toDouble(), 255);
  }

  // ---- 太极 ----
  if (r <= taijiR) {
    final half = taijiR / 2;
    // 上半:阳(宣纸白);下半:阴(朱砂)
    final dTop = math.sqrt(dx * dx + (dy + half) * (dy + half));
    final dBot = math.sqrt(dx * dx + (dy - half) * (dy - half));
    (int, int, int) col;
    if (dTop < half) {
      col = paper;
    } else if (dBot < half) {
      col = cinnabar;
    } else {
      col = dx < 0 ? paper : cinnabar;
    }
    // 两个鱼眼
    final eye = taijiR * 0.16;
    if (dTop < eye) col = cinnabar;
    if (dBot < eye) col = paper;
    return (col.$1.toDouble(), col.$2.toDouble(), col.$3.toDouble(), 255);
  }

  // ---- 背景 ----
  return (ink.$1.toDouble(), ink.$2.toDouble(), ink.$3.toDouble(), 255);
}

/// 功能图片 1024×500:左侧图标 + 右侧文字区(文字用色块示意,实际文案在商店填)。
img.Image drawFeature() {
  const w = 1024, h = 500;
  final im = img.Image(width: w, height: h, numChannels: 3);
  // 斜向渐变背景:藏青 → 深赭
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final t = (x / w * 0.65 + y / h * 0.35).clamp(0.0, 1.0);
      final r = (ink.$1 + (0x5C - ink.$1) * t).round();
      final g = (ink.$2 + (0x2A - ink.$2) * t).round();
      final b = (ink.$3 + (0x24 - ink.$3) * t).round();
      im.setPixelRgb(x, y, r, g, b);
    }
  }
  // 左侧放一枚太极图标
  final icon = drawIcon(300, rounded: true, transparent: true);
  img.compositeImage(im, icon, dstX: 90, dstY: 100);
  return im;
}

void main() {
  final root = Directory.current.path;

  // ---- Android 启动图标 ----
  const densities = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
  densities.forEach((d, s) {
    final dir = Directory('$root/android/app/src/main/res/mipmap-$d')..createSync(recursive: true);
    File('${dir.path}/ic_launcher.png').writeAsBytesSync(img.encodePng(drawIcon(s)));
    File('${dir.path}/ic_launcher_round.png').writeAsBytesSync(img.encodePng(drawIcon(s, rounded: true, transparent: true)));
    print('android mipmap-$d  ${s}px');
  });

  // ---- Play 商店素材 ----
  final store = Directory('$root/store')..createSync(recursive: true);
  // 512 图标:Play 要求 32 位 PNG,可以有 alpha 通道但内容需不透明
  final icon512 = drawIcon(512);
  File('${store.path}/icon-512.png').writeAsBytesSync(img.encodePng(icon512));
  File('${store.path}/feature-1024x500.png').writeAsBytesSync(img.encodePng(drawFeature()));
  print('store/icon-512.png, store/feature-1024x500.png');

  // ---- iOS ----
  final iosDir = Directory('$root/ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (iosDir.existsSync()) {
    const iosSizes = [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024];
    for (final s in iosSizes) {
      // iOS 图标不能有 alpha
      final im = drawIcon(s, rounded: false);
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
      // 普通图标:圆形透明底,和 Android 圆形启动图标一致,浅色标签栏上不突兀
      File('${icons.path}/Icon-$s.png').writeAsBytesSync(img.encodePng(drawIcon(s, rounded: true, transparent: true)));
      // maskable:必须是铺满的不透明方图,系统自己套遮罩;太极圆盘居中,落在 80% 安全区内
      File('${icons.path}/Icon-maskable-$s.png').writeAsBytesSync(img.encodePng(drawIcon(s)));
    }
    File('${webDir.path}/favicon.png').writeAsBytesSync(img.encodePng(drawIcon(48, rounded: true, transparent: true)));
    print('web/icons 192/512 + maskable, favicon 48');
  }

  print('done');
}
