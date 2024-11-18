import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'write_bluetooth_data_screen.dart';

class ReadDataScreen extends StatefulWidget {
  final BluetoothDevice device;

  ReadDataScreen({required this.device});

  @override
  _ReadDataScreenState createState() => _ReadDataScreenState();
}

class _ReadDataScreenState extends State<ReadDataScreen> {
  List<BluetoothService> services = [];
  List<BluetoothCharacteristic> characteristics = [];
  bool isLoading = true;
  String readData = '';
  bool isSubscribed = false;
  BluetoothCharacteristic? subscribedCharacteristic;
  List<Map<String, String>> lights = [];
  List<Map<String, dynamic>> rooms = [];

  @override
  void initState() {
    super.initState();
    discoverServices();
  }

  void discoverServices() async {
    try {
      List<BluetoothService> services = await widget.device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          characteristics.add(characteristic);
        }
      }
      setState(() {
        this.services = services;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void readCharacteristic(BluetoothCharacteristic characteristic) async {
    try {
      List<int> value = await characteristic.read();
      String data = String.fromCharCodes(value);
      setState(() {
        readData = data;
        parseJsonData(data);
      });
    } catch (e) {
      setState(() {
        readData = 'Error: Unable to read characteristic';
      });
    }
  }

  void parseJsonData(String data) {
    try {
      var jsonData = jsonDecode(data);
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
    } catch (e) {
      print("Error parsing JSON data: $e");
    }
  }

  void toggleSubscription(BluetoothCharacteristic characteristic) async {
    if (isSubscribed) {
      await characteristic.setNotifyValue(false);
      setState(() {
        isSubscribed = false;
      });
    } else {
      characteristic.value.listen((value) {
        String data = String.fromCharCodes(value);
        setState(() {
          readData += data;
          parseJsonData(readData);
        });
      });
      await characteristic.setNotifyValue(true);
      setState(() {
        isSubscribed = true;
        subscribedCharacteristic = characteristic;
      });
    }
  }

  void subscribeToLightsAndRooms() async {
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == "12345678-1234-5678-1234-56789abcdef3") {
          toggleSubscription(characteristic);
          return;
        }
      }
    }
    print("Characteristic not found.");
  }

  void copyToClipboard() {
    Clipboard.setData(ClipboardData(text: readData));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Copied to clipboard!'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Read Data'),
      ),
      body: Column(
        children: [
          isLoading
              ? Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : characteristics.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Text('No characteristics found'),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: characteristics.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text('Characteristic UUID: ${characteristics[index].uuid}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    readCharacteristic(characteristics[index]);
                                  },
                                  child: Text('Read Data'),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    toggleSubscription(characteristics[index]);
                                  },
                                  child: Text(isSubscribed && subscribedCharacteristic == characteristics[index] ? 'Unsubscribe' : 'Subscribe'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          Container(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Read Data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: subscribeToLightsAndRooms,
            child: Text('Read Lights and Rooms'),
          ),
          ElevatedButton(
            onPressed: copyToClipboard,
            child: Text('Copy to Clipboard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WriteDataScreen(device: widget.device, lights: lights, rooms: rooms),
                ),
              );
            },
            child: Text('Go to Write Screen'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Text(readData),
            ),
          ),
        ],
      ),
    );
  }
}
