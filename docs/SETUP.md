# 开发环境

## 工具链

| 工具 | 版本 | 说明 |
|---|---|---|
| Flutter | ≥ 3.27(Dart ≥ 3.6) | iOS + Windows 桌面;用到 `Color.withValues` 与 `CardThemeData` |
| Xcode | ≥ 15 | iOS 构建与 Vision 框架 |
| Visual Studio 2022 | 含"使用 C++ 的桌面开发" | Windows 构建 |
| Node.js | ≥ 20 | 后端 |

```bash
flutter config --enable-windows-desktop
flutter doctor
```

## 客户端

```bash
cd app
flutter pub get
flutter test
```

首跑测试重点看 `test/astro/solar_terms_test.dart` 和 `test/calendar/lunar_test.dart`:
它们对照的是历书参照值,全绿说明天文底层无误。

### 资源文件(需自行放置)

| 路径 | 内容 | 来源 |
|---|---|---|
| `assets/data/kangxi_strokes.json` | 康熙笔画字典 | 开源整理版或自建;格式见 `stroke_dictionary.dart` |
| `assets/models/hand_landmark_full.tflite` | MediaPipe 手部关键点 | MediaPipe 官方发布 |
| `assets/models/face_landmark.tflite` | MediaPipe 面部 468 点 | MediaPipe 官方发布 |
| `assets/fonts/SourceHanSerifSC-*.otf` | 思源宋体 | Adobe 开源(SIL OFL) |

Windows 端 `tflite_flutter` 需要 `libtensorflowlite_c.dll`,参考该包 README 放到 `windows/` 下。

### 运行

```bash
flutter run -d windows
```

```bash
flutter run -d <ios-device-id>
```

首次启动在"设置"里填后端地址(默认 `http://localhost:8787`)。

## 后端

```bash
cd server
cp .env.example .env    # 填 ANTHROPIC_API_KEY
npm install
npm run dev
```

生产:

```bash
npm run build && npm start
```

或 `docker build -t mingli-server . && docker run -p 8787:8787 --env-file .env mingli-server`。

## iOS 原生部分

`ios/Runner/VisionPlugin.swift` 在 `AppDelegate` 里注册 MethodChannel `mingli/vision`。
`Info.plist` 需添加:

```xml
<key>NSCameraUsageDescription</key>
<string>用于拍摄手掌或面部,照片仅在本机分析,不会上传。</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>用于选择手掌或面部照片,照片仅在本机分析,不会上传。</string>
```
