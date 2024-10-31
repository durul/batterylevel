import 'dart:async';

import 'package:flutter/material.dart';

import 'EventChannelBattery.dart';

class PlatformChannel extends StatefulWidget {
  const PlatformChannel({super.key});

  @override
  State<PlatformChannel> createState() => _PlatformChannelState();
}

class _PlatformChannelState extends State<PlatformChannel> {
  // Initialize the battery level and charging status.
  String _batteryLevel = 'Battery level: unknown.';

  @override
  void initState() {
    super.initState();
    _getBatteryLevel();
  }

  // Get the battery level.
  Future<void> _getBatteryLevel() async {
    String batteryLevel = await EventChannelBatteryLevel.getBatteryLevel();
    setState(() {
      _batteryLevel = batteryLevel;
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
              stream: EventChannelBatteryLevel.batteryLevel,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Battery status: unknown.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
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
