import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController {
      setupOcrChannel(messenger: controller.binaryMessenger)
    }

    return ok
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SafebiteOcrPlugin") {
      setupOcrChannel(messenger: registrar.messenger())
    }
  }

  private func setupOcrChannel(messenger: FlutterBinaryMessenger) {
    let ocrChannel = FlutterMethodChannel(name: "safebite/ocr", binaryMessenger: messenger)
    ocrChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "recognizeText" {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String,
              let image = UIImage(contentsOfFile: imagePath),
              let cgImage = image.cgImage else {
          result(FlutterError(code: "INVALID_ARGS", message: "Cannot load image from path: \(call.arguments ?? [:])", details: nil))
          return
        }

        let request = VNRecognizeTextRequest { request, error in
          guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
            DispatchQueue.main.async { result("") }
            return
          }
          let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
          let fullText = recognizedStrings.joined(separator: "\n")
          DispatchQueue.main.async {
            result(fullText)
          }
        }
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
          do {
            try handler.perform([request])
          } catch {
            DispatchQueue.main.async {
              result("")
            }
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
