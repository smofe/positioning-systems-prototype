import 'package:flutter/material.dart';
import 'package:positioning_systems_prototype/tabbar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Positioning systems prototype',
      home: TabbedMenu(),
    );
  }
}
