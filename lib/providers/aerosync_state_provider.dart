import 'dart:async';
import 'package:flutter/material.dart';

import '../models/fan_automation_data.dart';
import '../models/preset_model.dart';
import '../physics/mpm_simulation_engine.dart';
import '../services/hardware_serial_dispatcher.dart';
import '../services/unity_network_listener.dart';

class AeroSyncStateProvider extends ChangeNotifier {
  // Active Navigation Rail Tab (0: Timeline, 1: Library, 2: Fans & Hardware, 3: Export)
  int _activeRailIndex = 0;
  int get activeRailIndex => _activeRailIndex;

  void setActiveRailIndex(int index) {
    _activeRailIndex = index;
    notifyListeners();
  }

  // Master Source-of-Truth Playback Control
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  double _currentTime = 0.0; // Playhead timecode in seconds
  double get currentTime => _currentTime;
  
  double _totalDuration = 120.0; // Dynamic timeline duration (matches loaded video length!)
  double get totalDuration => _totalDuration;

  void setTotalDuration(double seconds) {
    if (seconds > 0.0 && (_totalDuration - seconds).abs() > 0.1) {
      _totalDuration = seconds;
      notifyListeners();
    }
  }

  Timer? _playbackTimer;

  // Real-time MPM Wind Physics Simulation Engine
  final MPMWindSimulationEngine physicsEngine = MPMWindSimulationEngine();

  // Unity WiFi UDP Listener Service
  late UnityNetworkListener unityListener;
  bool isUnityTriggerReceived = false;

  // ESP-32 / ESP-01 Serial UART Relay Hardware Dispatcher Service
  final HardwareSerialDispatcher hardwareDispatcher = HardwareSerialDispatcher();

  void setComPort(String newPort) {
    hardwareDispatcher.comPort = newPort;
    notifyListeners();
  }

  // Manual Slider Override Mode
  bool _isManualSliderMode = true;
  bool get isManualSliderMode => _isManualSliderMode;

  // Manual Raw Fan Intensities (Continuous 0.0 to 1.0)
  double _manualF1 = 0.85;
  double _manualF2 = 0.50;
  double _manualF3 = 0.20;

  // Evaluated Intensities: Continuous values (0.0 to 1.0) passed directly to MPM Physics Engine!
  double get f1Intensity => _isManualSliderMode ? _manualF1 : _evaluateFanTrackState('Fan 1').intensity;
  double get f2Intensity => _isManualSliderMode ? _manualF2 : _evaluateFanTrackState('Fan 2').intensity;
  double get f3Intensity => _isManualSliderMode ? _manualF3 : _evaluateFanTrackState('Fan 3').intensity;

  // Derived Discrete States for ESP-32 Relay Dispatch (Off / Low / High)
  FanState get f1State => FanState.fromIntensity(f1Intensity);
  FanState get f2State => FanState.fromIntensity(f2Intensity);
  FanState get f3State => FanState.fromIntensity(f3Intensity);

  int get f1SpeedLevel => f1State.levelCode;
  int get f2SpeedLevel => f2State.levelCode;
  int get f3SpeedLevel => f3State.levelCode;

  void setManualFanIntensity(int fanNumber, double value, {bool syncToTimeline = true}) {
    _isManualSliderMode = true;
    final clamped = value.clamp(0.0, 1.0);
    if (fanNumber == 1) _manualF1 = clamped;
    if (fanNumber == 2) _manualF2 = clamped;
    if (fanNumber == 3) _manualF3 = clamped;

    // Automatically update the timeline track keyframe at active playhead time!
    if (syncToTimeline) {
      final fanId = 'Fan $fanNumber';
      final newState = FanState.fromIntensity(clamped);
      addKeyframe(fanId, _currentTime, newState);
    }

    hardwareDispatcher.dispatchStates(
      f1: f1State,
      f2: f2State,
      f3: f3State,
      forceDispatch: true,
    );
    notifyListeners();
  }

  void setFanState(int fanNumber, FanState state) {
    setManualFanIntensity(fanNumber, state.intensity);
  }

  void setFanSpeedLevel(int fanNumber, int level) {
    final state = level == 0 ? FanState.off : (level == 1 ? FanState.low : FanState.high);
    setFanState(fanNumber, state);
  }

  /// Explicitly save current F1, F2, F3 slider intensities as keyframes on timeline tracks at current playhead time
  void saveCurrentSlidersToTimeline() {
    _isManualSliderMode = false; // Lock into timeline track mode!

    addKeyframe('Fan 1', _currentTime, FanState.fromIntensity(_manualF1));
    addKeyframe('Fan 2', _currentTime, FanState.fromIntensity(_manualF2));
    addKeyframe('Fan 3', _currentTime, FanState.fromIntensity(_manualF3));

    hardwareDispatcher.dispatchStates(
      f1: f1State,
      f2: f2State,
      f3: f3State,
      forceDispatch: true,
    );
    notifyListeners();
  }

