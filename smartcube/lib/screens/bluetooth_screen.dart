import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_data.dart';

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<BluetoothDevice> devicesList = [];

  @override
  void initState() {
    super.initState();
    checkBluetooth();
  }

  void checkBluetooth() async {
    bool isOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    if (isOn) {
      scanForDevices();
    } else {
      // Bluetooth is not enabled
      print('Bluetooth is not enabled');
    }
  }

  void scanForDevices() {
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName.contains('SmartCube') && !devicesList.contains(r.device)) {
          setState(() {
            devicesList.add(r.device);
          });
        }
      }
    });

    FlutterBluePlus.startScan();
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceDataScreen(device: device)),
    ).then((_) {
      // Handle what to do when returning back from DeviceDataScreen
      device.disconnect();
  });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Founded SmartCube devices'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                devicesList.clear();
              });
              scanForDevices();
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: devicesList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(devicesList[index].name),
            trailing: ElevatedButton(
              onPressed: () => connectToDevice(devicesList[index]),
              child: Text('Connect'),
            ),
          );
        },
      ),
    );
  }
}
