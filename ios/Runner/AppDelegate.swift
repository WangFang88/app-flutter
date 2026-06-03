import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let pushChannelName = "reminder_app/push"
  private var pushChannel: FlutterMethodChannel?
  private var _pendingReminderId: String?
  private var _pendingAckReminderId: String?
  private var _didReceiveCalledDuringLaunch = false

  // 前台收到通知时显示横幅（iOS 默认前台不显示）
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    UNUserNotificationCenter.current().delegate = self
    // 原生注册通知分类，确保 APNs 推送在 Flutter 初始化前也能显示操作按钮
    let ackAction = UNNotificationAction(identifier: "ack_reminder", title: "我知道了", options: [])
    let ackCategory = UNNotificationCategory(identifier: "reminder_ack", actions: [ackAction], intentIdentifiers: [], options: [])
    UNUserNotificationCenter.current().setNotificationCategories([ackCategory])

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

    // 处理 App 从终止状态点击通知启动的情况（didReceive 可能未被调用时的兜底）
    if !_didReceiveCalledDuringLaunch {
      if let remoteNotification = launchOptions?[.remoteNotification] as? [String: Any],
         let reminderId = remoteNotification["reminderId"] as? String {
        _pendingReminderId = reminderId
      }
    }

    // 等 Flutter MethodChannel handler 注册完成后，发送待处理的通知
    if _pendingReminderId != nil {
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
        guard let self = self, let rid = self._pendingReminderId else { return }
        self._pendingReminderId = nil
        NSLog("📱 Sending pending notification tap: \(rid)")
        self.pushChannel?.invokeMethod("onNotificationTap", arguments: rid)
      }
    }
    if _pendingAckReminderId != nil {
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
        guard let self = self, let rid = self._pendingAckReminderId else { return }
        self._pendingAckReminderId = nil
        NSLog("📱 Sending pending ack: \(rid)")
        self.pushChannel?.invokeMethod("onAcknowledgeDirect", arguments: rid)
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

  override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    _didReceiveCalledDuringLaunch = true

    let actionId = response.actionIdentifier
    let userInfo = response.notification.request.content.userInfo
    NSLog("📱 Notification tapped, actionId=\(actionId), userInfo=\(userInfo)")

    if let reminderId = userInfo["reminderId"] as? String {
      if actionId == "ack_reminder" {
        // ★ 点击"我知道了"按钮：只确认，不打开 App
        NSLog("📱 Ack button tapped for reminderId: \(reminderId)")
        _pendingAckReminderId = nil
        if let channel = pushChannel {
          channel.invokeMethod("onAcknowledgeDirect", arguments: reminderId)
        } else {
          // pushChannel 尚未初始化，存起来等 didFinishLaunchingWithOptions 处理
          _pendingAckReminderId = reminderId
        }
      } else if actionId == UNNotificationDefaultActionIdentifier {
        // ★ 点击通知主体：打开 App，进入详情页（详情页会自动确认）
        NSLog("📱 Notification body tapped for reminderId: \(reminderId)")
        _pendingReminderId = nil // 清除兜底，因为这里已经处理了
        if let channel = pushChannel {
          channel.invokeMethod("onNotificationTap", arguments: reminderId)
        } else {
          // pushChannel 尚未初始化，存起来等 didFinishLaunchingWithOptions 处理
          _pendingReminderId = reminderId
        }
      }
    }
    completionHandler()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
