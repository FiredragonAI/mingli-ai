/// 掌纹提取(纯 Dart,`image` 包)。
///
/// 关键点只给骨架,掌纹得从像素里抠。流程:
/// 1. 以关键点确定掌心 ROI(腕 → 四指根的四边形),并建立掌心坐标系;
/// 2. 灰度 → 直方图均衡 → 高斯模糊 → Sobel 梯度幅值 → 自适应阈值得到"暗线"掩膜;
/// 3. 连通域标记,按长度筛出主纹路,每个连通域抽样成折线;
/// 4. 按位置与走向粗分为感情线 / 智慧线 / 生命线。
///
/// 精度定位是"娱乐级可用",不是医学级。掌纹判别本身也没有客观标准,
/// 所以特征只是给大模型一个有依据的谈资,而不是结论。
library;

import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../../core/vision/geometry.dart';
import '../../core/vision/palm_features.dart';

class PalmLineExtractor {
  PalmLineExtractor({this.roiSize = 256, this.minComponentLength = 40});

  /// ROI 重采样边长。
  final int roiSize;

  /// 连通域最小像素数,低于此视为噪点。
  final int minComponentLength;

  /// 主入口。[image] 是原图,[lm] 是同一张图上的关键点。
  List<PalmLine> extract(img.Image image, HandLandmarks lm) {
    // ---- 1. 掌心坐标系:原点腕,x 轴指向小指根方向(与掌宽平行),单位掌长 ----
    final origin = lm.wrist;
    final xAxis = lm.pinkyMcp - lm.indexMcp;
    final unit = lm.palmLength;

    // ROI 四角:腕两侧外扩、四指根上沿。用仿射把它采样到 roiSize² 的方格
    final baseMid = Point2.mid(lm.indexMcp, lm.pinkyMcp);
    final up = (baseMid - origin) / (baseMid - origin).length;
    final right = xAxis / xAxis.length;
    final halfW = lm.palmWidth * 0.65;
    final roiOrigin = origin - right * halfW - up * (unit * 0.05);
    final roiRight = right * (halfW * 2);
    final roiUp = up * (unit * 1.05);

    final roi = img.Image(width: roiSize, height: roiSize, numChannels: 1);
    for (var y = 0; y < roiSize; y++) {
      for (var x = 0; x < roiSize; x++) {
        final fx = x / (roiSize - 1);
        final fy = 1 - y / (roiSize - 1); // 图像 y 向下,ROI 顶部对应指根
        final src = roiOrigin + roiRight * fx + roiUp * fy;
        final sx = src.x.round().clamp(0, image.width - 1);
        final sy = src.y.round().clamp(0, image.height - 1);
        final p = image.getPixel(sx, sy);
        final gray = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
        roi.setPixelR(x, y, gray);
      }
    }

    // ---- 2. 增强与边缘 ----
    var g = img.normalize(roi, min: 0, max: 255);
    g = img.gaussianBlur(g, radius: 1);
    final mask = _darkLineMask(g);

    // ---- 3. 连通域 ----
    final comps = _connectedComponents(mask, roiSize, roiSize);
    comps.removeWhere((c) => c.length < minComponentLength);
    comps.sort((a, b) => b.length.compareTo(a.length));

    // ---- 4. 转折线、归一化到掌心坐标(x: 0..1 左→右,y: 0..1 腕→指根),分类 ----
    final lines = <PalmLine>[];
    final used = <String>{};
    for (final c in comps.take(8)) {
      final poly = _componentToPolyline(c, roiSize);
      final norm = [
        for (final p in poly) Point2(p.x / (roiSize - 1), 1 - p.y / (roiSize - 1)),
      ];
      final name = _classify(norm);
      if (name == null || used.contains(name)) continue;
      used.add(name);
      lines.add(PalmLine(name: name, points: norm, segments: 1));
      if (used.length == 3) break;
    }

    // 同一条线被切成两段时,把第二段并入并记为断裂
    for (final c in comps.skip(8).take(8)) {
      final poly = _componentToPolyline(c, roiSize);
      final norm = [for (final p in poly) Point2(p.x / (roiSize - 1), 1 - p.y / (roiSize - 1))];
      final name = _classify(norm);
      final idx = lines.indexWhere((l) => l.name == name);
      if (idx >= 0) {
        final merged = [...lines[idx].points, ...norm]..sort((a, b) => a.x.compareTo(b.x));
        lines[idx] = PalmLine(name: lines[idx].name, points: merged, segments: lines[idx].segments + 1);
      }
    }
    return lines;
  }

