/// 端侧关键点检测的统一接口。
///
/// - iOS:走 MethodChannel 调 Apple Vision(VNDetectHumanHandPoseRequest /
///   VNDetectFaceLandmarksRequest),零模型体积、系统级优化。
/// - Windows:走 tflite_flutter 跑 MediaPipe Hand/Face Landmark 模型。
///
/// 两端都只返回关键点;照片从不离开进程内存。
library;

import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/vision/face_features.dart';
import '../../core/vision/geometry.dart';
import '../../core/vision/palm_features.dart';
import 'tflite_landmark_service.dart';

abstract class LandmarkService {
  /// 检测手部 21 关键点。检测不到返回 null。
  Future<HandLandmarks?> detectHand(String imagePath);

  /// 检测面部关键点并转为命名点。检测不到返回 null。
  Future<FaceKeyPoints?> detectFace(String imagePath);

  /// 上一次检测"在照片里哪儿找到的目标"的说明,给用户看;平台不提供时为 null。
  String? get lastLocationNote => null;

  /// 按平台选实现。
  static LandmarkService forPlatform() {
    if (Platform.isIOS) return IosVisionLandmarkService();
    return TfliteLandmarkService();
  }
}

/// iOS:Apple Vision。Swift 侧实现见 `ios/Runner/VisionPlugin.swift`。
class IosVisionLandmarkService implements LandmarkService {
  static const _channel = MethodChannel('mingli/vision');

  @override
  String? get lastLocationNote => null;

  @override
  Future<HandLandmarks?> detectHand(String imagePath) async {
    final res = await _channel.invokeMapMethod<String, dynamic>('detectHand', {'path': imagePath});
    if (res == null) return null;
    final pts = (res['points'] as List)
        .map((p) => Point2((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
        .toList();
    if (pts.length != 21) return null;
    return HandLandmarks(points: pts, isLeftHand: res['isLeft'] as bool? ?? false);
  }

  @override
  Future<FaceKeyPoints?> detectFace(String imagePath) async {
    final res = await _channel.invokeMapMethod<String, dynamic>('detectFace', {'path': imagePath});
    if (res == null) return null;
    return FaceKeyPoints.fromJson(res);
  }
}
