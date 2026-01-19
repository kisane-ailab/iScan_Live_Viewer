import 'dart:async';
import 'package:flutter/widgets.dart';
import 'generated/native_video_api.g.dart';

/// Native C++ 기반 비디오 렌더러
///
/// ZMQ 수신 및 JPEG 디코딩을 C++에서 처리하여 고성능 비디오 스트리밍을 제공합니다.
/// - libjpeg-turbo: SIMD 가속 JPEG 디코딩 (~1-2ms)
/// - ZeroMQ: 네이티브 소켓 통신
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

  /// ZMQ 스트림 시작
  ///
  /// [zmqAddress] - ZMQ 연결 주소 (예: "tcp://localhost:5556")
  Future<void> startStream(String zmqAddress) async {
    if (!_isInitialized || _textureKey == null) {
      throw StateError('NativeVideoRenderer not initialized. Call initialize() first.');
    }
    await _hostApi.startStream(_textureKey!, zmqAddress);
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
