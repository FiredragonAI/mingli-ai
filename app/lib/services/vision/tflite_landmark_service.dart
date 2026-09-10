/// Windows(及其他无系统级视觉 API 的平台):用 tflite_flutter 跑 MediaPipe 模型。
///
/// 模型文件放在 `assets/models/`:
/// - `hand_landmark_full.tflite`   输入 224×224×3 float[0,1],输出 63 = 21×(x,y,z)
/// - `face_landmark.tflite`         输入 192×192×3 float[0,1],输出 1404 = 468×(x,y,z)
///
/// 这两个是"landmark"阶段模型,假定输入已是裁好的 ROI。v1 通过取景框引导用户
/// 把手/脸放满画面来省掉检测阶段;后续可加 palm_detection / face_detection 两级流水线。
library;

import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/vision/face_features.dart';
import '../../core/vision/geometry.dart';
import '../../core/vision/palm_features.dart';
import 'landmark_service.dart';
import 'mediapipe_face_map.dart';

class TfliteLandmarkService implements LandmarkService {
  Interpreter? _hand;
  Interpreter? _face;

  Future<Interpreter> _loadHand() async =>
      _hand ??= await Interpreter.fromAsset('assets/models/hand_landmark_full.tflite');

  Future<Interpreter> _loadFace() async =>
      _face ??= await Interpreter.fromAsset('assets/models/face_landmark.tflite');

  @override
  Future<HandLandmarks?> detectHand(String imagePath) async {
    final decoded = img.decodeImage(await File(imagePath).readAsBytes());
    if (decoded == null) return null;
    final interpreter = await _loadHand();

    const size = 224;
    final input = _toFloatTensor(decoded, size);
    final output = List.filled(63, 0.0).reshape([1, 63]);
    final presence = List.filled(1, 0.0).reshape([1, 1]);
    final handedness = List.filled(1, 0.0).reshape([1, 1]);

    // 输出张量顺序以模型元数据为准;full 模型为 landmarks / presence / handedness / world
    final outputs = <int, Object>{0: output, 1: presence, 2: handedness};
    try {
      interpreter.runForMultipleInputs([input], outputs);
    } catch (_) {
      interpreter.run(input, output);
    }

    final score = (presence[0] as List)[0] as double;
    if (score < 0.5) return null;

    final flat = (output[0] as List).cast<double>();
    final pts = <Point2>[
      for (var i = 0; i < 21; i++)
        Point2(flat[i * 3] / size * decoded.width, flat[i * 3 + 1] / size * decoded.height),
    ];
    final isLeft = ((handedness[0] as List)[0] as double) < 0.5;
    return HandLandmarks(points: pts, isLeftHand: isLeft);
  }

  @override
  Future<FaceKeyPoints?> detectFace(String imagePath) async {
    final decoded = img.decodeImage(await File(imagePath).readAsBytes());
    if (decoded == null) return null;
    final interpreter = await _loadFace();

    const size = 192;
    final input = _toFloatTensor(decoded, size);
    final output = List.filled(1404, 0.0).reshape([1, 1, 1, 1404]);
    final score = List.filled(1, 0.0).reshape([1, 1, 1, 1]);
    try {
      interpreter.runForMultipleInputs([input], {0: output, 1: score});
    } catch (_) {
      interpreter.run(input, output);
    }
    final conf = (((score[0] as List)[0] as List)[0] as List)[0] as double;
    if (conf < 0.5) return null;

    final flat = (((output[0] as List)[0] as List)[0] as List).cast<double>();
    final pts468 = <Point2>[
      for (var i = 0; i < 468; i++)
        Point2(flat[i * 3] / size * decoded.width, flat[i * 3 + 1] / size * decoded.height),
    ];
    return faceKeyPointsFromMediaPipe(pts468);
  }

  /// 缩放到 size×size,归一化到 [0,1],NHWC。
  List<List<List<List<double>>>> _toFloatTensor(img.Image src, int size) {
    final resized = img.copyResize(src, width: size, height: size, interpolation: img.Interpolation.linear);
    return [
      List.generate(
        size,
        (y) => List.generate(size, (x) {
          final p = resized.getPixel(x, y);
          return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
        }),
      ),
    ];
  }

  void dispose() {
    _hand?.close();
    _face?.close();
  }
}

// `List.reshape` 由 tflite_flutter 的 ListShape 扩展提供。
