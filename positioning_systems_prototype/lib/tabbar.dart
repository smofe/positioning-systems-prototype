import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:positioning_systems_prototype/ble_detection_view.dart';
import 'package:positioning_systems_prototype/ble_measurement_view.dart';
import 'package:positioning_systems_prototype/nfc_view.dart';

class TabbedMenu extends StatelessWidget {
  const TabbedMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.nfc)),
              Tab(icon: Icon(Icons.bluetooth)),
              Tab(icon: Icon(Icons.bluetooth_audio)),
            ],
          ),
          title: Text('Positioning Systems Prototype'),
        ),
        body: TabBarView(
          children: [
            NFCView(),
            BLEMeasurementView(),
            BLEDetectionView(),
          ],
        ),
      ),
    );
  }
}
