import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceManager extends ChangeNotifier {
  BluetoothDevice? _device;

  BluetoothDevice? get device => _device;

  void setDevice(BluetoothDevice device) {
    _device = device;
    notifyListeners();
  }

  Future<void> connectDevice() async {
    if (_device != null) {
      await _device!.connect();
    }
  }

  Future<void> disconnectDevice() async {
    if (_device != null) {
      await _device!.disconnect();
    }
  }
}
