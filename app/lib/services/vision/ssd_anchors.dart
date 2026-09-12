/// MediaPipe 检测模型(BlazeFace / BlazePalm)的 SSD 锚框生成与输出解码。
///
/// 这两类模型输出的不是坐标,而是"相对锚框的偏移"。锚框本身不在模型里,
/// 要按 MediaPipe 的 `SsdAnchorsCalculator` 规则在客户端生成,再用
/// `TfLiteTensorsToDetectionsCalculator` 的规则解码。下面照搬这两份规则。
library;

import 'dart:math' as math;

import '../../core/vision/geometry.dart';

class SsdAnchorOptions {
  const SsdAnchorOptions({
    required this.inputSize,
    required this.strides,
    required this.minScale,
    required this.maxScale,
    required this.numKeypoints,
    required this.scoreThreshold,
    this.anchorOffset = 0.5,
    this.interpolatedScaleAspectRatio = 1.0,
  });

  final int inputSize;
  final List<int> strides;
  final double minScale;
  final double maxScale;
  final int numKeypoints;
  final double scoreThreshold;
  final double anchorOffset;

  /// 0 表示不插入中间尺度的额外锚框。
  final double interpolatedScaleAspectRatio;

  /// 每个检测的原始值个数:4 个框 + 每个关键点 2 个。
  int get valuesPerBox => 4 + numKeypoints * 2;
}

/// BlazeFace 短距(自拍距离),输入 128,896 锚框。
const faceShortRangeOptions = SsdAnchorOptions(
  inputSize: 128,
  strides: [8, 16, 16, 16],
  minScale: 0.1484375,
  maxScale: 0.75,
  numKeypoints: 6,
  scoreThreshold: 0.5,
);

/// BlazeFace 全距(远处小脸也能找到),输入 192,2304 锚框。
const faceFullRangeOptions = SsdAnchorOptions(
  inputSize: 192,
  strides: [4],
  minScale: 0.1484375,
  maxScale: 0.75,
  numKeypoints: 6,
  scoreThreshold: 0.6,
  interpolatedScaleAspectRatio: 0.0,
);

/// BlazePalm(full / lite 同一套锚框),输入 192,2016 锚框。
const palmOptions = SsdAnchorOptions(
  inputSize: 192,
  strides: [8, 16, 16, 16],
  minScale: 0.1484375,
  maxScale: 0.75,
  numKeypoints: 7,
  scoreThreshold: 0.5,
);

/// 一个锚框,坐标归一化到 0–1;fixed_anchor_size 下宽高恒为 1。
class Anchor {
  const Anchor(this.x, this.y);
  final double x;
  final double y;
}

List<Anchor> generateAnchors(SsdAnchorOptions o) {
  final anchors = <Anchor>[];
  final n = o.strides.length;

  double scaleAt(int index) =>
      n == 1 ? (o.minScale + o.maxScale) * 0.5 : o.minScale + (o.maxScale - o.minScale) * index / (n - 1);

  var layer = 0;
  while (layer < n) {
    var anchorsPerCell = 0;
    var last = layer;
    while (last < n && o.strides[last] == o.strides[layer]) {
      anchorsPerCell += 1; // aspect_ratio 1.0
      if (o.interpolatedScaleAspectRatio > 0) anchorsPerCell += 1; // 插值尺度
      last++;
    }
    final stride = o.strides[layer];
    final cells = (o.inputSize / stride).ceil();
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        for (var k = 0; k < anchorsPerCell; k++) {
          anchors.add(Anchor((x + o.anchorOffset) / cells, (y + o.anchorOffset) / cells));
        }
      }
    }
    // scaleAt 只影响非固定尺寸锚框;MediaPipe 这几张模型都是 fixed_anchor_size,宽高恒 1,
    // 这里调用一次只为保持与原算法的对应关系,便于将来对照。
    scaleAt(layer);
    layer = last;
  }
  return anchors;
}

/// 一次检测结果,坐标归一化到 0–1(相对输入正方形)。
class Detection {
  const Detection({
    required this.xCenter,
    required this.yCenter,
    required this.width,
    required this.height,
    required this.score,
    required this.keypoints,
  });

  final double xCenter;
  final double yCenter;
  final double width;
  final double height;
  final double score;
  final List<Point2> keypoints;
}

/// 从原始张量里挑出分数最高的一个检测;低于阈值返回 null。
///
/// [rawBoxes] 长度 = 锚框数 × valuesPerBox;[rawScores] 长度 = 锚框数(未过 sigmoid)。
Detection? decodeBest(List<double> rawBoxes, List<double> rawScores, List<Anchor> anchors, SsdAnchorOptions o) {
  var bestIdx = -1;
  var bestScore = -1.0;
  for (var i = 0; i < anchors.length; i++) {
    final s = _sigmoid(rawScores[i].clamp(-100.0, 100.0));
    if (s > bestScore) {
      bestScore = s;
      bestIdx = i;
    }
  }
  if (bestIdx < 0 || bestScore < o.scoreThreshold) return null;

  final a = anchors[bestIdx];
  final base = bestIdx * o.valuesPerBox;
  final scale = o.inputSize.toDouble();
  // reverse_output_order = true:顺序为 x, y, w, h
  final xc = rawBoxes[base] / scale + a.x;
  final yc = rawBoxes[base + 1] / scale + a.y;
  final w = rawBoxes[base + 2] / scale;
  final h = rawBoxes[base + 3] / scale;
  final kps = <Point2>[
    for (var k = 0; k < o.numKeypoints; k++)
      Point2(rawBoxes[base + 4 + k * 2] / scale + a.x, rawBoxes[base + 5 + k * 2] / scale + a.y),
  ];
  return Detection(xCenter: xc, yCenter: yc, width: w, height: h, score: bestScore, keypoints: kps);
}

double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));
