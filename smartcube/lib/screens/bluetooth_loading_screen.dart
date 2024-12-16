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
  bool _jsonValid = false;
  String _statusMessage = "Getting information from device...";
  BluetoothCharacteristic? generalInfoCharacteristic;

  bool _confirmButtonPresent = false;
  bool _confirmButtonPressed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    readGeneralInformationCharacteristic();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Future<void> readGeneralInformationCharacteristic() async {
    try {
      if (!mounted) return;
      List<BluetoothService> services = await widget.device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString() ==
              "12345678-1234-5678-1234-56789abcdef1") {
            generalInfoCharacteristic = characteristic;
            bool linkStatus = false;
            while (!linkStatus) {
              if (!mounted) return;
              print("Reading general information...");
              await readGeneralInformation(characteristic);
              linkStatus = await getLinkStatus();
            }
            NavigateToMainScreen();
          }
        }
      }
    } catch (e) {
      print('Error reading general information characteristic: $e');
      return;
    }
  }

  Future<bool> getLinkStatus() async {
    if (!mounted) return false;
    print("Update screen, state: $bridge");
    switch (bridge) {
      case 0:
        setState(() {
          _statusMessage = 'Press link button on bridge';
          _confirmButtonPresent = true;
          _confirmButtonPressed = false;
          _isLoading = false;
        });
        await Future.delayed(Duration(seconds: 1));
        while (!_confirmButtonPressed) {
          await Future.delayed(Duration(seconds: 1));
          print("Press confirm button...");
        }
        print("Confirm button pressed...");
        await writeBridgeStatus(2);
        return false;
      case 1:
        setState(() {
          _statusMessage = 'Connection successful';
          _confirmButtonPresent = false;
          _confirmButtonPressed = false;
          _isLoading = false;
        });
        await readDeviceData();
        return true;
      case 2:
        setState(() {
          _isLoading = true;
          _confirmButtonPresent = false;
          _statusMessage = 'Linking to bridge...';
        });
        await Future.delayed(Duration(seconds: 3));
        return false;
      case 3:
        setState(() {
          _statusMessage = 'Link button not pressed, please retry';
          _confirmButtonPresent = true;
          _confirmButtonPressed = false;
          _isLoading = false;
        });
        while (!_confirmButtonPressed) {
          await Future.delayed(Duration(seconds: 1));
          print("Press confirm button...");
        }
        print("Confirm button pressed...");
        await writeBridgeStatus(2);
        return false;
      case 5:
        setState(() {
          _statusMessage =
              'Bridge not found, please make sure the bridge is connected to your network and retry';
          _confirmButtonPresent = true;
          _confirmButtonPressed = false;
          _isLoading = false;
        });
        while (!_confirmButtonPressed) {
          await Future.delayed(Duration(seconds: 1));
          print("Press confirm button...");
        }
        print("Confirm button pressed...");
        await writeBridgeStatus(2);
        return false;
      default:
        _statusMessage = 'Unknown status';
        return false;
    }
  }

  Future<void> readDeviceData() async {
    try {
      if (!mounted) return;
      print("Discovering services...");
      List<BluetoothService> services = await widget.device.discoverServices();
      print("Services discovered: ${services.length}");
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString() ==
              "12345678-1234-5678-1234-56789abcdef1") {
            print("Reading general information...");
            await readGeneralInformation(characteristic);
          } else if (characteristic.uuid.toString() ==
              "12345678-1234-5678-1234-56789abcdef2") {
            print("Reading light side information...");
            await readLightSideInfo(characteristic);
          } else if (characteristic.uuid.toString() ==
              "12345678-1234-5678-1234-56789abcdef3") {
            print("Subscribing to lights and rooms...");
            await subscribeToLightsAndRooms(characteristic);
          } else if (characteristic.uuid.toString() ==
              "12345678-1234-5678-1234-56789abcdef4") {
            print("Reading selected lights...");
            await readSelectedLights(characteristic);
          }
        }
      }
    } catch (e) {
      print("Error reading device data: $e");
      return;
    }
  }

  Future<void> writeBridgeStatus(int newStatus) async {
    try {
      if (!mounted) return;
      if (generalInfoCharacteristic != null) {
        List<int> value = await generalInfoCharacteristic!.read();
        String data = String.fromCharCodes(value);
        var jsonData = jsonDecode(data);

        // Update only the Bridge status
        jsonData['Bridge'] = newStatus;

        await generalInfoCharacteristic!
            .write(utf8.encode(jsonEncode(jsonData)));
        print("Bridge status updated to $newStatus");

        setState(() {
          bridge = newStatus;
        });
      }
    } catch (e) {
      print("Error writing bridge status: $e");
    }
  }

  void NavigateToMainScreen() {
    print("Navigating to main screen...");
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MainScreen(
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
  }

  Future<void> readGeneralInformation(
      BluetoothCharacteristic characteristic) async {
    try {
      if (!mounted) return;
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
      return;
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
          lightsSideInfo =
              Map<String, Map<String, dynamic>>.from(jsonData['Lights'][0]);
        });
      }
    } catch (e) {
      print("Error reading light side information: $e");
    }
  }

  Future<void> subscribeToLightsAndRooms(
      BluetoothCharacteristic characteristic) async {
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
          _jsonValid = true;
        }
      });
      print("Subscribing...");
      await characteristic.setNotifyValue(true);
      print("Subscribed...");
      while (!_jsonValid) {
        print("Waiting for valid JSON....");
        await Future.delayed(Duration(seconds: 1));
      }
    } catch (e) {
      print("Error reading lights and rooms: $e");
    }
  }

  bool isJsonComplete(String json) {
    try {
      if (json.isEmpty) return false;
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
              .map((light) => {
                    'uuid': light['uuid'] as String,
                    'name': light['name'] as String
                  })
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

  Future<void> readSelectedLights(
      BluetoothCharacteristic characteristic) async {
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            widget.device.disconnect();
            Navigator.pop(context);
            },
      ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(_statusMessage),
            if (_confirmButtonPresent)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _confirmButtonPressed = true;
                  });
                },
                child: Text("Confirm"),
              ),
          ],
        ),
      ),
    );
  }
}
