import 'package:flutter/material.dart';
import 'dart:convert';

class LightsRoomsSelector extends StatefulWidget {
  final List<Map<String, String>> lights;
  final List<Map<String, dynamic>> rooms;
  final List<String> selectedLights;
  final Function(String) onClose;

  LightsRoomsSelector({
    required this.lights,
    required this.rooms,
    required this.selectedLights,
    required this.onClose,
  });

  @override
  _LightsRoomsSelectorState createState() => _LightsRoomsSelectorState();
}

class _LightsRoomsSelectorState extends State<LightsRoomsSelector> {
  final TextEditingController _controller = TextEditingController();
  List<String> selectedLights = [];
  List<String> selectedRooms = [];
  String jsonData = '';

  @override
  void initState() {
    super.initState();
    selectedLights = List.from(widget.selectedLights);
    updateSelectedRooms();
    generateSelectedLightsJson();
  }

  @override
  void deactivate() {
    widget.onClose(jsonData);
    super.deactivate();
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

  void updateSelectedRooms() {
    selectedRooms = widget.rooms.where((room) {
      return room['lights'].every((light) => selectedLights.contains(light));
    }).map((room) => room['uuid'].toString()).toList();
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: ScrollController(),
              child: Column(
                children: [
                  SizedBox(height: 20,),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
