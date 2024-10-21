import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'read_bluetooth_data_screen.dart';
import 'write_bluetooth_data_screen.dart';

class DeviceDataScreen extends StatefulWidget {
  final BluetoothDevice device;

  DeviceDataScreen({required this.device});

  @override
  _DeviceDataScreenState createState() => _DeviceDataScreenState();
}

class _DeviceDataScreenState extends State<DeviceDataScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Data'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReadDataScreen(device: widget.device)),
                );
              },
              child: Text('Read Data'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WriteDataScreen(device: widget.device)),
                );
              },
              child: Text('Write Data'),
            ),
          ],
        ),
      ),
    );
  }
}
