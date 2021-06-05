import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:input_slider/input_slider.dart';

const BEACON_DEVICE_ID = "08:3A:F2:A8:E6:E6";

class BLEView extends StatefulWidget {
  const BLEView({Key? key}) : super(key: key);

  @override
  _BLEViewState createState() => _BLEViewState();
}

class _BLEViewState extends State<BLEView> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BLESignalDataPoint> _dataPoints = [];
  List<int> _scannedDistances = [];
  late int _scanStartMillis;
  bool isScanning = false;
  int distance = 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InputSlider(
          onChange: (value) {
            setState(() {
              distance = value.round();
            });
          },
          min: 0,
          max: 200,
          defaultValue: 5,
          decimalPlaces: 0,
        ),
        isScanning
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: LinearProgressIndicator(),
              )
            : ElevatedButton(
                onPressed: () {
                  flutterBlue.startScan(
                      timeout: Duration(seconds: 10), allowDuplicates: true);
                  _scanStartMillis = DateTime.now().millisecondsSinceEpoch;
                  setState(() {
                    _scannedDistances.add(distance);
                  });
                  flutterBlue.scanResults.listen((results) {
                    for (ScanResult r in results) {
                      _dataPoints.add(BLESignalDataPoint(
                          distance: distance,
                          rssi: r.rssi,
                          milliseconds: DateTime.now().millisecondsSinceEpoch -
                              _scanStartMillis));
                    }
                  });

                  flutterBlue.isScanning.listen((bool isScanning) {
                    setState(() {
                      this.isScanning = isScanning;
                    });
                  });
                },
                child: Text("Start scan")),
        Expanded(
          child: ListView.builder(
              itemCount: _scannedDistances.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text("Distance ${_scannedDistances[index]}"),
                );
              }),
        ),
        ElevatedButton(
            onPressed: () async {
              List<List<dynamic>> data = [];
              _dataPoints.forEach((element) {
                data.add(
                    [element.distance, element.milliseconds, element.rssi]);
              });
              String csv = ListToCsvConverter().convert(data);
              final pathOfTheFileToWrite =
                  "storage/emulated/0/Download/myCsvFile.csv";
              print("Writing to $pathOfTheFileToWrite");
              File file = File(pathOfTheFileToWrite);
              file.writeAsString(csv).then((value) => print(value));
            },
            child: Text("Export csv")),
      ],
    );
  }
}

class BLESignalDataPoint {
  final int milliseconds;
  final int rssi;
  final int distance;

  BLESignalDataPoint(
      {required this.distance, required this.rssi, required this.milliseconds});

  @override
  String toString() {
    return "[$distance cm | $milliseconds ms] $rssi db";
  }
}