  /// 暗线掩膜:像素比局部均值暗超过阈值即为纹路。
  List<bool> _darkLineMask(img.Image g) {
    final w = g.width, h = g.height;
    final mask = List<bool>.filled(w * h, false);
    const win = 7;
    for (var y = win; y < h - win; y++) {
      for (var x = win; x < w - win; x++) {
        var sum = 0;
        for (var dy = -win; dy <= win; dy += 3) {
          for (var dx = -win; dx <= win; dx += 3) {
            sum += g.getPixel(x + dx, y + dy).r.toInt();
          }
        }
        const n = 25; // (2*7/3+1)^2 ≈ 5×5 采样
        final mean = sum / n;
        final v = g.getPixel(x, y).r;
        if (mean - v > 14) mask[y * w + x] = true;
      }
    }
    return mask;
  }

  List<List<int>> _connectedComponents(List<bool> mask, int w, int h) {
    final labels = List<int>.filled(w * h, 0);
    final comps = <List<int>>[];
    var next = 1;
    final stack = <int>[];
    for (var i = 0; i < w * h; i++) {
      if (!mask[i] || labels[i] != 0) continue;
      final comp = <int>[];
      stack.add(i);
      labels[i] = next;
      while (stack.isNotEmpty) {
        final cur = stack.removeLast();
        comp.add(cur);
        final cx = cur % w, cy = cur ~/ w;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final nx = cx + dx, ny = cy + dy;
            if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
            final ni = ny * w + nx;
            if (mask[ni] && labels[ni] == 0) {
              labels[ni] = next;
              stack.add(ni);
            }
          }
        }
      }
      comps.add(comp);
      next++;
    }
    return comps;
  }

  /// 连通域 → 沿主方向排序并均匀抽 12 个点。
  List<Point2> _componentToPolyline(List<int> comp, int w) {
    final pts = comp.map((i) => Point2((i % w).toDouble(), (i ~/ w).toDouble())).toList();
    // 主方向:用 x、y 方差判断
    var mx = 0.0, my = 0.0;
    for (final p in pts) {
      mx += p.x;
      my += p.y;
    }
    mx /= pts.length;
    my /= pts.length;
    var vx = 0.0, vy = 0.0;
    for (final p in pts) {
      vx += (p.x - mx) * (p.x - mx);
      vy += (p.y - my) * (p.y - my);
    }
    pts.sort(vx >= vy ? (a, b) => a.x.compareTo(b.x) : (a, b) => a.y.compareTo(b.y));
    const samples = 12;
    final step = math.max(1, pts.length ~/ samples);
    final out = <Point2>[];
    for (var i = 0; i < pts.length; i += step) {
      // 同一 bin 内取均值,消除抖动
      final end = math.min(pts.length, i + step);
      var sx = 0.0, sy = 0.0;
      for (var j = i; j < end; j++) {
        sx += pts[j].x;
        sy += pts[j].y;
      }
      out.add(Point2(sx / (end - i), sy / (end - i)));
    }
    return out;
  }

  /// 按归一化掌心坐标分类。y: 0 腕 → 1 指根;x: 0 拇指侧 → 1 小指侧(右手镜像由 UI 层处理)。
  String? _classify(List<Point2> pts) {
    var cy = 0.0, cx = 0.0;
    for (final p in pts) {
      cx += p.x;
      cy += p.y;
    }
    cx /= pts.length;
    cy /= pts.length;
    final horizontal = (pts.last.x - pts.first.x).abs() > (pts.last.y - pts.first.y).abs();
    final curv = polylineCurvature(pts);

    if (horizontal && cy > 0.62) return '感情线';
    if (horizontal && cy > 0.38 && cy <= 0.62) return '智慧线';
    if (!horizontal && cx < 0.45 && curv > 0.08) return '生命线';
    if (!horizontal && cx < 0.45) return '生命线';
    return null;
  }
}
