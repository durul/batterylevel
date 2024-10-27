//
//  BatteryService.swift
//  Runner
//
//  Created by durul dalkanat on 10/27/24.
//

import Flutter
import UIKit

class BatteryService {
    static let shared = BatteryService()
    private var batteryChannel: FlutterMethodChannel?

    func setup(controller: FlutterViewController) {
        // Setup Battery Method Channel
        batteryChannel = FlutterMethodChannel(
            name: "samples.flutter.io/battery",
            binaryMessenger: controller.binaryMessenger
        )

        //  Flutter side calls "getBatteryLevel" on the method channel, execute the receiveBatteryLevel() in this class.
        batteryChannel?.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "getBatteryLevel":
                self?.receiveBatteryLevel(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - Battery Level Handling with Method Channel

    private func receiveBatteryLevel(result: FlutterResult) {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        if device.batteryState == UIDevice.BatteryState.unknown {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Battery level not available.",
                                details: nil))
        } else {
            result(Int(device.batteryLevel * 100))
        }
    }
}
