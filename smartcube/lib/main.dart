import 'package:flutter/material.dart';
import 'screens/bluetooth_screen.dart'; // Import the BluetoothScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothScreen(), // Directly set the home to BluetoothScreen
    );
  }
}
