import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mingli_ai/core/vision/geometry.dart';
import 'package:mingli_ai/services/vision/roi.dart';
import 'package:mingli_ai/services/vision/ssd_anchors.dart';

void main() {
  group('SSD 锚框数与 MediaPipe 官方模型输出一致', () {
    test('BlazeFace 短距 896', () => expect(generateAnchors(faceShortRangeOptions).length, 896));
    test('BlazeFace 全距 2304', () => expect(generateAnchors(faceFullRangeOptions).length, 2304));
    test('BlazePalm 2016', () => expect(generateAnchors(palmOptions).length, 2016));
    test('锚框中心落在 0–1 内且按行扫描', () {
      final a = generateAnchors(faceFullRangeOptions);
      expect(a.first.x, closeTo(0.5 / 48, 1e-9));
      expect(a.first.y, closeTo(0.5 / 48, 1e-9));
      expect(a.last.x, closeTo(47.5 / 48, 1e-9));
      expect(a.every((p) => p.x > 0 && p.x < 1 && p.y > 0 && p.y < 1), isTrue);
    });
  });

  group('解码', () {
    test('分数低于阈值返回 null;最高分被选中并带关键点', () {
      const o = faceShortRangeOptions;
      final anchors = generateAnchors(o);
      final boxes = List.filled(anchors.length * o.valuesPerBox, 0.0);
      final scores = List.filled(anchors.length, -10.0);
      expect(decodeBest(boxes, scores, anchors, o), isNull);

      const idx = 123;
      scores[idx] = 3.0; // sigmoid ≈ 0.95
      final b = idx * o.valuesPerBox;
      boxes[b] = 6.4; // x 偏移 = 6.4/128 = 0.05
      boxes[b + 1] = -6.4;
      boxes[b + 2] = 32; // w = 0.25
      boxes[b + 3] = 32;
      boxes[b + 4] = 1.28; // 关键点 0
      boxes[b + 5] = 1.28;
      final d = decodeBest(boxes, scores, anchors, o)!;
      expect(d.score, closeTo(0.9526, 1e-3));
      expect(d.xCenter, closeTo(anchors[idx].x + 0.05, 1e-9));
      expect(d.yCenter, closeTo(anchors[idx].y - 0.05, 1e-9));
      expect(d.width, closeTo(0.25, 1e-9));
      expect(d.keypoints.length, 6);
      expect(d.keypoints[0].x, closeTo(anchors[idx].x + 0.01, 1e-9));
    });
  });

  group('ROI', () {
    test('toImage / toRoi 互逆', () {
      const roi = Roi(cx: 300, cy: 200, size: 150, rotation: 0.7);
      for (final (u, v) in [(0.0, 0.0), (1.0, 1.0), (0.3, 0.8), (0.5, 0.5)]) {
        final p = roi.toImage(u, v);
        final back = roi.toRoi(p);
        expect(back.x, closeTo(u, 1e-9));
        expect(back.y, closeTo(v, 1e-9));
      }
      expect(roi.toImage(0.5, 0.5).x, closeTo(300, 1e-9));
    });

    test('由倾斜的两眼构造的 ROI 会把两眼摆平', () {
      final im = img.Image(width: 400, height: 300);
      // 右眼 (0.40,0.45)、左眼 (0.55,0.38):左眼更高,脸向左歪
      const det = Detection(
        xCenter: 0.48,
        yCenter: 0.45,
        width: 0.3,
        height: 0.4,
        score: 0.9,
        keypoints: [Point2(0.40, 0.45), Point2(0.55, 0.38), Point2(0.48, 0.5), Point2(0.48, 0.6), Point2(0.35, 0.5), Point2(0.6, 0.5)],
      );
      final roi = Roi.fromDetection(det, im, kpStart: 0, kpEnd: 1, targetAngle: 0, scale: 1.5);
      final r = roi.toRoi(const Point2(0.40 * 400, 0.45 * 300));
      final l = roi.toRoi(const Point2(0.55 * 400, 0.38 * 300));
      expect((r.y - l.y).abs(), lessThan(1e-9), reason: '两眼在 ROI 里应同一水平线');
      expect(l.x, greaterThan(r.x), reason: '左眼(图像右侧)应在 ROI 右侧');
      expect(roi.size, closeTo(math.max(0.3 * 400, 0.4 * 300) * 1.5, 1e-9));
    });

    test('手掌 ROI:手指朝上并向指尖方向平移', () {
      final im = img.Image(width: 400, height: 400);
      // 腕 (0.5,0.8) → 中指根 (0.5,0.5):手已经竖直朝上
      const det = Detection(
        xCenter: 0.5, yCenter: 0.65, width: 0.2, height: 0.3, score: 0.9,
        keypoints: [Point2(0.5, 0.8), Point2(0.45, 0.6), Point2(0.5, 0.5), Point2(0.55, 0.6), Point2(0.4, 0.7), Point2(0.6, 0.7), Point2(0.5, 0.7)],
      );
      final roi = Roi.fromDetection(det, im, kpStart: 0, kpEnd: 2, targetAngle: math.pi / 2, scale: 2.6, shiftY: -0.5);
      expect(roi.rotation.abs(), lessThan(1e-9));
      expect(roi.cy, closeTo(0.65 * 400 - 0.5 * 0.3 * 400, 1e-9), reason: '沿手指方向(向上)移半个框高');
      expect(roi.cx, closeTo(200, 1e-9));
    });

    test('整图 ROI 重采样尺寸正确且值域 0–1', () {
      final im = img.Image(width: 60, height: 40);
      img.fill(im, color: img.ColorRgb8(255, 128, 0));
      final t = warpRoiToTensor(im, Roi.wholeImage(im), 16);
      expect(t.length, 1);
      expect(t[0].length, 16);
      expect(t[0][0].length, 16);
      final center = t[0][8][8];
      expect(center[0], closeTo(1.0, 1e-6));
      expect(center[1], closeTo(128 / 255, 1e-6));
      expect(center[2], closeTo(0.0, 1e-6));
      // 整图 ROI 以长边为正方形,短边方向两侧越界应为黑
      expect(t[0][0][8][0], 0.0);
    });
  });
}
