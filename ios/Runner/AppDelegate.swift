import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
    // FlutterEventSink
    private var eventSink: FlutterEventSink?

    // FlutterResult is a type alias for a closure that takes an optional Any argument and returns void.
    private var flutterResult: FlutterResult?

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // If the guard statement fails (meaning we couldn't get a FlutterViewController),
        // We call the superclass's implementation of application(_:didFinishLaunchingWithOptions:)
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        // Setup Battery Service
        BatteryService.shared.setup(controller: controller)

        // Setup Charging Event Channel
        let chargingChannel = FlutterEventChannel(
            name: "samples.flutter.io/charging",
            binaryMessenger: controller.binaryMessenger
        )
        chargingChannel.setStreamHandler(self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Battery State Handling with Event Channel

    @objc private func onBatteryStateDidChange(_ notification: Notification) {
        sendBatteryStateEvent()
    }

    private func sendBatteryStateEvent() {
        guard let eventSink = eventSink else { return }

        let batteryState = UIDevice.current.batteryState

        switch batteryState {
        case .charging, .full:
            eventSink(BatteryState.charging)
        case .unplugged:
            eventSink(BatteryState.discharging)
        case .unknown:
            eventSink(FlutterError(
                code: MyFlutterErrorCode.unavailable,
                message: "Charging status unavailable",
                details: nil
            ))
        @unknown default:
            eventSink(FlutterError(
                code: MyFlutterErrorCode.unavailable,
                message: "Charging status unavailable",
                details: nil
            ))
        }
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        UIDevice.current.isBatteryMonitoringEnabled = true
        sendBatteryStateEvent()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onBatteryStateDidChange),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }
}
