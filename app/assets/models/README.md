# 端侧模型(Windows 用)

- `hand_landmark_full.tflite` — MediaPipe Hand Landmark(full),输入 224×224×3
- `face_landmark.tflite` — MediaPipe Face Mesh,468 点,输入 192×192×3

来源:`https://storage.googleapis.com/mediapipe-assets/`(Google MediaPipe 官方模型资源桶)。
许可:Apache License 2.0(见 <https://github.com/google/mediapipe/blob/master/LICENSE>)。

Windows 端运行它们还需要 `app/blobs/libtensorflowlite_c-win.dll`(TensorFlow Lite C API,
Apache-2.0,取自 tflite_flutter 早期作者的发布页
<https://github.com/am15h/tflite_flutter_plugin/releases/tag/v0.5.0>)。这是较老的 TFLite 版本,
只含 CPU 推理、不含 XNNPack/GPU 加速;两个模型实测均可正常加载推理(见 docs/SETUP.md 自检)。
将来若换更新的 DLL,把文件替换后重跑自检即可。

iOS 端改用 Apple Vision(`VNDetectHumanHandPoseRequest` / `VNDetectFaceLandmarksRequest`),
系统自带,不需要这两个文件。

重新下载(文件较大,不进 git,首次搭建环境需手动获取一次,已在本仓库中提供):

```bash
curl -o hand_landmark_full.tflite https://storage.googleapis.com/mediapipe-assets/hand_landmark_full.tflite
curl -o face_landmark.tflite https://storage.googleapis.com/mediapipe-assets/face_landmark.tflite
```
