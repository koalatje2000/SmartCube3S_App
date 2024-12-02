import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'color_picker.dart';
import 'lights_rooms_selector.dart'; 

class MainScreen extends StatefulWidget {
  final BluetoothDevice device;
  final String name;
  final int type;
  final int battery;
  final bool charging;
  final int bridge;
  final Map<String, Map<String, dynamic>> lightsSideInfo;
  final List<Map<String, String>> lights;
  final List<Map<String, dynamic>> rooms;
  final List<String> selectedLights;

  MainScreen({
    required this.device,
    required this.name,
    required this.type,
    required this.battery,
    required this.charging,
    required this.bridge,
    required this.lightsSideInfo,
    required this.lights,
    required this.rooms,
    required this.selectedLights,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Color? _selectedColor;
  late List<String> _selectedLights;
  late bool _dataChanged;

  @override
  void initState() {
    super.initState();
    _selectedLights = widget.selectedLights;
    widget.device.connect(autoConnect: false);
  }

  @override
  void dispose() {
    widget.device.disconnect();
    super.dispose();
  }

  Color _colorFromHex(String hexColor) {
    return Color(int.parse(hexColor, radix: 16) | 0xFF000000);
  }

  void _showColorPicker(int side) {
    setState(() {
      _selectedColor = _colorFromHex(widget.lightsSideInfo[side.toString()]?["H"] ?? "FFFFFF");
      _dataChanged = false;
    });
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return HueColorPickerWidget(
          initialColor: _selectedColor!,
          onColorChanged: (color) {
            setState(() {
              _selectedColor = color;
              widget.lightsSideInfo[side.toString()]?["H"] = color.value.toRadixString(16).substring(2).toUpperCase();
              _dataChanged = true;
            });
          },
          onSliderChanged: (value) {
            setState(() {
              widget.lightsSideInfo[side.toString()]?["B"] = value.toInt();
              _dataChanged = true;
            });
          },
          lightsSideInfo: widget.lightsSideInfo,
          selectedSide: side,
          onClose: () {
            print("Closed screen...");
            setState(() {
              if(_dataChanged){
                  _updateSideCharacteristic();
              }
            });
          },
        );
      },
    );
  }

  void _showLightsRoomsSelector() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) {
          return LightsRoomsSelector(
            lights: widget.lights,
            rooms: widget.rooms,
            selectedLights: _selectedLights,
            onClose: (String data) {
              print("Closed screen...");
              List<String> newSelectedLights = (jsonDecode(data)["SelectedLights"] as List).map((item) => item as String).toList();
              setState(() {
                if (!listEquals(newSelectedLights, _selectedLights)) {
                  _selectedLights = newSelectedLights;
                  _updateSelectedLightsCharacteristic(_selectedLights);
                }
              });
            },
          );
        },
      );
    },
  );
}

bool listEquals<T>(List<T> list1, List<T> list2) {
  if (list1.length != list2.length) {
    return false;
  }
  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) {
      return false;
    }
  }
  return true;
}


  void _updateSelectedLightsCharacteristic(List<String> selectedLights) async {
    String characteristicUuid = "12345678-1234-5678-1234-56789abcdef4";
    List<BluetoothService> services = await widget.device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == characteristicUuid) {
          if (characteristic.properties.write) {
            await characteristic.write(utf8.encode(jsonEncode({"SelectedLights": selectedLights})));
            print("Data sent: ${jsonEncode({"SelectedLights": selectedLights})}");
          } else {
            print("Selected characteristic is not writable");
          }
          return;
        }
      }
    }
    print("Characteristic not found");
  }

  void _updateSideCharacteristic() async {
    String characteristicUuid = "12345678-1234-5678-1234-56789abcdef2";
    List<BluetoothService> services = await widget.device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == characteristicUuid) {
          if (characteristic.properties.write) {
            var lightsData = {"Lights": [widget.lightsSideInfo]};
            await characteristic.write(utf8.encode(jsonEncode(lightsData)));
            print("Data sent: ${jsonEncode(lightsData)}");
          } else {
            print("Selected characteristic is not writable");
          }
          return;
        }
      }
    }
    print("Characteristic not found");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Screen'),
      ),
      body: Center(
        child: GridView.builder(
          padding: EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            int side = index + 1;
            return Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _colorFromHex(widget.lightsSideInfo[side.toString()]?["H"] ?? "FFFFFF"),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showColorPicker(side),
                  child: Text('Change color for side $side'),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.batch_prediction_outlined),
              onPressed: _showLightsRoomsSelector,
            ),
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                // TODO: implement settingsscreen
              },
            ),
          ],
        ),
      ),
    );
  }
}
