import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MainScreen extends StatefulWidget {
  final BluetoothDevice device;
  final String name;
  final int type;
  final int battery;
  final bool charging;
  final int bridge;
  final Map<String, Map<String, dynamic>> lightsSideInfo;
  final List<Map<String, String>> lights;
  final List<Map<String, dynamic>> rooms;
  final List<String> selectedLights;

  MainScreen({
    required this.device,
    required this.name,
    required this.type,
    required this.battery,
    required this.charging,
    required this.bridge,
    required this.lightsSideInfo,
    required this.lights,
    required this.rooms,
    required this.selectedLights,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure the device stays connected
    widget.device.connect(autoConnect: false);
  }

  @override
  void dispose() {
    widget.device.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Screen'),
      ),
      body: Center(
        child: Text('Lights ${widget.lights}'),
      ),
    );
  }
}