  // Active Uploaded Video Preview State
  String activeVideoPath = '';
  String activeVideoName = 'VR_STORM_RUN.MP4';
  String activeCameraAngle = 'CAM_01_FRONT';
  bool showPhysicsOverlay = true;

  void setActiveVideo(String name, {String path = ''}) {
    activeVideoName = name;
    activeVideoPath = path;
    notifyListeners();
  }

  void setActiveCameraAngle(String angle) {
    activeCameraAngle = angle;
    notifyListeners();
  }

  void togglePhysicsOverlay() {
    showPhysicsOverlay = !showPhysicsOverlay;
    notifyListeners();
  }

  void uploadNewVideo(String nameOrPath) {
    final cleanName = nameOrPath.contains(RegExp(r'[/\\]')) ? nameOrPath.split(RegExp(r'[/\\]')).last : nameOrPath;
    activeVideoName = cleanName;
    activeVideoPath = nameOrPath.contains(RegExp(r'[/\\]')) ? nameOrPath : '';

    // Synchronize full timeline video track clip length
    videoClips = [
      VideoClipSegment(
        title: cleanName,
        startTime: 0.0,
        duration: _totalDuration,
      )
    ];
    notifyListeners();
  }

  // Timeline Tracks & Presets
  late List<FanTrackData> fanTracks;
  late List<VideoClipSegment> videoClips;
  String currentPresetName = 'Desert Storm Sigma';

  List<WindPreset> presets = [
    const WindPreset(
      id: 'p1',
      title: 'Desert Storm Sigma',
      modifiedTime: '2 hrs ago',
      isSelected: true,
      defaultF1: 0.85,
      defaultF2: 0.90,
      defaultF3: 0.70,
      description: 'High velocity VR desert storm preset.',
    ),
    const WindPreset(
      id: 'p2',
      title: 'Gentle Breeze Alpha',
      modifiedTime: 'Yesterday',
      isSelected: false,
      defaultF1: 0.25,
      defaultF2: 0.20,
      defaultF3: 0.15,
      description: 'Laminar low-speed background ambient airflow.',
    ),
    const WindPreset(
      id: 'p3',
      title: 'Turbulence Test 04',
      modifiedTime: '3 days ago',
      isSelected: false,
      defaultF1: 0.60,
      defaultF2: 0.85,
      defaultF3: 0.40,
      description: 'Stepped vortex relay test with staggered fan bursts.',
    ),
    const WindPreset(
      id: 'p4',
      title: 'Canyon Draft Default',
      modifiedTime: 'Oct 12, 2023',
      isSelected: false,
      defaultF1: 0.50,
      defaultF2: 0.50,
      defaultF3: 0.50,
      description: 'Standard baseline canyon flight preset.',
    ),
  ];

  // Save Modal State
  bool isSaveModalOpen = false;
  String presetSaveName = 'Scene_04_Storm_Approach';

  AeroSyncStateProvider({bool autoStartLoop = true}) {
    _initDefaultTracks();
    _initServices();
    if (autoStartLoop) {
      _startPlaybackLoop();
    }
  }

  void _initServices() {
    unityListener = UnityNetworkListener(
      port: 8052,
      onGameStartTriggered: (rawPacket, senderIp) {
        isUnityTriggerReceived = true;
        _currentTime = 0.0;
        _isManualSliderMode = false; // Timeline automation takes over on VR Game Start
        _isPlaying = true;
        notifyListeners();
      },
    );
    unityListener.startListening();
  }

  void _initDefaultTracks() {
    videoClips = [
      const VideoClipSegment(title: 'VR_STORM_RUN.MP4', startTime: 0.0, duration: 120.0),
    ];

    fanTracks = [
      FanTrackData(
        fanId: 'Fan 1',
        name: 'Fan 1',
        keyframes: [
          const SteppedKeyframe(timeSeconds: 0.0, state: FanState.off),
          const SteppedKeyframe(timeSeconds: 15.0, state: FanState.low),
          const SteppedKeyframe(timeSeconds: 40.0, state: FanState.high),
          const SteppedKeyframe(timeSeconds: 70.0, state: FanState.off),
          const SteppedKeyframe(timeSeconds: 85.0, state: FanState.low),
          const SteppedKeyframe(timeSeconds: 105.0, state: FanState.off),
        ],
      ),
      FanTrackData(
        fanId: 'Fan 2',
        name: 'Fan 2',
        keyframes: [
          const SteppedKeyframe(timeSeconds: 0.0, state: FanState.off),
          const SteppedKeyframe(timeSeconds: 22.0, state: FanState.high, hasHandleNode: true),
          const SteppedKeyframe(timeSeconds: 48.0, state: FanState.low, hasHandleNode: true),
          const SteppedKeyframe(timeSeconds: 72.0, state: FanState.off),
        ],
      ),
      FanTrackData(
        fanId: 'Fan 3',
        name: 'Fan 3',
        keyframes: [
          const SteppedKeyframe(timeSeconds: 0.0, state: FanState.off),
          const SteppedKeyframe(timeSeconds: 52.0, state: FanState.high),
          const SteppedKeyframe(timeSeconds: 100.0, state: FanState.off),
        ],
      ),
    ];
  }

