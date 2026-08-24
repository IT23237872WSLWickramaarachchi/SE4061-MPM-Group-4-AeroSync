import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class UnityNetworkListener {
  int port;
  RawDatagramSocket? _socket;
  bool isListening = false;

  final void Function(String rawPacket, String senderIp) onGameStartTriggered;

  DateTime? lastTriggerTime;
  String? lastSenderIp;

  UnityNetworkListener({
    this.port = 8052,
    required this.onGameStartTriggered,
  });

  Future<bool> startListening() async {
    try {
      await stopListening();
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      isListening = true;

      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            final message = utf8.decode(datagram.data).trim();
            final sender = datagram.address.address;

            if (kDebugMode) {
              print('Unity Network Listener Received Packet from $sender: $message');
            }

            // Check for trigger signals: "GAME_START", "START", or JSON packet
            if (message.toUpperCase().contains('GAME_START') ||
                message.toUpperCase().contains('START') ||
                message.contains('scene')) {
              lastTriggerTime = DateTime.now();
              lastSenderIp = sender;
              onGameStartTriggered(message, sender);
            }
          }
        }
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting UnityNetworkListener on port $port: $e');
      }
      isListening = false;
      return false;
    }
  }

  Future<void> stopListening() async {
    _socket?.close();
    _socket = null;
    isListening = false;
  }
}
