import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let pushChannelName = "reminder_app/push"
  private var pushChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      pushChannel = FlutterMethodChannel(name: pushChannelName, binaryMessenger: controller.binaryMessenger)
      pushChannel?.setMethodCallHandler { [weak self] call, result in
        guard call.method == "registerForRemoteNotifications" else {
          result(FlutterMethodNotImplemented)
          return
        }
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
          result(nil)
        }
      }
    }
    return result
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    pushChannel?.invokeMethod("onApnsToken", arguments: token)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    pushChannel?.invokeMethod("onApnsTokenError", arguments: error.localizedDescription)
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
