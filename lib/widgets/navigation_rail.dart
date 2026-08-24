import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aerosync_state_provider.dart';
import '../theme/aerosync_theme.dart';

class AeroSyncNavRail extends StatelessWidget {
  const AeroSyncNavRail({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AeroSyncStateProvider>();
    final activeIdx = state.activeRailIndex;

    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: AeroSyncTheme.darkBackground,
        border: Border(
          right: BorderSide(color: AeroSyncTheme.borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Tab 0: Timeline / Main Editor
          _buildNavItem(
            context,
            index: 0,
            icon: Icons.show_chart,
            label: 'Timeline',
            isActive: activeIdx == 0,
          ),
          const SizedBox(height: 12),
          // Tab 1: Library
          _buildNavItem(
            context,
            index: 1,
            icon: Icons.folder_outlined,
            label: 'Library',
            isActive: activeIdx == 1,
          ),
          const SizedBox(height: 12),
          // Tab 2: Fans Config
          _buildNavItem(
            context,
            index: 2,
            icon: Icons.cyclone_outlined,
            label: 'Fans',
            isActive: activeIdx == 2,
          ),
          const Spacer(),
          // Tab 3: Export (Bottom)
          _buildNavItem(
            context,
            index: 3,
            icon: Icons.upload_outlined,
            label: 'Export',
            isActive: activeIdx == 3,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final state = context.read<AeroSyncStateProvider>();

    return InkWell(
      onTap: () => state.setActiveRailIndex(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? AeroSyncTheme.primaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? AeroSyncTheme.darkBackground : AeroSyncTheme.textMuted,
              ),
              if (isActive)
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AeroSyncTheme.darkBackground,
                    height: 1.1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
