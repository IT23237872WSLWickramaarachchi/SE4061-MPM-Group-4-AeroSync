import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aerosync_state_provider.dart';
import '../theme/aerosync_theme.dart';

class PlaybackStatusPanel extends StatelessWidget {
  const PlaybackStatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AeroSyncStateProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AeroSyncTheme.panelBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AeroSyncTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Playback Status',
            style: TextStyle(
              color: AeroSyncTheme.textMain,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Timecodes Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ELAPSED',
                    style: TextStyle(
                      color: AeroSyncTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.elapsedFormatted,
                    style: const TextStyle(
                      color: AeroSyncTheme.primaryTeal,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Consolas',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'REMAINING',
                    style: TextStyle(
                      color: AeroSyncTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.remainingFormatted,
                    style: const TextStyle(
                      color: AeroSyncTheme.liveRed,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Consolas',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'FAN TELEMETRY',
            style: TextStyle(
              color: AeroSyncTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          // Fan 1 Telemetry Row
          _buildFanSpeedRow(
            context,
            label: 'Fan 1',
            accentColor: AeroSyncTheme.fan1Orange,
            icon: Icons.cyclone,
            activeLevel: state.f1SpeedLevel,
            onSelectLevel: (lvl) => state.setFanSpeedLevel(1, lvl),
          ),
          const SizedBox(height: 10),
          // Fan 2 Telemetry Row
          _buildFanSpeedRow(
            context,
            label: 'Fan 2',
            accentColor: AeroSyncTheme.fan2Pink,
            icon: Icons.cyclone,
            activeLevel: state.f2SpeedLevel,
            onSelectLevel: (lvl) => state.setFanSpeedLevel(2, lvl),
          ),
          const SizedBox(height: 10),
          // Fan 3 Telemetry Row
          _buildFanSpeedRow(
            context,
            label: 'Fan 3',
            accentColor: AeroSyncTheme.fan3Blue,
            icon: Icons.cyclone,
            activeLevel: state.f3SpeedLevel,
            onSelectLevel: (lvl) => state.setFanSpeedLevel(3, lvl),
          ),
          const Spacer(),
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => state.togglePlayPause(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AeroSyncTheme.primaryTeal,
                foregroundColor: AeroSyncTheme.darkBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
              ),
              icon: Icon(
                state.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 20,
              ),
              label: Text(
                state.isPlaying ? 'PAUSE SEQUENCE' : 'PLAY SEQUENCE',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFanSpeedRow(
    BuildContext context, {
    required String label,
    required Color accentColor,
    required IconData icon,
    required int activeLevel,
    required ValueChanged<int> onSelectLevel,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              color: AeroSyncTheme.textMain,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        _buildSpeedBtn('Off', 0, activeLevel, accentColor, onSelectLevel),
        const SizedBox(width: 4),
        _buildSpeedBtn('Speed 1', 1, activeLevel, accentColor, onSelectLevel),
        const SizedBox(width: 4),
        _buildSpeedBtn('Speed 2', 2, activeLevel, accentColor, onSelectLevel),
      ],
    );
  }

  Widget _buildSpeedBtn(
    String text,
    int level,
    int activeLevel,
    Color activeColor,
    ValueChanged<int> onSelectLevel,
  ) {
    final bool isActive = level == activeLevel;

    return InkWell(
      onTap: () => onSelectLevel(level),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor : AeroSyncTheme.cardBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? activeColor : AeroSyncTheme.borderColor,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? AeroSyncTheme.darkBackground : AeroSyncTheme.textMuted,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
