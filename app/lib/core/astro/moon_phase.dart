/// 朔望月——求"定朔"(真正的日月合朔时刻)。
///
/// 现行农历用**定朔**排月首:合朔那一瞬所在的那一天,就是初一。
/// 算法取自 Meeus《Astronomical Algorithms》ch.49,含全部 25 个主周期项
/// 与 14 个行星摄动项,精度优于 20 秒。
library;

import 'dart:math' as math;

import 'angle.dart';
import 'delta_t.dart';

/// 求第 [k] 个朔(k=0 对应 2000-01-06 的新月)的时刻,返回 **UT 儒略日**。
///
/// k 为整数时是朔(新月);k+0.5 是望(满月)。本项目只用到朔。
double newMoonJdUt(double k) => jdeToJdUt(_moonPhaseJde(k));

/// 求**不晚于** [jdUt] 的最后一次朔。
double lastNewMoonBefore(double jdUt) {
  var k = _approximateK(jdUt).floorToDouble();
  // 初值可能偏一格,前后各挪一次即可锁定
  while (newMoonJdUt(k) > jdUt) {
    k -= 1;
  }
  while (newMoonJdUt(k + 1) <= jdUt) {
    k += 1;
  }
  return newMoonJdUt(k);
}

/// 求**晚于** [jdUt] 的第一次朔。
double nextNewMoonAfter(double jdUt) {
  var k = _approximateK(jdUt).floorToDouble();
  while (newMoonJdUt(k) <= jdUt) {
    k += 1;
  }
  while (newMoonJdUt(k - 1) > jdUt) {
    k -= 1;
  }
  return newMoonJdUt(k);
}

/// 由儒略日粗估朔的序号 k。
double _approximateK(double jdUt) =>
    (jdUt - 2451550.09766) / 29.530588861;

/// Meeus 49 —— 返回 TT 尺度的儒略日。
double _moonPhaseJde(double k) {
  final t = k / 1236.85;
  final t2 = t * t;
  final t3 = t2 * t;
  final t4 = t3 * t;

  var jde = 2451550.09766 +
      29.530588861 * k +
      0.00015437 * t2 -
      0.000000150 * t3 +
      0.00000000073 * t4;

  // 地球轨道离心率随时间的修正因子
  final e = 1 - 0.002516 * t - 0.0000074 * t2;

  // 太阳平近点角
  final m = degToRad(normalizeDegrees(
      2.5534 + 29.10535670 * k - 0.0000014 * t2 - 0.00000011 * t3));
  // 月亮平近点角
  final mp = degToRad(normalizeDegrees(201.5643 +
      385.81693528 * k +
      0.0107582 * t2 +
      0.00001238 * t3 -
      0.000000058 * t4));
  // 月亮升交点角距
  final f = degToRad(normalizeDegrees(160.7108 +
      390.67050284 * k -
      0.0016118 * t2 -
      0.00000227 * t3 +
      0.000000011 * t4));
  // 月亮轨道升交点黄经
  final omega = degToRad(normalizeDegrees(
      124.7746 - 1.56375588 * k + 0.0020672 * t2 + 0.00000215 * t3));

  double s(double x) => math.sin(x);

  jde += -0.40720 * s(mp) +
      0.17241 * e * s(m) +
      0.01608 * s(2 * mp) +
      0.01039 * s(2 * f) +
      0.00739 * e * s(mp - m) +
      -0.00514 * e * s(mp + m) +
      0.00208 * e * e * s(2 * m) +
      -0.00111 * s(mp - 2 * f) +
      -0.00057 * s(mp + 2 * f) +
      0.00056 * e * s(2 * mp + m) +
      -0.00042 * s(3 * mp) +
      0.00042 * e * s(m + 2 * f) +
      0.00038 * e * s(m - 2 * f) +
      -0.00024 * e * s(2 * mp - m) +
      -0.00017 * s(omega) +
      -0.00007 * s(mp + 2 * m) +
      0.00004 * s(2 * mp - 2 * f) +
      0.00004 * s(3 * m) +
      0.00003 * s(mp + m - 2 * f) +
      0.00003 * s(2 * mp + 2 * f) +
      -0.00003 * s(mp + m + 2 * f) +
      0.00003 * s(mp - m + 2 * f) +
      -0.00002 * s(mp - m - 2 * f) +
      -0.00002 * s(3 * mp + m) +
      0.00002 * s(4 * mp);

  // 行星摄动附加项
  final planetary = <List<double>>[
    [0.000325, 299.77 + 0.107408 * k - 0.009173 * t2],
    [0.000165, 251.88 + 0.016321 * k],
    [0.000164, 251.83 + 26.651886 * k],
    [0.000126, 349.42 + 36.412478 * k],
    [0.000110, 84.66 + 18.206239 * k],
    [0.000062, 141.74 + 53.303771 * k],
    [0.000060, 207.14 + 2.453732 * k],
    [0.000056, 154.84 + 7.306860 * k],
    [0.000047, 34.52 + 27.261239 * k],
    [0.000042, 207.19 + 0.121824 * k],
    [0.000040, 291.34 + 1.844379 * k],
    [0.000037, 161.72 + 24.198154 * k],
    [0.000035, 239.56 + 25.513099 * k],
    [0.000023, 331.55 + 3.592518 * k],
  ];
  for (final term in planetary) {
    jde += term[0] * math.sin(degToRad(normalizeDegrees(term[1])));
  }

  return jde;
}
