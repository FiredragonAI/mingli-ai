/// MediaPipe Face Mesh(468 点)→ 命名关键点。
///
/// 索引来自 MediaPipe 官方 canonical face mesh 拓扑。"左/右"按**图像视角**:
/// 图像左侧(被摄者右脸)记为 left。
library;

import '../../core/vision/face_features.dart';
import '../../core/vision/geometry.dart';

FaceKeyPoints faceKeyPointsFromMediaPipe(List<Point2> p) {
  return FaceKeyPoints(
    foreheadTop: p[10],
    chin: p[152],
    templeLeft: p[127],
    templeRight: p[356],
    cheekLeft: p[234],
    cheekRight: p[454],
    jawLeft: p[172],
    jawRight: p[397],
    browLeftInner: p[107],
    browLeftOuter: p[70],
    browLeftTop: p[105],
    browRightInner: p[336],
    browRightOuter: p[300],
    browRightTop: p[334],
    eyeLeftInner: p[133],
    eyeLeftOuter: p[33],
    eyeLeftTop: p[159],
    eyeLeftBottom: p[145],
    eyeRightInner: p[362],
    eyeRightOuter: p[263],
    eyeRightTop: p[386],
    eyeRightBottom: p[374],
    nasion: p[168],
    noseTip: p[1],
    noseBottom: p[2],
    nostrilLeft: p[98],
    nostrilRight: p[327],
    mouthLeft: p[61],
    mouthRight: p[291],
    lipTop: p[0],
    lipBottom: p[17],
    lipInnerTop: p[13],
    lipInnerBottom: p[14],
  );
}

/// 供测试用的合成人脸(正脸、比例接近理想),避免在测试里依赖模型。
FaceKeyPoints syntheticIdealFace() {
  const w = 300.0, h = 420.0;
  const cx = w / 2;
  return FaceKeyPoints(
    foreheadTop: const Point2(cx, 0),
    chin: const Point2(cx, h),
    templeLeft: const Point2(15, 140),
    templeRight: const Point2(w - 15, 140),
    cheekLeft: const Point2(0, 210),
    cheekRight: const Point2(w, 210),
    jawLeft: const Point2(35, 340),
    jawRight: const Point2(w - 35, 340),
    browLeftInner: const Point2(cx - 30, 140),
    browLeftOuter: const Point2(cx - 95, 145),
    browLeftTop: const Point2(cx - 62, 135),
    browRightInner: const Point2(cx + 30, 140),
    browRightOuter: const Point2(cx + 95, 145),
    browRightTop: const Point2(cx + 62, 135),
    eyeLeftInner: const Point2(cx - 30, 175),
    eyeLeftOuter: const Point2(cx - 90, 175),
    eyeLeftTop: const Point2(cx - 60, 165),
    eyeLeftBottom: const Point2(cx - 60, 185),
    eyeRightInner: const Point2(cx + 30, 175),
    eyeRightOuter: const Point2(cx + 90, 175),
    eyeRightTop: const Point2(cx + 60, 165),
    eyeRightBottom: const Point2(cx + 60, 185),
    nasion: const Point2(cx, 170),
    noseTip: const Point2(cx, 260),
    noseBottom: const Point2(cx, 280),
    nostrilLeft: const Point2(cx - 35, 270),
    nostrilRight: const Point2(cx + 35, 270),
    mouthLeft: const Point2(cx - 55, 335),
    mouthRight: const Point2(cx + 55, 335),
    lipTop: const Point2(cx, 320),
    lipBottom: const Point2(cx, 352),
    lipInnerTop: const Point2(cx, 334),
    lipInnerBottom: const Point2(cx, 338),
  );
}
