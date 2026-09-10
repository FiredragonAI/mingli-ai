/// 手相特征。
///
/// 输入是设备端提取好的 21 个手部关键点(MediaPipe 索引约定)和掌纹折线,
/// 输出是**比例、角度、分类**这类几何描述——不含任何像素。
/// 只有这个 JSON 会离开设备。
library;

import 'geometry.dart';

/// 21 点手部关键点,MediaPipe 约定:0 腕,1–4 拇指,5–8 食指,9–12 中指,13–16 无名指,17–20 小指。
class HandLandmarks {
  const HandLandmarks({required this.points, required this.isLeftHand});
  final List<Point2> points;
  final bool isLeftHand;

  Point2 get wrist => points[0];
  Point2 get thumbTip => points[4];
  Point2 get indexMcp => points[5];
  Point2 get indexTip => points[8];
  Point2 get middleMcp => points[9];
  Point2 get middleTip => points[12];
  Point2 get ringMcp => points[13];
  Point2 get ringTip => points[16];
  Point2 get pinkyMcp => points[17];
  Point2 get pinkyTip => points[20];

  /// 掌宽:食指根到小指根。
  double get palmWidth => indexMcp.distanceTo(pinkyMcp);

  /// 掌长:腕到中指根。
  double get palmLength => wrist.distanceTo(middleMcp);
}

/// 一条掌纹。坐标已归一化到掌心坐标系(腕为原点、掌长为 1)。
class PalmLine {
  const PalmLine({
    required this.name,
    required this.points,
    required this.segments,
  });

  /// 生命线 / 智慧线 / 感情线 / 其他。
  final String name;
  final List<Point2> points;

  /// 该线由几段构成(>1 表示有断裂或岛纹)。
  final int segments;

  double get length => polylineLength(points);
  double get curvature => polylineCurvature(points);

  Map<String, dynamic> toJson() => {
        'name': name,
        'length': round3(length),
        'curvature': round3(curvature),
        'segments': segments,
        'start': points.first.toJson(),
        'end': points.last.toJson(),
      };
}

/// 手相特征结果。
class PalmFeatures {
  const PalmFeatures({
    required this.hand,
    required this.handShape,
    required this.palmAspect,
    required this.fingerToPalm,
    required this.fingerRatios,
    required this.thumbAngle,
    required this.lines,
    required this.notes,
  });

  final String hand;

  /// 土型 / 火型 / 风型 / 水型。
  final String handShape;

  /// 掌长 / 掌宽。>1.15 为长掌。
  final double palmAspect;

  /// 中指长 / 掌长。>0.8 为长指。
  final double fingerToPalm;

  /// 各指相对中指的长度比。
  final Map<String, double> fingerRatios;

  /// 拇指张开角(度)。
  final double thumbAngle;
  final List<PalmLine> lines;
  final List<String> notes;

  Map<String, dynamic> toJson() => {
        'hand': hand,
        'handShape': handShape,
        'palmAspect': round3(palmAspect),
        'fingerToPalm': round3(fingerToPalm),
        'fingerRatios': {for (final e in fingerRatios.entries) e.key: round3(e.value)},
        'thumbAngle': round3(thumbAngle),
        'lines': lines.map((l) => l.toJson()).toList(),
        'notes': notes,
      };
}

/// 由关键点与掌纹计算特征。
PalmFeatures computePalmFeatures(HandLandmarks lm, List<PalmLine> lines) {
  final palmW = lm.palmWidth;
  final palmL = lm.palmLength;
  final aspect = palmL / palmW;

  final middleLen = lm.middleMcp.distanceTo(lm.middleTip);
  final indexLen = lm.indexMcp.distanceTo(lm.indexTip);
  final ringLen = lm.ringMcp.distanceTo(lm.ringTip);
  final pinkyLen = lm.pinkyMcp.distanceTo(lm.pinkyTip);
  final thumbLen = lm.points[2].distanceTo(lm.thumbTip);

  final fingerToPalm = middleLen / palmL;

  final longPalm = aspect > 1.15;
  final longFingers = fingerToPalm > 0.80;
  final shape = switch ((longPalm, longFingers)) {
    (false, false) => '土型',
    (false, true) => '风型',
    (true, false) => '火型',
    (true, true) => '水型',
  };

  final thumbAngle = angleDegrees(lm.thumbTip - lm.points[1], lm.indexMcp - lm.points[1]);

  final notes = <String>[];
  final ir = indexLen / ringLen;
  if (ir < 0.95) {
    notes.add('食指明显短于无名指,传统上视为行动力、冒险精神较强');
  } else if (ir > 1.03) {
    notes.add('食指长于无名指,传统上视为自尊心与掌控欲较强');
  } else {
    notes.add('食指与无名指长度相近,性格较均衡');
  }
  if (thumbAngle > 55) notes.add('拇指张角大,性格开放慷慨');
  if (thumbAngle < 35) notes.add('拇指张角小,行事谨慎保守');
  if (pinkyLen / middleLen < 0.68) notes.add('小指偏短,表达沟通上需多主动');

  for (final l in lines) {
    switch (l.name) {
      case '生命线':
        notes.add(l.curvature > 0.28 ? '生命线弧度大,精力充沛' : '生命线较直,偏好稳定作息');
        if (l.segments > 1) notes.add('生命线有断续,传统上主生活阶段有大变动');
      case '智慧线':
        notes.add(l.length > 0.75 ? '智慧线长,思虑周密' : '智慧线偏短,重直觉与实干');
        if (l.curvature > 0.2) notes.add('智慧线下垂弯曲,想象力丰富');
      case '感情线':
        notes.add(l.length > 0.7 ? '感情线长,情感投入深' : '感情线偏短,情感表达克制');
        if (l.segments > 1) notes.add('感情线断续,感情经历起伏较多');
    }
  }

  return PalmFeatures(
    hand: lm.isLeftHand ? '左手' : '右手',
    handShape: shape,
    palmAspect: aspect,
    fingerToPalm: fingerToPalm,
    fingerRatios: {
      '食指/中指': indexLen / middleLen,
      '无名指/中指': ringLen / middleLen,
      '小指/中指': pinkyLen / middleLen,
      '拇指/掌宽': thumbLen / palmW,
      '食指/无名指': ir,
    },
    thumbAngle: thumbAngle,
    lines: lines,
    notes: notes,
  );
}
