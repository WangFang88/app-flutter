import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let pushChannelName = "reminder_app/push"
  private let apiBaseUrl = "https://dangling-mumbling-arson.ngrok-free.dev"
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

  /// 通过原生 URLSession 直接发送 acknowledge 请求（不依赖 MethodChannel / Dart 侧）
  private func sendNativeAcknowledge(reminderId: String) {
    guard let token = UserDefaults.standard.string(forKey: "flutter.token"), !token.isEmpty else {
      #if DEBUG
      NSLog("📱 Native ack skipped: no auth token")
      #endif
      return
    }
    guard let url = URL(string: "\(apiBaseUrl)/reminders/\(reminderId)/acknowledge") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.httpBody = "{}".data(using: .utf8)
    URLSession.shared.dataTask(with: request) { _, response, error in
      if let error = error {
        #if DEBUG
        NSLog("📱 Native ack failed: \(error.localizedDescription)")
        #endif
        return
      }
      if let httpResponse = response as? HTTPURLResponse {
        #if DEBUG
        NSLog("📱 Native ack response: \(httpResponse.statusCode)")
        #endif
      }
    }.resume()
  }

  /// 设置 pushChannel（在 UIScene 架构下 window?.rootViewController 为 nil，
  /// 需要通过 FlutterImplicitEngineBridge 的 binaryMessenger 创建）
  private func setupPushChannel(with messenger: FlutterBinaryMessenger) {
    guard pushChannel == nil else { return }
    pushChannel = FlutterMethodChannel(name: pushChannelName, binaryMessenger: messenger)
    pushChannel?.setMethodCallHandler { [weak self] call, result in
      if call.method == "registerForRemoteNotifications" {
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
          result(nil)
        }
      } else if call.method == "reassertDelegate" {
        UNUserNotificationCenter.current().delegate = self
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
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

    // UIScene 下 window?.rootViewController 可能为 nil，此处作为兜底
    if let controller = window?.rootViewController as? FlutterViewController {
      setupPushChannel(with: controller.binaryMessenger)
    }

    // 处理 App 从终止状态点击通知启动的情况（didReceive 可能未被调用时的兜底）
    if !_didReceiveCalledDuringLaunch {
      if let remoteNotification = launchOptions?[.remoteNotification] as? [String: Any],
         let reminderId = remoteNotification["reminderId"] as? String {
        _pendingReminderId = reminderId
      }
    }

    // 等 Flutter MethodChannel handler 注册完成后，发送待处理的通知
    let pendingReminderId = _pendingReminderId
    let pendingAckId = _pendingAckReminderId
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
      guard let self = self else { return }
      if let rid = pendingReminderId {
        #if DEBUG
        NSLog("📱 Sending pending notification tap: \(rid)")
        #endif
        self.pushChannel?.invokeMethod("onNotificationTap", arguments: rid)
        self._pendingReminderId = nil
      }
      if let rid = pendingAckId {
        #if DEBUG
        NSLog("📱 Sending pending ack: \(rid)")
        #endif
        self.sendNativeAcknowledge(reminderId: rid)
        self.pushChannel?.invokeMethod("onAcknowledgeDirect", arguments: rid)
        self._pendingAckReminderId = nil
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
    #if DEBUG
    NSLog("📱 Notification tapped, actionId=\(actionId), userInfo=\(userInfo)")
    #endif

    // 兼容 APNs 推送的 "reminderId" 和本地通知的 "payload"
    let reminderId = (userInfo["reminderId"] as? String) ?? (userInfo["payload"] as? String)
    if let reminderId = reminderId {
      if actionId == "ack_reminder" {
        // ★ 点击"我知道了"按钮：只确认，不打开 App
        #if DEBUG
        NSLog("📱 Ack button tapped for reminderId: \(reminderId)")
        #endif
        _pendingAckReminderId = nil
        // ① 原生 HTTP 确认：不依赖 MethodChannel，即使 Dart isolate 未就绪也能写入 MySQL
        sendNativeAcknowledge(reminderId: reminderId)
        // ② MethodChannel 方式：让 Dart 侧取消本地通知等副作用
        if let channel = pushChannel {
          channel.invokeMethod("onAcknowledgeDirect", arguments: reminderId)
        } else {
          _pendingAckReminderId = reminderId
        }
      } else if actionId == UNNotificationDefaultActionIdentifier {
        // ★ 点击通知主体：打开 App，进入详情页（详情页会自动确认）
        #if DEBUG
        NSLog("📱 Notification body tapped for reminderId: \(reminderId)")
        #endif
        _pendingReminderId = nil
        if let channel = pushChannel {
          channel.invokeMethod("onNotificationTap", arguments: reminderId)
        } else {
          _pendingReminderId = reminderId
        }
      }
    }
    completionHandler()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // ★ 在 Flutter 引擎初始化时创建 pushChannel（UIScene 场景下唯一可靠的方式）
    setupPushChannel(with: engineBridge.applicationRegistrar.messenger())

    // 时区通道：让 Dart 侧获取设备 IANA 时区名
    let tzChannel = FlutterMethodChannel(name: "reminder_app/timezone", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    tzChannel.setMethodCallHandler { call, result in
      if call.method == "getLocalTimezone" {
        result(TimeZone.current.identifier)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // ★ 引擎初始化后，确保 AppDelegate 仍然是 UNUserNotificationCenter 的 delegate
    UNUserNotificationCenter.current().delegate = self
  }
}
