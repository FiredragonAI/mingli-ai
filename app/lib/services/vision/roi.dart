/// 感兴趣区域(ROI):一个可旋转的正方形,连接"检测"与"关键点"两级。
///
/// 检测阶段给出目标的位置和倾斜角,这里把它裁成模型要的正方形并摆正;
/// 关键点阶段输出的是裁切图内的坐标,再由 [Roi.toImage] 映射回原图。
/// 正反两次变换用同一个旋转矩阵,所以不会"裁的时候转了、映射回去没转"。
library;

import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../../core/vision/geometry.dart';
import 'ssd_anchors.dart';

class Roi {
  const Roi({required this.cx, required this.cy, required this.size, required this.rotation});

  /// 中心,原图像素坐标。
  final double cx;
  final double cy;

  /// 边长,原图像素。
  final double size;

  /// 旋转角(弧度)。ROI 相对原图逆时针转过的角度。
  final double rotation;

  /// ROI 归一化坐标 (u,v ∈ [0,1]) → 原图像素。
  Point2 toImage(double u, double v) {
    final dx = (u - 0.5) * size, dy = (v - 0.5) * size;
    final c = math.cos(rotation), s = math.sin(rotation);
    return Point2(cx + dx * c - dy * s, cy + dx * s + dy * c);
  }

  /// 原图像素 → ROI 归一化坐标。
  Point2 toRoi(Point2 p) {
    final dx = p.x - cx, dy = p.y - cy;
    final c = math.cos(-rotation), s = math.sin(-rotation);
    return Point2((dx * c - dy * s) / size + 0.5, (dx * s + dy * c) / size + 0.5);
  }

  /// 覆盖整张图的 ROI(检测失败时的兜底:假定目标已填满画面)。
  factory Roi.wholeImage(img.Image im) => Roi(
        cx: im.width / 2,
        cy: im.height / 2,
        size: math.max(im.width, im.height).toDouble(),
        rotation: 0,
      );

  /// 由检测结果构造 ROI(MediaPipe DetectionsToRects + RectTransformation 规则)。
  ///
  /// [kpStart]/[kpEnd] 是用来定倾斜角的两个关键点下标,[targetAngle] 是希望
  /// 这两点连线在 ROI 内呈现的角度;[scale] 放大倍数;[shiftY] 沿 ROI 自身 y 轴的偏移。
  factory Roi.fromDetection(
    Detection d,
    img.Image im, {
    required int kpStart,
    required int kpEnd,
    required double targetAngle,
    required double scale,
    double shiftY = 0,
  }) {
    final w = im.width.toDouble(), h = im.height.toDouble();
    final p0 = d.keypoints[kpStart], p1 = d.keypoints[kpEnd];
    // 图像 y 轴向下,取负号换成数学坐标
    final angle = math.atan2(-(p1.y - p0.y) * h, (p1.x - p0.x) * w);
    final rotation = _normalize(targetAngle - angle);

    final boxW = d.width * w, boxH = d.height * h;
    var cx = d.xCenter * w, cy = d.yCenter * h;
    if (shiftY != 0) {
      cx += -boxH * shiftY * math.sin(rotation);
      cy += boxH * shiftY * math.cos(rotation);
    }
    final side = math.max(boxW, boxH) * scale;
    return Roi(cx: cx, cy: cy, size: side, rotation: rotation);
  }

  static double _normalize(double a) {
    var r = a % (2 * math.pi);
    if (r > math.pi) r -= 2 * math.pi;
    if (r < -math.pi) r += 2 * math.pi;
    return r;
  }
}

/// 把 ROI 重采样成 size×size 的浮点张量 [1][size][size][3],值域 0–1。
///
/// 双线性插值;越界像素取黑色。这是 MediaPipe ImageToTensor 的最小实现。
List<List<List<List<double>>>> warpRoiToTensor(img.Image src, Roi roi, int size) {
  final w = src.width, h = src.height;
  final rows = List.generate(size, (j) {
    final v = (j + 0.5) / size;
    return List.generate(size, (i) {
      final u = (i + 0.5) / size;
      final p = roi.toImage(u, v);
      return _sampleBilinear(src, p.x - 0.5, p.y - 0.5, w, h);
    });
  });
  return [rows];
}

List<double> _sampleBilinear(img.Image im, double x, double y, int w, int h) {
  if (x < -1 || y < -1 || x > w || y > h) return const [0.0, 0.0, 0.0];
  final x0 = x.floor(), y0 = y.floor();
  final fx = x - x0, fy = y - y0;
  List<double> px(int xi, int yi) {
    if (xi < 0 || yi < 0 || xi >= w || yi >= h) return const [0.0, 0.0, 0.0];
    final p = im.getPixel(xi, yi);
    return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
  }
  final a = px(x0, y0), b = px(x0 + 1, y0), c = px(x0, y0 + 1), d = px(x0 + 1, y0 + 1);
  return List.generate(3, (k) {
    final top = a[k] * (1 - fx) + b[k] * fx;
    final bot = c[k] * (1 - fx) + d[k] * fx;
    return top * (1 - fy) + bot * fy;
  });
}
