import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'bluetooth_loading_screen.dart';
import 'package:smartcube/class/bluetooth_device_manager.dart';

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
      print('Bluetooth is not enabled');
    }
  }

  void scanForDevices() {
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName.contains('SmartCube') &&
            !devicesList.contains(r.device)) {
          setState(() {
            devicesList.add(r.device);
          });
        }
      }
    });

    FlutterBluePlus.startScan();
  }

  void connectToDevice(BluetoothDevice device) async {
    final bluetoothDeviceManager =
        Provider.of<BluetoothDeviceManager>(context, listen: false);
    bluetoothDeviceManager.setDevice(device);
    await bluetoothDeviceManager.connectDevice();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => BluetoothLoadingScreen(device: device)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color.fromARGB(255, 46, 46, 46), // Set the background color to gray
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),
            Center(
              child: Text(
                'Welcome',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Press the ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Icon(
                    Icons.bluetooth,
                    color: Colors.white,
                  ),
                  Text(
                    ' button on your SmartCube',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 63, 65, 64),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16.0), // Add padding
                  itemCount: devicesList.isEmpty ? 1 : devicesList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        title: Text(
                          devicesList.isEmpty
                              ? 'No SmartCube found'
                              : 'Select SmartCube:',
                          style: TextStyle(
                              color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return ListTile(
                      title: Text(
                        devicesList[index - 1].name,
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => connectToDevice(devicesList[index - 1]),
                        child: Text('Connect'),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return Divider(
                      color: index == 0 ? Color.fromARGB(255, 219, 221, 220) : Color.fromARGB(180, 46, 48, 47), // Set the color of the divider
                      thickness: index == 0 ? 0.5 : 1, // Different thickness for the first divider
                      indent: index == 0 ? 100 : 15,
                      endIndent: index == 0 ? 100 : 22,
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Image.asset("assets/SmartCube logo.png", width: 200),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothDeviceManager()),
      ],
      child: MaterialApp(
        home: BluetoothScreen(),
      ),
    );
  }
}
