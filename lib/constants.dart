import 'package:flutter/services.dart';

// Construct a MethodChannel with the specified name.
const kMethodChannel = MethodChannel('samples.flutter.io/battery');

// Construct an EventChannel with the specified name.
const kEventChannel = EventChannel('samples.flutter.io/charging');
