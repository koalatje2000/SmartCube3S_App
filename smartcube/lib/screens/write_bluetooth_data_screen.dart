import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'dart:math';

class WriteDataScreen extends StatefulWidget {
  final BluetoothDevice device;
  final List<Map<String, String>> lights;
  final List<Map<String, dynamic>> rooms;
  WriteDataScreen({required this.device, required this.lights, required this.rooms});

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
  List<String> selectedLights = [];
  List<String> selectedRooms = [];

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

  void generateColorJson() {
    Map<String, dynamic> lightsData = {};
    for (int i = 0; i < colors.length; i++) {
      lightsData["${i + 1}"] = {
        "H": colors[i].value.toRadixString(16).substring(2).toUpperCase(),
        "B": brightness[i].toInt(),
        "M": 0
      };
    }

    Map<String, dynamic> colorJson = {
      "Lights": [lightsData],
    };

    setState(() {
      jsonData = jsonEncode(colorJson);
      _controller.text = jsonData;
    });
  }

  void generateSelectedLightsJson() {
    Map<String, dynamic> selectedLightsJson = {
      "SelectedLights": selectedLights,
    };

    setState(() {
      jsonData = jsonEncode(selectedLightsJson);
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

  void toggleRoomSelection(String roomId, List<dynamic> roomLights) {
    setState(() {
      if (selectedRooms.contains(roomId)) {
        selectedRooms.remove(roomId);
        roomLights.forEach((lightId) {
          selectedLights.remove(lightId);
        });
      } else {
        selectedRooms.add(roomId);
        roomLights.forEach((lightId) {
          if (!selectedLights.contains(lightId)) {
            selectedLights.add(lightId);
          }
        });
      }
      generateSelectedLightsJson();
    });
  }

  void toggleLightSelection(String lightId) {
    setState(() {
      if (selectedLights.contains(lightId)) {
        selectedLights.remove(lightId);
        widget.rooms.forEach((room) {
          if (room['lights'].contains(lightId)) {
            selectedRooms.remove(room['uuid']);
          }
        });
      } else {
        selectedLights.add(lightId);
        widget.rooms.forEach((room) {
          if (room['lights'].every((light) => selectedLights.contains(light))) {
            if (!selectedRooms.contains(room['uuid'])) {
              selectedRooms.add(room['uuid']);
            }
          }
        });
      }
      generateSelectedLightsJson();
    });
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
                  // Colors Section
                  Text(
                    'Set Colors:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                  ElevatedButton(
                    onPressed: generateColorJson,
                    child: Text('Generate Color JSON'),
                  ),
                  SizedBox(height: 20),

                  // Lights and Rooms Section
                  Text(
                    'Select Lights:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Column(
                    children: widget.lights.map((light) {
                      return CheckboxListTile(
                        title: Text(light['name']!),
                        value: selectedLights.contains(light['uuid']),
                        onChanged: (bool? value) {
                          toggleLightSelection(light['uuid']!);
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Select Rooms:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Column(
                    children: widget.rooms.map((room) {
                      return CheckboxListTile(
                        title: Text(room['name']!),
                        value: selectedRooms.contains(room['uuid']),
                        onChanged: (bool? value) {
                          toggleRoomSelection(room['uuid']!, room['lights']!);
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),

                  // Characteristic Section
                  Text(
                    'Select Characteristic:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                  
                  // Text to Send Section
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
