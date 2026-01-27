import 'dart:async';
import 'package:flutter/widgets.dart';
import 'generated/native_video_api.g.dart';

/// Native C++ 기반 비디오 렌더러
///
/// ZMQ 또는 HTTP MJPEG 스트림 수신 및 JPEG 디코딩을 C++에서 처리하여
/// 고성능 비디오 스트리밍을 제공합니다.
///
/// 지원 프로토콜:
/// - ZMQ: tcp://IP:PORT (예: tcp://192.168.0.100:17002)
/// - HTTP MJPEG: http://IP:PORT/path (예: http://192.168.0.100:18081/livecam/mjpeg?cam=left)
///
/// 주소 형식에 따라 자동으로 프로토콜이 선택됩니다:
/// - tcp:// 또는 지정 없음 → ZMQ PUB/SUB
/// - http:// 또는 https:// → HTTP MJPEG 스트리밍
///
/// 기술 스택:
/// - libjpeg-turbo: SIMD 가속 JPEG 디코딩 (~1-2ms)
/// - ZeroMQ: ZMQ 스트림용 네이티브 소켓 통신
/// - WinHTTP: HTTP MJPEG 스트림용 HTTP 클라이언트
/// - TextureRegistrar: 제로카피 GPU 텍스처 업데이트
class NativeVideoRenderer implements NativeVideoFlutterApi {
  final NativeVideoHostApi _hostApi = NativeVideoHostApi();
  int? _textureId;
  int? _textureKey;
  bool _isInitialized = false;

  /// 프레임 수신 콜백
  void Function(FrameInfo info)? onFrameReceivedCallback;

  /// 에러 콜백
  void Function(String message)? onErrorCallback;

  /// 현재 텍스처 ID
  int? get textureId => _textureId;

  /// 초기화 여부
  bool get isInitialized => _isInitialized;

  /// 렌더러 초기화
  ///
  /// [textureKey] - 텍스처 식별용 키
  /// Returns: Flutter TextureWidget에서 사용할 textureId
  Future<int> initialize(int textureKey) async {
    _textureKey = textureKey;
    _textureId = await _hostApi.initialize(textureKey);
    _isInitialized = true;
    return _textureId!;
  }

  /// 스트림 시작 (ZMQ 또는 HTTP MJPEG 자동 감지)
  ///
  /// [address] - 스트림 주소
  ///   - ZMQ: "tcp://IP:PORT" (예: "tcp://192.168.0.100:17002")
  ///   - HTTP MJPEG: "http://IP:PORT/path" (예: "http://192.168.0.100:18081/livecam/mjpeg?cam=left")
  Future<void> startStream(String address) async {
    if (!_isInitialized || _textureKey == null) {
      throw StateError('NativeVideoRenderer not initialized. Call initialize() first.');
    }
    await _hostApi.startStream(_textureKey!, address);
  }

  /// ZMQ 스트림 중지
  Future<void> stopStream() async {
    if (_textureKey == null) return;
    await _hostApi.stopStream(_textureKey!);
  }

  /// 현재 프레임 정보 가져오기 (폴링용)
  Future<FrameInfo?> getFrameInfo() async {
    if (!_isInitialized || _textureKey == null) return null;
    return await _hostApi.getFrameInfo(_textureKey!);
  }

  /// 리소스 정리
  Future<void> dispose() async {
    if (_textureKey != null) {
      await _hostApi.dispose(_textureKey!);
    }
    _textureId = null;
    _textureKey = null;
    _isInitialized = false;
  }

  /// 텍스처 위젯 생성
  ///
  /// [width], [height] - 위젯 크기
  Widget buildTextureWidget({double? width, double? height}) {
    if (_textureId == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: width,
      height: height,
      child: Texture(textureId: _textureId!),
    );
  }

  // NativeVideoFlutterApi implementation

  @override
  void onFrameReceived(FrameInfo info) {
    onFrameReceivedCallback?.call(info);
  }

  @override
  void onError(String message) {
    onErrorCallback?.call(message);
  }
}
