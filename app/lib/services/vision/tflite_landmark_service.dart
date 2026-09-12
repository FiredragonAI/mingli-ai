/// Windows(及其他无系统级视觉 API 的平台):用 tflite_flutter 跑 MediaPipe 模型。
///
/// 两级流水线,与 MediaPipe 官方图一致:
///
///   整张照片 → **检测**(BlazeFace / BlazePalm,找到位置与倾斜角)
///            → **裁切摆正**([Roi])
///            → **关键点**(face_landmark 468 点 / hand_landmark 21 点)
///            → 坐标映射回原图
///
/// 所以全身照、合照、歪着拍的都能用;检测失败时退回"假定目标填满画面"。
///
/// 模型文件在 `assets/models/`。输出张量不按下标猜,按**形状**匹配:
/// 元素数 63 / 1404 的是关键点,元素数 1 的是存在概率(手模型另有 1 个是左右手)。
library;

import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/vision/face_features.dart';
import '../../core/vision/geometry.dart';
import '../../core/vision/palm_features.dart';
import 'landmark_service.dart';
import 'mediapipe_face_map.dart';
import 'roi.dart';
import 'ssd_anchors.dart';

const handModelAsset = 'assets/models/hand_landmark_full.tflite';
const faceModelAsset = 'assets/models/face_landmark.tflite';
const faceDetFullAsset = 'assets/models/face_detection_full_range.tflite';
const faceDetShortAsset = 'assets/models/face_detection_short_range.tflite';
const palmDetAsset = 'assets/models/palm_detection_full.tflite';

/// 检测阶段返回的定位结果。
class Located {
  const Located(this.roi, this.confidence, this.coverage);
  final Roi roi;

  /// 检测置信度;兜底(整图)时为 0。
  final double confidence;

  /// 目标框占画面短边的比例,用来给用户提示"脸太小"。
  final double coverage;
}

class TfliteLandmarkService implements LandmarkService {
  final _cache = <String, Interpreter>{};
  final _anchors = <String, List<Anchor>>{};

  String? _lastNote;

  @override
  String? get lastLocationNote => _lastNote;

  void _noteLocated(String what, Located l) {
    if (l.confidence == 0) {
      _lastNote = '未能在照片中单独定位到$what,已按整张照片分析;若结果不准,请换一张$what更清晰、占画面更大的照片。';
      return;
    }
    final pct = (l.coverage * 100).round();
    final sizeHint = l.coverage < 0.15 ? ',$what在照片里偏小,细节可能不够,建议换近一点的照片' : '';
    _lastNote = '已在照片中定位到$what(置信度 ${(l.confidence * 100).round()}%,约占画面短边 $pct%)$sizeHint。';
  }

  Future<Interpreter> _model(String asset) async => _cache[asset] ??= await Interpreter.fromAsset(asset);

  // ------------------------------------------------------------------ 检测

  Future<Detection?> _detect(img.Image im, String asset, SsdAnchorOptions o) async {
    final it = await _model(asset);
    final anchors = _anchors[asset] ??= generateAnchors(o);
    final input = warpRoiToTensor(im, Roi.wholeImage(im), o.inputSize);
    final outputs = _allocateOutputs(it);
    it.runForMultipleInputs([input], outputs);

    List<double>? boxes, scores;
    for (final v in outputs.values) {
      final flat = _flatten(v);
      if (flat.length == anchors.length * o.valuesPerBox) boxes = flat;
      if (flat.length == anchors.length) scores = flat;
    }
    if (boxes == null || scores == null) return null;
    return decodeBest(boxes, scores, anchors, o);
  }

  /// 找脸:先全距模型(远处小脸),再短距模型(近距自拍),都没有就用整图。
  Future<Located> locateFace(img.Image im) async {
    for (final (asset, o) in [(faceDetFullAsset, faceFullRangeOptions), (faceDetShortAsset, faceShortRangeOptions)]) {
      final d = await _detect(im, asset, o);
      if (d != null) {
        // 关键点 0 右眼、1 左眼;两眼连线摆平;框放大 1.5 倍
        final roi = Roi.fromDetection(d, im, kpStart: 0, kpEnd: 1, targetAngle: 0, scale: 1.5);
        return Located(roi, d.score, _coverage(d, im));
      }
    }
    return Located(Roi.wholeImage(im), 0, 1);
  }

  /// 找手掌:关键点 0 腕、2 中指根;让手指朝上;框放大 2.6 倍并沿手指方向上移半个框。
  Future<Located> locateHand(img.Image im) async {
    final d = await _detect(im, palmDetAsset, palmOptions);
    if (d != null) {
      final roi = Roi.fromDetection(d, im, kpStart: 0, kpEnd: 2, targetAngle: 3.141592653589793 / 2, scale: 2.6, shiftY: -0.5);
      return Located(roi, d.score, _coverage(d, im));
    }
    return Located(Roi.wholeImage(im), 0, 1);
  }

  double _coverage(Detection d, img.Image im) {
    final short = im.width < im.height ? im.width : im.height;
    final box = (d.width * im.width) > (d.height * im.height) ? d.width * im.width : d.height * im.height;
    return box / short;
  }

  // ------------------------------------------------------------------ 关键点

