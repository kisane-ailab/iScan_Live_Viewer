import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'camera_state.freezed.dart';

/// 카메라 연결 상태를 나타내는 엔티티
@freezed
class CameraState with _$CameraState {
  const factory CameraState({
    required int id,
    required String address,
    String? presetLabel, // 프리셋에서 선택한 경우 라벨 (예: "천상가옥 - top_1(R)")
    @Default(false) bool isConnected,
    @Default(false) bool isConnecting,
    @Default(false) bool isReceiveTimeout,
    Uint8List? imageData,
    ui.Image? decodedImage,
    int? textureId, // Native 텍스처 ID
    Map<String, dynamic>? header,
    @Default([]) List<String> logs,
    @Default(0) int frameCount,
    @Default(0.0) double receiveFps,
    @Default(0.0) double renderFps,
    String? error,
    DateTime? lastFrameTime,
  }) = _CameraState;
}
