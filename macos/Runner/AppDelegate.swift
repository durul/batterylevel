import Cocoa
import FlutterMacOS
import IOKit.ps

@main
class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var flutterResult: FlutterResult?

    private var powerSourceRunLoopSource: CFRunLoopSource?

    // Static callback function for power source changes
    private static var sharedDelegate: AppDelegate?

    // Store the run loop source as a property to prevent deallocation

    private static let powerSourceCallback: IOPowerSourceCallbackType = { _ in
        sharedDelegate?.sendBatteryStateEvent()
    }

    override func applicationWillFinishLaunching(_ notification: Notification) {
        super.applicationWillFinishLaunching(notification)

        guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
            return
        }

        // Setup Battery Method Channel
        let batteryChannel = FlutterMethodChannel(
            name: "samples.flutter.io/battery",
            binaryMessenger: controller.engine.binaryMessenger
        )

        batteryChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "getBatteryLevel":
                self?.receiveBatteryLevel(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Store reference for callback
        AppDelegate.sharedDelegate = self

        // Setup Charging Event Channel
        let chargingChannel = FlutterEventChannel(
            name: "samples.flutter.io/charging",
            binaryMessenger: controller.engine.binaryMessenger
        )
        chargingChannel.setStreamHandler(self)
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    deinit {
        // Clean up the run loop source and shared delegate reference
        if let runLoopSource = powerSourceRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        }
        AppDelegate.sharedDelegate = nil
    }

    private func receiveBatteryLevel(result: @escaping FlutterResult) {
        if let powerSource = getPowerSourceInfo() {
            if let currentCapacity = powerSource["Current Capacity"] as? Int {
                result(currentCapacity)
                return
            }
        }

        result(FlutterError(
            code: "UNAVAILABLE",
            message: "Battery level not available.",
            details: nil
        ))
    }

    private func getPowerSourceInfo() -> [String: Any]? {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        print("Number of power sources: \(sources.count)")

        if let source = sources.first {
            return IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any]
        }
        return nil
    }

    // MARK: - Battery State Handling

    private func sendBatteryStateEvent() {
        guard let eventSink = eventSink else {
            print("No event sink available")
            return
        }

        if let powerSource = getPowerSourceInfo() {
            print("Power source info: \(powerSource)")

            if let isChargingRaw = powerSource["Is Charging"] as? Int {
                let isCharging = isChargingRaw != 0 // Explicitly check for non-zero
                print("Charging state (raw): \(isChargingRaw), (bool): \(isCharging)")
                eventSink(isCharging ? "charging" : "discharging")

                // More robust: Check Power Source State too
                if let powerSourceState = powerSource["Power Source State"] as? String {
                    switch powerSourceState {
                    case "AC Power":
                        if isCharging {
                            eventSink("charging") // Definitely charging
                        } else {
                            eventSink("full") // Likely full, but plugged in
                        }
                    case "Battery Power":
                        eventSink("discharging") // Definitely discharging
                    default:
                        eventSink("unknown") // Handle other states
                    }
                } else {
                    eventSink(isCharging ? "charging" : "discharging") // Fallback if Power Source State is missing
                }

                return // Exit after handling
            } else {
                print("'Is Charging' key not found or not an integer")
            }
        } else {
            print("No power source info available")
        }

        eventSink(FlutterError(
            code: "UNAVAILABLE",
            message: "Charging status unavailable",
            details: nil
        ))
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        sendBatteryStateEvent()

        // Setup power source change notification using static callback
        let runLoopSource = IOPSNotificationCreateRunLoopSource(
            AppDelegate.powerSourceCallback,
            nil
        ).takeRetainedValue()

        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        powerSourceRunLoopSource = runLoopSource

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let runLoopSource = powerSourceRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
            powerSourceRunLoopSource = nil
        }
        eventSink = nil
        return nil
    }
}
