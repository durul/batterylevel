import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    // FlutterResult is a type alias for a closure that takes an optional Any argument and returns void.
    private var flutterResult: FlutterResult?

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // If the guard statement fails (meaning we couldn't get a FlutterViewController), we:
        // Call the superclass's implementation of application(_:didFinishLaunchingWithOptions:) and return its result.
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        // Setup Battery Method Channel
        let batteryChannel = FlutterMethodChannel(
            name: "samples.flutter.io/battery",
            binaryMessenger: controller.binaryMessenger
        )

        //  Flutter side calls "getBatteryLevel" on the method channel, execute the receiveBatteryLevel() in this class.
        batteryChannel.setMethodCallHandler { [weak self] call, result in
            self?.flutterResult = result
            switch call.method {
            case "getBatteryLevel":
                self?.receiveBatteryLevel(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Setup Charging Event Channel
        let chargingChannel = FlutterEventChannel(
            name: "samples.flutter.io/charging",
            binaryMessenger: controller.binaryMessenger
        )
        chargingChannel.setStreamHandler(self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Battery Level Handling

    private func receiveBatteryLevel(result: FlutterResult) {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        if device.batteryState == UIDevice.BatteryState.unknown {
            result(FlutterError(code: MyFlutterErrorCode.unavailable,
                                message: "Battery level not available.",
                                details: nil))
        } else {
            result(Int(device.batteryLevel * 100))
        }
    }

    // MARK: - Battery State Handling

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
            eventSink(BatteryState.disscharging)
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
