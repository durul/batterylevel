import Cocoa
import FlutterMacOS
import IOKit.ps

@main
class AppDelegate: FlutterAppDelegate {
    private var eventSink: FlutterEventSink?
    
    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        super.applicationDidFinishLaunching(aNotification)
        
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
    }
    
    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
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
        
        if let source = sources.first {
            return IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any]
        }
        return nil
    }
}
