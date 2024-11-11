import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'read_bluetooth_data_screen.dart';
import 'write_bluetooth_data_screen.dart';
import 'cube_screen.dart'; 

class DeviceDataScreen extends StatefulWidget {
  final BluetoothDevice device;

  DeviceDataScreen({required this.device});

  @override
  _DeviceDataScreenState createState() => _DeviceDataScreenState();
}

class _DeviceDataScreenState extends State<DeviceDataScreen> {
  final String characteristicUUID = "12345678-1234-5678-1234-56789abcdef3";
  String collectedData = "";

  @override
  void initState() {
    super.initState();
    connectToCharacteristic();
  }

  void connectToCharacteristic() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == characteristicUUID) {
          characteristic.setNotifyValue(true);
          characteristic.value.listen((value) {
            setState(() {
              collectedData += String.fromCharCodes(value);
            });
          });
        }
      }
    }
  }

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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CubeScreen()),
                );
              },
              child: Text('Open Cube'),
            ),
            SizedBox(height: 20),
            Text(
              'Collected Data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(collectedData),
          ],
        ),
      ),
    );
  }
}
