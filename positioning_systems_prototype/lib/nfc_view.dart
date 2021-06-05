import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:positioning_systems_prototype/scanned_tag.dart';

class NFCView extends StatefulWidget {
  const NFCView({Key? key}) : super(key: key);

  @override
  _NFCViewState createState() => _NFCViewState();
}

class _NFCViewState extends State<NFCView> {
  List<ScannedTag> scannedTags = [];

  @override
  void initState() {
    super.initState();
    _initializeNFCManager();
  }

  void _initializeNFCManager() async {
    // Check availability
    bool isAvailable = await NfcManager.instance.isAvailable();
    print("is Available: $isAvailable");
// Start Session
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        parseNFCTag(tag);
      },
    );
  }

  void parseNFCTag(NfcTag tag) {
    Ndef? ndef = Ndef.from(tag);
    if (ndef != null) {
      final rawMessage = ndef.cachedMessage?.records.first.payload;
      if (rawMessage != null) {
        final parsedMessage = utf8.decode(rawMessage.toList().sublist(3));
        print("Read message: $parsedMessage");
        final type = parsedMessage.split("-")[0];
        final id = parsedMessage.split("-")[1];
        if (id != "") {
          if (type == "patient")
            setState(() {
              scannedTags.add(ScannedTag(type: TagType.PATIENT, id: id));
            });
          if (type == "entity")
            setState(() {
              scannedTags.add(ScannedTag(type: TagType.ENTITY, id: id));
            });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: scannedTags.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  leading: (scannedTags[index].type == TagType.ENTITY)
                      ? Icon(Icons.shopping_bag)
                      : Icon(Icons.person),
                  title: Text(scannedTags[index].toString()),
                  subtitle: Text(scannedTags[index].time.toString()),
                );
              }),
        ),
        ElevatedButton(
            onPressed: () {
              setState(() {
                scannedTags.clear();
              });
            },
            child: Text("clear")),
      ],
    );
  }
}
