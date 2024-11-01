// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:batterylevel/main.dart';

void main() {
  group('button tap test', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      driver.close();
    });

    test('tap on the button, verify result', () async {
      final SerializableFinder batteryLevelLabel =
      find.byValueKey('Battery level label');
      expect(batteryLevelLabel, isNotNull);

      final SerializableFinder button = find.text('Refresh');
      await driver.waitFor(button);
      await driver.tap(button);

      String? batteryLevel;
      while (batteryLevel == null || batteryLevel.contains('unknown')) {
        batteryLevel = await driver.getText(batteryLevelLabel);
      }

      expect(batteryLevel.contains('%'), isTrue);
    });
  });
}
