/// 面相特征。
///
/// 各平台(iOS Vision / Windows MediaPipe)把检测结果转换成同一套**命名关键点**
/// [FaceKeyPoints],这里只做比例几何:三庭五眼、脸型、十二宫的几何代理。
/// 输出不含像素,不含可逆的关键点坐标——只有比例和分类。
library;

import 'geometry.dart';

/// 平台无关的面部关键点。坐标为图像像素或归一化坐标皆可,内部只用比例。
class FaceKeyPoints {
  const FaceKeyPoints({
    required this.foreheadTop,
    required this.chin,
    required this.templeLeft,
    required this.templeRight,
    required this.cheekLeft,
    required this.cheekRight,
    required this.jawLeft,
    required this.jawRight,
    required this.browLeftInner,
    required this.browLeftOuter,
    required this.browLeftTop,
    required this.browRightInner,
    required this.browRightOuter,
    required this.browRightTop,
    required this.eyeLeftInner,
    required this.eyeLeftOuter,
    required this.eyeLeftTop,
    required this.eyeLeftBottom,
    required this.eyeRightInner,
    required this.eyeRightOuter,
    required this.eyeRightTop,
    required this.eyeRightBottom,
    required this.nasion,
    required this.noseTip,
    required this.noseBottom,
    required this.nostrilLeft,
    required this.nostrilRight,
    required this.mouthLeft,
    required this.mouthRight,
    required this.lipTop,
    required this.lipBottom,
    required this.lipInnerTop,
    required this.lipInnerBottom,
  });

  final Point2 foreheadTop; // 发际中点(天庭上缘)
  final Point2 chin; // 下巴最低点(地阁)
  final Point2 templeLeft, templeRight; // 眉高处两侧
  final Point2 cheekLeft, cheekRight; // 颧骨最宽处
  final Point2 jawLeft, jawRight; // 口角高度两侧下颌
  final Point2 browLeftInner, browLeftOuter, browLeftTop;
  final Point2 browRightInner, browRightOuter, browRightTop;
  final Point2 eyeLeftInner, eyeLeftOuter, eyeLeftTop, eyeLeftBottom;
  final Point2 eyeRightInner, eyeRightOuter, eyeRightTop, eyeRightBottom;
  final Point2 nasion; // 山根
  final Point2 noseTip; // 准头
  final Point2 noseBottom; // 鼻底
  final Point2 nostrilLeft, nostrilRight; // 鼻翼
  final Point2 mouthLeft, mouthRight;
  final Point2 lipTop, lipBottom; // 唇外缘
  final Point2 lipInnerTop, lipInnerBottom; // 唇缝

  factory FaceKeyPoints.fromJson(Map<String, dynamic> j) {
    Point2 p(String k) => Point2.fromJson(j[k] as Map<String, dynamic>);
    return FaceKeyPoints(
      foreheadTop: p('foreheadTop'),
      chin: p('chin'),
      templeLeft: p('templeLeft'),
      templeRight: p('templeRight'),
      cheekLeft: p('cheekLeft'),
      cheekRight: p('cheekRight'),
      jawLeft: p('jawLeft'),
      jawRight: p('jawRight'),
      browLeftInner: p('browLeftInner'),
      browLeftOuter: p('browLeftOuter'),
      browLeftTop: p('browLeftTop'),
      browRightInner: p('browRightInner'),
      browRightOuter: p('browRightOuter'),
      browRightTop: p('browRightTop'),
      eyeLeftInner: p('eyeLeftInner'),
      eyeLeftOuter: p('eyeLeftOuter'),
      eyeLeftTop: p('eyeLeftTop'),
      eyeLeftBottom: p('eyeLeftBottom'),
      eyeRightInner: p('eyeRightInner'),
      eyeRightOuter: p('eyeRightOuter'),
      eyeRightTop: p('eyeRightTop'),
      eyeRightBottom: p('eyeRightBottom'),
      nasion: p('nasion'),
      noseTip: p('noseTip'),
      noseBottom: p('noseBottom'),
      nostrilLeft: p('nostrilLeft'),
      nostrilRight: p('nostrilRight'),
      mouthLeft: p('mouthLeft'),
      mouthRight: p('mouthRight'),
      lipTop: p('lipTop'),
      lipBottom: p('lipBottom'),
      lipInnerTop: p('lipInnerTop'),
      lipInnerBottom: p('lipInnerBottom'),
    );
  }

  /// 图像中的 y 轴向下时,brow 中心 y 取两眉顶端平均。
  double get browLineY => (browLeftTop.y + browRightTop.y) / 2;
  double get eyeLineY =>
      (eyeLeftInner.y + eyeLeftOuter.y + eyeRightInner.y + eyeRightOuter.y) / 4;
}

