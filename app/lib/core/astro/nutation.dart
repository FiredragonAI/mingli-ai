/// 章动与黄赤交角(Meeus ch.22)。
///
/// 用的是 Meeus 给出的简化式,标称精度 0.5″。
/// 0.5″ 折算到太阳位置约 12 秒时间,对节气"精确到分钟"的目标绰绰有余。
library;

import 'dart:math' as math;

import 'angle.dart';

/// 章动结果,单位:度。
class Nutation {
  const Nutation(this.longitude, this.obliquity);

  /// 黄经章动 Δψ。
  final double longitude;

  /// 交角章动 Δε。
  final double obliquity;
}

/// 计算章动。[t] 为儒略世纪数(TT)。
Nutation nutation(double t) {
  // 月球升交点平黄经
  final omega = degToRad(normalizeDegrees(125.04452 - 1934.136261 * t));
  // 太阳平黄经
  final ls = degToRad(normalizeDegrees(280.4665 + 36000.7698 * t));
  // 月球平黄经
  final lm = degToRad(normalizeDegrees(218.3165 + 481267.8813 * t));

  // 单位:角秒
  final dPsiArcsec = -17.20 * math.sin(omega) -
      1.32 * math.sin(2 * ls) -
      0.23 * math.sin(2 * lm) +
      0.21 * math.sin(2 * omega);

  final dEpsArcsec = 9.20 * math.cos(omega) +
      0.57 * math.cos(2 * ls) +
      0.10 * math.cos(2 * lm) -
      0.09 * math.cos(2 * omega);

  return Nutation(dPsiArcsec / 3600.0, dEpsArcsec / 3600.0);
}

/// 平黄赤交角 ε₀,单位:度(Laskar 多项式,Meeus 22.3)。
double meanObliquity(double t) {
  final u = t / 100.0;
  const arcsec = 1 / 3600.0;
  return 23.0 +
      26.0 / 60.0 +
      21.448 * arcsec +
      arcsec *
          _poly(u, [
            0,
            -4680.93,
            -1.55,
            1999.25,
            -51.38,
            -249.67,
            -39.05,
            7.12,
            27.87,
            5.79,
            2.45,
          ]);
}

/// 真黄赤交角 ε = ε₀ + Δε,单位:度。
double trueObliquity(double t) => meanObliquity(t) + nutation(t).obliquity;

double _poly(double x, List<double> c) {
  var r = 0.0;
  for (var i = c.length - 1; i >= 0; i--) {
    r = r * x + c[i];
  }
  return r;
}
