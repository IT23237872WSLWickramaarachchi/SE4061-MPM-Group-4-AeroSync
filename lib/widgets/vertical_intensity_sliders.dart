import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aerosync_state_provider.dart';
import '../theme/aerosync_theme.dart';

class VerticalIntensityConfigPanel extends StatelessWidget {
  const VerticalIntensityConfigPanel({super.key});

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
          // Header: INTENSITY CONFIG + Settings Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'INTENSITY CONFIG',
                  style: TextStyle(
                    color: AeroSyncTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    fontFamily: AeroSyncTheme.fontHeadline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined, size: 16, color: AeroSyncTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sliders Row
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildVerticalSlider(
                  context,
                  label: 'F1',
                  color: AeroSyncTheme.fan1Orange,
                  value: state.f1Intensity,
                  onChanged: (val) => state.setManualFanIntensity(1, val),
                ),
                _buildVerticalSlider(
                  context,
                  label: 'F2',
                  color: AeroSyncTheme.fan2Pink,
                  value: state.f2Intensity,
                  onChanged: (val) => state.setManualFanIntensity(2, val),
                ),
                _buildVerticalSlider(
                  context,
                  label: 'F3',
                  color: AeroSyncTheme.fan3Blue,
                  value: state.f3Intensity,
                  onChanged: (val) => state.setManualFanIntensity(3, val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Save Intensity Settings To Timeline Action Button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () {
                state.saveCurrentSlidersToTimeline();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Saved F1, F2, F3 keyframes at ${state.elapsedFormatted} onto timeline!'),
                    backgroundColor: AeroSyncTheme.primaryTeal,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AeroSyncTheme.primaryTeal,
                foregroundColor: AeroSyncTheme.darkBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
              ),
              icon: const Icon(Icons.save_as_outlined, size: 16),
              label: const Text(
                'SAVE TO TIMELINE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  fontFamily: AeroSyncTheme.fontHeadline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalSlider(
    BuildContext context, {
    required String label,
    required Color color,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: AeroSyncTheme.fontTechnical,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3, // Vertical orientation
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 14,
                activeTrackColor: color,
                inactiveTrackColor: const Color(0xFF10151D),
                thumbColor: Colors.transparent,
                overlayColor: color.withValues(alpha: 0.2),
                thumbShape: _CustomCircleThumbShape(thumbRadius: 10, borderColor: color),
                trackShape: _CustomSliderTrackShape(accentColor: color, borderColor: AeroSyncTheme.borderColor),
              ),
              child: Slider(
                value: value.clamp(0.0, 1.0),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(value * 100).round()}%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: AeroSyncTheme.fontTechnical,
          ),
        ),
      ],
    );
  }
}

class _CustomSliderTrackShape extends RoundedRectSliderTrackShape {
  final Color accentColor;
  final Color borderColor;
  _CustomSliderTrackShape({required this.accentColor, required this.borderColor});

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final Canvas canvas = context.canvas;
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      offset: offset,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Track Background
    final Paint bgPaint = Paint()
      ..color = const Color(0xFF10151D)
      ..style = PaintingStyle.fill;

    // Active Track Fill (From left up to thumbCenter)
    final Paint activePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final RRect bgRRect = RRect.fromRectAndRadius(trackRect, const Radius.circular(8));
    canvas.drawRRect(bgRRect, bgPaint);

    final double activeWidth = (thumbCenter.dx - trackRect.left).clamp(0.0, trackRect.width);
    if (activeWidth > 0) {
      final Rect activeRect = Rect.fromLTWH(trackRect.left, trackRect.top, activeWidth, trackRect.height);
      final RRect activeRRect = RRect.fromRectAndRadius(activeRect, const Radius.circular(8));
      canvas.drawRRect(activeRRect, activePaint);
    }

    canvas.drawRRect(bgRRect, borderPaint);

    // Tick marks inside track
    final Paint tickPaint = Paint()
      ..color = const Color(0xFF2C3848)
      ..strokeWidth = 1.0;

    for (double i = 0.25; i < 1.0; i += 0.25) {
      final tickX = trackRect.left + trackRect.width * i;
      canvas.drawLine(
        Offset(tickX, trackRect.top + 3),
        Offset(tickX, trackRect.bottom - 3),
        tickPaint,
      );
    }
  }
}

class _CustomCircleThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final Color borderColor;

  const _CustomCircleThumbShape({
    required this.thumbRadius,
    required this.borderColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final Paint bgPaint = Paint()
      ..color = const Color(0xFF161D1B)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, thumbRadius, bgPaint);
    canvas.drawCircle(center, thumbRadius, borderPaint);
  }
}
