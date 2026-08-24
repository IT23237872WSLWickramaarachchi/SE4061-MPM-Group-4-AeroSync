import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aerosync_state_provider.dart';
import '../theme/aerosync_theme.dart';
import 'daw_timeline_painter.dart';

class DAWTimelineWidget extends StatelessWidget {
  const DAWTimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AeroSyncStateProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AeroSyncTheme.panelBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AeroSyncTheme.borderColor, width: 1),
      ),
      child: Column(
        children: [
          // 1. DAW Timeline Toolbar
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF10151C),
              border: Border(
                bottom: BorderSide(color: AeroSyncTheme.borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 124,
                  child: Text(
                    'Tracks',
                    style: TextStyle(
                      color: AeroSyncTheme.textMain,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildToolIcon(Icons.near_me_outlined, 'Select', isSelected: true),
                const SizedBox(width: 8),
                _buildToolIcon(Icons.content_cut, 'Split / Cut'),
                const SizedBox(width: 8),
                _buildToolIcon(Icons.zoom_in, 'Zoom In'),
                const SizedBox(width: 8),
                _buildToolIcon(Icons.zoom_out, 'Zoom Out'),
                const SizedBox(width: 8),
                _buildToolIcon(Icons.push_pin_outlined, 'Magnet / Snap'),
              ],
            ),
          ),
          // 2. Timeline Tracks Body (Headers + CustomPainter)
          Expanded(
            child: Stack(
              children: [
                Row(
                  children: [
                    // Track Headers Column (Width 140px)
                    Container(
                      width: 140,
                      decoration: const BoxDecoration(
                        color: Color(0xFF131922),
                        border: Border(
                          right: BorderSide(color: AeroSyncTheme.borderColor, width: 1),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 32), // Height of top ruler
                          Expanded(
                            child: Column(
                              children: [
                                _buildTrackHeader('Video 1', AeroSyncTheme.primaryTeal, Icons.videocam_outlined),
                                _buildTrackHeader('Fan 1', AeroSyncTheme.fan1Orange, Icons.cyclone),
                                _buildTrackHeader('Fan 2', AeroSyncTheme.fan2Pink, Icons.cyclone),
                                _buildTrackHeader('Fan 3', AeroSyncTheme.fan3Blue, Icons.cyclone),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Timeline Interactive Canvas
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onTapDown: (details) => _handleScrub(details.localPosition, constraints.maxWidth, state),
                            onPanUpdate: (details) => _handleScrub(details.localPosition, constraints.maxWidth, state),
                            child: CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: DAWTimelinePainter(
                                currentTime: state.currentTime,
                                totalDuration: state.totalDuration,
                                videoClips: state.videoClips,
                                fanTracks: state.fanTracks,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // Floating Sync Play Action Button (Bottom Right matching Screenshot 1)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () => state.togglePlayPause(),
                    backgroundColor: AeroSyncTheme.primaryTeal,
                    foregroundColor: AeroSyncTheme.darkBackground,
                    elevation: 4,
                    icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(
                      state.isPlaying ? 'Pause' : 'Sync Play',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolIcon(IconData icon, String tooltip, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? AeroSyncTheme.cardBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        size: 16,
        color: isSelected ? AeroSyncTheme.primaryTeal : AeroSyncTheme.textMuted,
      ),
    );
  }

  Widget _buildTrackHeader(String title, Color accentColor, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AeroSyncTheme.borderColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleScrub(Offset localPos, double trackWidth, AeroSyncStateProvider state) {
    // Note: The custom painter starts at headerWidth 140 within total width,
    // but in LayoutBuilder here we are in the canvas area directly.
    final fraction = (localPos.dx / trackWidth).clamp(0.0, 1.0);
    final targetTime = fraction * state.totalDuration;
    state.seekTo(targetTime);
  }
}
