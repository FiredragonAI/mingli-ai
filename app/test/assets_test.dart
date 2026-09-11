// 校验第三方资源确实打包进了 app——这两个文件之前只有占位 README,
// 用户实际点"面相 AI"时报 "Unable to load asset"。现在应确认能读到。

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MediaPipe 手部/面部关键点模型已打包且是合法 tflite 文件', () async {
    for (final path in [
      'assets/models/hand_landmark_full.tflite',
      'assets/models/face_landmark.tflite',
    ]) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(1000000), reason: '$path 体积过小,像是占位文件');
      // tflite(FlatBuffers)文件第 4-7 字节是标识符 "TFL3"
      final magic = String.fromCharCodes(data.buffer.asUint8List(4, 4));
      expect(magic, 'TFL3', reason: '$path 不是合法的 tflite 文件');
    }
  });

  test('康熙笔画字典已打包且覆盖到常用五行字', () async {
    final data = await rootBundle.loadString('assets/data/kangxi_strokes.json');
    for (final ch in ['火', '水', '土', '金', '木', '云', '国', '龙']) {
      expect(data.contains('"$ch"'), isTrue, reason: '字典缺少「$ch」');
    }
    expect(data.length, greaterThan(1000000), reason: '字典体积过小,可能只是内置兜底表');
  });
}
