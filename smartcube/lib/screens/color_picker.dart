import 'package:flutter/material.dart';
import 'package:smartcube/class/flutter_circle_color_picker.dart';

class HueColorPickerWidget extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<double> onMiredValueChanged;
  final Map<String, Map<String, dynamic>> lightsSideInfo;
  final int selectedSide;
  final Function() onClose;

  HueColorPickerWidget({
    required this.initialColor,
    required this.onColorChanged,
    required this.onSliderChanged,
    required this.onMiredValueChanged,
    required this.lightsSideInfo,
    required this.selectedSide,
    required this.onClose,
  });

  @override
  _HueColorPickerWidgetState createState() => _HueColorPickerWidgetState();
}

class _HueColorPickerWidgetState extends State<HueColorPickerWidget> {
  late Color _currentColor;
  late CircleColorPickerController _controller;
  late double _sliderValue;
  late double _miredSliderValue;

  // Custom array of colors
  final List<Color> customColors = [
    const Color.fromARGB(255, 255, 0, 0),
    const Color.fromARGB(255, 252, 176, 0),
    const Color.fromARGB(255, 252, 239, 0),
    const Color.fromARGB(255, 0, 255, 0),
    const Color.fromARGB(255, 0, 248, 252),
    const Color.fromARGB(255, 0, 0, 255),
    const Color.fromARGB(255, 202, 0, 252),
    const Color.fromARGB(255, 252, 0, 151),
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _controller = CircleColorPickerController(initialColor: _currentColor);
    _sliderValue = widget.lightsSideInfo[widget.selectedSide.toString()]?["B"]?.toDouble() ?? 50.0;
    _miredSliderValue = widget.lightsSideInfo[widget.selectedSide.toString()]?["M"]?.toDouble() ?? 500.0;
    if (_miredSliderValue < 153) _miredSliderValue = 153;
    if (_miredSliderValue > 500) _miredSliderValue = 500;
  }

  @override
  void deactivate() {
    widget.onClose();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 10),
              CircleColorPicker(
                controller: _controller,
                strokeWidth: 8,
                size: Size(175, 175),
                onChanged: (color) {
                  setState(() {
                    _currentColor = color;
                    widget.lightsSideInfo[widget.selectedSide.toString()]?["M"] = 0;
                  });
                  widget.onColorChanged(color);
                },
              ),
              SizedBox(width: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  children: List.generate(customColors.length, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentColor = customColors[index]);
                        _controller.color = customColors[index];
                        widget.onColorChanged(customColors[index]);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: customColors[index],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(width: 30),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outlined),
              Expanded(
                child: Slider(
                  value: _sliderValue,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: _sliderValue.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _sliderValue = value;
                      widget.onSliderChanged(value);
                    });
                  },
                ),
              ),
              Icon(Icons.lightbulb),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.thermostat, color: Color.fromARGB(255, 0, 0, 255),),
              Expanded(
                child: Slider(
                  value: _miredSliderValue,
                  min: 153,
                  max: 500,
                  divisions: 100,
                  label: "${(1000000/_miredSliderValue).round()}K",
                  onChanged: (value) {
                    setState(() {
                      _miredSliderValue = value;
                      widget.onMiredValueChanged(value);
                    });
                  },
                ),
              ),
              Icon(Icons.thermostat, color: Color.fromARGB(255, 255, 0, 0)),
            ],
          ),
        ],
      ),
    );
  }
}
