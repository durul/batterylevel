import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';

class PlatformChannel extends StatefulWidget {
  const PlatformChannel({super.key});

  @override
  State<PlatformChannel> createState() => _PlatformChannelState();
}

class _PlatformChannelState extends State<PlatformChannel> {
  // Initialize the battery level and charging status.
  String _batteryLevel = 'Battery level: unknown.';
  String _chargingStatus = 'Battery status: unknown.';
  final Stream<dynamic> _stream = kEventChannel.receiveBroadcastStream();

  @override
  void initState() {
    super.initState();
    _getBatteryLevel();
  }

  // Get the battery level.
  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      // specifying the concrete method to call using the String identifier getBatteryLevel.
      final int? result = await kMethodChannel.invokeMethod('getBatteryLevel');
      batteryLevel = 'Battery level: $result%.';
    } on PlatformException catch (e) {
      if (e.code == 'NO_BATTERY') {
        batteryLevel = 'No battery.';
      } else {
        batteryLevel = 'Failed to get battery level.';
      }
    }
    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  Stream<dynamic> streamTimeFromNative() {
    // Listen to charging status changes
    return kEventChannel.receiveBroadcastStream();
  }

  void _onError(Object? error) {
    setState(() {
      _chargingStatus = 'Battery status: unknown.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(_batteryLevel, key: const Key('Battery level label')),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _getBatteryLevel,
                  child: const Text('Refresh'),
                ),
              ),
            ],
          ),
          StreamBuilder<dynamic>(
              stream: streamTimeFromNative(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasError) {
                  // Handle error case
                  _onError(snapshot.error);
                }

                if (snapshot.hasData) {
                  return Text(
                    '${snapshot.data}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                } else {
                  return const Text('No data');
                }
              })
        ],
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: PlatformChannel()));
}
