import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:input_slider/input_slider.dart';

const BEACON_DEVICE_ID = "EA:B1:D0:AA:37:58";

class BLEDetectionView extends StatefulWidget {
  const BLEDetectionView({Key? key}) : super(key: key);

  @override
  _BLEDetectionViewState createState() => _BLEDetectionViewState();
}

class _BLEDetectionViewState extends State<BLEDetectionView> {
  FlutterBlue flutterBlue = FlutterBlue.instance;

  String? nearbyPatient;
  bool isScanning = false;
  int rssiThreshold = -60;
  List<double?> rssiAveragePatient = [null, null, null, null];

  int rollingAverageWindow = 30;
  int? currentPatient;

  double approxRollingAverage(double avg, double new_sample) {
    avg -= avg / rollingAverageWindow;
    avg += new_sample / rollingAverageWindow;

    return avg;
  }

  @override
  void initState() {
    super.initState();

    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.name.startsWith("patient")) {
          final id = int.parse(r.device.name.split("-")[1]);
          switch (id) {
            case 1:
              setState(() {
                rssiAveragePatient[0] = approxRollingAverage(
                    rssiAveragePatient[0] ?? r.rssi.toDouble(),
                    r.rssi.toDouble());
              });
              break;
            case 2:
              setState(() {
                rssiAveragePatient[1] = approxRollingAverage(
                    rssiAveragePatient[1] ?? r.rssi.toDouble(),
                    r.rssi.toDouble());
              });
              break;
            case 3:
              setState(() {
                rssiAveragePatient[2] = approxRollingAverage(
                    rssiAveragePatient[2] ?? r.rssi.toDouble(),
                    r.rssi.toDouble());
              });
              break;
            case 4:
              setState(() {
                rssiAveragePatient[3] = approxRollingAverage(
                    rssiAveragePatient[3] ?? r.rssi.toDouble(),
                    r.rssi.toDouble());
              });
              break;
          }
          var nearestPatient;
          for (int i = 0; i < rssiAveragePatient.length; i++) {
            if (rssiAveragePatient[i] != null) {
              if (nearestPatient == null) nearestPatient = i;
              if (rssiAveragePatient[i]! > rssiAveragePatient[nearestPatient]!)
                nearestPatient = i;
            }
          }
          if (rssiAveragePatient[nearestPatient] != null) {
            if (rssiAveragePatient[nearestPatient]! > rssiThreshold) {
              currentPatient = nearestPatient + 1;
            } else {
              currentPatient = null;
            }
          }
        }
      }
    });

    flutterBlue.isScanning.listen((bool isScanning) {
      setState(() {
        this.isScanning = isScanning;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (rssiAveragePatient[0] != null)
          Text('Patient 1: ' + rssiAveragePatient[0]!.toStringAsFixed(1)),
        if (rssiAveragePatient[1] != null)
          Text('Patient 2: ' + rssiAveragePatient[1]!.toStringAsFixed(1)),
        if (rssiAveragePatient[2] != null)
          Text('Patient 3: ' + rssiAveragePatient[2]!.toStringAsFixed(1)),
        if (rssiAveragePatient[3] != null)
          Text('Patient 4: ' + rssiAveragePatient[3]!.toStringAsFixed(1)),
        (currentPatient != null)
            ? Text('Currently looking at Patient $currentPatient')
            : Text("No patient nearby"),
        InputSlider(
            leading: Text("Threshold"),
            onChange: (value) {
              setState(() {
                rssiThreshold = value.round();
              });
            },
            min: -100,
            max: -20,
            defaultValue: -60),
        InputSlider(
            leading: Text("Window"),
            onChange: (value) {
              setState(() {
                rollingAverageWindow = value.round();
              });
            },
            min: 5,
            max: 100,
            defaultValue: 20),
        isScanning
            ? ElevatedButton(
                onPressed: () {
                  flutterBlue.stopScan();
                },
                child: Text("Stop scanning"))
            : ElevatedButton(
                style: ButtonStyle(
                    padding: MaterialStateProperty.resolveWith((states) =>
                        EdgeInsets.symmetric(vertical: 16, horizontal: 64))),
                onPressed: () async {
                  FlutterBlue.instance.stopScan();
                  await Future.delayed(Duration(milliseconds: 3));
                  flutterBlue.startScan(allowDuplicates: true);
                },
                child: Text("Start scan")),
      ],
    );
  }
}
