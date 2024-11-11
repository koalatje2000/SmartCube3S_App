import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    discoverServices();
  }

  void discoverServices() async {
    try {
      print("Discovering services...");
      List<BluetoothService> services = await widget.device.discoverServices();
      print("Services discovered: ${services.length}");
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          print("Found characteristic: ${characteristic.uuid}");
          characteristics.add(characteristic);
        }
      }
      setState(() {
        this.services = services;
        isLoading = false;
      });
    } catch (e) {
      print("Error discovering services: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void readCharacteristic(BluetoothCharacteristic characteristic) async {
    try {
      print("Reading characteristic: ${characteristic.uuid}");
      List<int> value = await characteristic.read();
      String data;
      
      try {
        data = utf8.decode(value);
      } catch (e) {
        data = value.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
      }
      
      print("Characteristic value: $data");
      setState(() {
        readData = 'Characteristic ${characteristic.uuid}: $data';
      });
    } catch (e) {
      print("Error reading characteristic: $e");
      setState(() {
        readData = 'Error: Unable to read characteristic';
      });
    }
  }

  void toggleSubscription(BluetoothCharacteristic characteristic) async {
    if (isSubscribed) {
      await characteristic.setNotifyValue(false);
      setState(() {
        isSubscribed = false;
        readData += '\nUnsubscribed from characteristic: ${characteristic.uuid}';
      });
    } else {
      characteristic.value.listen((value) {
        String data;
        try {
          data = utf8.decode(value);
        } catch (e) {
          data = value.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
        }
        setState(() {
          readData += '\nCharacteristic ${characteristic.uuid}: $data';
        });
      });
      await characteristic.setNotifyValue(true);
      setState(() {
        isSubscribed = true;
        subscribedCharacteristic = characteristic;
        readData += '\nSubscribed to characteristic: ${characteristic.uuid}';
      });
    }
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