  FanState _evaluateFanTrackState(String fanId) {
    final track = fanTracks.firstWhere((t) => t.fanId == fanId, orElse: () => fanTracks.first);
    return track.evaluateStateAt(_currentTime);
  }

  void _startPlaybackLoop() {
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_isPlaying) {
        _currentTime += 0.016;
        if (_currentTime >= _totalDuration) {
          _currentTime = 0.0;
        }

        // Dispatch hardware serial relay payload to ESP-01 / ESP-32
        hardwareDispatcher.dispatchStates(
          f1: f1State,
          f2: f2State,
          f3: f3State,
        );
      }

      // Step physical MPM wind engine with active fan intensities
      physicsEngine.stepSimulation(
        0.016,
        f1Intensity,
        f2Intensity,
        f3Intensity,
      );

      notifyListeners();
    });
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _isManualSliderMode = false; // Playing timeline activates automated tracks
      hardwareDispatcher.dispatchStates(
        f1: f1State,
        f2: f2State,
        f3: f3State,
        forceDispatch: true,
      );
    }
    notifyListeners();
  }

  void seekTo(double timeSeconds) {
    _currentTime = timeSeconds.clamp(0.0, _totalDuration);
    _isManualSliderMode = false; // Scrubbing timeline evaluates automated tracks
    
    hardwareDispatcher.dispatchStates(
      f1: f1State,
      f2: f2State,
      f3: f3State,
      forceDispatch: true,
    );
    notifyListeners();
  }

  void addKeyframe(String fanId, double timeSeconds, FanState state) {
    final track = fanTracks.firstWhere((t) => t.fanId == fanId);
    // Replace keyframes within 1.5 seconds window to update step point cleanly
    track.keyframes.removeWhere((k) => (k.timeSeconds - timeSeconds).abs() < 1.5);
    track.keyframes.add(SteppedKeyframe(timeSeconds: timeSeconds, state: state, hasHandleNode: true));
    track.keyframes.sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds));
  }

  // JSON Preset Serialization (Export & Import)
  String exportPresetJson() {
    final preset = WindTimelinePreset(
      presetName: currentPresetName,
      sceneDurationSeconds: _totalDuration,
      videoClips: videoClips,
      fanTracks: fanTracks,
    );
    return preset.encodeJson();
  }

  bool importPresetJson(String rawJson) {
    try {
      final preset = WindTimelinePreset.decodeJson(rawJson);
      currentPresetName = preset.presetName;
      videoClips = preset.videoClips;
      fanTracks = preset.fanTracks;
      _totalDuration = preset.sceneDurationSeconds;
      _isManualSliderMode = false;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void selectPreset(String id) {
    presets = presets.map((p) => p.copyWith(isSelected: p.id == id)).toList();
    final selected = presets.firstWhere((p) => p.id == id);
    currentPresetName = selected.title;
    _manualF1 = selected.defaultF1;
    _manualF2 = selected.defaultF2;
    _manualF3 = selected.defaultF3;
    _isManualSliderMode = true;
    notifyListeners();
  }

  void openSaveModal() {
    isSaveModalOpen = true;
    notifyListeners();
  }

  void closeSaveModal() {
    isSaveModalOpen = false;
    notifyListeners();
  }

  void saveCurrentPreset(String name) {
    currentPresetName = name;
    final newPreset = WindPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: name,
      modifiedTime: 'Just now',
      isSelected: true,
      defaultF1: f1Intensity,
      defaultF2: f2Intensity,
      defaultF3: f3Intensity,
    );
    presets = presets.map((p) => p.copyWith(isSelected: false)).toList();
    presets.insert(0, newPreset);
    isSaveModalOpen = false;
    notifyListeners();
  }

  // Formatted Timecodes using JetBrains Mono styling
  String get elapsedFormatted {
    final mins = (_currentTime / 60).floor().toString().padLeft(2, '0');
    final secs = (_currentTime % 60).floor().toString().padLeft(2, '0');
    final millis = ((_currentTime * 100) % 100).floor().toString().padLeft(2, '0');
    return '00:$mins:$secs.$millis';
  }

  String get remainingFormatted {
    final rem = _totalDuration - _currentTime;
    final mins = (rem / 60).floor().toString().padLeft(2, '0');
    final secs = (rem % 60).floor().toString().padLeft(2, '0');
    final millis = ((rem * 100) % 100).floor().toString().padLeft(2, '0');
    return '-00:$mins:$secs.$millis';
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    unityListener.stopListening();
    super.dispose();
  }
}
