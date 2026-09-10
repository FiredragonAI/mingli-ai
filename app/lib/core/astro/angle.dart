/// 角度工具。
library;

import 'dart:math' as math;

const double degToRadFactor = math.pi / 180.0;
const double radToDegFactor = 180.0 / math.pi;

double degToRad(double deg) => deg * degToRadFactor;
double radToDeg(double rad) => rad * radToDegFactor;

/// 归一到 [0, 360)。
double normalizeDegrees(double deg) {
  final r = deg % 360.0;
  return r < 0 ? r + 360.0 : r;
}

/// 归一到 [0, 2π)。
double normalizeRadians(double rad) {
  const twoPi = 2 * math.pi;
  final r = rad % twoPi;
  return r < 0 ? r + twoPi : r;
}

/// 归一到 (-180, 180],用于求两个角度的最短差值。
double normalizeDegreesSigned(double deg) {
  var r = normalizeDegrees(deg);
  if (r > 180.0) r -= 360.0;
  return r;
}
