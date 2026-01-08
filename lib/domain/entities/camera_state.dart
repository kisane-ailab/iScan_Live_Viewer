import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'camera_state.freezed.dart';

/// 카메라 연결 상태를 나타내는 엔티티
@freezed
class CameraState with _$CameraState {
  const factory CameraState({
    required int id,
    required String address,
    @Default(false) bool isConnected,
    @Default(false) bool isConnecting,
    @Default(false) bool isReceiveTimeout,
    Uint8List? imageData,
    Map<String, dynamic>? header,
    @Default([]) List<String> logs,
    @Default(0) int frameCount,
    @Default(0.0) double receiveFps,
    @Default(0.0) double renderFps,
    String? error,
    DateTime? lastFrameTime,
  }) = _CameraState;
}
