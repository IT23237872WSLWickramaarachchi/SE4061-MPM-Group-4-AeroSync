import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aerosync_state_provider.dart';
import '../theme/aerosync_theme.dart';

class AeroSyncTopBar extends StatelessWidget {
  const AeroSyncTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AeroSyncStateProvider>();

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AeroSyncTheme.darkBackground,
        border: Border(
          bottom: BorderSide(color: AeroSyncTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // AeroSync Logo & Title
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AeroSyncTheme.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cyclone,
                  size: 20,
                  color: AeroSyncTheme.darkBackground,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AeroSync',
                style: TextStyle(
                  color: AeroSyncTheme.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Action Buttons: Undo, Redo, Load Preset, Save Preset
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.undo, size: 20, color: AeroSyncTheme.textMuted),
                tooltip: 'Undo',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.redo, size: 20, color: AeroSyncTheme.textMuted),
                tooltip: 'Redo',
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  state.setActiveRailIndex(1); // Switch to Preset Library
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AeroSyncTheme.textMain,
                  side: const BorderSide(color: AeroSyncTheme.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  backgroundColor: AeroSyncTheme.panelBackground,
                ),
                child: const Text('Load Preset', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  state.openSaveModal();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AeroSyncTheme.primaryTeal,
                  foregroundColor: AeroSyncTheme.darkBackground,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
                child: const Text('Save Preset', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
