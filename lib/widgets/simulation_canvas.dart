import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../physics/mpm_simulation_engine.dart';
import '../providers/aerosync_state_provider.dart';
import '../theme/aerosync_theme.dart';

class SimulationPreviewCanvas extends StatefulWidget {
  final String cameraLabel;
  final bool showLiveBadge;

  const SimulationPreviewCanvas({
    super.key,
    this.cameraLabel = 'VR_PREVIEW_CANVAS',
    this.showLiveBadge = false,
  });

  @override
  State<SimulationPreviewCanvas> createState() => _SimulationPreviewCanvasState();
}

class _SimulationPreviewCanvasState extends State<SimulationPreviewCanvas> {
  bool _isDraggingOver = false;

  void _showUploadVideoDialog(BuildContext context, AeroSyncStateProvider state) {
    final controller = TextEditingController(text: 'VR_CUSTOM_SCENE_01.MP4');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AeroSyncTheme.panelBackground,
        title: const Row(
          children: [
            Icon(Icons.video_call_outlined, color: AeroSyncTheme.primaryTeal),
            SizedBox(width: 8),
            Text('Upload & Attach Video File', style: TextStyle(color: AeroSyncTheme.textMain, fontSize: 16, fontFamily: AeroSyncTheme.fontHeadline)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select or enter a video file path/name (.mp4, .mov) to stick to the video player and sync with the DAW timeline:',
              style: TextStyle(color: AeroSyncTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF0F141B),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AeroSyncTheme.borderColor),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AeroSyncTheme.primaryTeal, fontFamily: AeroSyncTheme.fontTechnical, fontSize: 13, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.movie_outlined, size: 16, color: AeroSyncTheme.primaryTeal),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Presets / Sample VR Videos:', style: TextStyle(color: AeroSyncTheme.textDim, fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildVideoChip('VR_STORM_RUN.MP4', controller),
                _buildVideoChip('VR_SCENE_INTRO.MP4', controller),
                _buildVideoChip('DESERT_FLIGHT_VR.MP4', controller),
                _buildVideoChip('TUNNEL_TEST_04.MP4', controller),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AeroSyncTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                state.uploadNewVideo(controller.text.trim());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Video "${controller.text.trim()}" loaded and stuck to video player!'),
                    backgroundColor: AeroSyncTheme.primaryTeal,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AeroSyncTheme.primaryTeal, foregroundColor: AeroSyncTheme.darkBackground),
            icon: const Icon(Icons.file_upload, size: 16),
            label: const Text('Load & Stick Video', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoChip(String text, TextEditingController controller) {
    return ActionChip(
      backgroundColor: AeroSyncTheme.cardBackground,
      side: const BorderSide(color: AeroSyncTheme.borderColor),
      label: Text(text, style: const TextStyle(color: AeroSyncTheme.primaryTeal, fontSize: 10, fontFamily: AeroSyncTheme.fontTechnical)),
      onPressed: () => controller.text = text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AeroSyncStateProvider>();

    return DropTarget(
      onDragEntered: (details) {
        setState(() => _isDraggingOver = true);
      },
      onDragExited: (details) {
        setState(() => _isDraggingOver = false);
      },
      onDragDone: (details) {
        setState(() => _isDraggingOver = false);
        if (details.files.isNotEmpty) {
          final file = details.files.first;
          final path = file.path;
          state.uploadNewVideo(path);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dropped video "${file.name}" loaded and timeline duration synced!'),
              backgroundColor: AeroSyncTheme.primaryTeal,
            ),
          );
        }
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _isDraggingOver ? AeroSyncTheme.primaryTeal : AeroSyncTheme.borderColor,
            width: _isDraggingOver ? 2.5 : 1.0,
          ),
        ),
        child: Stack(
          children: [
            // Layer 1: MediaKit Native Hardware Accelerated Video Player & Viewport
            Positioned.fill(
              child: SimpleVideoPlayerViewport(
                videoName: state.activeVideoName,
                videoPath: state.activeVideoPath,
                currentTime: state.currentTime,
                isPlaying: state.isPlaying,
                isDraggingOver: _isDraggingOver,
                onUploadPressed: () => _showUploadVideoDialog(context, state),
                onDurationResolved: (durationSeconds) {
                  state.setTotalDuration(durationSeconds);
                },
              ),
            ),

            // Layer 2: Real-Time Physical Wind Particle Streamlines Overlay
            if (state.showPhysicsOverlay)
              Positioned.fill(
                child: CustomPaint(
                  painter: MPMSimulationPainter(engine: state.physicsEngine),
                ),
              ),

            // Layer 3: Top Control Bar (Video Title Badge, Upload Button, Live Indicator, Timecode)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Active Video Title Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AeroSyncTheme.panelBackground.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AeroSyncTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.movie_outlined, size: 14, color: AeroSyncTheme.primaryTeal),
                            const SizedBox(width: 8),
                            Text(
                              state.activeVideoName,
                              style: const TextStyle(
                                color: AeroSyncTheme.textMain,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: AeroSyncTheme.fontTechnical,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Upload / Pick Video File Button
                      ElevatedButton.icon(
                        onPressed: () => _showUploadVideoDialog(context, state),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AeroSyncTheme.panelBackground.withValues(alpha: 0.90),
                          foregroundColor: AeroSyncTheme.primaryTeal,
                          side: const BorderSide(color: AeroSyncTheme.primaryTeal),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.file_upload_outlined, size: 14),
                        label: const Text(
                          'Upload Video',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: AeroSyncTheme.fontHeadline,
                          ),
                        ),
                      ),
                      if (widget.showLiveBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AeroSyncTheme.liveRed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AeroSyncTheme.liveRed, width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, size: 8, color: AeroSyncTheme.liveRed),
                              SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: AeroSyncTheme.liveRed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AeroSyncTheme.fontTechnical,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  // JetBrains Mono Timecode
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AeroSyncTheme.panelBackground.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AeroSyncTheme.borderColor),
                    ),
                    child: Text(
                      state.elapsedFormatted,
                      style: const TextStyle(
                        color: AeroSyncTheme.primaryTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: AeroSyncTheme.fontTechnical,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Layer 4: Bottom Telemetry & Physics Overlay Controls HUD
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Air Velocity Telemetry
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AeroSyncTheme.panelBackground.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AeroSyncTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed, size: 14, color: AeroSyncTheme.primaryTeal),
                        const SizedBox(width: 6),
                        Text(
                          'AIR VEL: ${(state.physicsEngine.averageVelocity * 2.4).toStringAsFixed(1)} m/s',
                          style: const TextStyle(
                            color: AeroSyncTheme.textMain,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            fontFamily: AeroSyncTheme.fontTechnical,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.hub_outlined, size: 14, color: AeroSyncTheme.fan2Pink),
                        const SizedBox(width: 6),
                        Text(
                          'TURBULENCE: ${(state.physicsEngine.turbulenceIndex).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AeroSyncTheme.textMain,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            fontFamily: AeroSyncTheme.fontTechnical,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Physics Overlay Toggle Button
                  InkWell(
                    onTap: () => state.togglePhysicsOverlay(),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: state.showPhysicsOverlay ? AeroSyncTheme.primaryTeal.withValues(alpha: 0.2) : AeroSyncTheme.panelBackground.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: state.showPhysicsOverlay ? AeroSyncTheme.primaryTeal : AeroSyncTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.grain, size: 14, color: state.showPhysicsOverlay ? AeroSyncTheme.primaryTeal : AeroSyncTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'Physics Overlay',
                            style: TextStyle(
                              color: state.showPhysicsOverlay ? AeroSyncTheme.primaryTeal : AeroSyncTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: AeroSyncTheme.fontHeadline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple Video Player Viewport: Uses MediaKit for real video decoding on Windows
class SimpleVideoPlayerViewport extends StatefulWidget {
  final String videoName;
  final String videoPath;
  final double currentTime;
  final bool isPlaying;
  final bool isDraggingOver;
  final VoidCallback onUploadPressed;
  final ValueChanged<double> onDurationResolved;

  const SimpleVideoPlayerViewport({
    super.key,
    required this.videoName,
    required this.videoPath,
    required this.currentTime,
    required this.isPlaying,
    required this.isDraggingOver,
    required this.onUploadPressed,
    required this.onDurationResolved,
  });

  @override
  State<SimpleVideoPlayerViewport> createState() => _SimpleVideoPlayerViewportState();
}

class _SimpleVideoPlayerViewportState extends State<SimpleVideoPlayerViewport> {
  Player? _player;
  VideoController? _controller;
  bool _hasOpened = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    try {
      final player = Player();
      final controller = VideoController(player);
      _player = player;
      _controller = controller;

      player.stream.duration.listen((dur) {
        if (dur != Duration.zero) {
          final sec = dur.inMilliseconds / 1000.0;
          if (sec > 0) {
            widget.onDurationResolved(sec);
          }
        }
      });

      if (widget.videoPath.isNotEmpty && File(widget.videoPath).existsSync()) {
        player.open(Media(widget.videoPath));
        setState(() => _hasOpened = true);
      }
    } catch (e) {
      debugPrint('MediaKit init safe fallback: $e');
    }
  }

  @override
  void didUpdateWidget(covariant SimpleVideoPlayerViewport oldWidget) {
    super.didUpdateWidget(oldWidget);

    try {
      final player = _player;
      if (player != null) {
        if (oldWidget.videoPath != widget.videoPath && widget.videoPath.isNotEmpty && File(widget.videoPath).existsSync()) {
          player.open(Media(widget.videoPath));
          setState(() => _hasOpened = true);
        }

        if (widget.isPlaying != oldWidget.isPlaying) {
          if (widget.isPlaying) {
            player.play();
          } else {
            player.pause();
          }
        }

        // Sync timeline playhead position to player
        final currentMs = player.state.position.inMilliseconds;
        final stateMs = (widget.currentTime * 1000).round();
        if ((currentMs - stateMs).abs() > 300) {
          player.seek(Duration(milliseconds: stateMs));
        }
      }
    } catch (e) {
      debugPrint('MediaKit update safe fallback: $e');
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF090D12),
      child: Center(
        child: widget.isDraggingOver
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AeroSyncTheme.primaryTeal.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AeroSyncTheme.primaryTeal, width: 2),
                    ),
                    child: const Icon(Icons.file_download, size: 48, color: AeroSyncTheme.primaryTeal),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DROP VIDEO FILE HERE TO ATTACH',
                    style: TextStyle(
                      color: AeroSyncTheme.primaryTeal,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontFamily: AeroSyncTheme.fontTechnical,
                    ),
                  ),
                ],
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  // Layer A: Hardware Accelerated Native Video Player Viewport (Preserved 16:9 Scale)
                  if (_hasOpened && _controller != null)
                    Positioned.fill(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Video(
                            controller: _controller!,
                            fit: BoxFit.cover,
                            controls: NoVideoControls,
                          ),
                        ),
                      ),
                    )
                  else
                    CustomPaint(
                      size: Size.infinite,
                      painter: SimpleVideoFramePainter(
                        videoName: widget.videoName,
                        currentTime: widget.currentTime,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Simple Clean Video Frame Painter Fallback
class SimpleVideoFramePainter extends CustomPainter {
  final String videoName;
  final double currentTime;

  SimpleVideoFramePainter({
    required this.videoName,
    required this.currentTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Clean Dark Video Surface Gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF0B1017),
          Color(0xFF0F1722),
          Color(0xFF0A0E15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRect(rect, bgPaint);

    // Subtle Horizontal Video Scanlines
    final scanlinePaint = Paint()
      ..color = const Color(0xFF131D2A).withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (double y = 0; y <= size.height; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SimpleVideoFramePainter oldDelegate) {
    return oldDelegate.currentTime != currentTime || oldDelegate.videoName != videoName;
  }
}

class MPMSimulationPainter extends CustomPainter {
  final MPMWindSimulationEngine engine;

  MPMSimulationPainter({required this.engine});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / MPMWindSimulationEngine.gridWidth;
    final scaleY = size.height / MPMWindSimulationEngine.gridHeight;

    // Draw Dark Tunnel Gridlines
    final gridPaint = Paint()
      ..color = const Color(0xFF141D29).withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int x = 0; x <= MPMWindSimulationEngine.gridWidth; x += 4) {
      canvas.drawLine(Offset(x * scaleX, 0), Offset(x * scaleX, size.height), gridPaint);
    }
    for (int y = 0; y <= MPMWindSimulationEngine.gridHeight; y += 4) {
      canvas.drawLine(Offset(0, y * scaleY), Offset(size.width, y * scaleY), gridPaint);
    }

    // Draw Wind Tunnel Car Silhouette Obstacle
    final obstaclePaint = Paint()
      ..color = const Color(0xFF1A2636).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final obstacleBorderPaint = Paint()
      ..color = AeroSyncTheme.primaryTeal.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final carPath = Path();
    final carLeft = 24.0 * scaleX;
    final carTop = 11.0 * scaleY;
    final carRight = 35.0 * scaleX;
    final carBottom = 18.0 * scaleY;

    carPath.moveTo(carLeft, carBottom);
    carPath.lineTo(carLeft + 2 * scaleX, carBottom - 2 * scaleY);
    carPath.quadraticBezierTo(carLeft + 4 * scaleX, carTop + 1 * scaleY, carLeft + 7 * scaleX, carTop);
    carPath.lineTo(carRight - 3 * scaleX, carTop + 1 * scaleY);
    carPath.quadraticBezierTo(carRight - 1 * scaleX, carTop + 4 * scaleY, carRight, carBottom);
    carPath.close();

    canvas.drawPath(carPath, obstaclePaint);
    canvas.drawPath(carPath, obstacleBorderPaint);

    // Draw Fan Nozzle Thrust Indicators on Left Edge
    _drawNozzle(canvas, scaleX, scaleY, 1, 9, AeroSyncTheme.fan1Orange, 'F1');
    _drawNozzle(canvas, scaleX, scaleY, 10, 17, AeroSyncTheme.fan2Pink, 'F2');
    _drawNozzle(canvas, scaleX, scaleY, 18, 26, AeroSyncTheme.fan3Blue, 'F3');

    // Draw MPM Air Particles & Velocity Tails over Video
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final tailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final p in engine.particles) {
      final px = p.position.x * scaleX;
      final py = p.position.y * scaleY;
      final vx = p.velocity.x * scaleX * 0.08;
      final vy = p.velocity.y * scaleY * 0.08;

      particlePaint.color = p.color;
      tailPaint.color = p.color.withValues(alpha: 0.45);
      tailPaint.strokeWidth = 1.5;

      // Draw particle velocity trail line
      canvas.drawLine(Offset(px, py), Offset(px - vx, py - vy), tailPaint);

      // Draw particle glowing point
      canvas.drawCircle(Offset(px, py), 2.2, particlePaint);
    }
  }

  void _drawNozzle(Canvas canvas, double sx, double sy, int yStart, int yEnd, Color color, String label) {
    final rect = Rect.fromLTRB(0, yStart * sy, 1.5 * sx, yEnd * sy);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant MPMSimulationPainter oldDelegate) => true;
}
