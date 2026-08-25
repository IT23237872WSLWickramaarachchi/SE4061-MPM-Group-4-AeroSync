import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/aerosync_state_provider.dart';
import '../theme/aerosync_theme.dart';

class HardwareSettingsPanel extends StatelessWidget {
  const HardwareSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AeroSyncStateProvider>();

    return Container(
      padding: const EdgeInsets.all(24),
      color: AeroSyncTheme.darkBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.settings_remote,
                size: 24,
                color: AeroSyncTheme.primaryTeal,
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hardware & VR Sync Configuration',
                    style: TextStyle(
                      color: AeroSyncTheme.textMain,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: AeroSyncTheme.fontHeadline,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ESP-32 / ESP-01 Serial UART Relay Dispatcher & Unity VR Network Listener',
                    style: TextStyle(
                      color: AeroSyncTheme.textMuted,
                      fontSize: 12,
                      fontFamily: AeroSyncTheme.fontHeadline,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  final jsonStr = state.exportPresetJson();
                  _showJsonDialog(
                    context,
                    'Exported JSON Timeline Preset',
                    jsonStr,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AeroSyncTheme.panelBackground,
                  foregroundColor: AeroSyncTheme.primaryTeal,
                  side: const BorderSide(color: AeroSyncTheme.borderColor),
                ),
                icon: const Icon(Icons.code, size: 16),
                label: const Text(
                  'Export JSON',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  _showImportJsonDialog(context, state);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AeroSyncTheme.primaryTeal,
                  foregroundColor: AeroSyncTheme.darkBackground,
                ),
                icon: const Icon(Icons.file_upload_outlined, size: 16),
                label: const Text(
                  'Import JSON',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Configuration Cards Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unity Network Listener Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AeroSyncTheme.panelBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AeroSyncTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.wifi,
                            size: 18,
                            color: AeroSyncTheme.primaryTeal,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'UNITY VR WIFI LISTENER',
                            style: TextStyle(
                              color: AeroSyncTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              fontFamily: AeroSyncTheme.fontTechnical,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'UDP Listening Port',
                        '${state.unityListener.port}',
                      ),
                      _buildInfoRow(
                        'Listener Status',
                        state.unityListener.isListening
                            ? 'ACTIVE (Listening...)'
                            : 'STOPPED',
                      ),
                      _buildInfoRow('Trigger Event', 'GAME_START / START'),
                      _buildInfoRow(
                        'Last Received',
                        state.unityListener.lastSenderIp ??
                            'Waiting for Unity VR...',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // ESP-32 Serial UART Dispatcher Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AeroSyncTheme.panelBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AeroSyncTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.memory,
                            size: 18,
                            color: AeroSyncTheme.fan1Orange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ESP-32 / ESP-01 SERIAL UART',
                            style: TextStyle(
                              color: AeroSyncTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              fontFamily: AeroSyncTheme.fontTechnical,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'COM Port',
                        state.hardwareDispatcher.comPort,
                      ),
                      _buildInfoRow(
                        'Baud Rate',
                        '${state.hardwareDispatcher.baudRate} 8-N-1',
                      ),
                      _buildInfoRow(
                        'Relay Protocol',
                        'F1:<0|1|2>,F2:<0|1|2>,F3:<0|1|2>\\n',
                      ),
                      _buildInfoRow(
                        'Active Relay Dispatch',
                        'F1:${state.f1State.label}, F2:${state.f2State.label}, F3:${state.f3State.label}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Live UART Serial Dispatch Log Monitor
          const Text(
            'LIVE SERIAL DISPATCH MONITOR',
            style: TextStyle(
              color: AeroSyncTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              fontFamily: AeroSyncTheme.fontTechnical,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF090D0C),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AeroSyncTheme.borderColor),
              ),
              child: ListView.builder(
                itemCount: state.hardwareDispatcher.dispatchLog.length,
                itemBuilder: (context, index) {
                  final log = state.hardwareDispatcher.dispatchLog[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log,
                      style: const TextStyle(
                        color: AeroSyncTheme.primaryTeal,
                        fontSize: 11,
                        fontFamily: AeroSyncTheme.fontTechnical,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AeroSyncTheme.textMuted,
              fontSize: 12,
              fontFamily: AeroSyncTheme.fontHeadline,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AeroSyncTheme.textMain,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: AeroSyncTheme.fontTechnical,
            ),
          ),
        ],
      ),
    );
  }

  void _showJsonDialog(BuildContext context, String title, String jsonContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AeroSyncTheme.panelBackground,
        title: Text(
          title,
          style: const TextStyle(color: AeroSyncTheme.textMain, fontSize: 16),
        ),
        content: SizedBox(
          width: 500,
          height: 350,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonContent,
              style: const TextStyle(
                color: AeroSyncTheme.primaryTeal,
                fontFamily: AeroSyncTheme.fontTechnical,
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AeroSyncTheme.primaryTeal),
            ),
          ),
        ],
      ),
    );
  }

  void _showImportJsonDialog(
    BuildContext context,
    AeroSyncStateProvider state,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AeroSyncTheme.panelBackground,
        title: const Text(
          'Import JSON Timeline Preset',
          style: TextStyle(color: AeroSyncTheme.textMain, fontSize: 16),
        ),
        content: SizedBox(
          width: 500,
          height: 250,
          child: TextField(
            controller: controller,
            maxLines: 10,
            style: const TextStyle(
              color: AeroSyncTheme.primaryTeal,
              fontFamily: AeroSyncTheme.fontTechnical,
              fontSize: 12,
            ),
            decoration: const InputDecoration(
              hintText: 'Paste JSON timeline string here...',
              hintStyle: TextStyle(color: AeroSyncTheme.textDim),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AeroSyncTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final success = state.importPresetJson(controller.text);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Preset JSON imported successfully!'
                          : 'Invalid JSON preset format!',
                    ),
                    backgroundColor: success
                        ? AeroSyncTheme.primaryTeal
                        : AeroSyncTheme.liveRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AeroSyncTheme.primaryTeal,
              foregroundColor: AeroSyncTheme.darkBackground,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
