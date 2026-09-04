import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class UnityNetworkListener {
  int port;
  RawDatagramSocket? _socket;
  bool isListening = false;

  final void Function(String rawPacket, String senderIp, String projectId) onGameStartTriggered;

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

            String projectId = '';
            bool isStartTrigger = false;

            try {
              // Attempt to parse JSON (from new bridge)
              final Map<String, dynamic> jsonPayload = jsonDecode(message);
              if (jsonPayload.containsKey('action') && jsonPayload['action'] == 'GAME_START') {
                isStartTrigger = true;
                if (jsonPayload.containsKey('projectId')) {
                  projectId = jsonPayload['projectId'].toString();
                }
              }
            } catch (e) {
              // Fallback for old simple text messages
              if (message.toUpperCase().contains('GAME_START') ||
                  message.toUpperCase().contains('START') ||
                  message.contains('scene')) {
                isStartTrigger = true;
              }
            }

            if (isStartTrigger) {
              lastTriggerTime = DateTime.now();
              lastSenderIp = sender;
              onGameStartTriggered(message, sender, projectId);
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
