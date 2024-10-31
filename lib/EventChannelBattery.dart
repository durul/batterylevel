import 'package:flutter/services.dart';

import 'constants.dart';

class EventChannelBatteryLevel {
  // Create a method to get the timerValue stream.
  static Stream get batteryLevel {
    // Use the receiveBroadcastStream method to create a stream of events from the platform side.
    // Map the dynamic events to integers as they are received.
    return kEventChannel.receiveBroadcastStream();
  }

  // Get the battery level.
  static Future<String> getBatteryLevel() async {
    String batteryLevel;
    try {
      // specifying the concrete method to call using the getBatteryLevel.
      final int? result = await kMethodChannel.invokeMethod('getBatteryLevel');
      batteryLevel = 'Battery level: $result%.';
    } on PlatformException catch (e) {
      if (e.code == 'NO_BATTERY') {
        batteryLevel = 'No battery.';
      } else {
        batteryLevel = 'Failed to get battery level.';
      }
    }
    return batteryLevel;
  }
}
