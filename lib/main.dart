import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'providers/aerosync_state_provider.dart';
import 'theme/aerosync_theme.dart';
import 'widgets/daw_timeline.dart';
import 'widgets/footer.dart';
import 'widgets/hardware_settings_panel.dart';
import 'widgets/navigation_rail.dart';
import 'widgets/playback_status_panel.dart';
import 'widgets/preset_library_view.dart';
import 'widgets/save_preset_modal.dart';
import 'widgets/simulation_canvas.dart';
import 'widgets/top_bar.dart';
import 'widgets/vertical_intensity_sliders.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    MediaKit.ensureInitialized();
  } catch (e) {
    debugPrint('MediaKit init info: $e');
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => AeroSyncStateProvider(),
      child: const AeroSyncApp(),
    ),
  );
}

class AeroSyncApp extends StatelessWidget {
  const AeroSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroSync Control Suite - VR Wind Controller',
      debugShowCheckedModeBanner: false,
      theme: AeroSyncTheme.themeData,
      home: const MainShellView(),
    );
  }
}

class MainShellView extends StatelessWidget {
  const MainShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AeroSyncStateProvider>();

    return Scaffold(
      backgroundColor: AeroSyncTheme.darkBackground,
      body: Stack(
        children: [
          Column(
            children: [
              // Top Bar with Global Actions
              const AeroSyncTopBar(),
              // Rail + Canvas Main Workspace Layout
              Expanded(
                child: Row(
                  children: [
                    // Left Navigation Rail
                    const AeroSyncNavRail(),
                    // Canvas Expanded Content Workspace
                    Expanded(
                      child: _buildBodyContent(context, state.activeRailIndex),
                    ),
                  ],
                ),
              ),
              // Footer Status Bar
              const AeroSyncFooter(),
            ],
          ),
          // Save Preset Modal Overlay
          const SavePresetModal(),
        ],
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context, int railIndex) {
    switch (railIndex) {
      case 1:
        return const PresetLibraryView();
      case 2:
        return const HardwareSettingsPanel();
      case 3:
        return const Center(
          child: Text(
            'Export Module & VR Hardware Package Builder',
            style: TextStyle(
              color: AeroSyncTheme.textMuted,
              fontSize: 16,
              fontFamily: AeroSyncTheme.fontHeadline,
            ),
          ),
        );
      case 0:
      default:
        return const MainEditorLayout();
    }
  }
}

class MainEditorLayout extends StatelessWidget {
  final bool showPlaybackStatusPanel;

  const MainEditorLayout({super.key, this.showPlaybackStatusPanel = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Top Split Canvas Area: Real-Time Preview Canvas + Fan Intensity Sliders / Telemetry
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preview Canvas (CAM_01_FRONT / PREVIEW)
                Expanded(
                  flex: 7,
                  child: SimulationPreviewCanvas(
                    cameraLabel: showPlaybackStatusPanel ? 'CAM_01_FRONT' : 'VR_PREVIEW_CANVAS',
                    showLiveBadge: showPlaybackStatusPanel,
                  ),
                ),
                const SizedBox(width: 12),
                // Right Panel: Vertical Sliders (F1-F3) or Playback Telemetry Status
                Expanded(
                  flex: 4,
                  child: showPlaybackStatusPanel
                      ? const PlaybackStatusPanel()
                      : const VerticalIntensityConfigPanel(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Bottom Area: DAW-Style Stepped Fan Automation Timeline
          const Expanded(
            flex: 4,
            child: DAWTimelineWidget(),
          ),
        ],
      ),
    );
  }
}
