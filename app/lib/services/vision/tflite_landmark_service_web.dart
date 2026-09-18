/// Web 端替身:tflite_flutter 依赖 dart:ffi,浏览器里跑不了。
///
/// 只为了让 landmark_service.dart 的条件导入在 Web 上有东西可指;
/// 界面层会按 `supportsOnDeviceVision == false` 把手相/面相入口整个藏掉,
/// 正常情况下这里的方法不会被调到。
library;

import '../../core/vision/face_features.dart';
import '../../core/vision/palm_features.dart';
import 'landmark_service.dart';

class TfliteLandmarkService implements LandmarkService {
  @override
  String? get lastLocationNote => null;

  @override
  Future<HandLandmarks?> detectHand(String imagePath) async => null;

  @override
  Future<FaceKeyPoints?> detectFace(String imagePath) async => null;

  static Future<String> selfTest() async => 'Web 端无端侧模型';
}
