import 'package:flutter/material.dart';
import '../models/fan_automation_data.dart';
import '../theme/aerosync_theme.dart';

class DAWTimelinePainter extends CustomPainter {
  final double currentTime;
  final double totalDuration;
  final List<VideoClipSegment> videoClips;
  final List<FanTrackData> fanTracks;

  DAWTimelinePainter({
    required this.currentTime,
    required this.totalDuration,
    required this.videoClips,
    required this.fanTracks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double headerWidth = 140.0;
    const double rulerHeight = 32.0;
    final double trackAreaWidth = size.width - headerWidth;
    final double trackAreaHeight = size.height - rulerHeight;

    final double trackHeight = trackAreaHeight / 4.0; // 4 tracks: Video 1, Fan 1, Fan 2, Fan 3

    // 1. Background Grid & Track Dividing Lines
    final bgPaint = Paint()..color = const Color(0xFF0C1210);
    canvas.drawRect(Rect.fromLTWH(headerWidth, rulerHeight, trackAreaWidth, trackAreaHeight), bgPaint);

    final linePaint = Paint()
      ..color = AeroSyncTheme.borderColor
      ..strokeWidth = 1.0;

    // Horizontal track dividers
    for (int i = 0; i <= 4; i++) {
      final y = rulerHeight + i * trackHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Vertical time gridlines
    const double timeStep = 15.0; // Seconds per major gridline
    final int majorLines = (totalDuration / timeStep).floor();
    for (int i = 0; i <= majorLines; i++) {
      final time = i * timeStep;
      final x = headerWidth + (time / totalDuration) * trackAreaWidth;
      
      // Gridline
      canvas.drawLine(Offset(x, rulerHeight), Offset(x, size.height), linePaint);

      // JetBrains Mono Timecode label on ruler
      final mins = (time / 60).floor();
      final secs = (time % 60).floor().toString().padLeft(2, '0');
      final label = '$mins:$secs';
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: AeroSyncTheme.textMuted,
            fontSize: 10,
            fontFamily: AeroSyncTheme.fontTechnical,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 4, 8));
    }

    // 2. Track 0: Video Clips
    final videoTrackTop = rulerHeight;
    for (final clip in videoClips) {
      final clipX = headerWidth + (clip.startTime / totalDuration) * trackAreaWidth;
      final clipW = (clip.duration / totalDuration) * trackAreaWidth;
      final clipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(clipX, videoTrackTop + 6, clipW, trackHeight - 12),
        const Radius.circular(4),
      );

      final clipBgPaint = Paint()..color = AeroSyncTheme.videoClipBg;
      final clipBorderPaint = Paint()
        ..color = AeroSyncTheme.videoClipBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawRRect(clipRect, clipBgPaint);
      canvas.drawRRect(clipRect, clipBorderPaint);

      // Title Text inside clip
      final clipTextPainter = TextPainter(
        text: TextSpan(
          text: clip.title,
          style: const TextStyle(
            color: AeroSyncTheme.primaryTeal,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: AeroSyncTheme.fontTechnical,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      clipTextPainter.layout();
      clipTextPainter.paint(canvas, Offset(clipX + 8, videoTrackTop + (trackHeight - 12) / 2));
    }

    // 3. Discrete Stepped Fan Automation Curves (Off, Low, High)
    for (int tIdx = 0; tIdx < fanTracks.length; tIdx++) {
      final track = fanTracks[tIdx];
      final trackTop = rulerHeight + (tIdx + 1) * trackHeight;
      final trackBottom = trackTop + trackHeight;

      Color curveColor;
      Color fillColor;

      if (track.fanId == 'Fan 1') {
        curveColor = AeroSyncTheme.fan1Orange;
        fillColor = AeroSyncTheme.fan1OrangeFill;
      } else if (track.fanId == 'Fan 2') {
        curveColor = AeroSyncTheme.fan2Pink;
        fillColor = AeroSyncTheme.fan2PinkFill;
      } else {
        curveColor = AeroSyncTheme.fan3Blue;
        fillColor = AeroSyncTheme.fan3BlueFill;
      }

      final curvePath = Path();
      final fillPath = Path();

      if (track.keyframes.isNotEmpty) {
        fillPath.moveTo(headerWidth, trackBottom);

        for (int i = 0; i < track.keyframes.length; i++) {
          final kf = track.keyframes[i];
          final kfX = headerWidth + (kf.timeSeconds / totalDuration) * trackAreaWidth;
          final kfY = trackBottom - (kf.value * (trackHeight - 12) + 6);

          if (i == 0) {
            curvePath.moveTo(headerWidth, kfY);
            curvePath.lineTo(kfX, kfY);
            fillPath.lineTo(headerWidth, kfY);
            fillPath.lineTo(kfX, kfY);
          } else {
            final prevKf = track.keyframes[i - 1];
            final prevY = trackBottom - (prevKf.value * (trackHeight - 12) + 6);
            
            // Sharp Non-Interpolated Zero-Order Hold Step: Horizontal then Vertical!
            curvePath.lineTo(kfX, prevY);
            curvePath.lineTo(kfX, kfY);

            fillPath.lineTo(kfX, prevY);
            fillPath.lineTo(kfX, kfY);
          }

          if (i == track.keyframes.length - 1) {
            final nextTime = (kf.timeSeconds + 25.0).clamp(0.0, totalDuration);
            final endX = headerWidth + (nextTime / totalDuration) * trackAreaWidth;
            curvePath.lineTo(endX, kfY);
            fillPath.lineTo(endX, kfY);
            fillPath.lineTo(endX, trackBottom);
          }
        }
        fillPath.lineTo(headerWidth, trackBottom);
        fillPath.close();

        // Draw Fill Area
        canvas.drawPath(fillPath, Paint()..color = fillColor);

        // Draw Stepped Outline Stroke
        canvas.drawPath(
          curvePath,
          Paint()
            ..color = curveColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );

        // Draw Keyframe Node Points
        for (final kf in track.keyframes) {
          final kfX = headerWidth + (kf.timeSeconds / totalDuration) * trackAreaWidth;
          final kfY = trackBottom - (kf.value * (trackHeight - 12) + 6);

          canvas.drawCircle(Offset(kfX, kfY), 4.5, Paint()..color = curveColor);
          canvas.drawCircle(
            Offset(kfX, kfY),
            4.5,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }

    // 4. Playhead Needle & Cap
    final playheadX = headerWidth + (currentTime / totalDuration) * trackAreaWidth;

    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      Paint()
        ..color = AeroSyncTheme.primaryTeal
        ..strokeWidth = 2.0,
    );

    // Playhead Cap
    final capPath = Path();
    capPath.moveTo(playheadX - 6, 0);
    capPath.lineTo(playheadX + 6, 0);
    capPath.lineTo(playheadX + 6, 12);
    capPath.lineTo(playheadX, 18);
    capPath.lineTo(playheadX - 6, 12);
    capPath.close();

    canvas.drawPath(capPath, Paint()..color = AeroSyncTheme.primaryTeal);
  }

  @override
  bool shouldRepaint(covariant DAWTimelinePainter oldDelegate) {
    return oldDelegate.currentTime != currentTime || oldDelegate.totalDuration != totalDuration;
  }
}
