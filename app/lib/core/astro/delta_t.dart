/// ΔT = TT − UT,力学时与世界时之差。
///
/// VSOP87 等天文级数吃的是 **TT**,而用户给的出生时间是 **UT**(民用时),
/// 两者差几十秒。节气时刻要精确到分钟,这个修正不能省。
///
/// 采用 Espenak & Meeus(NASA 日月食网站)的分段多项式。
/// 1900–2100 区间内误差远小于 1 秒,对命理足够。
library;

/// 返回 ΔT,单位:秒。[year] 可带小数(如 2026.5)。
double deltaTSeconds(double year) {
  if (year < -500) {
    final u = (year - 1820) / 100;
    return -20 + 32 * u * u;
  }
  if (year < 500) {
    final u = year / 100;
    return _poly(u, [
      10583.6, -1014.41, 33.78311, -5.952053,
      -0.1798452, 0.022174192, 0.0090316521,
    ]);
  }
  if (year < 1600) {
    final u = (year - 1000) / 100;
    return _poly(u, [
      1574.2, -556.01, 71.23472, 0.319781,
      -0.8503463, -0.005050998, 0.0083572073,
    ]);
  }
  if (year < 1700) {
    final u = year - 1600;
    return _poly(u, [120, -0.9808, -0.01532, 1 / 7129.0]);
  }
  if (year < 1800) {
    final u = year - 1700;
    return _poly(u, [8.83, 0.1603, -0.0059285, 0.00013336, -1 / 1174000.0]);
  }
  if (year < 1860) {
    final u = year - 1800;
    return _poly(u, [
      13.72, -0.332447, 0.0068612, 0.0041116, -0.00037436,
      0.0000121272, -0.0000001699, 0.000000000875,
    ]);
  }
  if (year < 1900) {
    final u = year - 1860;
    return _poly(u, [
      7.62, 0.5737, -0.251754, 0.01680668,
      -0.0004473624, 1 / 233174.0,
    ]);
  }
  if (year < 1920) {
    final u = year - 1900;
    return _poly(u, [-2.79, 1.494119, -0.0598939, 0.0061966, -0.000197]);
  }
  if (year < 1941) {
    final u = year - 1920;
    return _poly(u, [21.20, 0.84493, -0.076100, 0.0020936]);
  }
  if (year < 1961) {
    final u = year - 1950;
    return _poly(u, [29.07, 0.407, -1 / 233.0, 1 / 2547.0]);
  }
  if (year < 1986) {
    final u = year - 1975;
    return _poly(u, [45.45, 1.067, -1 / 260.0, -1 / 718.0]);
  }
  if (year < 2005) {
    final u = year - 2000;
    return _poly(u, [
      63.86, 0.3345, -0.060374, 0.0017275, 0.000651814, 0.00002373599,
    ]);
  }
  if (year < 2026) {
    // 2005 年起用 IERS 实测年均值线性插值。Espenak–Meeus 的 2005–2050 外推式
    // 在 2020 年给 71.6 s,实测只有 69.4 s(地球自转近年变快),故不再使用。
    final i = (year - 2005).floor().clamp(0, _observed.length - 2);
    final f = year - 2005 - i;
    return _observed[i] + (_observed[i + 1] - _observed[i]) * f;
  }
  // 2026 年后:自最后实测值起按 0.2 s/年 缓升。ΔT 的远期走势本就不可预测,
  // 这个斜率取历史百年均值,对节气分钟级显示无影响。
  return _observed.last + 0.2 * (year - 2025);
}

/// IERS 年初 ΔT 实测(秒),2005–2025。
const List<double> _observed = [
  64.69, 64.85, 65.15, 65.46, 65.78, // 2005–2009
  66.07, 66.32, 66.60, 66.91, 67.28, // 2010–2014
  67.64, 68.10, 68.59, 68.97, 69.22, // 2015–2019
  69.36, 69.36, 69.29, 69.20, 69.18, // 2020–2024
  69.20, // 2025
];

/// ΔT,单位:天。
double deltaTDays(double year) => deltaTSeconds(year) / 86400.0;

/// 由儒略日(UT)近似求年份小数,供 [deltaTSeconds] 使用。
double approximateYear(double jdUt) => 2000.0 + (jdUt - 2451545.0) / 365.25;

/// UT 儒略日 → TT 儒略日(即 JDE)。
double jdUtToJde(double jdUt) => jdUt + deltaTDays(approximateYear(jdUt));

/// TT 儒略日 → UT 儒略日。
double jdeToJdUt(double jde) => jde - deltaTDays(approximateYear(jde));

double _poly(double x, List<double> coefficients) {
  var result = 0.0;
  for (var i = coefficients.length - 1; i >= 0; i--) {
    result = result * x + coefficients[i];
  }
  return result;
}
