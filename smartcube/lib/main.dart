import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'class/bluetooth_device_manager.dart';
import 'screens/bluetooth_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BluetoothDeviceManager(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothScreen(),
    );
  }
}
