import Flutter
import GoogleMaps
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Optional Info.plist key: GMSApiKey  — or use `--dart-define` only on Flutter side.
    // Native map still requires GMSServices before GoogleMap widget appears.
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !key.isEmpty,
       !key.hasPrefix("$(") {
      GMSServices.provideAPIKey(key)
    }
    // Needed so FCM can map APNs → FCM token (My Sancho push).
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    FlutterMethodChannel(name: "mysancho/badge", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        switch call.method {
        case "clear":
          Self.setBadge(0)
          result(nil)
        case "set":
          let count = (call.arguments as? Int) ?? 0
          Self.setBadge(max(0, count))
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  private static func setBadge(_ count: Int) {
    let application = UIApplication.shared
    application.applicationIconBadgeNumber = count
    if #available(iOS 16.0, *) {
      UNUserNotificationCenter.current().setBadgeCount(count)
    }
  }
}
