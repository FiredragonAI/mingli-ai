/// Windows(及其他无系统级视觉 API 的平台):用 tflite_flutter 跑 MediaPipe 模型。
///
/// 模型文件放在 `assets/models/`:
/// - `hand_landmark_full.tflite`   输入 224×224×3 float[0,1],输出 63 = 21×(x,y,z)
/// - `face_landmark.tflite`         输入 192×192×3 float[0,1],输出 1404 = 468×(x,y,z)
///
/// 这两个是"landmark"阶段模型,假定输入已是裁好的 ROI。v1 通过取景框引导用户
/// 把手/脸放满画面来省掉检测阶段;后续可加 palm_detection / face_detection 两级流水线。
///
/// 输出张量的顺序不同版本模型不一样,所以不按下标猜,而是按**形状**匹配:
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

const handModelAsset = 'assets/models/hand_landmark_full.tflite';
const faceModelAsset = 'assets/models/face_landmark.tflite';

class TfliteLandmarkService implements LandmarkService {
  Interpreter? _hand;
  Interpreter? _face;

  Future<Interpreter> _loadHand() async => _hand ??= await Interpreter.fromAsset(handModelAsset);
  Future<Interpreter> _loadFace() async => _face ??= await Interpreter.fromAsset(faceModelAsset);

  @override
  Future<HandLandmarks?> detectHand(String imagePath) async {
    final decoded = img.decodeImage(await File(imagePath).readAsBytes());
    if (decoded == null) return null;
    final interpreter = await _loadHand();

    final size = interpreter.getInputTensor(0).shape[1];
    final input = _toFloatTensor(decoded, size);
    final outputs = _allocateOutputs(interpreter);
    interpreter.runForMultipleInputs([input], outputs);

    final byCount = _flattenByCount(interpreter, outputs);
    final landmarks = byCount[63];
    if (landmarks == null) return null;

    // 元素数为 1 的张量:第一个是存在概率,第二个是左右手(MediaPipe 顺序)
    final scalars = _scalarOutputs(interpreter, outputs);
    final presence = scalars.isNotEmpty ? scalars[0] : 1.0;
    if (presence < 0.5) return null;
    final handedness = scalars.length > 1 ? scalars[1] : 0.5;

    final pts = <Point2>[
      for (var i = 0; i < 21; i++)
        Point2(landmarks[i * 3] / size * decoded.width, landmarks[i * 3 + 1] / size * decoded.height),
    ];
    return HandLandmarks(points: pts, isLeftHand: handedness < 0.5);
  }

  @override
  Future<FaceKeyPoints?> detectFace(String imagePath) async {
    final decoded = img.decodeImage(await File(imagePath).readAsBytes());
    if (decoded == null) return null;
    final interpreter = await _loadFace();

    final size = interpreter.getInputTensor(0).shape[1];
    final input = _toFloatTensor(decoded, size);
    final outputs = _allocateOutputs(interpreter);
    interpreter.runForMultipleInputs([input], outputs);

    final byCount = _flattenByCount(interpreter, outputs);
    final flat = byCount[1404];
    if (flat == null) return null;

    final scalars = _scalarOutputs(interpreter, outputs);
    // face_landmark 的置信度是未经 sigmoid 的 logit,>0 即视为有脸
    if (scalars.isNotEmpty && scalars[0] < 0) return null;

    final pts468 = <Point2>[
      for (var i = 0; i < 468; i++)
        Point2(flat[i * 3] / size * decoded.width, flat[i * 3 + 1] / size * decoded.height),
    ];
    return faceKeyPointsFromMediaPipe(pts468);
  }

  /// 按每个输出张量的实际形状分配缓冲区。
  Map<int, Object> _allocateOutputs(Interpreter it) {
    final out = <int, Object>{};
    for (var i = 0; i < it.getOutputTensors().length; i++) {
      final shape = it.getOutputTensor(i).shape;
      final n = shape.fold(1, (a, b) => a * b);
      out[i] = List.filled(n, 0.0).reshape(shape);
    }
    return out;
  }

  /// 把输出按元素数归类并拍平成一维 double 列表。
  Map<int, List<double>> _flattenByCount(Interpreter it, Map<int, Object> outputs) {
    final res = <int, List<double>>{};
    for (final e in outputs.entries) {
      final flat = _flatten(e.value);
      res.putIfAbsent(flat.length, () => flat);
    }
    return res;
  }

  /// 元素数为 1 的输出,按张量下标顺序。
  List<double> _scalarOutputs(Interpreter it, Map<int, Object> outputs) {
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

  /// 自检:加载两个模型、列出张量形状、用全零输入各跑一次。
  ///
  /// 用于确认 Windows 端的 TFLite 动态库和模型文件都能正常工作
  /// (启动时设置环境变量 `MINGLI_SELFTEST=1` 会运行它并把结果写到临时目录)。
  static Future<String> selfTest() async {
    final buf = StringBuffer();
    for (final (label, asset) in [('hand', handModelAsset), ('face', faceModelAsset)]) {
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
        final svc = TfliteLandmarkService();
        final outputs = svc._allocateOutputs(it);
        final sw = Stopwatch()..start();
        it.runForMultipleInputs([input], outputs);
        buf.writeln('  run ok in ${sw.elapsedMilliseconds} ms; scalars=${svc._scalarOutputs(it, outputs)}');
        it.close();
      } catch (e) {
        buf.writeln('  FAILED: $e');
      }
    }
    return buf.toString();
  }

  void dispose() {
    _hand?.close();
    _face?.close();
  }
}

// `List.reshape` 由 tflite_flutter 的 ListShape 扩展提供。