  @override
  Future<HandLandmarks?> detectHand(String imagePath) async {
    final decoded = img.decodeImage(await File(imagePath).readAsBytes());
    if (decoded == null) return null;
    final located = await locateHand(decoded);
    _noteLocated('手掌', located);
    final it = await _model(handModelAsset);

    final size = it.getInputTensor(0).shape[1];
    final outputs = _allocateOutputs(it);
    it.runForMultipleInputs([warpRoiToTensor(decoded, located.roi, size)], outputs);

    final landmarks = _firstWithCount(outputs, 63);
    if (landmarks == null) return null;
    final scalars = _scalarOutputs(outputs);
    final presence = scalars.isNotEmpty ? scalars[0] : 1.0;
    if (presence < 0.5) return null;
    final handedness = scalars.length > 1 ? scalars[1] : 0.5;

    final pts = <Point2>[
      for (var i = 0; i < 21; i++) located.roi.toImage(landmarks[i * 3] / size, landmarks[i * 3 + 1] / size),
    ];
    return HandLandmarks(points: pts, isLeftHand: handedness < 0.5);
  }

  @override
  Future<FaceKeyPoints?> detectFace(String imagePath) async {
    final decoded = img.decodeImage(await File(imagePath).readAsBytes());
    if (decoded == null) return null;
    final located = await locateFace(decoded);
    _noteLocated('人脸', located);
    final it = await _model(faceModelAsset);

    final size = it.getInputTensor(0).shape[1];
    final outputs = _allocateOutputs(it);
    it.runForMultipleInputs([warpRoiToTensor(decoded, located.roi, size)], outputs);

    final flat = _firstWithCount(outputs, 1404);
    if (flat == null) return null;
    final scalars = _scalarOutputs(outputs);
    // face_landmark 的置信度是未过 sigmoid 的 logit,>0 视为有脸
    if (scalars.isNotEmpty && scalars[0] < 0) return null;

    final pts468 = <Point2>[
      for (var i = 0; i < 468; i++) located.roi.toImage(flat[i * 3] / size, flat[i * 3 + 1] / size),
    ];
    return faceKeyPointsFromMediaPipe(pts468);
  }

  // ------------------------------------------------------------------ 工具

  Map<int, Object> _allocateOutputs(Interpreter it) {
    final out = <int, Object>{};
    for (var i = 0; i < it.getOutputTensors().length; i++) {
      final shape = it.getOutputTensor(i).shape;
      out[i] = List.filled(shape.fold(1, (a, b) => a * b), 0.0).reshape(shape);
    }
    return out;
  }

  List<double>? _firstWithCount(Map<int, Object> outputs, int n) {
    final keys = outputs.keys.toList()..sort();
    for (final k in keys) {
      final f = _flatten(outputs[k]!);
      if (f.length == n) return f;
    }
    return null;
  }

  List<double> _scalarOutputs(Map<int, Object> outputs) {
    final keys = outputs.keys.toList()..sort();
    return [
      for (final k in keys)
        if (_flatten(outputs[k]!).length == 1) _flatten(outputs[k]!).first,
    ];
  }

  static List<double> _flatten(Object o) {
    if (o is List) {
      final out = <double>[];
      for (final x in o) {
        if (x is List) {
          out.addAll(_flatten(x));
        } else {
          out.add((x as num).toDouble());
        }
      }
      return out;
    }
    return [(o as num).toDouble()];
  }

  /// 自检:加载全部模型、列出张量形状、各空跑一次;检测模型另核对锚框数与输出是否吻合。
  static Future<String> selfTest() async {
    final buf = StringBuffer();
    const models = <(String, String, SsdAnchorOptions?)>[
      ('face-det-full', faceDetFullAsset, faceFullRangeOptions),
      ('face-det-short', faceDetShortAsset, faceShortRangeOptions),
      ('palm-det', palmDetAsset, palmOptions),
      ('face-landmark', faceModelAsset, null),
      ('hand-landmark', handModelAsset, null),
    ];
    final svc = TfliteLandmarkService();
    for (final (label, asset, opts) in models) {
      buf.writeln('== $label: $asset');
      try {
        final it = await Interpreter.fromAsset(asset);
        for (var i = 0; i < it.getInputTensors().length; i++) {
          final t = it.getInputTensor(i);
          buf.writeln('  in[$i]  ${t.name}  ${t.shape}  ${t.type}');
        }
        for (var i = 0; i < it.getOutputTensors().length; i++) {
          final t = it.getOutputTensor(i);
          buf.writeln('  out[$i] ${t.name}  ${t.shape}  ${t.type}');
        }
        final size = it.getInputTensor(0).shape[1];
        final input = [List.generate(size, (_) => List.generate(size, (_) => [0.0, 0.0, 0.0]))];
        final outputs = svc._allocateOutputs(it);
        final sw = Stopwatch()..start();
        it.runForMultipleInputs([input], outputs);
        buf.writeln('  run ok in ${sw.elapsedMilliseconds} ms; scalars=${svc._scalarOutputs(outputs)}');
        if (opts != null) {
          final n = generateAnchors(opts).length;
          final sizes = outputs.values.map((v) => _flatten(v).length).toList();
          final ok = sizes.contains(n) && sizes.contains(n * opts.valuesPerBox);
          buf.writeln('  anchors=$n outputs=$sizes ${ok ? 'MATCH' : 'MISMATCH!'}');
        }
        it.close();
      } catch (e) {
        buf.writeln('  FAILED: $e');
      }
    }
    return buf.toString();
  }

  void dispose() {
    for (final it in _cache.values) {
      it.close();
    }
    _cache.clear();
  }
}

// `List.reshape` 由 tflite_flutter 的 ListShape 扩展提供。
