import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/infrastructure/native/generated/native_video_api.g.dart',
  cppHeaderOut: 'windows/runner/native_video_api.g.h',
  cppSourceOut: 'windows/runner/native_video_api.g.cpp',
))

/// Frame info from video stream header
class FrameInfo {
  FrameInfo({
    this.camIdx,
    this.camNum,
    this.brightness,
    this.motion,
    this.bboxX,
    this.bboxY,
    this.bboxW,
    this.bboxH,
    required this.frameCount,
  });

  String? camIdx;
  String? camNum;
  double? brightness;
  bool? motion;
  int? bboxX;
  int? bboxY;
  int? bboxW;
  int? bboxH;
  int frameCount;
}

/// Host API - called from Dart, implemented in C++
@HostApi()
abstract class NativeVideoHostApi {
  /// Initialize renderer and return textureId
  int initialize(int textureKey);

  /// Start ZMQ stream for specific texture
  void startStream(int textureKey, String zmqAddress);

  /// Stop ZMQ stream for specific texture
  void stopStream(int textureKey);

  /// Get current frame info (for polling)
  FrameInfo? getFrameInfo(int textureKey);

  /// Dispose resources for specific texture
  void dispose(int textureKey);
}

/// Flutter API - called from C++, implemented in Dart
@FlutterApi()
abstract class NativeVideoFlutterApi {
  /// Frame received callback with header info
  void onFrameReceived(FrameInfo info);

  /// Error callback
  void onError(String message);
}