class FaceFeatures {
  const FaceFeatures({
    required this.faceShape,
    required this.faceAspect,
    required this.threeCourts,
    required this.fiveEyes,
    required this.foreheadWidthRatio,
    required this.cheekWidthRatio,
    required this.jawWidthRatio,
    required this.browLengthRatio,
    required this.browGapRatio,
    required this.eyeOpenness,
    required this.eyeTilt,
    required this.noseWidthRatio,
    required this.noseLengthRatio,
    required this.mouthWidthRatio,
    required this.lipThicknessRatio,
    required this.mouthCornerTilt,
    required this.chinLengthRatio,
    required this.symmetry,
    required this.palaces,
    required this.notes,
  });

  /// 田 / 由 / 甲 / 申 / 目 / 圆 / 同。
  final String faceShape;
  final double faceAspect;

  /// 上停、中停、下停占比,和为 1。
  final List<double> threeCourts;

  /// 脸宽 / 眼长。理想约 5。
  final double fiveEyes;

  final double foreheadWidthRatio; // 额宽 / 脸宽
  final double cheekWidthRatio; // 颧宽 / 脸宽(=1 时以颧骨为最宽)
  final double jawWidthRatio; // 颌宽 / 脸宽
  final double browLengthRatio; // 眉长 / 眼长
  final double browGapRatio; // 印堂宽 / 眼长
  final double eyeOpenness; // 眼高 / 眼长
  final double eyeTilt; // 眼尾相对眼头的倾角,正为上扬
  final double noseWidthRatio; // 鼻翼宽 / 脸宽
  final double noseLengthRatio; // 山根到鼻底 / 脸长
  final double mouthWidthRatio; // 口宽 / 脸宽
  final double lipThicknessRatio; // 唇厚 / 脸长
  final double mouthCornerTilt; // 口角倾角,正为上扬
  final double chinLengthRatio; // 唇下到下巴 / 脸长
  final double symmetry; // 0–1,1 为完全对称

  /// 十二宫几何代理描述。
  final Map<String, String> palaces;
  final List<String> notes;

  Map<String, dynamic> toJson() => {
        'faceShape': faceShape,
        'faceAspect': round3(faceAspect),
        'threeCourts': threeCourts.map(round3).toList(),
        'fiveEyes': round3(fiveEyes),
        'widths': {
          'forehead': round3(foreheadWidthRatio),
          'cheek': round3(cheekWidthRatio),
          'jaw': round3(jawWidthRatio),
        },
        'brow': {'length': round3(browLengthRatio), 'gap': round3(browGapRatio)},
        'eye': {'openness': round3(eyeOpenness), 'tilt': round3(eyeTilt)},
        'nose': {'width': round3(noseWidthRatio), 'length': round3(noseLengthRatio)},
        'mouth': {
          'width': round3(mouthWidthRatio),
          'lipThickness': round3(lipThicknessRatio),
          'cornerTilt': round3(mouthCornerTilt),
        },
        'chinLength': round3(chinLengthRatio),
        'symmetry': round3(symmetry),
        'palaces': palaces,
        'notes': notes,
      };
}

