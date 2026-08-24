import 'dart:convert';

enum FanState {
  off('Off', 0.0, 0),
  low('Low', 0.5, 1),
  high('High', 1.0, 2);

  final String label;
  final double intensity;
  final int levelCode;

  const FanState(this.label, this.intensity, this.levelCode);

  static FanState fromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'high':
        return FanState.high;
      case 'low':
        return FanState.low;
      case 'off':
      default:
        return FanState.off;
    }
  }

  static FanState fromIntensity(double value) {
    if (value < 0.25) return FanState.off;
    if (value < 0.75) return FanState.low;
    return FanState.high;
  }
}

class SteppedKeyframe {
  final double timeSeconds;
  final FanState state;
  final bool hasHandleNode;

  const SteppedKeyframe({
    required this.timeSeconds,
    required this.state,
    this.hasHandleNode = false,
  });

  double get value => state.intensity;

  Map<String, dynamic> toJson() => {
        'time': timeSeconds,
        'state': state.label,
        'hasHandleNode': hasHandleNode,
      };

  factory SteppedKeyframe.fromJson(Map<String, dynamic> json) {
    return SteppedKeyframe(
      timeSeconds: (json['time'] as num).toDouble(),
      state: FanState.fromLabel(json['state'] as String? ?? 'Off'),
      hasHandleNode: json['hasHandleNode'] as bool? ?? false,
    );
  }
}

class VideoClipSegment {
  final String title;
  final double startTime;
  final double duration;

  const VideoClipSegment({
    required this.title,
    required this.startTime,
    required this.duration,
  });

  double get endTime => startTime + duration;

  Map<String, dynamic> toJson() => {
        'title': title,
        'startTime': startTime,
        'duration': duration,
      };

  factory VideoClipSegment.fromJson(Map<String, dynamic> json) {
    return VideoClipSegment(
      title: json['title'] as String,
      startTime: (json['startTime'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
    );
  }
}

class FanTrackData {
  final String fanId; // 'Fan 1', 'Fan 2', 'Fan 3'
  final String name;
  final List<SteppedKeyframe> keyframes;

  FanTrackData({
    required this.fanId,
    required this.name,
    required this.keyframes,
  });

  /// Zero-order hold (stepped / non-interpolated) evaluator
  FanState evaluateStateAt(double timeSeconds) {
    if (keyframes.isEmpty) return FanState.off;
    if (timeSeconds < keyframes.first.timeSeconds) return FanState.off;

    FanState currentState = FanState.off;
    for (final kf in keyframes) {
      if (timeSeconds >= kf.timeSeconds) {
        currentState = kf.state;
      } else {
        break;
      }
    }
    return currentState;
  }

  double evaluateAt(double timeSeconds) {
    return evaluateStateAt(timeSeconds).intensity;
  }

  Map<String, dynamic> toJson() => {
        'fanId': fanId,
        'name': name,
        'keyframes': keyframes.map((k) => k.toJson()).toList(),
      };

  factory FanTrackData.fromJson(Map<String, dynamic> json) {
    return FanTrackData(
      fanId: json['fanId'] as String,
      name: json['name'] as String,
      keyframes: (json['keyframes'] as List)
          .map((k) => SteppedKeyframe.fromJson(k as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WindTimelinePreset {
  final String schemaVersion;
  final String presetName;
  final double sceneDurationSeconds;
  final List<VideoClipSegment> videoClips;
  final List<FanTrackData> fanTracks;

  WindTimelinePreset({
    this.schemaVersion = '1.0',
    required this.presetName,
    this.sceneDurationSeconds = 120.0,
    required this.videoClips,
    required this.fanTracks,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'presetName': presetName,
        'sceneDurationSeconds': sceneDurationSeconds,
        'videoClips': videoClips.map((v) => v.toJson()).toList(),
        'fanTracks': fanTracks.map((f) => f.toJson()).toList(),
      };

  factory WindTimelinePreset.fromJson(Map<String, dynamic> json) {
    return WindTimelinePreset(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0',
      presetName: json['presetName'] as String,
      sceneDurationSeconds: (json['sceneDurationSeconds'] as num?)?.toDouble() ?? 120.0,
      videoClips: (json['videoClips'] as List? ?? [])
          .map((v) => VideoClipSegment.fromJson(v as Map<String, dynamic>))
          .toList(),
      fanTracks: (json['fanTracks'] as List? ?? [])
          .map((f) => FanTrackData.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  String encodeJson() => jsonEncode(toJson());

  static WindTimelinePreset decodeJson(String rawJson) {
    final Map<String, dynamic> data = jsonDecode(rawJson) as Map<String, dynamic>;
    return WindTimelinePreset.fromJson(data);
  }
}
