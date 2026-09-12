# 端侧模型(Windows 用)

两级流水线,与 MediaPipe 官方图一致:先**检测**(整张照片里找到目标的位置与倾斜角),
裁切摆正后再提**关键点**。所以全身照、合照、歪着拍的照片都能用。

| 文件 | 作用 | 输入 | 输出 |
|---|---|---|---|
| `face_detection_full_range.tflite` | BlazeFace 全距检测(远处小脸) | 192×192 | 2304 锚框 × (4 框 + 6 关键点) |
| `face_detection_short_range.tflite` | BlazeFace 短距检测(自拍距离,兜底) | 128×128 | 896 锚框 × 16 |
| `palm_detection_full.tflite` | BlazePalm 手掌检测 | 192×192 | 2016 锚框 × (4 框 + 7 关键点) |
| `face_landmark.tflite` | Face Mesh 468 点 | 192×192 | 1404 + 置信度 |
| `hand_landmark_full.tflite` | Hand Landmark 21 点 | 224×224 | 63 + 存在概率 + 左右手 + 63(世界坐标) |

锚框生成与解码规则见 `lib/services/vision/ssd_anchors.dart`,ROI 裁切与坐标映射见 `roi.dart`。

来源:`https://storage.googleapis.com/mediapipe-assets/`(Google MediaPipe 官方模型资源桶)。
许可:Apache License 2.0(见 <https://github.com/google/mediapipe/blob/master/LICENSE>)。

Windows 端运行它们还需要 `app/blobs/libtensorflowlite_c-win.dll`(TensorFlow Lite C API,
Apache-2.0,取自 tflite_flutter 早期作者的发布页
<https://github.com/am15h/tflite_flutter_plugin/releases/tag/v0.5.0>)。这是较老的 TFLite 版本,
只含 CPU 推理、不含 XNNPack/GPU 加速;五个模型实测均可正常加载推理(见 docs/SETUP.md 自检)。
将来若换更新的 DLL,把文件替换后重跑自检即可。

iOS 端改用 Apple Vision(`VNDetectHumanHandPoseRequest` / `VNDetectFaceLandmarksRequest`),
系统自带、自己处理整图定位,不需要这些文件。

重新下载:

```bash
for f in face_detection_full_range face_detection_short_range palm_detection_full face_landmark hand_landmark_full; do
  curl -o $f.tflite https://storage.googleapis.com/mediapipe-assets/$f.tflite
done
```
