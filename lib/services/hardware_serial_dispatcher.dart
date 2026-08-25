import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/fan_automation_data.dart';

class HardwareSerialDispatcher {
  String comPort;
  int baudRate;
  bool isConnected;
  final List<String> dispatchLog = [];

  FanState _lastF1 = FanState.off;
  FanState _lastF2 = FanState.off;
  FanState _lastF3 = FanState.off;

  HardwareSerialDispatcher({
    this.comPort = 'COM4',
    this.baudRate = 115200,
    this.isConnected = true,
  });

  /// Dispatch fan relay commands to ESP-32 / ESP-01 IoT bridge over UART
  void dispatchStates({
    required FanState f1,
    required FanState f2,
    required FanState f3,
    bool forceDispatch = false,
  }) {
    // Only send payload if fan state changed or force option enabled
    if (!forceDispatch && f1 == _lastF1 && f2 == _lastF2 && f3 == _lastF3) {
      return;
    }

    _lastF1 = f1;
    _lastF2 = f2;
    _lastF3 = f3;

    // Format UART Payload for ESP-32 Relay Controller
    // Format: "F1:<0|1|2>,F2:<0|1|2>,F3:<0|1|2>\n"
    final payload = 'F1:${f1.levelCode},F2:${f2.levelCode},F3:${f3.levelCode}\n';
    final timestamp = DateTime.now().toString().split(' ').last.substring(0, 8);
    final cleanPort = comPort.split(' ').first.trim();

    bool bytesWritten = false;
    if (Platform.isWindows) {
      try {
        final devicePath = '\\\\.\\$cleanPort';
        final file = File(devicePath);
        final raf = file.openSync(mode: FileMode.writeOnly);
        raf.writeStringSync(payload);
        raf.flushSync();
        raf.closeSync();
        bytesWritten = true;
      } catch (e) {
        if (kDebugMode) {
          print('Serial Port TX Warning ($cleanPort): $e');
        }
      }
    }

    final statusLabel = bytesWritten ? 'UART TX SUCCESS' : 'UART TX LOGGED';
    final logEntry = '[$timestamp] [$cleanPort] $statusLabel -> ${payload.trim()} (F1:${f1.label}, F2:${f2.label}, F3:${f3.label})';

    dispatchLog.insert(0, logEntry);
    if (dispatchLog.length > 50) {
      dispatchLog.removeLast();
    }

    if (kDebugMode) {
      print('HARDWARE DISPATCH: $logEntry');
    }
  }

  void clearLogs() {
    dispatchLog.clear();
  }
}

