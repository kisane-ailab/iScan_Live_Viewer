import 'dart:typed_data';

/// 카메라 데이터 스트림 콜백
typedef OnFrameReceived = void Function(Map<String, dynamic> header, Uint8List imageData);
typedef OnError = void Function(String error);

/// 카메라 레포지토리 인터페이스
abstract class CameraRepository {
  /// 카메라에 연결
  Future<void> connect(String address, {
    required OnFrameReceived onFrame,
    required OnError onError,
  });

  /// 카메라 연결 해제
  void disconnect();

  /// 연결 상태
  bool get isConnected;
}
