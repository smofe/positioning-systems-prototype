import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:intl/intl.dart';

const BEACON_DEVICE_ID = "EA:B1:D0:AA:37:58";

class BLEMeasurementView extends StatefulWidget {
  const BLEMeasurementView({Key? key}) : super(key: key);

  @override
  _BLEMeasurementViewState createState() => _BLEMeasurementViewState();
}

class _BLEMeasurementViewState extends State<BLEMeasurementView> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BLESignalDataSet> _dataSets = [];
  late int _scanStartMillis;
  bool isScanning = false;
  int distance = 10;
  int measurementInterval = 10;
  int scanDuration = 10;
  double progress = 0;
  Timer? progressTimer;
  ScrollController _scrollController = new ScrollController();

  @override
  void initState() {
    super.initState();

    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.id == DeviceIdentifier(BEACON_DEVICE_ID)) {
          _dataSets.last.dataPoints.add(BLESignalDataPoint(
              distance: _dataSets.last.distance,
              rssi: r.rssi,
              milliseconds:
                  DateTime.now().millisecondsSinceEpoch - _scanStartMillis));
        }
      }
    });

    flutterBlue.isScanning.listen((bool isScanning) {
      setState(() {
        this.isScanning = isScanning;
      });
      if (isScanning) {
        _initTimer();
      } else {
        _cancelTimer();
      }
    });
  }

  @override
  void dispose() {
    progressTimer?.cancel();
    super.dispose();
  }

  void _initTimer() {
    progressTimer?.cancel();
    progressTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      setState(() {
        progress += 0.1;
      });
    });
  }

  void _cancelTimer() {
    progressTimer?.cancel();
    progress = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // InputSlider(
        //   onChange: (value) {
        //     setState(() {
        //       distance = value.round();
        //     });
        //   },
        //   min: 0,
        //   max: 300,
        //   division: 30,
        //   defaultValue: distance.toDouble(),
        //   decimalPlaces: 0,
        // ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            isScanning
                ? "Scanning at distance ${distance - measurementInterval}..."
                : "Next measurement distance: $distance",
            style: Theme.of(context).textTheme.headline5,
          ),
        ),
        isScanning
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: LinearProgressIndicator(value: progress / scanDuration),
              )
            : ElevatedButton(
                style: ButtonStyle(
                    padding: MaterialStateProperty.resolveWith((states) =>
                        EdgeInsets.symmetric(vertical: 16, horizontal: 64))),
                onPressed: () async {
                  FlutterBlue.instance.stopScan();
                  await Future.delayed(Duration(milliseconds: 3));
                  flutterBlue.startScan(
                      timeout: Duration(seconds: scanDuration),
                      allowDuplicates: true);
                  _scanStartMillis = DateTime.now().millisecondsSinceEpoch;
                  _dataSets.add(BLESignalDataSet(distance: distance));
                  setState(() {
                    distance += measurementInterval;
                  });
                  Future.delayed(Duration(milliseconds: 100), () {
                    _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOut);
                  });
                },
                child: Text("Start scan")),
        Expanded(
          child: ListView.builder(
              controller: _scrollController,
              itemCount: _dataSets.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text("Distance ${_dataSets[index].distance}"),
                  subtitle:
                      Text("Samples: ${_dataSets[index].dataPoints.length}"),
                );
              }),
        ),
        ElevatedButton(
            onPressed: () async {
              List<List<dynamic>> data = [];
              _dataSets.forEach((dataSet) {
                dataSet.dataPoints.forEach((element) {
                  data.add(
                      [element.distance, element.milliseconds, element.rssi]);
                });
              });

              String csv = ListToCsvConverter().convert(data);
              DateTime now = DateTime.now();
              String formattedDate =
                  DateFormat('yyyy-MM-dd–kk-mm-ss').format(now);
              final pathOfTheFileToWrite =
                  "storage/emulated/0/Download/scanresults-$formattedDate.csv";

              File file = File(pathOfTheFileToWrite);
              file.writeAsString(csv).then((value) =>
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Saved file $value"),
                  )));
            },
            child: Text("Export csv")),
      ],
    );
  }
}

class BLESignalDataSet {
  final int distance;
  List<BLESignalDataPoint> dataPoints = [];

  BLESignalDataSet({required this.distance});
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
