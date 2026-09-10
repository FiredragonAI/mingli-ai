import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // UIScene 生命周期下 window 在此刻尚未就绪,改用插件注册器拿 messenger
    if let registrar = self.registrar(forPlugin: "MingliVisionPlugin") {
      MingliVisionPlugin.register(with: registrar.messenger())
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// MARK: - 端侧视觉:手部 / 面部关键点(Apple Vision)
//
// 与 AppDelegate 放在同一文件,是因为 Xcode 工程不会自动收录新建的 .swift 文件,
// 而本项目没有 Mac 可以打开 Xcode。合并后无需改 project.pbxproj。
// MethodChannel `mingli/vision`,只返回坐标,图像不离开本进程。

final class MingliVisionPlugin: NSObject {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "mingli/vision", binaryMessenger: messenger)
    let plugin = MingliVisionPlugin()
    channel.setMethodCallHandler(plugin.handle)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any], let path = args["path"] as? String,
          let image = UIImage(contentsOfFile: path), let cg = image.cgImage else {
      result(FlutterError(code: "bad_args", message: "需要 path", details: nil))
      return
    }
    let orientation = CGImagePropertyOrientation(image.imageOrientation)
    let width = CGFloat(cg.width), height = CGFloat(cg.height)

    DispatchQueue.global(qos: .userInitiated).async {
      switch call.method {
      case "detectHand":
        self.detectHand(cg, orientation, width, height, result)
      case "detectFace":
        self.detectFace(cg, orientation, width, height, result)
      default:
        DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
      }
    }
  }

  // MARK: 手部 21 点(转成 MediaPipe 顺序)

  private func detectHand(_ cg: CGImage, _ o: CGImagePropertyOrientation, _ w: CGFloat, _ h: CGFloat, _ result: @escaping FlutterResult) {
    let request = VNDetectHumanHandPoseRequest()
    request.maximumHandCount = 1
    let handler = VNImageRequestHandler(cgImage: cg, orientation: o, options: [:])
    do {
      try handler.perform([request])
      guard let obs = request.results?.first else {
        DispatchQueue.main.async { result(nil) }
        return
      }
      let order: [VNHumanHandPoseObservation.JointName] = [
        .wrist,
        .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
        .indexMCP, .indexPIP, .indexDIP, .indexTip,
        .middleMCP, .middlePIP, .middleDIP, .middleTip,
        .ringMCP, .ringPIP, .ringDIP, .ringTip,
        .littleMCP, .littlePIP, .littleDIP, .littleTip,
      ]
      var points: [[String: Double]] = []
      for j in order {
        guard let p = try? obs.recognizedPoint(j), p.confidence > 0.1 else {
          DispatchQueue.main.async { result(nil) }
          return
        }
        // Vision 坐标原点左下,翻成图像坐标(原点左上)
        points.append(["x": Double(p.location.x * w), "y": Double((1 - p.location.y) * h)])
      }
      var isLeft = false
      if #available(iOS 15.0, *) { isLeft = obs.chirality == .left }
      DispatchQueue.main.async { result(["points": points, "isLeft": isLeft]) }
    } catch {
      DispatchQueue.main.async { result(FlutterError(code: "vision", message: error.localizedDescription, details: nil)) }
    }
  }

  // MARK: 面部命名关键点

  private func detectFace(_ cg: CGImage, _ o: CGImagePropertyOrientation, _ w: CGFloat, _ h: CGFloat, _ result: @escaping FlutterResult) {
    let request = VNDetectFaceLandmarksRequest()
    let handler = VNImageRequestHandler(cgImage: cg, orientation: o, options: [:])
    do {
      try handler.perform([request])
      guard let face = request.results?.first, let lm = face.landmarks else {
        DispatchQueue.main.async { result(nil) }
        return
      }
      let box = face.boundingBox
      func px(_ p: CGPoint) -> [String: Double] {
        let x = (box.origin.x + p.x * box.size.width) * w
        let y = (1 - (box.origin.y + p.y * box.size.height)) * h
        return ["x": Double(x), "y": Double(y)]
      }
      func pts(_ r: VNFaceLandmarkRegion2D?) -> [CGPoint] { r?.normalizedPoints ?? [] }
      func minBy(_ a: [CGPoint], _ f: (CGPoint) -> CGFloat) -> CGPoint { a.min { f($0) < f($1) } ?? .zero }
      func maxBy(_ a: [CGPoint], _ f: (CGPoint) -> CGFloat) -> CGPoint { a.max { f($0) < f($1) } ?? .zero }

      let contour = pts(lm.faceContour)
      let lEye = pts(lm.leftEye), rEye = pts(lm.rightEye)
      let lBrow = pts(lm.leftEyebrow), rBrow = pts(lm.rightEyebrow)
      let nose = pts(lm.nose), crest = pts(lm.noseCrest), median = pts(lm.medianLine)
      let outer = pts(lm.outerLips), inner = pts(lm.innerLips)
      guard !contour.isEmpty, !lEye.isEmpty, !rEye.isEmpty, !nose.isEmpty, !outer.isEmpty, !median.isEmpty else {
        DispatchQueue.main.async { result(nil) }
        return
      }

      // Vision 的 left/right 是被摄者视角;这里 left = 图像左侧(即被摄者右侧)
      let imgLeftEye = rEye, imgRightEye = lEye
      let imgLeftBrow = rBrow, imgRightBrow = lBrow

      let chin = minBy(contour) { $0.y }
      let cheekL = minBy(contour) { $0.x }, cheekR = maxBy(contour) { $0.x }
      let foreheadTop = maxBy(median) { $0.y }
      let browY = ((imgLeftBrow.map { $0.y }.max() ?? 0) + (imgRightBrow.map { $0.y }.max() ?? 0)) / 2
      let templeL = contour.filter { $0.x < 0.5 }.min { abs($0.y - browY) < abs($1.y - browY) } ?? cheekL
      let templeR = contour.filter { $0.x >= 0.5 }.min { abs($0.y - browY) < abs($1.y - browY) } ?? cheekR
      let mouthY = outer.map { $0.y }.reduce(0, +) / CGFloat(outer.count)
      let jawL = contour.filter { $0.x < 0.5 }.min { abs($0.y - mouthY) < abs($1.y - mouthY) } ?? cheekL
      let jawR = contour.filter { $0.x >= 0.5 }.min { abs($0.y - mouthY) < abs($1.y - mouthY) } ?? cheekR

      let nasion = maxBy(crest.isEmpty ? nose : crest) { $0.y }
      let noseTip = maxBy(nose) { $0.y }
      let noseBottom = minBy(nose) { $0.y }
      let nostrilL = minBy(nose) { $0.x }, nostrilR = maxBy(nose) { $0.x }

      let out: [String: Any] = [
        "foreheadTop": px(foreheadTop), "chin": px(chin),
        "templeLeft": px(templeL), "templeRight": px(templeR),
        "cheekLeft": px(cheekL), "cheekRight": px(cheekR),
        "jawLeft": px(jawL), "jawRight": px(jawR),
        "browLeftInner": px(maxBy(imgLeftBrow) { $0.x }), "browLeftOuter": px(minBy(imgLeftBrow) { $0.x }), "browLeftTop": px(maxBy(imgLeftBrow) { $0.y }),
        "browRightInner": px(minBy(imgRightBrow) { $0.x }), "browRightOuter": px(maxBy(imgRightBrow) { $0.x }), "browRightTop": px(maxBy(imgRightBrow) { $0.y }),
        "eyeLeftInner": px(maxBy(imgLeftEye) { $0.x }), "eyeLeftOuter": px(minBy(imgLeftEye) { $0.x }),
        "eyeLeftTop": px(maxBy(imgLeftEye) { $0.y }), "eyeLeftBottom": px(minBy(imgLeftEye) { $0.y }),
        "eyeRightInner": px(minBy(imgRightEye) { $0.x }), "eyeRightOuter": px(maxBy(imgRightEye) { $0.x }),
        "eyeRightTop": px(maxBy(imgRightEye) { $0.y }), "eyeRightBottom": px(minBy(imgRightEye) { $0.y }),
        "nasion": px(nasion), "noseTip": px(noseTip), "noseBottom": px(noseBottom),
        "nostrilLeft": px(nostrilL), "nostrilRight": px(nostrilR),
        "mouthLeft": px(minBy(outer) { $0.x }), "mouthRight": px(maxBy(outer) { $0.x }),
        "lipTop": px(maxBy(outer) { $0.y }), "lipBottom": px(minBy(outer) { $0.y }),
        "lipInnerTop": px(maxBy(inner.isEmpty ? outer : inner) { $0.y }),
        "lipInnerBottom": px(minBy(inner.isEmpty ? outer : inner) { $0.y }),
      ]
      DispatchQueue.main.async { result(out) }
    } catch {
      DispatchQueue.main.async { result(FlutterError(code: "vision", message: error.localizedDescription, details: nil)) }
    }
  }
}

extension CGImagePropertyOrientation {
  init(_ o: UIImage.Orientation) {
    switch o {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
