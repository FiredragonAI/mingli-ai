/// 太阳位置与均时差。
///
/// 节气、真太阳时都从这里出。整个命理引擎最底层的物理量就是
/// "某一瞬间太阳的视黄经",其余都是查表和取模。
library;

import 'dart:math' as math;

import 'angle.dart';
import 'julian.dart';
import 'nutation.dart';
import 'vsop87_earth.dart';

/// 太阳的地心视位置。
class SunPosition {
  const SunPosition({
    required this.apparentLongitude,
    required this.apparentLatitude,
    required this.radiusVector,
    required this.trueLongitude,
  });

  /// 视黄经 λ,单位:度,[0,360)。**节气就是按它切的。**
  final double apparentLongitude;

  /// 视黄纬 β,单位:度(太阳几乎恒为 0,量级 1e-4)。
  final double apparentLatitude;

  /// 日地距离,单位:AU。
  final double radiusVector;

  /// 未加章动、光行差的真黄经,单位:度。
  final double trueLongitude;
}

/// 求给定 **TT 儒略日** 时刻太阳的地心视位置。
SunPosition sunPosition(double jde) {
  final tau = julianMillennia(jde);
  final t = tau * 10.0; // 儒略世纪数

  // 地球日心黄经 L(弧度)
  final l = (_series(earthL0, tau) +
          _series(earthL1, tau) * tau +
          _series(earthL2, tau) * tau * tau +
          _series(earthL3, tau) * math.pow(tau, 3) +
          _series(earthL4, tau) * math.pow(tau, 4) +
          _series(earthL5, tau) * math.pow(tau, 5)) /
      1e8;

  // 地球日心黄纬 B(弧度)
  final b = (_series(earthB0, tau) + _series(earthB1, tau) * tau) / 1e8;

  // 日地距离 R(AU)
  final r = (_series(earthR0, tau) +
          _series(earthR1, tau) * tau +
          _series(earthR2, tau) * tau * tau +
          _series(earthR3, tau) * math.pow(tau, 3) +
          _series(earthR4, tau) * math.pow(tau, 4)) /
      1e8;

  // 由日心地球位置翻成地心太阳位置
  var theta = normalizeDegrees(radToDeg(l) + 180.0);
  var beta = -radToDeg(b);

  // VSOP87 的动力学黄道 → FK5 参考系(Meeus 25.9)
  final lambdaPrime =
      degToRad(theta - 1.397 * t - 0.00031 * t * t);
  theta += -0.09033 / 3600.0;
  beta += (0.03916 / 3600.0) *
      (math.cos(lambdaPrime) - math.sin(lambdaPrime));

  final trueLongitude = normalizeDegrees(theta);

  // 章动 + 光行差 → 视黄经
  final nut = nutation(t);
  final aberration = -20.4898 / (3600.0 * r);
  final apparent = normalizeDegrees(theta + nut.longitude + aberration);

  return SunPosition(
    apparentLongitude: apparent,
    apparentLatitude: beta,
    radiusVector: r,
    trueLongitude: trueLongitude,
  );
}

/// 太阳视黄经,度。便捷入口。
double sunApparentLongitude(double jde) => sunPosition(jde).apparentLongitude;

/// 均时差(Equation of Time):真太阳时 − 平太阳时,单位:**分钟**。
///
/// 全年在 −14 ~ +16 分钟之间摆动。八字排盘换算真太阳时必须叠加它,
/// 否则 11 月初生人可能整整差掉半个时辰的边界。
double equationOfTimeMinutes(double jde) {
  final tau = julianMillennia(jde);
  final t = tau * 10.0;

  // 太阳几何平黄经(Meeus 28.2)
  final l0 = normalizeDegrees(280.4664567 +
      360007.6982779 * tau +
      0.03032028 * tau * tau +
      math.pow(tau, 3) / 49931.0 -
      math.pow(tau, 4) / 15300.0 -
      math.pow(tau, 5) / 2000000.0);

  final pos = sunPosition(jde);
  final nut = nutation(t);
  final epsilon = degToRad(trueObliquity(t));

  final lambda = degToRad(pos.apparentLongitude);
  final betaRad = degToRad(pos.apparentLatitude);

  // 视赤经 α
  final alpha = normalizeDegrees(radToDeg(math.atan2(
    math.sin(lambda) * math.cos(epsilon) -
        math.tan(betaRad) * math.sin(epsilon),
    math.cos(lambda),
  )));

  var e = l0 - 0.0057183 - alpha + nut.longitude * math.cos(epsilon);
  // 结果本应是个小角度,取模后落回 (−180,180] 再换算成分钟
  e = normalizeDegreesSigned(e);
  return e * 4.0;
}

double _series(List<List<double>> terms, double tau) {
  var sum = 0.0;
  for (final term in terms) {
    sum += term[0] * math.cos(term[1] + term[2] * tau);
  }
  return sum;
}
