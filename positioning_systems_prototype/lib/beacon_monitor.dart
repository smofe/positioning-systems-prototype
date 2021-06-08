import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:beacons_plugin/beacons_plugin.dart';
import 'package:flutter/material.dart';

class BeaconMonitor extends StatefulWidget {
  @override
  _BeaconMonitorState createState() => _BeaconMonitorState();
}

class _BeaconMonitorState extends State<BeaconMonitor> {
  String _beaconResult = 'Not Scanned Yet.';
  var isRunning = false;
  int rssiThreshold = -60;
  double? rssiAverage;
  int rollingAverageWindow = 10;

  final StreamController<String> beaconEventsController =
      StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    beaconEventsController.close();
    super.dispose();
  }

  double approxRollingAverage(double avg, double new_sample) {
    avg -= avg / rollingAverageWindow;
    avg += new_sample / rollingAverageWindow;

    return avg;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (Platform.isAndroid) {
      //Prominent disclosure
      await BeaconsPlugin.setDisclosureDialogMessage(
          title: "Need Location Permission",
          message: "This app collects location data to work with beacons.");

      //Only in case, you want the dialog to be shown again. By Default, dialog will never be shown if permissions are granted.
      //await BeaconsPlugin.clearDisclosureDialogShowFlag(false);
    }

    BeaconsPlugin.listenToBeacons(beaconEventsController);

    await BeaconsPlugin.addRegion(
        "dPS Training", "f7826da6-4fa2-4e98-8024-bc5b71e0893e");

    beaconEventsController.stream.listen(
        (data) {
          if (data.isNotEmpty) {
            Map<String, dynamic> dataJson = jsonDecode(data);
            int rssi = int.parse(dataJson["rssi"]);
            setState(() {
              rssiAverage = approxRollingAverage(
                  rssiAverage ?? rssi.toDouble(), rssi.toDouble());
            });
            if (rssiAverage! >= rssiThreshold) {
              if (dataJson["major"] == "1") {
                setState(() {
                  _beaconResult = "Patient - ${dataJson["minor"]} detected";
                });
              }
            } else {
              setState(() {
                _beaconResult = "No patient detected";
              });
            }

            print("Beacons DataReceived: " + data);
          }
        },
        onDone: () {},
        onError: (error) {
          print("Error: $error");
        });

    //Send 'true' to run in background
    //await BeaconsPlugin.runInBackground(true);

    if (Platform.isAndroid) {
      BeaconsPlugin.channel.setMethodCallHandler((call) async {
        if (call.method == 'scannerReady') {
          await BeaconsPlugin.startMonitoring();
          setState(() {
            isRunning = true;
          });
        }
      });
    } else if (Platform.isIOS) {
      await BeaconsPlugin.startMonitoring();
      setState(() {
        isRunning = true;
      });
    }

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('$rssiAverage'),
          Text('$_beaconResult'),
          Padding(
            padding: EdgeInsets.all(10.0),
          ),
          SizedBox(
            height: 20.0,
          ),
          ElevatedButton(
            onPressed: () async {
              if (isRunning) {
                await BeaconsPlugin.stopMonitoring();
              } else {
                initPlatformState();
                await BeaconsPlugin.startMonitoring();
              }
              setState(() {
                isRunning = !isRunning;
              });
            },
            child: Text(isRunning ? 'Stop Scanning' : 'Start Scanning',
                style: TextStyle(fontSize: 20)),
          ),
          SizedBox(
            height: 20.0,
          ),
        ],
      ),
    );
  }
}

// import 'dart:async';
// import 'dart:io';
//
// import 'package:beacons_plugin/beacons_plugin.dart';
// import 'package:flutter/material.dart';
//
// class BeaconMonitor extends StatefulWidget {
//   const BeaconMonitor({Key? key}) : super(key: key);
//
//   @override
//   _BeaconMonitorState createState() => _BeaconMonitorState();
// }
//
// class _BeaconMonitorState extends State<BeaconMonitor> {
//   var isRunning = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _setupBeaconMonitor();
//   }
//
//   void _setupBeaconMonitor() async {
//     BeaconsPlugin.setDebugLevel(2);
//     //IMPORTANT: Start monitoring once scanner is setup & ready (only for Android)
//     if (Platform.isAndroid) {
//       BeaconsPlugin.channel.setMethodCallHandler((call) async {
//         if (call.method == 'scannerReady') {
//           await BeaconsPlugin.startMonitoring();
//         }
//       });
//     } else if (Platform.isIOS) {
//       await BeaconsPlugin.startMonitoring();
//     }
//
//     final StreamController<String> beaconEventsController =
//         StreamController<String>.broadcast();
//     BeaconsPlugin.listenToBeacons(beaconEventsController);
//     BeaconsPlugin.addRegion(
//             "dPS Training", "f7826da6-4fa2-4e98-8024-bc5b71e0893e")
//         .then((result) {});
//     beaconEventsController.stream.listen((data) {
//       print(data);
//       if (data.isNotEmpty) {
//         print("Beacons DataReceived: " + data);
//       }
//     }, onDone: () {
//       print("done");
//     }, onError: (error) {
//       print("Error: $error");
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: () async {
//         if (isRunning) {
//           await BeaconsPlugin.stopMonitoring();
//         } else {
//           _setupBeaconMonitor();
//           await BeaconsPlugin.startMonitoring();
//         }
//         setState(() {
//           isRunning = !isRunning;
//         });
//       },
//       child: Text(isRunning ? 'Stop Scanning' : 'Start Scanning',
//           style: TextStyle(fontSize: 20)),
//     );
//   }
// }
