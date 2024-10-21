import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'dart:math';

class WriteDataScreen extends StatefulWidget {
  final BluetoothDevice device;

  WriteDataScreen({required this.device});

  @override
  _WriteDataScreenState createState() => _WriteDataScreenState();
}

class _WriteDataScreenState extends State<WriteDataScreen> {
  List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.pink];
  List<double> brightness = [50, 50, 50, 50, 50];
  List<BluetoothCharacteristic> characteristics = [];
  BluetoothCharacteristic? selectedCharacteristic;
  String jsonData = '';
  bool isLoading = true;
  final TextEditingController _controller = TextEditingController();

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
        selectedCharacteristic = characteristics.isNotEmpty ? characteristics.first : null;
        isLoading = false;
      });
    } catch (e) {
      print("Error discovering services: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void setRandomColor(int index) {
    final random = Random();
    setState(() {
      colors[index] = Color.fromARGB(255, random.nextInt(256), random.nextInt(256), random.nextInt(256));
    });
  }

  void generateLightData() {
    Map<String, dynamic> lights = {};
    for (int i = 0; i < colors.length; i++) {
      lights["${i + 1}"] = {
        "H": colors[i].value.toRadixString(16).substring(2).toUpperCase(),
        "B": brightness[i].toInt(),
        "M": 0
      };
    }

    Map<String, dynamic> data = {
      "Lights": [lights]
    };

    setState(() {
      jsonData = jsonEncode(data);
      _controller.text = jsonData;
    });
  }

  void sendData() async {
    if (selectedCharacteristic != null) {
      if (selectedCharacteristic!.properties.write) {
        await selectedCharacteristic!.write(utf8.encode(_controller.text));
        print("Data sent: ${_controller.text}");
      } else {
        print("Selected characteristic is not writable");
      }
    } else {
      print("No characteristic selected");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Write Data'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  for (int i = 0; i < colors.length; i++)
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => setRandomColor(i),
                          child: Text('Set Random Color ${i + 1}'),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          color: colors[i],
                          margin: EdgeInsets.only(left: 10),
                        ),
                        Expanded(
                          child: Slider(
                            value: brightness[i],
                            min: 0,
                            max: 100,
                            divisions: 100,
                            label: brightness[i].round().toString(),
                            onChanged: (value) {
                              setState(() {
                                brightness[i] = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: generateLightData,
                    child: Text('Generate Light Data'),
                  ),
                  SizedBox(height: 20),
                  DropdownButton<BluetoothCharacteristic>(
                    value: selectedCharacteristic,
                    onChanged: (BluetoothCharacteristic? newValue) {
                      setState(() {
                        selectedCharacteristic = newValue;
                      });
                    },
                    items: characteristics.map<DropdownMenuItem<BluetoothCharacteristic>>((BluetoothCharacteristic characteristic) {
                      return DropdownMenuItem<BluetoothCharacteristic>(
                        value: characteristic,
                        child: Text(characteristic.uuid.toString()),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Text to send',
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: sendData,
                    child: Text('Send Data'),
                  ),
                ],
              ),
            ),
    );
  }
}
