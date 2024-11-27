import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'dart:async';
import 'main_screen.dart';

class BluetoothLoadingScreen extends StatefulWidget {
  final BluetoothDevice device;

  BluetoothLoadingScreen({required this.device});

  @override
  _BluetoothLoadingScreenState createState() => _BluetoothLoadingScreenState();
}

class _BluetoothLoadingScreenState extends State<BluetoothLoadingScreen> {
  String name = '';
  int type = 0;
  int battery = 0;
  bool charging = false;
  int bridge = 0;
  Map<String, Map<String, dynamic>> lightsSideInfo = {};
  List<Map<String, String>> lights = [];
  List<Map<String, dynamic>> rooms = [];
  List<String> selectedLights = [];
  String readData = '';
  StreamSubscription<List<int>>? subscription;

  @override
  void initState() {
    super.initState();
    readDeviceData();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Future<void> readDeviceData() async {
    try {
      print("Discovering services...");
      List<BluetoothService> services = await widget.device.discoverServices();
      print("Services discovered: ${services.length}");
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == "12345678-1234-5678-1234-56789abcdef1") {
            print("Reading general information...");
            await readGeneralInformation(characteristic);
          } else if (characteristic.uuid.toString() == "12345678-1234-5678-1234-56789abcdef2") {
            print("Reading light side information...");
            await readLightSideInfo(characteristic);
          } else if (characteristic.uuid.toString() == "12345678-1234-5678-1234-56789abcdef3") {
            print("Subscribing to lights and rooms...");
            await subscribeToLightsAndRooms(characteristic);
          } else if (characteristic.uuid.toString() == "12345678-1234-5678-1234-56789abcdef4") {
            print("Reading selected lights...");
            await readSelectedLights(characteristic);
          }
        }
      }

      print("Navigating to main screen...");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(
            device: widget.device,
            name: name,
            type: type,
            battery: battery,
            charging: charging,
            bridge: bridge,
            lightsSideInfo: lightsSideInfo,
            lights: lights,
            rooms: rooms,
            selectedLights: selectedLights,
          )),
        );
      }
    } catch (e) {
      print("Error reading device data: $e");
    }
  }

  Future<void> readGeneralInformation(BluetoothCharacteristic characteristic) async {
    try {
      List<int> value = await characteristic.read();
      String data = String.fromCharCodes(value);
      print("General Information Data: $data");
      var jsonData = jsonDecode(data);
      if (mounted) {
        setState(() {
          name = jsonData['Name'];
          type = jsonData['Type'];
          battery = jsonData['Battery'];
          charging = jsonData['Charging'] == 1;
          bridge = jsonData['Bridge'];
        });
      }
    } catch (e) {
      print("Error reading general information: $e");
    }
  }

  Future<void> readLightSideInfo(BluetoothCharacteristic characteristic) async {
    try {
      List<int> value = await characteristic.read();
      String data = String.fromCharCodes(value);
      print("Light Side Information Data: $data");
      var jsonData = jsonDecode(data);
      if (mounted) {
        setState(() {
          lightsSideInfo = Map<String, Map<String, dynamic>>.from(jsonData['Lights'][0]);
        });
      }
    } catch (e) {
      print("Error reading light side information: $e");
    }
  }

  Future<void> subscribeToLightsAndRooms(BluetoothCharacteristic characteristic) async {
    try {
      StringBuffer receivedData = StringBuffer();
      subscription = characteristic.value.listen((value) {
        print("Characteristic updated");
        String dataPart = String.fromCharCodes(value);
        print("Received data part: $dataPart");
        receivedData.write(dataPart);
        if (isJsonComplete(receivedData.toString())) {
          parseLightsAndRoomsData(receivedData.toString());
          characteristic.setNotifyValue(false);
          subscription?.cancel();
          receivedData.clear();
        }
      });
      print("Subscribing...");
      await characteristic.setNotifyValue(true);
      print("Subscribed...");
    } catch (e) {
      print("Error reading lights and rooms: $e");
    }
  }

  bool isJsonComplete(String json) {
    try {
      jsonDecode(json);
      return true;
    } catch (e) {
      return false;
    }
  }

  void parseLightsAndRoomsData(String data) {
    try {
      print("Complete Lights and Rooms Data: $data");
      var jsonData = jsonDecode(data);
      if (mounted) {
        setState(() {
          lights = (jsonData['Lights'] as List)
              .map((light) => {'uuid': light['uuid'] as String, 'name': light['name'] as String})
              .toList();
          rooms = (jsonData['rooms'] as List)
              .map((room) => {
                    'uuid': room['uuid'] as String,
                    'name': room['name'] as String,
                    'lights': room['lights'] as List<dynamic>
                  })
              .toList();
        });
      }
    } catch (e) {
      print("Error parsing lights and rooms data: $e");
    }
  }

  Future<void> readSelectedLights(BluetoothCharacteristic characteristic) async {
    try {
      List<int> value = await characteristic.read();
      String data = String.fromCharCodes(value);
      print("Selected Lights Data: $data");
      var jsonData = jsonDecode(data);
      if (mounted) {
        setState(() {
          selectedLights = List<String>.from(jsonData['SelectedLights']);
        });
      }
    } catch (e) {
      print("Error reading selected lights: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loading...'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Reading data from the device...'),
          ],
        ),
      ),
    );
  }
}