FaceFeatures computeFaceFeatures(FaceKeyPoints k) {
  final faceHeight = k.chin.y - k.foreheadTop.y;
  final faceWidth = k.cheekRight.x - k.cheekLeft.x;
  final aspect = faceHeight / faceWidth;

  // 三停
  final upper = (k.browLineY - k.foreheadTop.y) / faceHeight;
  final middle = (k.noseBottom.y - k.browLineY) / faceHeight;
  final lower = (k.chin.y - k.noseBottom.y) / faceHeight;

  // 五眼
  final eyeLen = (k.eyeLeftInner.distanceTo(k.eyeLeftOuter) +
          k.eyeRightInner.distanceTo(k.eyeRightOuter)) /
      2;
  final fiveEyes = faceWidth / eyeLen;

  final foreheadW = (k.templeRight.x - k.templeLeft.x) / faceWidth;
  final jawW = (k.jawRight.x - k.jawLeft.x) / faceWidth;

  // 脸型(十字面法的几何近似)
  String shape;
  if (aspect > 1.55) {
    shape = '目字面';
  } else if (foreheadW > jawW + 0.12) {
    shape = '甲字面';
  } else if (jawW > foreheadW + 0.10) {
    shape = '由字面';
  } else if (aspect < 1.25 && (jawW - foreheadW).abs() < 0.08) {
    shape = jawW > 0.85 ? '田字面' : '圆字面';
  } else if (foreheadW < 0.88 && jawW < 0.88) {
    shape = '申字面';
  } else {
    shape = '同字面';
  }

  final browLen = (k.browLeftInner.distanceTo(k.browLeftOuter) +
          k.browRightInner.distanceTo(k.browRightOuter)) /
      2;
  final browGap = k.browRightInner.distanceTo(k.browLeftInner);

  final eyeH = ((k.eyeLeftBottom.y - k.eyeLeftTop.y) + (k.eyeRightBottom.y - k.eyeRightTop.y)) / 2;
  // 眼尾上扬:图像 y 向下,故 inner.y − outer.y 为正表示上扬
  final tiltL = -tiltDegrees(k.eyeLeftInner, k.eyeLeftOuter);
  final tiltR = tiltDegrees(k.eyeRightOuter, k.eyeRightInner);
  final eyeTilt = (tiltL.abs() + tiltR.abs()) / 2 * ((tiltL + tiltR) >= 0 ? 1 : -1);

  final noseW = k.nostrilRight.distanceTo(k.nostrilLeft) / faceWidth;
  final noseL = (k.noseBottom.y - k.nasion.y) / faceHeight;

  final mouthW = k.mouthRight.distanceTo(k.mouthLeft) / faceWidth;
  final lipThick = (k.lipBottom.y - k.lipTop.y) / faceHeight;
  final cornerY = (k.mouthLeft.y + k.mouthRight.y) / 2;
  final lipMidY = (k.lipInnerTop.y + k.lipInnerBottom.y) / 2;
  final cornerTilt = (lipMidY - cornerY) / eyeLen * 45; // 口角高于唇缝为正

  final chinLen = (k.chin.y - k.lipBottom.y) / faceHeight;

  // 对称:左右眼长、眉长、口角高度差
  final eyeAsym = (k.eyeLeftInner.distanceTo(k.eyeLeftOuter) -
              k.eyeRightInner.distanceTo(k.eyeRightOuter))
          .abs() /
      eyeLen;
  final browAsym = (k.browLeftInner.distanceTo(k.browLeftOuter) -
              k.browRightInner.distanceTo(k.browRightOuter))
          .abs() /
      browLen;
  final mouthAsym = (k.mouthLeft.y - k.mouthRight.y).abs() / eyeLen;
  final symmetry = (1 - (eyeAsym + browAsym + mouthAsym) / 3).clamp(0.0, 1.0);

  // 十二宫几何代理
  final palaces = <String, String>{
    '命宫(印堂)': browGap / eyeLen > 1.05 ? '开阔' : browGap / eyeLen < 0.85 ? '狭窄' : '适中',
    '财帛宫(鼻)': noseW > 0.27 ? '鼻翼丰厚' : noseW < 0.21 ? '鼻翼收窄' : '鼻翼适中',
    '官禄宫(额中)': upper > 0.35 ? '天庭饱满' : upper < 0.29 ? '额部偏短' : '额部适中',
    '田宅宫(眼上)': (k.eyeLeftTop.y - k.browLeftTop.y) / eyeLen > 0.55 ? '眉眼距宽' : '眉眼距窄',
    '夫妻宫(眼尾)': eyeTilt > 4 ? '眼尾上扬' : eyeTilt < -4 ? '眼尾下垂' : '眼尾平顺',
    '兄弟宫(眉)': browLen / eyeLen > 1.1 ? '眉长过目' : browLen / eyeLen < 0.9 ? '眉短于目' : '眉眼齐长',
    '疾厄宫(山根)': (k.nasion.y - k.eyeLineY).abs() / eyeLen < 0.15 ? '山根平' : '山根有起',
    '奴仆宫(下颌)': jawW > 0.88 ? '下颌方阔' : jawW < 0.78 ? '下颌收窄' : '下颌适中',
    '地阁(下巴)': chinLen > 0.20 ? '地阁长厚' : chinLen < 0.14 ? '地阁偏短' : '地阁适中',
    '迁移宫(额角)': foreheadW > 0.92 ? '额角开阔' : '额角内收',
  };

  final notes = <String>[
    '三停 ${(upper * 100).round()} : ${(middle * 100).round()} : ${(lower * 100).round()}'
        '(理想约 33:33:33,${_courtComment(upper, middle, lower)})',
    '五眼比 ${fiveEyes.toStringAsFixed(1)}(理想约 5)',
    '脸型为$shape',
    if (symmetry < 0.9) '面部左右略不对称' else '面部对称度良好',
    if (mouthW > 0.42) '口阔' else if (mouthW < 0.34) '口小',
    if (lipThick > 0.09) '唇厚' else if (lipThick < 0.06) '唇薄',
  ];

  return FaceFeatures(
    faceShape: shape,
    faceAspect: aspect,
    threeCourts: [upper, middle, lower],
    fiveEyes: fiveEyes,
    foreheadWidthRatio: foreheadW,
    cheekWidthRatio: 1.0,
    jawWidthRatio: jawW,
    browLengthRatio: browLen / eyeLen,
    browGapRatio: browGap / eyeLen,
    eyeOpenness: eyeH / eyeLen,
    eyeTilt: eyeTilt,
    noseWidthRatio: noseW,
    noseLengthRatio: noseL,
    mouthWidthRatio: mouthW,
    lipThicknessRatio: lipThick,
    mouthCornerTilt: cornerTilt,
    chinLengthRatio: chinLen,
    symmetry: symmetry,
    palaces: palaces,
    notes: notes,
  );
}

String _courtComment(double u, double m, double l) {
  final maxIdx = [u, m, l].indexOf([u, m, l].reduce((a, b) => a > b ? a : b));
  return ['上停偏长,早年运与思虑为重', '中停偏长,中年运与行动力为重', '下停偏长,晚年运与意志力为重'][maxIdx];
}
