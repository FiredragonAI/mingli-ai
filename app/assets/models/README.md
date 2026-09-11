# 端侧模型(Windows 用)

- `hand_landmark_full.tflite` — MediaPipe Hand Landmark(full),输入 224×224×3
- `face_landmark.tflite` — MediaPipe Face Mesh,468 点,输入 192×192×3

来源:`https://storage.googleapis.com/mediapipe-assets/`(Google MediaPipe 官方模型资源桶)。
许可:Apache License 2.0(见 <https://github.com/google/mediapipe/blob/master/LICENSE>)。

iOS 端改用 Apple Vision(`VNDetectHumanHandPoseRequest` / `VNDetectFaceLandmarksRequest`),
系统自带,不需要这两个文件。

重新下载(文件较大,不进 git,首次搭建环境需手动获取一次,已在本仓库中提供):

```bash
curl -o hand_landmark_full.tflite https://storage.googleapis.com/mediapipe-assets/hand_landmark_full.tflite
curl -o face_landmark.tflite https://storage.googleapis.com/mediapipe-assets/face_landmark.tflite
```
