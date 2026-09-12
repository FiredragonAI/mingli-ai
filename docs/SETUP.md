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

### 资源文件

| 路径 | 内容 | 状态 |
|---|---|---|
| `assets/data/kangxi_strokes.json` | 康熙笔画字典(10.3 万字,由 Unihan 派生) | 已随仓库提供,生成脚本 `tools/build_kangxi_dict.mjs` |
| `assets/models/hand_landmark_full.tflite` | MediaPipe 手部关键点 | 已随仓库提供(Apache-2.0) |
| `assets/models/face_landmark.tflite` | MediaPipe 面部 468 点 | 已随仓库提供(Apache-2.0) |
| `assets/fonts/SourceHanSerifSC-*.otf` | 思源宋体 | 可选;放入后取消 `pubspec.yaml` 里 fonts 段的注释 |
| `blobs/libtensorflowlite_c-win.dll` | TensorFlow Lite C 动态库(Windows 端跑手相/面相模型) | 已随仓库提供;`windows/CMakeLists.txt` 打包到 `<exe>/blobs/` |

**Windows 端侧模型自检**:设环境变量 `MINGLI_SELFTEST=1` 启动 exe,不进界面,
把两个模型的张量形状与一次空跑结果写到 `%TEMP%\mingli_selftest.txt` 后退出。
改动 DLL 或模型后先跑这个。

### 运行

```bash
flutter run -d windows
```

```bash
flutter run -d <ios-device-id>
```

后端地址在编译时注入:`--dart-define=MINGLI_API_URL=https://…`(以及可选的
`--dart-define=MINGLI_APP_TOKEN=…`)。不带参数时默认 `http://localhost:8787`,
也可以运行后在"设置"里临时改。云端部署见 [DEPLOY.md](DEPLOY.md)。
连不上云端时 app 自动退回本机规则引擎生成解读。

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
