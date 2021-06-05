import 'dart:async';
import 'dart:io';

import 'package:beacons_plugin/beacons_plugin.dart';
import 'package:flutter/material.dart';

class BeaconMonitor extends StatefulWidget {
  const BeaconMonitor({Key? key}) : super(key: key);

  @override
  _BeaconMonitorState createState() => _BeaconMonitorState();
}

class _BeaconMonitorState extends State<BeaconMonitor> {
  var isRunning = false;

  @override
  void initState() {
    super.initState();

    _setupBeaconMonitor();
  }

  void _setupBeaconMonitor() async {
    // //IMPORTANT: Start monitoring once scanner is setup & ready (only for Android)
    // if (Platform.isAndroid) {
    //   BeaconsPlugin.channel.setMethodCallHandler((call) async {
    //     if (call.method == 'scannerReady') {
    //       await BeaconsPlugin.startMonitoring();
    //     }
    //   });
    // } else if (Platform.isIOS) {
    //   await BeaconsPlugin.startMonitoring();
    // }

    final StreamController<String> beaconEventsController =
        StreamController<String>.broadcast();
    BeaconsPlugin.listenToBeacons(beaconEventsController);
    BeaconsPlugin.addRegion("myBeacon", "87b99b2c-90fd-11e9-bc42-526af7764f64")
        .then((result) {
      //print(result);
    });
    beaconEventsController.stream.listen((data) {
      print(data);
      if (data.isNotEmpty) {
        print("Beacons DataReceived: " + data);
      }
    }, onDone: () {
      print("done");
    }, onError: (error) {
      print("Error: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if(isRunning)
        {
          await BeaconsPlugin.stopMonitoring();
        }
        else
        {
          _setupBeaconMonitor();
          await BeaconsPlugin.startMonitoring();
        }
        setState(() {
          isRunning = !isRunning;
        });
      },
      child: Text(isRunning?'Stop Scanning':'Start Scanning', style: TextStyle(fontSize: 20)),
    );
  }
}
