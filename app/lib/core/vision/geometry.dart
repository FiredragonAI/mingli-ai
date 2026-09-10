/// 二维几何小工具,手相面相特征计算共用。
library;

import 'dart:math' as math;

class Point2 {
  const Point2(this.x, this.y);
  final double x;
  final double y;

  Point2 operator +(Point2 o) => Point2(x + o.x, y + o.y);
  Point2 operator -(Point2 o) => Point2(x - o.x, y - o.y);
  Point2 operator *(double k) => Point2(x * k, y * k);
  Point2 operator /(double k) => Point2(x / k, y / k);

  double get length => math.sqrt(x * x + y * y);

  double distanceTo(Point2 o) => (this - o).length;

  static Point2 mid(Point2 a, Point2 b) => (a + b) / 2;

  Map<String, double> toJson() => {'x': _r(x), 'y': _r(y)};

  factory Point2.fromJson(Map<String, dynamic> j) =>
      Point2((j['x'] as num).toDouble(), (j['y'] as num).toDouble());

  @override
  String toString() => '(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})';
}

double _r(double v) => (v * 10000).round() / 10000;

/// 保留 3 位小数,JSON 里不带一堆浮点尾巴。
double round3(double v) => (v * 1000).round() / 1000;

/// 折线总长。
double polylineLength(List<Point2> pts) {
  var s = 0.0;
  for (var i = 1; i < pts.length; i++) {
    s += pts[i].distanceTo(pts[i - 1]);
  }
  return s;
}

/// 折线弯曲度:各点到首尾连线的最大距离 / 首尾距离。直线为 0。
double polylineCurvature(List<Point2> pts) {
  if (pts.length < 3) return 0;
  final a = pts.first, b = pts.last;
  final chord = a.distanceTo(b);
  if (chord < 1e-9) return 0;
  var maxDist = 0.0;
  for (final p in pts) {
    final d = _pointToSegment(p, a, b);
    if (d > maxDist) maxDist = d;
  }
  return maxDist / chord;
}

double _pointToSegment(Point2 p, Point2 a, Point2 b) {
  final ab = b - a;
  final t = ((p - a).x * ab.x + (p - a).y * ab.y) / (ab.x * ab.x + ab.y * ab.y);
  final tt = t.clamp(0.0, 1.0);
  final proj = a + ab * tt;
  return p.distanceTo(proj);
}

/// 两向量夹角(度)。
double angleDegrees(Point2 v1, Point2 v2) {
  final dot = v1.x * v2.x + v1.y * v2.y;
  final den = v1.length * v2.length;
  if (den < 1e-12) return 0;
  return math.acos((dot / den).clamp(-1.0, 1.0)) * 180 / math.pi;
}

/// 线段相对水平方向的倾角(度),右手系 y 向下时正值表示向右下倾。
double tiltDegrees(Point2 from, Point2 to) =>
    math.atan2(to.y - from.y, to.x - from.x) * 180 / math.pi;

/// 把点集归一化到以 [origin] 为原点、[scale] 为单位长度、[xAxis] 为 x 方向的坐标系。
List<Point2> normalizeTo(List<Point2> pts, Point2 origin, Point2 xAxis, double scale) {
  final ux = xAxis / xAxis.length;
  final uy = Point2(-ux.y, ux.x);
  return [
    for (final p in pts)
      () {
        final d = p - origin;
        return Point2((d.x * ux.x + d.y * ux.y) / scale, (d.x * uy.x + d.y * uy.y) / scale);
      }(),
  ];
}
